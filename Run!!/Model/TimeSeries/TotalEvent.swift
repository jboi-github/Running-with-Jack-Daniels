//
//  TimeEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 13.06.22.
//

import Foundation
import CoreLocation

struct TotalEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "TotalEvent"
    var vector: VectorElement<Segment>
    init(_ vector: VectorElement<Segment>) {self.vector = vector}

    // MARK: Implement specifics
    struct Segment: Codable, Equatable {
        var workoutEvent: WorkoutEvent?
        var motionActivityEvent: MotionActivityEvent?
        var intensityEvent: IntensityEvent?
    }
    
    init(
        date: Date,
        workoutEvent: WorkoutEvent? = nil,
        motionActivityEvent: MotionActivityEvent? = nil,
        intensityEvent: IntensityEvent? = nil)
    {
        let segment = Segment(
            workoutEvent: workoutEvent,
            motionActivityEvent: motionActivityEvent,
            intensityEvent: intensityEvent)
        vector = VectorElement(
            date: date,
            optionalDoubles: [nil, nil, nil, nil],
            optionalInts: [nil],
            categorical: segment)
    }
    
    var segment: Segment {
        get {vector.categorical!}
        set {vector.categorical? = newValue}
    }
    
    var numberOfSteps: Int? {
        get {vector.optionalInts?[0]}
        set {vector.optionalInts?[0] = newValue}
    }
    
    var pdmDistance: CLLocationDistance? {
        get {vector.optionalDoubles?[0]}
        set {vector.optionalDoubles?[0] = newValue}
    }
    
    var activeDuration: TimeInterval? {
        get {vector.optionalDoubles?[1]}
        set {vector.optionalDoubles?[1] = newValue}
    }
    
    var gpsDistance: CLLocationDistance? {
        get {vector.optionalDoubles?[2]}
        set {vector.optionalDoubles?[2] = newValue}
    }
    
    var heartrateSeconds: Double? {
        get {vector.optionalDoubles?[3]}
        set {vector.optionalDoubles?[3] = newValue}
    }
    
    mutating func refresh(
        dirtyAfter: Date,
        workoutTimeseries: TimeSeries<WorkoutEvent, None>,
        motionActivityTimeseries: TimeSeries<MotionActivityEvent, None>,
        intensityTimeseries: TimeSeries<IntensityEvent, None>,
        pedometerDataTimeseries: TimeSeries<PedometerDataEvent, None>,
        distanceTimeseries: TimeSeries<DistanceEvent, None>,
        heartrateSecondsTimeseries: TimeSeries<HeartrateSecondsEvent, None>)
    {
        if date > dirtyAfter {
            // Refreshh all
            segment = Segment(
                workoutEvent: workoutTimeseries[date],
                motionActivityEvent: motionActivityTimeseries[date],
                intensityEvent: intensityTimeseries[date])
            
            let pedometerEvent = pedometerDataTimeseries[date]
            numberOfSteps = pedometerEvent?.numberOfSteps
            pdmDistance = pedometerEvent?.distance
            activeDuration = pedometerEvent?.activeDuration
            
            gpsDistance = distanceTimeseries[date]?.distance
            heartrateSeconds = heartrateSecondsTimeseries[date]?.heartrateSeconds
        } else {
            // Refresh if nil
            segment = Segment(
                workoutEvent: segment.workoutEvent ?? workoutTimeseries[date],
                motionActivityEvent: segment.motionActivityEvent ?? motionActivityTimeseries[date],
                intensityEvent: segment.intensityEvent ?? intensityTimeseries[date])
            
            if numberOfSteps == nil || pdmDistance == nil || activeDuration == nil {
                let pedometerEvent = pedometerDataTimeseries[date]
                numberOfSteps = pedometerEvent?.numberOfSteps
                pdmDistance = pedometerEvent?.distance
                activeDuration = pedometerEvent?.activeDuration
            }
            
            gpsDistance = gpsDistance ?? distanceTimeseries[date]?.distance
            heartrateSeconds = heartrateSeconds ?? heartrateSecondsTimeseries[date]?.heartrateSeconds
        }
    }
}

struct TotalEventDelta {
    let delta: VectorElementDelta
    init(_ delta: VectorElementDelta) {self.delta = delta}
    
    var duration: TimeInterval {delta.duration}
    var numberOfSteps: Double? {delta.optionalInts?[0]}
    var pdmDistance: CLLocationDistance? {delta.optionalDoubles?[0]}
    var activeDuration: TimeInterval? {delta.optionalDoubles?[1]}
    var gpsDistance: CLLocationDistance? {delta.optionalDoubles?[2]}
    var heartrateSeconds: Double? {delta.optionalDoubles?[3]}
}

extension TimeSeries where Element == TotalEvent, Meta == Date {
    func reflect(workoutEvent: WorkoutEvent) {
        insert(TotalEvent(date: workoutEvent.date, workoutEvent: workoutEvent))
        reflect(dirtyAfter: workoutEvent.date)
    }
    
    func reflect(motionActivityEvent: MotionActivityEvent) {
        insert(TotalEvent(date: motionActivityEvent.date, motionActivityEvent: motionActivityEvent))
        reflect(dirtyAfter: motionActivityEvent.date)
    }
    
    func reflect(intensityEvent: IntensityEvent) {
        insert(TotalEvent(date: intensityEvent.date, intensityEvent: intensityEvent))
        reflect(dirtyAfter: intensityEvent.date)
    }
    
    func reflect(dirtyAfter: Date) {meta = min(meta ?? .distantFuture, dirtyAfter)}
    
    func refresh(
        workoutTimeseries: TimeSeries<WorkoutEvent, None>,
        motionActivityTimeseries: TimeSeries<MotionActivityEvent, None>,
        intensityTimeseries: TimeSeries<IntensityEvent, None>,
        pedometerDataTimeseries: TimeSeries<PedometerDataEvent, None>,
        distanceTimeseries: TimeSeries<DistanceEvent, None>,
        heartrateSecondsTimeseries: TimeSeries<HeartrateSecondsEvent, None>)
    {
        elements.indices.forEach {
            self[$0]?.refresh(
                dirtyAfter: meta ?? .distantPast,
                workoutTimeseries: workoutTimeseries,
                motionActivityTimeseries: motionActivityTimeseries,
                intensityTimeseries: intensityTimeseries,
                pedometerDataTimeseries: pedometerDataTimeseries,
                distanceTimeseries: distanceTimeseries,
                heartrateSecondsTimeseries: heartrateSecondsTimeseries)
        }
        meta = elements.last?.date
    }
}
