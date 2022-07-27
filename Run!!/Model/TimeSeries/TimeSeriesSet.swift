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
    init(queue: SerialQueue) {
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
        self.pathTimeseries = TimeSeries<PathEvent, None>(queue: queue)
        self.resetTimeseries = TimeSeries<ResetEvent, None>(queue: queue)
        self.totalsTimeseries = TimeSeries<TotalEvent, Date>(queue: queue)
    }
    
    private unowned let queue: SerialQueue
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
    let pathTimeseries: TimeSeries<PathEvent, None>
    let resetTimeseries: TimeSeries<ResetEvent, None>
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
        pathTimeseries.archive(upTo: upTo)
        resetTimeseries.archive(upTo: upTo)
        totalsTimeseries.archive(upTo: upTo)
    }
    
    var isInBackground: Bool = true {
        didSet {
            resetTimeseries.isInBackground = isInBackground
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
            pathTimeseries.isInBackground = isInBackground
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
        pathTimeseries.insert(pathTimeseries.parse(locationEvent, intensityTimeseries[locationEvent.date]))
    }
    
    func reflect(_ heartrateEvent: HeartrateEvent) {
        if let intensities = intensityTimeseries.parse(heartrateEvent, heartrateTimeseries.elements.last) {
            var prev = intensityTimeseries.elements.last
            intensities.forEach { curr in
                defer {prev = curr}
                
                if let prev = prev {
                    if curr.intensity != prev.intensity {
                        intensityTimeseries.insert(curr)
                        pathTimeseries.reflect(curr)
                        totalsTimeseries.reflect(intensityEvent: curr)
                    }
                } else {
                    intensityTimeseries.insert(curr)
                    pathTimeseries.reflect(curr)
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
    
    func reflect(_ resetEvent: ResetEvent) {
        resetTimeseries.insert(resetEvent)
        totalsTimeseries.reflect(resetEvent: resetEvent)
        archive(upTo: resetEvent.originalDate)
    }

    // MARK: Reset Status
    
    struct WorkoutStatus: Dated {
        let date: Date
        
        /// ResetEvent: Date, when reset has started
        let resetDate: Date?
        
        /// ResetEvent: Elapsed time since reset has started
        let duration: TimeInterval?
        
        /// PedometerData: Total number of steps since reset
        let numberOfSteps: Int?
        
        /// PedometerData: Total cadence since reset in steps / second
        let cadence: Double?

        /// PedometerData: Total active time recognized by pedometer since reset
        let activeDuration: TimeInterval?

        /// MotionActivity: Latest motion type detected.
        let motion: MotionActivityEvent.Motion?
        
        /// MotionActivity: Latest confidence into detected motion type
        let confidence: MotionActivityEvent.Confidence?

        /// Heartrate: Latest masured heartrate
        let heartrate: Int?
        
        /// Heartrate: Total expended energy, if available
        let energyExpended: Int?
        
        /// Heartrate: Latest recognition, if heartrate monitor has contact to skin, if available
        let skinIsContacted: Bool?
        
        // Intensity: Latest running intensity by heartrate
        let intensity: Run.Intensity?

        /// Batterylevel: Latest measured percent of battery load between 0..100
        let batteryLevel: Int?
        
        /// BodySensorLocation: Latest location of heartrate monitor
        let bodySensorLocation: HRM.SensorLocation?

        /// Peripheral: Latest discovered ble periphals name, if any given.
        let peripheralName: String?

        /// Peripheral: Latest discovered ble periphal and its connection status.
        let peripheralState: PeripheralEvent.State?
        
        /// DistanceEvent or PedometerData: Total gps ord pdm distance since beginning of lap in meter
        let distance: CLLocationDistance?
        
        /// DistanceEvent or PedometerData: Total gps ord pdm speed in meter / second
        let speed: CLLocationSpeed?
        
        /// Total vdot since reset
        let vdot: Double?
    }

    @Published private(set) var status: WorkoutStatus?

    // Status is build on top of totals where possible
    private func _status(asOf: Date, total: TotalEventDelta) -> WorkoutStatus {
        WorkoutStatus(
            date: asOf,
            resetDate: resetTimeseries[asOf]?.originalDate,
            duration: total.duration,
            numberOfSteps: total.numberOfSteps,
            cadence: total.cadence,
            activeDuration: total.activeDuration,
            motion: motionActivityTimeseries[asOf]?.motion,
            confidence: motionActivityTimeseries[asOf]?.confidence,
            heartrate: heartrateTimeseries[asOf]?.heartrate,
            energyExpended: total.energyExpended,
            skinIsContacted: heartrateTimeseries[asOf]?.skinIsContacted,
            intensity: intensityTimeseries[asOf]?.intensity,
            batteryLevel: batteryLevelTimeseries[asOf]?.level,
            bodySensorLocation: bodySensorLocationTimeseries[asOf]?.sensorLocation,
            peripheralName: peripheralTimeseries[asOf]?.name,
            peripheralState: peripheralTimeseries[asOf]?.state,
            distance: total.distance,
            speed: total.speed,
            vdot: total.vdot)
    }
    
    // MARK: Calculation Engine for Totals
    
    /// Final result of calculation is an array of `Total` sorted by `asOf` descending.
    /// The array contains each combination of keys only once.
    /// The array is filtered down to only the current reset by `resetDate`
    struct Total: Dated, Equatable {
        init(
            endAt: Date,
            motionActivity: MotionActivityEvent.Motion?,
            resetDate: Date?,
            intensity: Run.Intensity?,
            duration: TimeInterval,
            numberOfSteps: Int?,
            activeDuration: TimeInterval?,
            energyExpended: Int?,
            distance: CLLocationDistance?,
            speed: CLLocationSpeed?,
            cadence: Double?,
            avgHeartrate: Int?,
            vdot: Double?)
        {
            self.endAt = endAt
            self.motionActivity = motionActivity
            self.resetDate = resetDate
            self.intensity = intensity
            self.duration = duration
            self.numberOfSteps = numberOfSteps
            self.activeDuration = activeDuration
            self.energyExpended = energyExpended
            
            self.distance = distance
            self.speed = speed
            self.cadence = cadence
            self.avgHeartrate = avgHeartrate
            
            self.vdot = vdot
        }

        // Implement `Dated`
        var date: Date {endAt}

        let endAt: Date

        // Key part
        let motionActivity: MotionActivityEvent.Motion?
        let resetDate: Date?
        let intensity: Run.Intensity?
        
        // Values, directly taken
        let duration: TimeInterval
        let numberOfSteps: Int?
        let activeDuration: TimeInterval?
        let energyExpended: Int?

        // Derivded and calculated values
        let distance: CLLocationDistance?
        let speed: CLLocationSpeed?
        let cadence: Double?
        let avgHeartrate: Int?
        let vdot: Double?
    }
    
    @Published private(set) var totals = [Total]()
    
    func refreshTotals(upTo: Date) {
        queue.async {
            let totals = self._totals(upTo: upTo)
            let status = self._status(asOf: upTo, total: totals.delta)
            DispatchQueue.main.async {
                self.totals = totals.totals
                self.status = status
            }
        }
    }
    
    private func _totals(upTo: Date) -> (delta: TotalEventDelta, totals: [Total]) {
        // Refresh and create last `upTo` event
        totalsTimeseries.refresh(
            resetTimeseries: resetTimeseries,
            motionActivityTimeseries: motionActivityTimeseries,
            intensityTimeseries: intensityTimeseries,
            pedometerDataTimeseries: pedometerDataTimeseries,
            distanceTimeseries: distanceTimeseries,
            heartrateTimeseries: heartrateTimeseries,
            heartrateSecondsTimeseries: heartrateSecondsTimeseries)
        var upToEvent = TotalEvent(date: upTo)
        upToEvent.refresh(
            dirtyAfter: .distantPast,
            resetTimeseries: resetTimeseries,
            intensityTimeseries: intensityTimeseries,
            motionActivityTimeseries: motionActivityTimeseries,
            pedometerDataTimeseries: pedometerDataTimeseries,
            distanceTimeseries: distanceTimeseries,
            heartrateTimeseries: heartrateTimeseries,
            heartrateSecondsTimeseries: heartrateSecondsTimeseries)
        
        // Get summed up totals
        guard let totals = try? totalsTimeseries.sumUp(upToEvent: upToEvent) else {
            return (TotalEventDelta.zero, [])
        }
        
        let allTotal = totals
            .filter { $0.value.motion?.isActive ?? true }
            .reduce(into: TotalEventDelta.zero) { $0 += $1.value.delta }
        
        let partTotals = totals
            // Sort by event end date, descending
            .sorted {$0.value.endDate > $1.value.endDate}
            // Map to resulting total
            .map {
                Total(
                    endAt: $0.value.endDate,
                    motionActivity: $0.value.motion,
                    resetDate: $0.key.resetEvent?.originalDate,
                    intensity: $0.key.intensityEvent?.intensity,
                    duration: $0.value.delta.duration,
                    numberOfSteps: $0.value.delta.numberOfSteps,
                    activeDuration: $0.value.delta.activeDuration,
                    energyExpended: $0.value.delta.energyExpended,
                    distance: $0.value.delta.distance,
                    speed: $0.value.delta.speed,
                    cadence: $0.value.delta.cadence,
                    avgHeartrate: $0.value.delta.avgHeartrate,
                    vdot: $0.value.delta.vdot)
            }
        
        return (allTotal, partTotals)
    }
}
