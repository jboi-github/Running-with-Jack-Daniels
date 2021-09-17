//
//  AggregateManager.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 15.09.21.
//

import Foundation
import CoreLocation
import Combine

/**
 Read states from status-Q of events and aggregate to necessary indicators:
 
 - Overall duration, distance of pauses (started, not running)
 - For each intensity, while started and running: duration, distance, avg-hr
 - Locations-Path: While started and running. While started and not running: Avg-Location per segment.
 - Segments while started: Begin, end, duration, distance (0, if not running), avg-hr (nan if not running)
 - Whenever duration, distance and avg-hr is known, calculate pace, vdot.
 */
class AggregateManager {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    static var sharedInstance = AggregateManager()

    /// Use singleton @sharedInstance
    init() {}
    
    // MARK: - Published
    
    public func start(at: Date = Date()) {
        log()
        totals.reset()
        segments.reset()
        locations.reset()

        EventsManager.sharedInstance.start(at: at)
        EventsManager.sharedInstance.statusPublisher
            .compactMap { [self] (type: EventsManager.AppStatusType) -> EventsManager.AppStatus? in
                switch type {
                case .rollback(let after):
                    rollback(after: after)
                    return nil
                case .commit(let before):
                    commit(before: before)
                    return nil
                case .status(let status):
                    return status
                }
            }
            .scan(Transition(durationS: 0, distanceM: 0, status: nil))
            { transition, status in
                guard let prevStatus = transition.status else {
                    return Transition(durationS: 0, distanceM: 0, status: status)
                }
                
                guard let prevLocation = prevStatus.T.location, let thisLocation = status.T.location else {
                    return transition
                }
                
                return Transition(
                    durationS: prevStatus.when.distance(to: status.when),
                    distanceM: thisLocation.distance(from: prevLocation),
                    status: status)
            }
            .sink { completion in
                var error: Error? {
                    switch completion {
                    case .finished:
                        return nil
                    case.failure(let error):
                        return error
                    }
                }
                if !check(error) {self.stop()}
            } receiveValue: {self.aggregate($0)}
            .store(in: &subscribers)

    }
    
    public func stop(at: Date = Date()) {
        log()
        EventsManager.sharedInstance.stop(at: at)
        totals.save()
        segments.save()
        locations.save()
    }
    
    public func reset(at: Date = Date()) {
        log()
        totals.reset()
        segments.reset()
        locations.reset()
        EventsManager.sharedInstance.reset(at: at)
    }
    
    // MARK: - Private
    
    /// Save all raw data:  Info, Locations, heartrates, running periods, start/Stop events
    private func save() throws { // TODO: !
        // Create a combined struct
        let combinedCodable = 3
        
        // encode into data and compress
        let data = try (JSONEncoder().encode(combinedCodable) as NSData).compressed(using: .lzfse)
        
        // Write to disk
        if let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let url = path
                .appendingPathComponent("Running-with-Jack-Daniels")
                .appendingPathComponent("\(Date().timeIntervalSince1970).json.lzfse")
            log(url, data.length, data.write(to: url, atomically: true))
        } else {
            throw "Cannot get Document Path"
        }
    }

    /// Available information that is contained in transition from one state to the next and in addition to what the state gives.
    fileprivate struct Transition {
        let durationS: TimeInterval
        let distanceM: CLLocationDistance
        
        let status: EventsManager.AppStatus!
    }
    
    private var subscribers = Set<AnyCancellable>()
    
    private func rollback(after: Date) {
        totals.rollback(after: after)
        segments.rollback(after: after)
        locations.rollback(after: after)
    }
    
    private func commit(before: Date) {
        totals.commit(before: before)
        segments.commit(before: before)
        locations.commit(before: before)
    }
    
    fileprivate func aggregate(_ transition: Transition) {
        totals.aggregate(transition: transition)
        segments.aggregate(transition: transition)
        locations.aggregate(transition: transition)
    }
    
    private struct Total: AggregateContent {
        static let zero = Self()

        static func + (lhs: Self, rhs: Transition) -> Self? {
            guard let isStarted = rhs.status.T.isStarted, isStarted else {return nil}
            
            guard let isRunning = rhs.status.T.isRunning,
                  let intensity = rhs.status.T.intensity
            else {return nil}
            
            let categorical = Categorical(isRunning: isRunning, intensity: intensity)
            let continuous = lhs.totals[categorical, default: Continuous.zero]
            var totals = lhs.totals
            
            let sumDurationSec = rhs.durationS + continuous.durationSec
            let sumDistanceM = isRunning ? rhs.distanceM + continuous.distanceM : 0
            let avgHeartrateBpm = AggregateManager.heartreateBpm(
                rhs.status.T.hrBpm ?? 0, continuous.heartrateBpm,
                rhs.durationS, continuous.durationSec)
            
            totals[categorical] = Continuous(
                durationSec: sumDurationSec,
                distanceM: sumDistanceM,
                heartrateBpm: avgHeartrateBpm)
            return Self(totals: totals)
        }
        
        // Categorical features
        struct Categorical: Hashable {
            let isRunning: Bool
            let intensity: Intensity
        }
        
        // Continuous features
        struct Continuous {
            let durationSec: TimeInterval
            let distanceM: CLLocationDistance
            let heartrateBpm: Int
            
            var paceSecPerKm: TimeInterval {AggregateManager.paceSecPerKm(distanceM, durationSec)}
            var vdot: Double {AggregateManager.vdot(heartrateBpm, paceSecPerKm)}

            static let zero = Continuous(durationSec: 0, distanceM: 0, heartrateBpm: 0)
        }
        
        private let totals: [Categorical: Continuous]
        
        private init(totals: [Categorical: Continuous] = [:]) {self.totals = totals}
    }

    private struct Segment: AggregateContent {
        static let zero = Self()

        static func + (lhs: Self, rhs: Transition) -> Self? {
            guard let isStarted = rhs.status.T.isStarted, isStarted else {return nil}
            
            guard let isRunning = rhs.status.T.isRunning,
                  let intensity = rhs.status.T.intensity,
                  let segmentId = rhs.status.T.segmentId
            else {return nil}
            
            let categorical = Categorical(segmentId: segmentId)
            let continuous = lhs.segments[categorical, default: Continuous.zero]
            var segments = lhs.segments
            
            let sumDurationSec = rhs.durationS + continuous.durationSec
            let sumDistanceM = isRunning ? rhs.distanceM + continuous.distanceM : 0
            let avgHeartrateBpm = AggregateManager.heartreateBpm(
                rhs.status.T.hrBpm ?? 0, continuous.heartrateBpm,
                rhs.durationS, continuous.durationSec)
            
            var location: (CLLocation, Int) {
                if let rhsLocation = rhs.status.T.location {
                    return (
                        AggregateManager.midLocation(
                            continuous.midLocation, rhsLocation, cnt: continuous.cntLocation),
                        continuous.cntLocation + 1)
                } else {
                    return (continuous.midLocation, continuous.cntLocation)
                }
            }
            
            segments[categorical] = Continuous(
                isRunning: isRunning,
                intensity: intensity,
                durationSec: sumDurationSec,
                distanceM: sumDistanceM,
                heartrateBpm: avgHeartrateBpm,
                midLocation: location.0,
                cntLocation: location.1)
            return Self(segments: segments)
        }
        
        // Categorical features
        struct Categorical: Hashable {
            let segmentId: Int
        }
        
        // Continuous features
        struct Continuous {
            let isRunning: Bool
            let intensity: Intensity
            let durationSec: TimeInterval
            let distanceM: CLLocationDistance
            let heartrateBpm: Int
            let midLocation: CLLocation
            let cntLocation: Int
            
            var paceSecPerKm: TimeInterval {AggregateManager.paceSecPerKm(distanceM, durationSec)}
            var vdot: Double {AggregateManager.vdot(heartrateBpm, paceSecPerKm)}

            static let zero = Continuous(
                isRunning: false,
                intensity: .Easy,
                durationSec: 0,
                distanceM: 0,
                heartrateBpm: 0,
                midLocation: CLLocation(),
                cntLocation: 0)
        }
        
        fileprivate let segments: [Categorical: Continuous]
        fileprivate let maxSegmentId: Categorical
        
        private init(segments: [Categorical: Continuous] = [:]) {
            self.segments = segments
            self.maxSegmentId = segments.keys.max {$0.segmentId < $1.segmentId} ?? Categorical(segmentId: -1)
        }
    }
    
    private struct Location: AggregateContent {
        static let zero = Self()

        static func + (lhs: Self, rhs: Transition) -> Self? {
            guard let location = rhs.status.T.location,
                  let original = rhs.status.T.locationOriginl,
                  let isStarted = rhs.status.T.isStarted,
                  let isRunning = rhs.status.T.isRunning
            else {return nil}
            
            guard isStarted else {return nil}
            
            if original && isRunning {
                return Self(locations: lhs.locations + [location])
            } else if !isRunning {
                // Find segment
                if let segments = AggregateManager.sharedInstance.segments.read(),
                   let segment = segments.segments[segments.maxSegmentId]
                {
                    return Self(locations: lhs.locations + [segment.midLocation])
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
        
        private let locations: [CLLocation]
        
        private init(locations: [CLLocation] = []) {self.locations = locations}
    }
    
    private var totals = BiTemporalAggregate<Total>()
    private var segments = BiTemporalAggregate<Segment>()
    private var locations = BiTemporalAggregate<Location>()

    // MARK: Helper for calculations
    
    private static func heartreateBpm(
        _ hrBpm1: Int, _ hrBpm2: Int,
        _ duration1: TimeInterval, _ duration2: TimeInterval) -> Int
    {
        let hr1 = Double(hrBpm1) * (duration1 / (duration1 + duration2))
        let hr2 = Double(hrBpm1) * (duration2 / (duration1 + duration2))
        
        return Int(hr1 + hr2 + 0.5)
    }
    
    private static func midLocation(_ location1: CLLocation, _ location2: CLLocation, cnt: Int) -> CLLocation {
        location1.moveScaled(by: 1.0 / Double(cnt + 1), to: location2)
    }
    
    private static func paceSecPerKm(
        _ distanceM: CLLocationDistance,
        _ durationSec: TimeInterval)
    -> TimeInterval
    {
        1000.0 * durationSec / distanceM
    }
    
    private static func vdot(_ heartrateBpm: Int, _ paceKmPerSec: TimeInterval) -> Double {
        let hrMax = Database.sharedInstance.hrMax.value
        let hrResting = Database.sharedInstance.hrResting.value
        
        if hrMax.isFinite && hrResting.isFinite {
            return train(
                hrBpm: heartrateBpm,
                hrMaxBpm: Int(hrMax + 0.5),
                restingBpm: Int(hrResting + 0.5),
                paceSecPerKm: paceKmPerSec) ?? .nan
        } else if hrMax.isFinite {
            return train(
                hrBpm: heartrateBpm,
                hrMaxBpm: Int(hrMax + 0.5),
                paceSecPerKm: paceKmPerSec) ?? .nan
        } else {
            return .nan
        }
    }
}

private protocol AggregateContent {
    static var zero: Self {get}
    static func +(lhs: Self, rhs: AggregateManager.Transition) -> Self?
}

private struct BiTemporalAggregate<Content: AggregateContent> {
    var contentAsOf = [(asOf: Date, content: Content)]()
    
    mutating func append(_ content: Content, asOf: Date) {
        contentAsOf.append((asOf: asOf, content: content))
    }

    func read() -> Content? {contentAsOf.last?.content}
    func save() {} // TODO: !

    mutating func commit(before: Date) {contentAsOf.removeAll {$0.asOf < before}}
    mutating func rollback(after: Date) {contentAsOf.removeAll {$0.asOf > after}}
    mutating func reset() {contentAsOf.removeAll()}
    
    /// Entrypoint to be called, whenever a new status/transition arrives.
    /// It is expected, that `aggregate` calls `append` to store the aggregations.
    mutating func aggregate(transition: AggregateManager.Transition) {
        guard let current = read() else {return append(Content.zero, asOf: transition.status.when)}
        
        guard let next = current + transition else {return} // Filtered out
        
        append(next, asOf: transition.status.when)
    }
}
