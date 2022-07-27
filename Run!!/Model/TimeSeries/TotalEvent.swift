//
//  TimeEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 13.06.22.
//

import Foundation
import CoreLocation

struct TotalEvent: KeyedTimeSeriesElement, Equatable {
    typealias Delta = TotalEventDelta
    
    // MARK: Implement KeyedTimeSeriesElement
    static let key: String = "TotalEvent"
    let date: Date
    
    /// Derived from `Stridable`
    func distance(to: Self) -> Delta {
        TotalEventDelta(
            duration: date.distance(to: to.date),
            resetDelta: to.resetEvent == nil ? nil : resetEvent?.distance(to: to.resetEvent!),
            intensityDelta: to.intensityEvent == nil ? nil : intensityEvent?.distance(to: to.intensityEvent!),
            motionActivityDelta: to.motionActivityEvent == nil ? nil : motionActivityEvent?.distance(to: to.motionActivityEvent!),
            pedometerDataDelta: to.pedometerDataEvent == nil ? nil : pedometerDataEvent?.distance(to: to.pedometerDataEvent!),
            distanceDelta: to.distanceEvent == nil ? nil : distanceEvent?.distance(to: to.distanceEvent!),
            heartrateSecondsDelta: to.heartrateSecondsEvent == nil ? nil : heartrateSecondsEvent?.distance(to: to.heartrateSecondsEvent!),
            heartrateDelta: to.heartrateEvent == nil ? nil : heartrateEvent?.distance(to: to.heartrateEvent!))
    }
    
    /// Derived from `Stridable`
    func advanced(by: Delta) -> Self {
        TotalEvent(
            date: date.advanced(by: by.duration),
            resetEvent: by.resetDelta == nil ? nil : resetEvent?.advanced(by: by.resetDelta!),
            motionActivityEvent: by.motionActivityDelta == nil ? nil : motionActivityEvent?.advanced(by: by.motionActivityDelta!),
            intensityEvent: by.intensityDelta == nil ? nil : intensityEvent?.advanced(by: by.intensityDelta!),
            pedometerDataEvent: by.pedometerDataDelta == nil ? nil : pedometerDataEvent?.advanced(by: by.pedometerDataDelta!),
            distanceEvent: by.distanceDelta == nil ? nil : distanceEvent?.advanced(by: by.distanceDelta!),
            heartrateSecondsEvent: by.heartrateSecondsDelta == nil ? nil : heartrateSecondsEvent?.advanced(by: by.heartrateSecondsDelta!),
            heartrateEvent: by.heartrateDelta == nil ? nil : heartrateEvent?.advanced(by: by.heartrateDelta!))
    }
    
    /// Extrapolation by simply continuing value
    func extrapolate(at: Date) -> Self {
        TotalEvent(
            date: at,
            resetEvent: resetEvent?.extrapolate(at: at),
            motionActivityEvent: motionActivityEvent?.extrapolate(at: at),
            intensityEvent: intensityEvent?.extrapolate(at: at),
            pedometerDataEvent: pedometerDataEvent?.extrapolate(at: at),
            distanceEvent: distanceEvent?.extrapolate(at: at),
            heartrateSecondsEvent: heartrateSecondsEvent?.extrapolate(at: at),
            heartrateEvent: heartrateEvent?.extrapolate(at: at))
    }
    
    /// Linear inter- or extrapolation between `self` and `towards`. if `clamped` any
    /// value outside self or towards is kept constant along time axis.
    func interpolate(at: Date, _ towards: Self) -> Self {
        TotalEvent(
            date: at,
            resetEvent: towards.resetEvent == nil ? nil : resetEvent?.interpolate(at: at, towards.resetEvent!),
            motionActivityEvent: towards.motionActivityEvent == nil ?
                nil : motionActivityEvent?.interpolate(at: at, towards.motionActivityEvent!),
            intensityEvent: towards.intensityEvent == nil ?
                nil : intensityEvent?.interpolate(at: at, towards.intensityEvent!),
            pedometerDataEvent: towards.pedometerDataEvent == nil ?
                nil : pedometerDataEvent?.interpolate(at: at, towards.pedometerDataEvent!),
            distanceEvent: towards.distanceEvent == nil ?
                nil : distanceEvent?.interpolate(at: at, towards.distanceEvent!),
            heartrateSecondsEvent: towards.heartrateSecondsEvent == nil ?
                nil : heartrateSecondsEvent?.interpolate(at: at, towards.heartrateSecondsEvent!),
            heartrateEvent: towards.heartrateEvent == nil ?
                nil : heartrateEvent?.interpolate(at: at, towards.heartrateEvent!))
    }

    /// Migrate element after load, e.g. if an older version needs to be migrated to current version.
    init(_ element: Self) {
        self.date = element.date
        self.resetEvent = element.resetEvent
        self.motionActivityEvent = element.motionActivityEvent
        self.intensityEvent = element.intensityEvent
        self.pedometerDataEvent = element.pedometerDataEvent
        self.distanceEvent = element.distanceEvent
        self.heartrateSecondsEvent = element.heartrateSecondsEvent
        self.heartrateEvent = element.heartrateEvent
    }

    init(
        date: Date,
        resetEvent: ResetEvent? = nil,
        motionActivityEvent: MotionActivityEvent? = nil,
        intensityEvent: IntensityEvent? = nil,
        pedometerDataEvent: PedometerDataEvent? = nil,
        distanceEvent: DistanceEvent? = nil,
        heartrateSecondsEvent: HeartrateSecondsEvent? = nil,
        heartrateEvent: HeartrateEvent? = nil)
    {
        self.date = date
        self.resetEvent = resetEvent
        self.motionActivityEvent = motionActivityEvent
        self.intensityEvent = intensityEvent
        self.pedometerDataEvent = pedometerDataEvent
        self.distanceEvent = distanceEvent
        self.heartrateSecondsEvent = heartrateSecondsEvent
        self.heartrateEvent = heartrateEvent
    }

    // MARK: Implement specifics
    private(set) var resetEvent: ResetEvent?
    private(set) var intensityEvent: IntensityEvent?
    
    private(set) var motionActivityEvent: MotionActivityEvent?
    private(set) var pedometerDataEvent: PedometerDataEvent? // pdm distance, steps, active duration
    private(set) var distanceEvent: DistanceEvent? // GPS distance
    private(set) var heartrateSecondsEvent: HeartrateSecondsEvent? // Heartrate average
    private(set) var heartrateEvent: HeartrateEvent? // EnergyExpended

    var resetDate: Date? {resetEvent?.originalDate}
    var intensity: Run.Intensity? {intensityEvent?.intensity}
    var motion: MotionActivityEvent.Motion? {motionActivityEvent?.motion}
    var numberOfSteps: Int? {pedometerDataEvent?.numberOfSteps}
    var pdmDistance: CLLocationDistance? {pedometerDataEvent?.distance}
    var activeDuration: TimeInterval? {pedometerDataEvent?.activeDuration}
    var gpsDistance: CLLocationDistance? {distanceEvent?.distance}
    var heartrateSeconds: Double? {heartrateSecondsEvent?.heartrateSeconds}
    var energyExpended: Int? {heartrateEvent?.energyExpended}
    
    mutating func refresh(
        dirtyAfter: Date,
        resetTimeseries: TimeSeries<ResetEvent, None>,
        intensityTimeseries: TimeSeries<IntensityEvent, None>,
        motionActivityTimeseries: TimeSeries<MotionActivityEvent, None>,
        pedometerDataTimeseries: TimeSeries<PedometerDataEvent, None>,
        distanceTimeseries: TimeSeries<DistanceEvent, None>,
        heartrateTimeseries: TimeSeries<HeartrateEvent, None>,
        heartrateSecondsTimeseries: TimeSeries<HeartrateSecondsEvent, None>)
    {
        if date > dirtyAfter {
            // Refresh all
            resetEvent = resetTimeseries[date]
            intensityEvent = intensityTimeseries[date]
            motionActivityEvent = motionActivityTimeseries[date]
            pedometerDataEvent = pedometerDataTimeseries[date]
            distanceEvent = distanceTimeseries[date]
            heartrateSecondsEvent = heartrateSecondsTimeseries[date]
            heartrateEvent = heartrateTimeseries[date]
        } else {
            // Refresh if nil
            resetEvent = resetEvent ?? resetTimeseries[date]
            intensityEvent = intensityEvent ?? intensityTimeseries[date]
            motionActivityEvent = motionActivityEvent ?? motionActivityTimeseries[date]
            pedometerDataEvent = pedometerDataEvent ?? pedometerDataTimeseries[date]
            distanceEvent = distanceEvent ?? distanceTimeseries[date]
            heartrateSecondsEvent = heartrateSecondsEvent ?? heartrateSecondsTimeseries[date]
            heartrateEvent = heartrateEvent ?? heartrateTimeseries[date]
        }
    }
}

struct TotalEventDelta: Scalable, AdditiveArithmetic, Equatable {
    // MARK: Implement AdditiveArithmetic
    static func - (lhs: TotalEventDelta, rhs: TotalEventDelta) -> TotalEventDelta {
        TotalEventDelta(
            duration: lhs.duration - rhs.duration,
            resetDelta: lhs.resetDelta - rhs.resetDelta,
            intensityDelta: lhs.intensityDelta - rhs.intensityDelta,
            motionActivityDelta: lhs.motionActivityDelta - rhs.motionActivityDelta,
            pedometerDataDelta: lhs.pedometerDataDelta - rhs.pedometerDataDelta,
            distanceDelta: lhs.distanceDelta - rhs.distanceDelta,
            heartrateSecondsDelta: lhs.heartrateSecondsDelta - rhs.heartrateSecondsDelta,
            heartrateDelta: lhs.heartrateDelta - rhs.heartrateDelta)
    }
    
    static func + (lhs: TotalEventDelta, rhs: TotalEventDelta) -> TotalEventDelta {
        TotalEventDelta(
            duration: lhs.duration + rhs.duration,
            resetDelta: lhs.resetDelta + rhs.resetDelta,
            intensityDelta: lhs.intensityDelta + rhs.intensityDelta,
            motionActivityDelta: lhs.motionActivityDelta + rhs.motionActivityDelta,
            pedometerDataDelta: lhs.pedometerDataDelta + rhs.pedometerDataDelta,
            distanceDelta: lhs.distanceDelta + rhs.distanceDelta,
            heartrateSecondsDelta: lhs.heartrateSecondsDelta + rhs.heartrateSecondsDelta,
            heartrateDelta: lhs.heartrateDelta + rhs.heartrateDelta)
    }
    
    static var zero = TotalEventDelta(
        duration: 0,
        resetDelta: nil,
        intensityDelta: nil,
        motionActivityDelta: nil,
        pedometerDataDelta: nil,
        distanceDelta: nil,
        heartrateSecondsDelta: nil,
        heartrateDelta: nil)

    // MARK: Implement Scalable
    static func * (lhs: TotalEventDelta, rhs: Double) -> TotalEventDelta {
        TotalEventDelta(
            duration: lhs.duration * rhs,
            resetDelta: lhs.resetDelta * rhs,
            intensityDelta: lhs.intensityDelta * rhs,
            motionActivityDelta: lhs.motionActivityDelta * rhs,
            pedometerDataDelta: lhs.pedometerDataDelta * rhs,
            distanceDelta: lhs.distanceDelta * rhs,
            heartrateSecondsDelta: lhs.heartrateSecondsDelta * rhs,
            heartrateDelta: lhs.heartrateDelta * rhs)
    }
    
    let duration: TimeInterval
    let resetDelta: VectorElementDelta?
    let intensityDelta: VectorElementDelta?
    
    let motionActivityDelta: VectorElementDelta?

    let pedometerDataDelta: VectorElementDelta? // pdm distance, steps, active duration
    let distanceDelta: VectorElementDelta? // GPS distance
    let heartrateSecondsDelta: VectorElementDelta? // Heartrate average
    let heartrateDelta: VectorElementDelta? // EnergyExpended

    var numberOfSteps: Int? { PedometerDataEvent.numberOfSteps(pedometerDataDelta).int() }
    var cadence: Double? { PedometerDataEvent.numberOfSteps(pedometerDataDelta?.originalNormalize()) }
    var pdmDistance: CLLocationDistance? { PedometerDataEvent.distance(pedometerDataDelta) }
    var activeDuration: TimeInterval? { PedometerDataEvent.activeDuration(pedometerDataDelta) }
    var gpsDistance: CLLocationDistance? { DistanceEvent.distance(distanceDelta) }
    var energyExpended: Int? { HeartrateEvent.energyExpended(heartrateDelta).int() }
    
    var pdmSpeed: CLLocationSpeed? { PedometerDataEvent.distance(pedometerDataDelta?.originalNormalize()) }
    var gpsSpeed: CLLocationSpeed? { DistanceEvent.distance(distanceDelta?.originalNormalize()) }
    var avgHeartrate: Int? {
        HeartrateSecondsEvent.heartrateSeconds(heartrateSecondsDelta?.originalNormalize()).int()
    }
    
    var distance: CLLocationDistance? { gpsDistance ?? pdmDistance }
    var speed: CLLocationSpeed? { gpsSpeed ?? pdmSpeed }
    var vdot: Double? {
        guard let speed = speed else {return nil}
        guard let avgHeartrate = avgHeartrate else {return nil}
        guard let hrLimits = Profile.hrLimits.value else {return nil}
        
        return Run.train(hrBpm: avgHeartrate, paceSecPerKm: 1000 / speed, limits: hrLimits)
    }
}

/// Helper for `sumUp` function
struct TotalEventKey: Hashable {
    let resetEvent: ResetEvent?
    let intensityEvent: IntensityEvent?
    
    // Hashable, just the value necessary to differentiate in the result
    func hash(into hasher: inout Hasher) {
        hasher.combine(resetEvent?.originalDate)
        hasher.combine(intensityEvent?.intensity)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.resetEvent?.originalDate == rhs.resetEvent?.originalDate else {return false}
        guard lhs.intensityEvent?.intensity == rhs.intensityEvent?.intensity else {return false}
        return true
    }
}

extension TimeSeries where Element == TotalEvent, Meta == Date {
    func reflect(resetEvent: ResetEvent) {
        insert(TotalEvent(date: resetEvent.date, resetEvent: resetEvent))
        reflect(dirtyAfter: resetEvent.date)
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
        resetTimeseries: TimeSeries<ResetEvent, None>,
        motionActivityTimeseries: TimeSeries<MotionActivityEvent, None>,
        intensityTimeseries: TimeSeries<IntensityEvent, None>,
        pedometerDataTimeseries: TimeSeries<PedometerDataEvent, None>,
        distanceTimeseries: TimeSeries<DistanceEvent, None>,
        heartrateTimeseries: TimeSeries<HeartrateEvent, None>,
        heartrateSecondsTimeseries: TimeSeries<HeartrateSecondsEvent, None>)
    {
        elements.indices.forEach {
            self[$0]?.refresh(
                dirtyAfter: meta ?? .distantPast,
                resetTimeseries: resetTimeseries,
                intensityTimeseries: intensityTimeseries,
                motionActivityTimeseries: motionActivityTimeseries,
                pedometerDataTimeseries: pedometerDataTimeseries,
                distanceTimeseries: distanceTimeseries,
                heartrateTimeseries: heartrateTimeseries,
                heartrateSecondsTimeseries: heartrateSecondsTimeseries)
        }
        meta = elements.last?.date
    }
    
    typealias TResult = [TotalEventKey: (delta: TotalEventDelta, endDate: Date, motion: MotionActivityEvent.Motion?)]
    
    /// Sum up totals up to given date.
    /// Totals are seperated by the Key and summed up within each key.
    /// Only values at or after the reset date in given `upToEvent` are considered. Older values are filtered out.
    /// Preliminary: The timeseries must be fully refreshed. `upToEvent`must contain a valid `resetEvent`
    func sumUp(upToEvent: TotalEvent) throws -> TResult {
        guard let resetDate = upToEvent.resetEvent?.originalDate else {
            throw "upToEvent must contain resetEvent"
        }
        
        var prevEvent: TotalEvent?
        
        // Elements in order with `upToEvent` at end
        return (elements + [upToEvent])
            // Collect and arrange into key and Delta
            .compactMap { event -> (key: TotalEventKey, delta: TotalEventDelta, endDate: Date, motion: MotionActivityEvent.Motion?)? in
                
                defer {prevEvent = event}
                guard let prevEvent = prevEvent else {return nil}
                guard let resetEvent = prevEvent.resetEvent, resetEvent.originalDate >= resetDate else {return nil}
                
                return (
                    key: TotalEventKey(
                        resetEvent: prevEvent.resetEvent,
                        intensityEvent: prevEvent.intensityEvent),
                    delta: prevEvent.distance(to: event),
                    endDate: event.date,
                    motion: prevEvent.motion)
            }
            // Sumup within keys
            .reduce(into: TResult()) {
                let value = $0[$1.key, default: (.zero, .distantPast, .none)]
                $0[$1.key] = (delta: value.delta + $1.delta, endDate: max(value.endDate, $1.endDate), motion: max(value.motion, $1.motion))
            }
    }
}
