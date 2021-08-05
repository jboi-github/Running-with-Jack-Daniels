//
//  WorkoutRecordingModel.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 23.07.21.
//

import CoreLocation
import MapKit

/// Delivers every n seconds a status about the runner to be displayed.
/// When ending (disappearing) it saves all information to UserDefaults an Healthkit
/// Every new HR is written to Healthkit
/// Every new Location writes speed and distance to Healthkit
class WorkoutRecordingModel: ObservableObject {
    // MARK: Initialize
    public static let sharedInstance = WorkoutRecordingModel()

    private init() {}
    
    // MARK: Public & Published
    
    /// Start new Workout. If HR is below easy, start a break. Set all variables and totals to zero and start the timer.
    public func onAppear() {startAt = Date()}
    
    /// End a workout. Close any open break. Stop timer. Write Workout with break-events and totals to Healthkit.
    /// Add final HR and location.
    public func onDisappear() {stopAt = Date()}
    
    @Published public private(set) var intensities = [Intensity: Info]()
    @Published public private(set) var totals = Info()
    @Published public private(set) var vdot = Double.nan
    @Published public private(set) var path = [PathItem]()
    public private(set) var breaks = [ClosedRange<Date>]()

    public struct Info {
        var distance: Double = 0.0 // Sum of distance
        var time: TimeInterval = 0.0 // Overall time
        var currentPace: TimeInterval = .infinity // Latest, reognized pace
        var hrs: Double = 0.0 // Heartrate-Seconds. Devide by time to get average heartrate
        
        var avgHr: Double {hrs / time}
        var avgPace: TimeInterval {1000.0 * time / distance}
        var avgVdot: Double? {
            WorkoutRecordingModel.sharedInstance.getVdot(hrBpm: avgHr, paceSecPerKm: avgPace)
        }
    }
    
    public struct PathItem: Identifiable {
        let id = UUID()
        
        let coordinate: CLLocationCoordinate2D
        let timestamp: Date
        let accuracyM: CLLocationDistance
        let intensity: Intensity?
        
        var accurayRegion: MKCoordinateRegion {
            MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: accuracyM * 2,
                longitudinalMeters: accuracyM * 2)
        }
    }
    
    public static func smooth(_ points: [PathItem]) -> [PathItem] {
        var result : [PathItem] = []
        
        // Returns the base point from point p to the line between p1 and p2
        func basePoint(
            p: CLLocationCoordinate2D,
            p1: CLLocationCoordinate2D,
            p2: CLLocationCoordinate2D) -> CLLocationCoordinate2D
        {
            let Ax = p1.latitude - p.latitude
            let Ay = p1.longitude - p.longitude
            let Bx = p1.latitude - p2.latitude
            let By = p1.longitude - p2.longitude
            let numerator = Ax*Bx + Ay*By
            let denominator = Bx*Bx + By*By
            
            let t = (0...denominator).contains(numerator) ? numerator / denominator : Double.infinity
            return CLLocationCoordinate2D(
                latitude: p1.latitude + t * (p2.latitude - p1.latitude),
                longitude: p1.longitude + t * (p2.longitude - p1.longitude))
        }
        
        func distanceM(p1: CLLocationCoordinate2D, p2: CLLocationCoordinate2D) -> Double {
            MKMapPoint(p1).distance(to: MKMapPoint(p2))
        }
        
        var lastSegmentBegin = -1
        var lastSegmentEnd = -1

        func addToResult(_ i: Int) {
            if i > lastSegmentEnd {
                lastSegmentBegin = lastSegmentEnd
                lastSegmentEnd = i
            }

            result.append(
                PathItem(
                    coordinate: points[i].coordinate,
                    timestamp: points[i].timestamp,
                    accuracyM: points[i].accuracyM,
                    intensity: .Interval)) // Red
        }
        
        // One recustion step of rdp
        func rdp(begin: Int, end: Int) {
            guard end > begin else {return}
            
            let distance = (begin+1..<end)
                .map { (i: Int) -> (i: Int, distanceM: Double) in
                    let distanceM = distanceM(
                        p1: points[i].coordinate,
                        p2: basePoint(
                            p: points[i].coordinate,
                            p1: points[begin].coordinate,
                            p2: points[end].coordinate))
                    return (i, distanceM)
                }
                .max {$0.distanceM < $1.distanceM}
            
            if let distance = distance, distance.distanceM > points[distance.i].accuracyM {
                rdp(begin: begin, end: distance.i)
                rdp(begin: distance.i, end: end)
            } else {
                addToResult(end)
            }
        }
        
        // Start recursion
        guard !points.isEmpty else {return result}
        
        addToResult(0)
        rdp(begin: 0, end: points.count - 1)
        
        // Copy last segment before end-point
        if lastSegmentBegin >= 0 && lastSegmentEnd >= 0 {
            result.removeLast()
            result.append(contentsOf: points[lastSegmentBegin+1...lastSegmentEnd])
        }
        return result
    }
    
    // MARK: Private
    private var startAt: Date? = nil {
        didSet {
            // Continue only if set to something
            guard let startAt = startAt else {return}
            timerWork(startAt)
            
            // Start Timer every second
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {_ in self.timerWork()}
        }
    }
    
    private var stopAt: Date? = nil {
        didSet {
            guard let stopAt = stopAt else {return}
            
            // Stop the workout
            timer?.invalidate()
            timerWork(stopAt)
            prevTimerCall = nil

            // TODO: Write to database
        }
    }
    
    private var timer: Timer? = nil
    private var prevTimerCall: TimerCall? = nil
    private var distanceAtStart: Double = 0.0
    
    private struct TimerCall {
        let when: Date
        let distance: Double
    }

    /// Get latest heartrate, distance, pace.
    /// Calculate vdot.
    /// Get intensity -> add to intensities and start or stop break if necessary
    /// Calculate totals
    private func timerWork(
        _ when: Date = Date(),
        _ distance: Double = GpsLocationReceiver.sharedInstance.currentDistanceM,
        _ location: CLLocation? = GpsLocationReceiver.sharedInstance.currentLocation,
        _ heartrate: Int = BleHeartRateReceiver.sharedInstance.heartrate)
    {
        // Not yet started
        guard let startAt = startAt else {return}
        
        defer {self.prevTimerCall = TimerCall(when: when, distance: distance)}
        
        // Just started, first call
        guard let prevTimerCall = prevTimerCall else {
            // Set all counter to zero
            distanceAtStart = distance
            totals = Info()
            intensities = [Intensity: Info]()
            breaks.removeAll()
            path.removeAll()
            return
        }

        vdot = currentVdot ?? Double.nan
        var newDistance = totals.distance
        if let intensity = currentIntensity {
            incIntensity(
                intensity,
                since: prevTimerCall.when, when: when,
                deltaDistance: distance - prevTimerCall.distance,
                heartrate: heartrate)

            newDistance = intensities.values.map {$0.distance}.reduce(0.0, +)
            appendToPath(location, at: when, intensity: intensity)
            endBreak(when) // Close break if open
        } else {
            appendToPath(location, at: when)
            beginBreak(when) // Open break if closed
        }
        totals = Info(
            distance: newDistance,
            time: when.timeIntervalSince(startAt),
            currentPace: currentPace)
    }
    
    private var currentPace: TimeInterval {
        GpsLocationReceiver.sharedInstance.prevVelocity?.paceSecPerKm ?? TimeInterval.infinity
    }
    
    private var currentIntensity: Intensity? {
        let hr = BleHeartRateReceiver.sharedInstance.heartrate
        if let intensity = Database
            .sharedInstance
            .hrLimits
            .value
            .first(where: {$0.value.contains(hr)})?
            .key
        {
            return intensity
        } else if Database.sharedInstance.hrMax.value < Double(hr) {
            return .Repetition
        } else {
            return nil
        }
    }
    
    private var currentVdot: Double? {
        getVdot(
            hrBpm: Double(BleHeartRateReceiver.sharedInstance.heartrate),
            paceSecPerKm: currentPace)
    }
    
    private func appendToPath(_ location: CLLocation?, at when: Date, intensity: Intensity? = nil) {
        if let location = location {
            path.append(
                PathItem(
                    coordinate: location.coordinate,
                    timestamp: when,
                    accuracyM: location.horizontalAccuracy,
                    intensity: intensity))
            path = WorkoutRecordingModel.smooth(path)
        }
    }
    
    private func getVdot(hrBpm: Double, paceSecPerKm: TimeInterval) -> Double? {
        let hrResting = Database.sharedInstance.hrResting.value
        let hrMax = Database.sharedInstance.hrMax.value
        
        log("\(hrBpm), \(paceSecPerKm), \(hrResting), \(hrMax)")
        if hrResting.isFinite && hrMax.isFinite {
            return train(
                hrBpm: Int(hrBpm),
                hrMaxBpm: Int(hrMax),
                restingBpm: Int(hrResting),
                paceSecPerKm: paceSecPerKm)
        } else if hrMax.isFinite {
            return train(hrBpm: Int(hrBpm), hrMaxBpm: Int(hrMax), paceSecPerKm: paceSecPerKm)
        } else {
            return nil
        }
    }
    
    private var isBreakOpen: Bool {
        guard let last = breaks.last else {return false}
        return last.upperBound == Date.distantFuture
    }
    
    /// Begin new break if not already open
    private func beginBreak(_ when: Date) {
        if !isBreakOpen {breaks.append(when...Date.distantFuture)}
    }
    
    /// End break if open
    private func endBreak(_ when: Date) {
        if isBreakOpen {breaks.append(breaks.removeLast().clamped(to: Date.distantPast...when))}
    }
    
    /// Increment existing intensity or create new one
    private func incIntensity(
        _ intensity: Intensity,
        since: Date, when: Date,
        deltaDistance: Double, heartrate: Int)
    {
        let timeInterval = when.timeIntervalSince(since)
        let prev = intensities[intensity, default: Info()]
        let incr = Info(
            distance: prev.distance + deltaDistance,
            time: prev.time + timeInterval,
            currentPace: currentPace,
            hrs: Double(heartrate) * timeInterval)
        intensities[intensity] = incr
    }
}
