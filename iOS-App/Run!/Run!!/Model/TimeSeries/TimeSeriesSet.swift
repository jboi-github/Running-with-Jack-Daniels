//
//  TimeSeriesSet.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 22.05.22.
//

import Foundation
import CoreLocation


// Implement simple set of all necessary timeseries
class TimeSeriesSet {
    let pedometerDataTimeseries = TimeSeries<PedometerDataEvent>()
    let pedometerEventTimeseries = TimeSeries<PedometerEvent>()
    let motionActivityTimeseries = TimeSeries<MotionActivityEvent>()
    let locationTimeseries = TimeSeries<LocationEvent>()
    let distanceTimeseries = TimeSeries<DistanceEvent>()
    let heartrateTimeseries = TimeSeries<HeartrateEvent>()
    let intensityTimeseries = TimeSeries<IntensityEvent>()
    let batteryLevelTimeseries = TimeSeries<BatteryLevelEvent>()
    let bodySensorLocationTimeseries = TimeSeries<BodySensorLocationEvent>()
    let peripheralTimeseries = TimeSeries<PeripheralEvent>()
    let workoutTimeseries = TimeSeries<WorkoutEvent>()
    
    func archive(upTo: Date) {
        pedometerDataTimeseries.archive(upTo: upTo)
        pedometerEventTimeseries.archive(upTo: upTo)
        motionActivityTimeseries.archive(upTo: upTo)
        locationTimeseries.archive(upTo: upTo)
        distanceTimeseries.archive(upTo: upTo)
        heartrateTimeseries.archive(upTo: upTo)
        intensityTimeseries.archive(upTo: upTo)
        batteryLevelTimeseries.archive(upTo: upTo)
        bodySensorLocationTimeseries.archive(upTo: upTo)
        peripheralTimeseries.archive(upTo: upTo)
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
            batteryLevelTimeseries.isInBackground = isInBackground
            bodySensorLocationTimeseries.isInBackground = isInBackground
            peripheralTimeseries.isInBackground = isInBackground
        }
    }
    
    func getWorkoutStatus(upTo: Date) {
        
    }
    
    struct WorkoutStatus {
        let date: Date
        let isWorkingOut: Bool
        let isActive: Bool
        let duration: TimeInterval
        let numberOfSteps: Int
        let pedometerDistance: CLLocationDistance?
        let pedometerActiveDuration: TimeInterval?
        let motionActivity: MotionActivityEvent.Motion
        let motionConfidence: MotionActivityEvent.Confidence
        let location: CLLocation
        let gpsDistance: CLLocationDistance
        let heartrate: Int
        let energyExpended: Int?
        let skinIsContacted: Bool?
        
    }
}
