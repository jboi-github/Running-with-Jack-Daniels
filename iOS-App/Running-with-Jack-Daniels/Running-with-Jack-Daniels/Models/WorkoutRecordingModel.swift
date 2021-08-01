//
//  WorkoutRecordingModel.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 23.07.21.
//

import CoreLocation

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
        var avgVdot: Double? {getVdot(hrBpm: avgHr, paceSecPerKm: avgPace)}
    }
    
    public struct PathItem: Identifiable {
        let id = UUID()
        
        let coordinate: CLLocationCoordinate2D
        let timestamp: Date
        let accuracyM: CLLocationDistance
        let intensity: Intensity?
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
            if let location = location {
                path.append(
                    PathItem(
                        coordinate: location.coordinate,
                        timestamp: when,
                        accuracyM: location.horizontalAccuracy,
                        intensity: intensity))
            }
            
            endBreak(when) // Close break if open
        } else {
            if let location = location {
                path.append(
                    PathItem(
                        coordinate: location.coordinate,
                        timestamp: when,
                        accuracyM: location.horizontalAccuracy,
                        intensity: nil))
            }

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
        WorkoutRecordingModel.getVdot(
            hrBpm: Double(BleHeartRateReceiver.sharedInstance.heartrate),
            paceSecPerKm: currentPace)
    }
    
    private static func getVdot(hrBpm: Double, paceSecPerKm: TimeInterval) -> Double? {
        let hrResting = Database.sharedInstance.hrResting.value
        let hrMax = Database.sharedInstance.hrMax.value
        
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
