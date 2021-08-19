//
//  WorkoutRecorder.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 05.08.21.
//

import CoreLocation
import MapKit
import Combine

/**
 Central class to provide workout related informations.
 - start/stop GPS, BLE and ACL for locations, heartrate and activity updates.
 - Reset component if failure occurs with retry delays starting at 1 second and increasing up to one minute. (1, 5, 10, 30, 60)
 - Provide current duration, pace, heartrate and vdot
 - Provide current distance, avg pace, avg heartrate, duration and vdot for each intensity, total and breaks
 - Provide smoothed path, including smoothed first location and calculated last location, with intensity and pausing segmentation.
 - Record heartrate and trigger sharing on HealthKit for Workout, smoothed route and heartrate samples when stopped.
 - Save info for workout on disk as compressed JSON after workout has stopped.
 
 Further principles:
 - Calculate as much as possible in background-threads
 - Build as much as possible useful information if a component (GPS, BLE, ACL) ist not receiving for any reason.
 */

public class WorkoutRecorder: ObservableObject {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    static var sharedInstance = WorkoutRecorder()
    
    /// Use singleton @sharedInstance
    private init() {}

    // MARK: - Published
    
    public struct Info {
        let infoSegment: InfoSegment
        let duration: TimeInterval
        let distance: CLLocationDistance // Only available if running. Zero if paused.
        let heartrateSec: Double // Only available if running. Zero if paused.
    }
    
    public enum InfoSegment: Hashable {
        case paused
        case running(intensity: Intensity)
    }
    
    /// Current, smoothed path so far. No RDP done on it. Just adHoc smoothing:
    /// - Only locations average while pausing
    /// - No post processing for deffered arrival of locations or segments.
    /// - locations before start and after stop are filtered out
    @Published public private(set) var simpleSmoothedPath = [CLLocation]()
    
    /// Statistics like distance, avg pace, time, avg heartrate per intensity.
    @Published public private(set) var totals = [InfoSegment: Info]()
    
    /// Start receiving data. Ignore any values, that have an earlier timestamp
    public func start(_ when: Date = Date()) {
        // Cleanup any previous run data
        isRunningEvents.removeAll()
        heartrateEvents.removeAll()
        locationEvents.removeAll()
        segments.removeAll()
        totals.removeAll()
        simpleSmoothedPath.removeAll()
        
        // Ensure to get data only while started
        startedEvent(StartedEvent(when: when, isStarted: true))
        
        // Start raw data receiver
        isRunningSink = AclMotionReceiver.sharedInstance.$isRunning.sink { e in
            DispatchQueue.global(qos: .userInitiated).async {self.isRunningEvent(e)}
        }
        heartrateSink = BleHeartrateReceiver.sharedInstance.$heartrate.sink { e in
            DispatchQueue.global(qos: .userInitiated).async {self.heartrateEvent(e)}
        }
        locationSink = GpsLocationReceiver.sharedInstance.$location.sink { e in
            DispatchQueue.global(qos: .userInitiated).async {self.locationEvent(e)}
        }
        
        // Start the engines
        AclMotionReceiver.sharedInstance.start()
        BleHeartrateReceiver.sharedInstance.start()
        GpsLocationReceiver.sharedInstance.start()
    }
    
    /// Stop receiving data. Ignore any values, that are received afterwards. Trigger sharing with healtkit.
    public func stop(_ when: Date = Date()) {
        startedEvent(StartedEvent(when: when, isStarted: false))

        // Stop the engines
        AclMotionReceiver.sharedInstance.stop()
        BleHeartrateReceiver.sharedInstance.stop()
        GpsLocationReceiver.sharedInstance.stop()
        
        // Save as compressed json to disk
        try? save()
        
        // TODO: Share
    }
    
    /// Get current totals, extrapolated up to given time
    public func current(_ when: Date = Date()) -> (
        paceSecPerKm: TimeInterval,
        totals: [InfoSegment: Info],
        total: Info)
    {
        func sum(totals: [InfoSegment: Info]) -> Info {
            return totals.reduce(Info.zero) {
                Info(
                    infoSegment: $0.infoSegment,
                    duration: $0.duration + $1.value.duration,
                    distance: $0.distance + $1.value.distance,
                    heartrateSec: $0.heartrateSec + $1.value.heartrateSec)
            }
        }
        
        if let last = segments.last, last.time.contains(when) {
            let totals = addSegmentTo(totals: totals, segment: last, till: when)
            return (last.paceSecPerKm, totals, sum(totals: totals))
        } else {
            return (.infinity, totals, sum(totals: totals))
        }
    }

    // MARK: - Private

    fileprivate enum Segment {
        case paused(location: CLLocation? = nil, duration: TimeInterval = 0.0)
        case running(
                intensity: Intensity,
                distance: CLLocationDistance = 0.0,
                heartrate: Double = 0.0,
                asOf: Date)
    }
    
    fileprivate struct TimedSegment {
        var segment: Segment
        var time: Range<Date>
    }

    fileprivate struct StartedEvent {
        let when: Date
        let isStarted: Bool
    }
    
    fileprivate struct HeartrateEvent {
        let when: Date
        let heartrate: Int
        let intensity: Intensity?
    }

    // MARK: Raw data
    private var startedEvents = [StartedEvent]()
    private var isRunningEvents = [AclMotionReceiver.IsRunning]()
    private var heartrateEvents = [HeartrateEvent]()
    private var locationEvents = [CLLocation]()

    /// Read the raw data of motions
    private var isRunningSink: AnyCancellable? = nil

    /// Read the raw data of heartrates
    private var heartrateSink: AnyCancellable? = nil

    /// Read the raw data of locations
    private var locationSink: AnyCancellable? = nil
    
    private func startedEvent(_ event: StartedEvent) {
        // Raw data
        startedEvents.append(event)
        
        // Segments
        _ = appendSegments(when: event.when)
    }
    
    private func isRunningEvent(_ event: AclMotionReceiver.IsRunning) {
        // Raw data
        isRunningEvents.append(event)
        
        // Segments
        _ = appendSegments(when: event.when)
    }
    
    private func heartrateEvent(_ heartrate: BleHeartrateReceiver.Heartrate?) {
        guard let heartrate = heartrate else {return} // False alarm
        
        // Raw data
        var intensity: Intensity? {
            let hrMax = Database.sharedInstance.hrMax.value
            let hrResting = Database.sharedInstance.hrResting.value
            let prevIntensity = heartrateEvents.last?.intensity

            if hrMax.isFinite && hrResting.isFinite {
                return intensity4Hr(
                    hrBpm: heartrate.heartrate,
                    hrMaxBpm: Int(hrMax + 0.5),
                    restingBpm: Int(hrResting + 0.5),
                    prevIntensity: prevIntensity)
            } else if hrMax.isFinite {
                return intensity4Hr(
                    hrBpm: heartrate.heartrate,
                    hrMaxBpm: Int(hrMax + 0.5),
                    prevIntensity: prevIntensity)
            } else {
                return nil
            }
        }

        let prevEvent = heartrateEvents.last
        let event = HeartrateEvent(
            when: heartrate.when,
            heartrate: heartrate.heartrate,
            intensity: intensity)
        heartrateEvents.append(event)
        
        // Segments
        if !appendSegments(when: (prevEvent ?? event).when),
           let last = segments.last,
           let intensity = event.intensity,
           last.segment.isRunning(at: intensity)
        {
            // HR was actual HR since prev event or segement start
            let duration = last.time.lowerBound.distance(to: event.when)
            let hrSec = Double(event.heartrate) * duration
            
            // Update segment and incorporate this heartrate
            if let segment = last.segment.incorporate(heartrateSec: hrSec) {
                segments[segments.endIndex - 1].segment = segment
            }
        }
    }
    
    private func locationEvent(_ location: CLLocation?) {
        guard let location = location else {return} // False alarm
        
        // Raw data
        let prevEvent = locationEvents.last
        locationEvents.append(location)
        
        // Segments
        if !appendSegments(when: location.timestamp),
           let last = segments.last
        {
            let s = last.segment.incorporate(
                location: location,
                prevLocation: prevEvent,
                startedAt: last.time.lowerBound)
            
            (0 ..< s.endIndex)
                .filter {segments.endIndex - s.endIndex + $0 >= 0}
                .forEach {segments[segments.endIndex - s.endIndex + $0].segment = s[$0]}
        }
        
        // Simplified Path
        if let last = segments.last,
           last.time.contains(location.timestamp)
        {
            DispatchQueue.main.async {
                switch last.segment {
                case .running:
                    self.simpleSmoothedPath.append(location)
                case .paused(let avgLocation, _):
                    if let avgLocation = avgLocation,
                       let lastLocation = self.simpleSmoothedPath.last,
                       last.time.contains(lastLocation.timestamp)
                    {
                        self.simpleSmoothedPath[self.simpleSmoothedPath.endIndex - 1] = avgLocation
                    } else {
                        self.simpleSmoothedPath.append(location)
                    }
                }
            }
        }
    }

    // MARK: Resulting data
    private var segments = [TimedSegment]()
    
    /// From latest HR, loc, running-status: What sould the segment acutally look like?
    private func actualSegment() -> Segment? {
        guard let lastStarted = startedEvents.last, lastStarted.isStarted else {return nil}
        guard let lastRunning = isRunningEvents.last, lastRunning.isRunning else {return .paused()}

        guard let lastHeartrate = heartrateEvents.last,
              let lastIntensity = lastHeartrate.intensity else
        {
            return .paused() // TODO: Alternative: return .running(intensity: .Easy)
        }
        
        let asOf = [lastStarted.when, lastRunning.when, lastHeartrate.when].max()!
        return .running(intensity: lastIntensity, asOf: asOf)
    }
    
    private func segmentChanged(actual: Segment?) -> Bool {
        let current = segments.last?.segment
        
        // Case both nil
        if current == nil && actual == nil {return false}
        guard let current = current, let actual = actual else {return true} // One is nil
        
        // Case both .paused. Location doesn't matter
        if current.isPaused && actual.isPaused {return false}
        
        // Case both are .running at same intensity. Distance and heartrate do not matter
        if current.isRunningAtSameIntensity(actual) {return false}
        
        return true
    }
    
    /// Return true, if new segment were appended.
    private func appendSegments(when: Date) -> Bool {
        let actual = actualSegment()
        guard segmentChanged(actual: actual) else {return false}
        
        // Close current
        if let last = segments.last {
            segments[segments.endIndex - 1].time = last.time.lowerBound ..< when
            let localTotals = addSegmentTo(totals: totals, segment: segments[segments.endIndex - 1])
            DispatchQueue.main.async {self.totals = localTotals}
        }
        
        // Append new segment
        if let actual = actual {
            segments.append(TimedSegment(segment: actual, time: when ..< Date.distantFuture))
            return true
        }
        return false
    }
    
    private func addSegmentTo(
        totals: [InfoSegment: Info],
        segment: TimedSegment,
        till: Date = .distantFuture) -> [InfoSegment: Info]
    {
        var totals = totals
        let info = Info(segment: segment, till: till)

        if let info0 = totals[info.infoSegment] {
            totals[info.infoSegment] = info0.added(other: info)
        } else {
            totals[info.infoSegment] = info
        }
        return totals
    }
    
    // MARK: Save and restore
    
    private struct CombinedCodable: Codable {
        var startedEvents = [StartedEvent]()
        var isRunningEvents = [AclMotionReceiver.IsRunning]()
        var heartrateEvents = [HeartrateEvent]()
        var locationEvents = [CodableCLLocation]()
    }
    
    /// Save all raw data:  Info, Locations, heartrates, running periods, start/Stop events
    private func save() throws {
        // Create a combined struct
        let combinedCodable = CombinedCodable(
            startedEvents: startedEvents,
            isRunningEvents: isRunningEvents,
            heartrateEvents: heartrateEvents,
            locationEvents: locationEvents.map {CodableCLLocation($0)})
        
        // encode into data and compress
        let data = try (JSONEncoder().encode(combinedCodable) as NSData).compressed(using: .lzfse)
        
        // Write to disk
        if let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let url = path.appendingPathComponent("\(Date().timeIntervalSince1970).json.lzfse")
            log(data.length, data.write(to: url, atomically: true))
        } else {
            throw "Cannot get Document Path"
        }
    }
}

// MARK: - Extensions

// MARK: InfoSegment Identififable
extension WorkoutRecorder.InfoSegment: Identifiable {
    public var id: Self {self}
    
    public var name: String {
        switch self {
        case .paused:
            return "paused"
        case .running(let intensity):
            return intensity.rawValue
        }
    }
}

// MARK: Info Identifiable
extension WorkoutRecorder.Info {
    var avgHeartrate: Int {Int(heartrateSec / duration + 0.5)}
    
    var avgPaceKmPerSec: TimeInterval {1000.0 * duration / distance}
    
    var vdot: Double {
        let hrMax = Database.sharedInstance.hrMax.value
        let hrResting = Database.sharedInstance.hrResting.value
        
        if hrMax.isFinite && hrResting.isFinite {
            return train(
                hrBpm: avgHeartrate,
                hrMaxBpm: Int(hrMax + 0.5),
                restingBpm: Int(hrResting + 0.5),
                paceSecPerKm: avgPaceKmPerSec) ?? .nan
        } else if hrMax.isFinite {
            return train(
                hrBpm: avgHeartrate,
                hrMaxBpm: Int(hrMax + 0.5),
                paceSecPerKm: avgPaceKmPerSec) ?? .nan
        } else {
            return .nan
        }
    }
    
    fileprivate init(segment: WorkoutRecorder.TimedSegment, till: Date) {
        duration = segment.time.lowerBound.distance(to: min(till, segment.time.upperBound))
        
        switch segment.segment {
        case .paused:
            infoSegment = .paused
            distance = 0.0
            heartrateSec = 0.0
        case .running(let intensity, let distance, let heartrateSec, let asOf):
            let deltaDuration = asOf.distance(to: till)
            infoSegment = .running(intensity: intensity)
            self.distance = distance * (duration + deltaDuration) / duration
            self.heartrateSec = heartrateSec
            
            log(self.distance, duration, deltaDuration, asOf, till, segment.time)
        }
    }
    
    fileprivate func added(other: WorkoutRecorder.Info) -> Self? {
        guard other.infoSegment == self.infoSegment else {return nil} // Must be same id
        
        return WorkoutRecorder.Info(
            infoSegment: infoSegment,
            duration: duration + other.duration,
            distance: distance + other.distance,
            heartrateSec: heartrateSec + other.heartrateSec)
    }
    
    static var zero: WorkoutRecorder.Info {
        WorkoutRecorder.Info(
            infoSegment: .paused,
            duration: 0,
            distance: 0,
            heartrateSec: 0)
    }
}

extension WorkoutRecorder.Segment: Equatable {
    fileprivate var isPaused: Bool {
        switch self {
        case .paused:
            return true
        default:
            return false
        }
    }
    
    fileprivate func isRunning(at intensity: Intensity) -> Bool {
        switch self {
        case .running(let localIntensity, _, _, _):
            return localIntensity == intensity
        default:
            return false
        }
    }
    
    fileprivate func isRunningAtSameIntensity(_ other: WorkoutRecorder.Segment) -> Bool {
        switch self {
        case .running(let localIntensity, _, _, _):
            switch other {
            case .running(let otherIntensity, _, _, _):
                return localIntensity == otherIntensity
            default:
                return false
            }
        default:
            return false
        }
    }
    
    fileprivate func incorporate(heartrateSec: Double) -> WorkoutRecorder.Segment? {
        switch self {
        case .running(let intensity, let distance, let hrSec, let asOf):
            return WorkoutRecorder.Segment.running(
                intensity: intensity,
                distance: distance,
                heartrate: hrSec + heartrateSec,
                asOf: asOf)
        default:
            return nil
        }
    }
    
    fileprivate func incorporate(location: CLLocation, prevLocation: CLLocation?, startedAt: Date) -> [WorkoutRecorder.Segment]
    {
        // Segment change in between?
        if let prevLocation = prevLocation,
           (prevLocation.timestamp ..< location.timestamp).contains(startedAt)
        {
            let midLocation = prevLocation.interpolate(to: location, at: startedAt)
            return [
                incorpLocations(from: prevLocation, to: midLocation),
                incorpLocations(from: midLocation, to: location)
            ]
        } else if let prevLocation = prevLocation {
            return [incorpLocations(from: prevLocation, to: location)]
        } else {
            return [incorpFirstLocation(location)]
        }
    }
    
    private func incorpLocations(from: CLLocation, to: CLLocation) -> WorkoutRecorder.Segment {
        switch self {
        case .paused(let avgLocation, let duration):
            guard let avgLocation = avgLocation else {return .paused(location: to)}

            let durationBefore = duration
            let durationDelta = avgLocation.timestamp.distance(to: to.timestamp)
            let durationNow = duration + durationDelta

            let prevLat = avgLocation.coordinate.latitude
            let prevLon = avgLocation.coordinate.longitude
            let prevAcc = avgLocation.horizontalAccuracy
            
            let currLat = to.coordinate.latitude
            let currLon = to.coordinate.longitude
            let currAcc = to.horizontalAccuracy

            let newLat = prevLat * (durationBefore / durationNow) + currLat * (durationDelta / durationNow)
            let newLon = prevLon * (durationBefore / durationNow) + currLon * (durationDelta / durationNow)
            let newAcc = sqrt(
                prevAcc*prevAcc * (durationBefore / durationNow) +
                    currAcc*currAcc * (durationDelta / durationNow))
            log(newLat, newLon, newAcc)
            
            let newLoc = to.moveTo(
                coordinate: CLLocationCoordinate2D(latitude: newLat, longitude: newLon),
                horizontalAccuracy: newAcc)
            
            return .paused(location: newLoc, duration: durationNow)
            
        case .running(let intensity, let distance, let heartrate, _):
            return .running(
                intensity: intensity,
                distance: distance + to.distance(from: from),
                heartrate: heartrate,
                asOf: to.timestamp)
        }
    }
    
    private func incorpFirstLocation(_ location: CLLocation) -> WorkoutRecorder.Segment {
        switch self {
        case .paused:
            return .paused(location: location)
        case .running:
            return self
        }
    }
}

extension WorkoutRecorder.TimedSegment {
    var paceSecPerKm: TimeInterval {
        switch segment {
        case .paused:
            return .infinity
        case .running(_, let distance, _, let asOf):
            let duration = time.lowerBound.distance(to: asOf)
            return 1000.0 * duration / distance
        }
    }
}

// MARK: Codable's

extension WorkoutRecorder.Info: Codable {}

extension WorkoutRecorder.InfoSegment: Codable {
    private enum CodableInfoSegmentEnum: String, Codable {
        case paused, running
    }
    
    private struct CodableInfoSegment: Codable {
        let enumContent: CodableInfoSegmentEnum
        let intensity: Intensity?
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let codable = try container.decode(CodableInfoSegment.self)

        switch codable.enumContent {
        case .paused:
            self = .paused
        case .running:
            if let intensity = codable.intensity {
                self = .running(intensity: intensity)
            } else {
                throw "Cannot decode from container!"
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .paused:
            try container.encode(CodableInfoSegment(enumContent: .paused, intensity: nil))
        case .running(let intensity):
            try container.encode(CodableInfoSegment(enumContent: .running, intensity: intensity))
        }
    }
}

extension WorkoutRecorder.StartedEvent: Codable {}
extension WorkoutRecorder.HeartrateEvent: Codable {}

struct CodableCLLocation: Codable {
    private let latitude: CLLocationDegrees
    private let longitude: CLLocationDegrees
    private let altitude: CLLocationDistance
    private let horizontalAccuracy: CLLocationAccuracy
    private let verticalAccuracy: CLLocationAccuracy
    private let timestamp: Date
    
    init(_ location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
        self.timestamp = location.timestamp
    }
    
    var asLocation: CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            timestamp: timestamp)
    }
}
