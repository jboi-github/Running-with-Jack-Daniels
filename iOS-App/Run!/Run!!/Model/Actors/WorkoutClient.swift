//
//  Workout2.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 06.05.22.
//

import Foundation

final class WorkoutClient: ClientDelegate {
    weak var client: Client<WorkoutClient>? {
        didSet {
            client?.statusChanged(to: isWorkingOut ? .started(since: .distantPast) : .stopped(since: .distantPast))
        }
    }
    
    @Persistent(key: "com.apps4live.Run!!.Workout.isWorkingOut") private var isWorkingOut: Bool = false
    
    init(
        queue: DispatchQueue,
        workoutTimeseries: TimeSeries<WorkoutEvent>,
        pedometerDataTimeseries: TimeSeries<PedometerDataEvent>,
        pedometerEventTimeseries: TimeSeries<PedometerEvent>,
        motionActivityTimeseries: TimeSeries<MotionActivityEvent>,
        locationTimeseries: TimeSeries<LocationEvent>,
        heartrateTimeseries: TimeSeries<HeartrateEvent>,
        batteryLevelTimeseries: TimeSeries<BatteryLevelEvent>,
        bodySensorLocationTimeseries: TimeSeries<BodySensorLocationEvent>,
        peripheralTimeseries: TimeSeries<PeripheralEvent>)
    {
        self.queue = queue
        self.workoutTimeseries = workoutTimeseries
        self.pedometerDataTimeseries = pedometerDataTimeseries
        self.pedometerEventTimeseries = pedometerEventTimeseries
        self.motionActivityTimeseries = motionActivityTimeseries
        self.locationTimeseries = locationTimeseries
        self.heartrateTimeseries = heartrateTimeseries
        self.batteryLevelTimeseries = batteryLevelTimeseries
        self.bodySensorLocationTimeseries = bodySensorLocationTimeseries
        self.peripheralTimeseries = peripheralTimeseries
    }
    
    private unowned let queue: DispatchQueue
    private unowned let workoutTimeseries: TimeSeries<WorkoutEvent>
    private unowned let pedometerDataTimeseries: TimeSeries<PedometerDataEvent>
    private unowned let pedometerEventTimeseries: TimeSeries<PedometerEvent>
    private unowned let motionActivityTimeseries: TimeSeries<MotionActivityEvent>
    private unowned let locationTimeseries: TimeSeries<LocationEvent>
    private unowned let heartrateTimeseries: TimeSeries<HeartrateEvent>
    private unowned let batteryLevelTimeseries: TimeSeries<BatteryLevelEvent>
    private unowned let bodySensorLocationTimeseries: TimeSeries<BodySensorLocationEvent>
    private unowned let peripheralTimeseries: TimeSeries<PeripheralEvent>

    func start(asOf: Date) -> ClientStatus {
        set(at: asOf, true)
        return .started(since: asOf)
    }
    
    func stop(asOf at: Date) {set(at: at, false)}
    
    private func set(at: Date, _ isWorkingOut: Bool) {
        self.isWorkingOut = isWorkingOut
        queue.async { [self] in
            workoutTimeseries.insert(WorkoutEvent(date: at, isWorkingOut: isWorkingOut))
            workoutTimeseries.archive(upTo: at)
            pedometerDataTimeseries.archive(upTo: at)
            pedometerEventTimeseries.archive(upTo: at)
            motionActivityTimeseries.archive(upTo: at)
            locationTimeseries.archive(upTo: at)
            heartrateTimeseries.archive(upTo: at)
            batteryLevelTimeseries.archive(upTo: at)
            bodySensorLocationTimeseries.archive(upTo: at)
            peripheralTimeseries.archive(upTo: at)
        }
    }
}
