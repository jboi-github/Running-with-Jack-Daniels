//
//  TimeSeriesSet.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 22.05.22.
//

import Foundation
import CoreLocation

// Implement simple set of all necessary timeseries
class TimeSeriesSet: ObservableObject {
    init(queue: DispatchQueue) {
        self.queue = queue
        self.pedometerDataTimeseries = TimeSeries<PedometerDataEvent, None>(queue: queue)
        self.pedometerEventTimeseries = TimeSeries<PedometerEvent, None>(queue: queue)
        self.motionActivityTimeseries = TimeSeries<MotionActivityEvent, None>(queue: queue)
        self.locationTimeseries = TimeSeries<LocationEvent, None>(queue: queue)
        self.distanceTimeseries = TimeSeries<DistanceEvent, None>(queue: queue)
        self.heartrateTimeseries = TimeSeries<HeartrateEvent, None>(queue: queue)
        self.intensityTimeseries = TimeSeries<IntensityEvent, None>(queue: queue)
        self.heartrateSecondsTimeseries = TimeSeries<HeartrateSecondsEvent, None>(queue: queue)
        self.batteryLevelTimeseries = TimeSeries<BatteryLevelEvent, None>(queue: queue)
        self.bodySensorLocationTimeseries = TimeSeries<BodySensorLocationEvent, None>(queue: queue)
        self.peripheralTimeseries = TimeSeries<PeripheralEvent, None>(queue: queue)
        self.workoutTimeseries = TimeSeries<WorkoutEvent, None>(queue: queue)
        self.totalsTimeseries = TimeSeries<TotalEvent, Date>(queue: queue)
    }
    
    let queue: DispatchQueue
    let pedometerDataTimeseries: TimeSeries<PedometerDataEvent, None>
    let pedometerEventTimeseries: TimeSeries<PedometerEvent, None>
    let motionActivityTimeseries: TimeSeries<MotionActivityEvent, None>
    let locationTimeseries: TimeSeries<LocationEvent, None>
    let distanceTimeseries: TimeSeries<DistanceEvent, None>
    let heartrateTimeseries: TimeSeries<HeartrateEvent, None>
    let intensityTimeseries: TimeSeries<IntensityEvent, None>
    let heartrateSecondsTimeseries: TimeSeries<HeartrateSecondsEvent, None>
    let batteryLevelTimeseries: TimeSeries<BatteryLevelEvent, None>
    let bodySensorLocationTimeseries: TimeSeries<BodySensorLocationEvent, None>
    let peripheralTimeseries: TimeSeries<PeripheralEvent, None>
    let workoutTimeseries: TimeSeries<WorkoutEvent, None>
    let totalsTimeseries: TimeSeries<TotalEvent, Date>

    // MARK: Common functions
    
    func archive(upTo: Date) {
        pedometerDataTimeseries.archive(upTo: upTo)
        pedometerEventTimeseries.archive(upTo: upTo)
        motionActivityTimeseries.archive(upTo: upTo)
        locationTimeseries.archive(upTo: upTo)
        distanceTimeseries.archive(upTo: upTo)
        heartrateTimeseries.archive(upTo: upTo)
        intensityTimeseries.archive(upTo: upTo)
        heartrateSecondsTimeseries.archive(upTo: upTo)
        batteryLevelTimeseries.archive(upTo: upTo)
        bodySensorLocationTimeseries.archive(upTo: upTo)
        peripheralTimeseries.archive(upTo: upTo)
        workoutTimeseries.archive(upTo: upTo)
        totalsTimeseries.archive(upTo: upTo)
    }
    
    var isInBackground: Bool = true {
        didSet {
            workoutTimeseries.isInBackground = isInBackground
            pedometerDataTimeseries.isInBackground = isInBackground
            pedometerEventTimeseries.isInBackground = isInBackground
            motionActivityTimeseries.isInBackground = isInBackground
            locationTimeseries.isInBackground = isInBackground
            distanceTimeseries.isInBackground = isInBackground
            heartrateTimeseries.isInBackground = isInBackground
            intensityTimeseries.isInBackground = isInBackground
            heartrateSecondsTimeseries.isInBackground = isInBackground
            batteryLevelTimeseries.isInBackground = isInBackground
            bodySensorLocationTimeseries.isInBackground = isInBackground
            peripheralTimeseries.isInBackground = isInBackground
            totalsTimeseries.isInBackground = isInBackground
        }
    }
    
    // MARK: Reflecting client detections
    func reflect(_ pedometerDataEvent: PedometerDataEvent, _ startDate: Date) {
        totalsTimeseries.reflect(dirtyAfter: pedometerDataTimeseries.elements.last?.date ?? startDate)
        pedometerDataTimeseries
            .newElements(startDate, pedometerDataEvent)
            .forEach {pedometerDataTimeseries.insert($0)}
    }
    
    func reflect(_ pedometerEvent: PedometerEvent) {
        pedometerEventTimeseries.insert(pedometerEvent)
    }
    
    func reflect(_ motionActivityEvent: MotionActivityEvent) {
        motionActivityTimeseries.insert(motionActivityEvent)
        totalsTimeseries.reflect(motionActivityEvent: motionActivityEvent)
    }
    
    func reflect(_ locationEvent: LocationEvent) {
        totalsTimeseries.reflect(dirtyAfter: distanceTimeseries.elements.last?.date ?? locationEvent.date)
        distanceTimeseries
            .parse(locationEvent.clLocation, locationTimeseries.elements.last?.clLocation)
            .forEach {distanceTimeseries.insert($0)}
        locationTimeseries.insert(locationEvent)
    }
    
    func reflect(_ heartrateEvent: HeartrateEvent) {
        if let intensities = intensityTimeseries.parse(heartrateEvent, heartrateTimeseries.elements.last) {
            var prev = intensityTimeseries.elements.last
            intensities.forEach { curr in
                defer {prev = curr}
                
                if let prev = prev {
                    if curr.intensity != prev.intensity {
                        intensityTimeseries.insert(curr)
                        totalsTimeseries.reflect(intensityEvent: curr)
                    }
                } else {
                    intensityTimeseries.insert(curr)
                    totalsTimeseries.reflect(intensityEvent: curr)
                }
            }
        }
        
        if let heartrateSecs = heartrateSecondsTimeseries.parse(heartrateEvent, heartrateTimeseries.elements.last)
        {
            totalsTimeseries.reflect(
                dirtyAfter: heartrateSecondsTimeseries.elements.last?.date ?? heartrateEvent.date)
            heartrateSecondsTimeseries.insert(heartrateSecs)
        }
        
        heartrateTimeseries.insert(heartrateEvent)
    }
    
    func reflect(_ workoutEvent: WorkoutEvent) {
        workoutTimeseries.insert(workoutEvent)
        totalsTimeseries.reflect(workoutEvent: workoutEvent)
        archive(upTo: workoutEvent.originalDate)
    }

    // MARK: Workout Status
    func getWorkoutStatus(asOf: Date) -> WorkoutStatus {
        let workoutAsOf = workoutTimeseries[asOf]
        let pedometerDataAsOf = pedometerDataTimeseries[asOf]
        let pedometerEventAsOf = pedometerEventTimeseries[asOf]
        let motionActivityAsOf = motionActivityTimeseries[asOf]
        let locationAsOf = locationTimeseries[asOf]
        let distanceAsOf = distanceTimeseries[asOf]
        let heartrateAsOf = heartrateTimeseries[asOf]
        let intensityAsOf = intensityTimeseries[asOf]
        let batteryLevelAsOf = batteryLevelTimeseries[asOf]
        let bodySensorLocationAsOf = bodySensorLocationTimeseries[asOf]
        let peripheralAsOf = peripheralTimeseries[asOf]
        
        if let isWorkingOutSince = workoutAsOf?.originalDate {
            let pedometerDataAtStart = pedometerDataTimeseries[isWorkingOutSince]
            let distanceAtStart = distanceTimeseries[isWorkingOutSince]

            return WorkoutStatus(
                date: asOf,
                isWorkingOut: workoutAsOf?.isWorkingOut,
                isWorkingOutSince: isWorkingOutSince,
                duration: isWorkingOutSince.distance(to: asOf),
                numberOfSteps: pedometerDataAsOf?.numberOfSteps - pedometerDataAtStart?.numberOfSteps,
                pdmDistance: pedometerDataAsOf?.distance - pedometerDataAtStart?.distance,
                activeDuration: pedometerDataAsOf?.activeDuration - pedometerDataAtStart?.activeDuration,
                isActive: pedometerEventAsOf?.isActive,
                motion: motionActivityAsOf?.motion,
                confidence: motionActivityAsOf?.confidence,
                heartrate: heartrateAsOf?.heartrate,
                energyExpended: heartrateAsOf?.energyExpended,
                skinIsContacted: heartrateAsOf?.skinIsContacted,
                intensity: intensityAsOf?.intensity,
                batteryLevel: batteryLevelAsOf?.level,
                bodySensorLocation: bodySensorLocationAsOf?.sensorLocation,
                peripheralName: peripheralAsOf?.name,
                peripheralState: peripheralAsOf?.state,
                location: locationAsOf?.clLocation,
                gpsDistance: distanceAsOf?.distance - distanceAtStart?.distance
            )
        } else {
            return WorkoutStatus(
                date: asOf,
                isWorkingOut: workoutAsOf?.isWorkingOut,
                isWorkingOutSince: nil,
                duration: nil,
                numberOfSteps: nil,
                pdmDistance: nil,
                activeDuration: nil,
                isActive: pedometerEventAsOf?.isActive,
                motion: motionActivityAsOf?.motion,
                confidence: motionActivityAsOf?.confidence,
                heartrate: heartrateAsOf?.heartrate,
                energyExpended: heartrateAsOf?.energyExpended,
                skinIsContacted: heartrateAsOf?.skinIsContacted,
                intensity: intensityAsOf?.intensity,
                batteryLevel: batteryLevelAsOf?.level,
                bodySensorLocation: bodySensorLocationAsOf?.sensorLocation,
                peripheralName: peripheralAsOf?.name,
                peripheralState: peripheralAsOf?.state,
                location: locationAsOf?.clLocation,
                gpsDistance: nil
            )
        }
    }
    
    struct WorkoutStatus: Dated {
        let date: Date
        
        /// WorkoutEvent: User is currently working out
        let isWorkingOut: Bool?
        
        /// WorkoutEvent: Date, when workout has started
        let isWorkingOutSince: Date?
        
        /// WorkoutEvent: Elapsed time since workout has started
        let duration: TimeInterval?
        
        /// PedometerData: Total number of steps since beginning of workout
        let numberOfSteps: Int?
        
        /// PedometerData: Total distance recognized by pedometer since beginning of workout
        let pdmDistance: CLLocationDistance?
        
        /// PedometerData: Total active time recognized by pedometer since beginning of workout
        let activeDuration: TimeInterval?

        /// PedometerEvent: Pedometer recognized resumed or paused acitivity while in foreground
        let isActive: Bool?

        /// MotionActivity: Type of motion detected.
        let motion: MotionActivityEvent.Motion?
        
        /// MotionActivity: Confidence into detected motion type
        let confidence: MotionActivityEvent.Confidence?

        /// Heartrate: Measured last heartrate
        let heartrate: Int?
        
        /// Heartrate: Measured expended energy, if available
        let energyExpended: Int?
        
        /// Heartrate: Recognize if heartrate monitor has contact to skin, if available
        let skinIsContacted: Bool?
        
        // Intensity: Runing intensity by heartrate
        let intensity: Run.Intensity?

        /// Batterylevel: Percent of battery load between 0..100
        let batteryLevel: Int?
        
        /// BodySensorLocation: Location of heartrate monitor
        let bodySensorLocation: BodySensorLocationEvent.SensorLocation?

        /// Peripheral: Latest discovered ble periphals name, if any given.
        let peripheralName: String?

        /// Peripheral: Latest discovered ble periphal and its connection status.
        let peripheralState: PeripheralEvent.State?

        /// Location: Latest measured gps location, if allowed.
        let location: CLLocation?
        
        /// DistanceEvent: Total gps distance since beginning of workout in meter
        let gpsDistance: CLLocationDistance?
    }
    
    // MARK: Calculation Engine for Totals
    
    /// Final result of calculation is an array of `Total` sorted by `asOf` descending.
    /// The array contains each combination of keys only once.
    /// The array is filtered down to only the current workout by `workoutDate`
    struct Total: Dated, Equatable {
        #if DEBUG
        init(
            asOf: Date,
            motionActivity: MotionActivityEvent.Motion?,
            workoutDate: Date?,
            isWorkingOut: Bool?,
            intensity: Run.Intensity?,
            duration: TimeInterval = 0,
            numberOfSteps: Double? = nil,
            pdmDistance: CLLocationDistance? = nil,
            activeDuration: TimeInterval? = nil,
            gpsDistance: CLLocationDistance? = nil,
            heartrateSeconds: Double? = nil)
        {
            self.asOf = asOf
            self.motionActivity = motionActivity
            self.workoutDate = workoutDate
            self.isWorkingOut = isWorkingOut
            self.intensity = intensity
            self.duration = duration
            self.numberOfSteps = numberOfSteps
            self.pdmDistance = pdmDistance
            self.activeDuration = activeDuration
            self.gpsDistance = gpsDistance
            self.heartrateSeconds = heartrateSeconds
        }
        #endif
        
        let asOf: Date
        
        // Key part
        let motionActivity: MotionActivityEvent.Motion?
        let workoutDate: Date?
        let isWorkingOut: Bool?
        let intensity: Run.Intensity?
        
        // Value part
        private(set) var duration: TimeInterval = 0
        private(set) var numberOfSteps: Double?
        private(set) var pdmDistance: CLLocationDistance?
        private(set) var activeDuration: TimeInterval?
        private(set) var gpsDistance: CLLocationDistance?
        private(set) var heartrateSeconds: Double?

        // Implement `Dated`
        var date: Date {asOf}
        
        fileprivate static func += (lhs: inout Self, rhs: VectorElementDelta) {
            let rhs = TotalEventDelta(rhs)
            
            lhs.duration += rhs.duration
            lhs.numberOfSteps += rhs.numberOfSteps
            lhs.pdmDistance += rhs.pdmDistance
            lhs.activeDuration += rhs.activeDuration
            lhs.gpsDistance += rhs.gpsDistance
            lhs.heartrateSeconds += rhs.heartrateSeconds
        }
        
        fileprivate init(_ asOf: Date, _ key: TotalKey) {
            self.asOf = asOf
            self.motionActivity = key.motionActivity
            self.workoutDate = key.workoutDate
            self.isWorkingOut = key.isWorkingOut
            self.intensity = key.intensity
        }
    }
    
    fileprivate struct TotalKey: Hashable {
        let motionActivity: MotionActivityEvent.Motion?
        let workoutDate: Date?
        let isWorkingOut: Bool?
        let intensity: Run.Intensity?
    }
    
    @Published private(set) var totals = [Total]()
    
    func refreshTotals(upTo: Date) {
        queue.async {
            let totals = self._totals(upTo: upTo)
            DispatchQueue.main.async {
                self.totals = totals
            }
        }
    }
    
    private func _totals(upTo: Date) -> [Total] {
        // Refresh and create last `upTo` event
        totalsTimeseries.refresh(
            workoutTimeseries: workoutTimeseries,
            motionActivityTimeseries: motionActivityTimeseries,
            intensityTimeseries: intensityTimeseries,
            pedometerDataTimeseries: pedometerDataTimeseries,
            distanceTimeseries: distanceTimeseries,
            heartrateSecondsTimeseries: heartrateSecondsTimeseries)
        var upToEvent = TotalEvent(date: upTo)
        upToEvent.refresh(
            dirtyAfter: .distantPast,
            workoutTimeseries: workoutTimeseries,
            motionActivityTimeseries: motionActivityTimeseries,
            intensityTimeseries: intensityTimeseries,
            pedometerDataTimeseries: pedometerDataTimeseries,
            distanceTimeseries: distanceTimeseries,
            heartrateSecondsTimeseries: heartrateSecondsTimeseries)
        
        var prevEvent: TotalEvent?
        return [
            totalsTimeseries.elements,
            [upToEvent]
        ]
            .flatMap {$0}
        
        // Map into key and delta-part, where delta is between start and end of a segment with constant key
            .compactMap { currEvent -> (date: Date, key: TotalKey, delta: VectorElementDelta)? in
                defer { prevEvent = currEvent }
                guard let prevEvent = prevEvent else {return nil}

                let key = TotalKey(
                    motionActivity: prevEvent.segment.motionActivityEvent?.motion,
                    workoutDate: prevEvent.segment.workoutEvent?.originalDate,
                    isWorkingOut: prevEvent.segment.workoutEvent?.isWorkingOut,
                    intensity: prevEvent.segment.intensityEvent?.intensity)
                
                let delta = prevEvent.distance(to: currEvent)
                
                return (date: prevEvent.date, key: key, delta: delta)
            }
        
        // Reduce into dictionary, sum up deltas
            .reduce(into: [TotalKey: Total]()) {
                $0[$1.key, default: Total($1.date, $1.key)] += $1.delta
            }
        
        // Map dictionary into array, sorted by `date` descending
            .values
            .sorted {$0.date > $1.date} // Sort result -> current segment first
    }
}
