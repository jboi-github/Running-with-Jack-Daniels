//
//  Totals.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 27.03.22.
//

import Foundation
import CoreLocation


class Totals {
    // MARK: Initalize
    init(
        motionGetter: @escaping (Date) -> Motion?,
        isActiveGetter: @escaping (Date) -> IsActive?,
        heartrateGetter: @escaping (Date) -> Heartrate?,
        intensityGetter: @escaping (Date) -> Intensity?,
        distanceGetter: @escaping (Date) -> Distance?,
        workout: Workout)
    {
        self.motionGetter = motionGetter
        self.isActiveGetter = isActiveGetter
        self.heartrateGetter = heartrateGetter
        self.intensityGetter = intensityGetter
        self.distanceGetter = distanceGetter
        self.workout = workout
    }
    
    // MARK: Interface
    struct Key: Hashable, Codable, Equatable {
        let isActive: Bool?
        let motionType: MotionType?
        let intensity: Run.Intensity?
    }
    
    struct Value: Codable, AdditiveArithmetic, Equatable {
        var sumHeartrate: Int?
        var sumDuration: TimeInterval?
        var sumDistance: CLLocationDistance?
        
        var avgHeartrate: Int? {
            guard let sumDuration = sumDuration, let sumHeartrate = sumHeartrate, sumDuration > 0 else {return nil}
            return Int(Double(sumHeartrate) / sumDuration + 0.5)
        }
        var avgSpeed: CLLocationSpeed? {
            guard let sumDistance = sumDistance, let sumDuration = sumDuration, sumDuration > 0 else {return nil}
            return sumDistance / sumDuration
        }

        var vdot: Double? {
            guard let heartrate = avgHeartrate else {return nil}
            guard let speed = avgSpeed else {return nil}
            guard let limits = Profile.hrLimits.value else {return nil}

            return Run.train(
                hrBpm: heartrate,
                paceSecPerKm: 1000 / speed,
                limits: limits)
        }
        
        // MARK: Implement AdditiveArithmetic
        static var zero: Value {Value(sumHeartrate: 0, sumDuration: 0, sumDistance: 0)}
        
        static func + (lhs: Value, rhs: Value) -> Value {
            Value(
                sumHeartrate: lhs.sumHeartrate + rhs.sumHeartrate,
                sumDuration: lhs.sumDuration + rhs.sumDuration,
                sumDistance: lhs.sumDistance + rhs.sumDistance)
        }

        static func - (lhs: Value, rhs: Value) -> Value {
            Value(
                sumHeartrate: lhs.sumHeartrate - rhs.sumHeartrate,
                sumDuration: lhs.sumDuration - rhs.sumDuration,
                sumDistance: lhs.sumDistance - rhs.sumDistance)
        }
    }
    
    private(set) var totals = [Key: Value]()
    
    func changed(motions appendedM: [Motion], _ removedM: [Motion], _ appendedA: [IsActive], _ removedA: [IsActive]) {
        // For each removed second
        removedM.forEach {
            guard (workout.startTime ... workout.endTime).contains($0.date) else {return}

            let key = key(asOf: $0.date, isActive: removedA[$0.date]?.isActive, motionType: removedM[$0.date]?.motion)
            let value = value(asOf: $0.date)
            totals[key, default: .zero] -= value
        }
        
        // For each appended second
        appendedM.forEach {
            guard (workout.startTime ... workout.endTime).contains($0.date) else {return}

            let key = key(asOf: $0.date, isActive: appendedA[$0.date]?.isActive, motionType: appendedM[$0.date]?.motion)
            let value = value(asOf: $0.date)
            totals[key, default: .zero] += value
        }
    }

    func changed(intensities appendedI: [Intensity], _ removedI: [Intensity], _ appendedH: [Heartrate], _ removedH: [Heartrate]) {
        // For each removed second
        removedI.forEach {
            guard (workout.startTime ... workout.endTime).contains($0.date) else {return}

            let key = key(asOf: $0.date, intensity: removedI[$0.date]?.intensity)
            let value = value(asOf: $0.date, heartrate: removedH[$0.date]?.heartrate)
            totals[key, default: .zero] -= value
        }
        
        // For each appended second
        appendedI.forEach {
            guard (workout.startTime ... workout.endTime).contains($0.date) else {return}

            let key = key(asOf: $0.date, intensity: appendedI[$0.date]?.intensity)
            let value = value(asOf: $0.date, heartrate: appendedH[$0.date]?.heartrate)
            totals[key, default: .zero] += value
        }
    }
    
    func changed(distances appended: [Distance], _ removed: [Distance]) {
        removed.forEach {
            guard (workout.startTime ... workout.endTime).contains($0.date) else {return}
            
            let value = value(asOf: $0.date, distance: removed[$0.date]?.speed)
            let key = key(asOf: $0.date)
            totals[key, default: .zero] -= value
        }
        
        appended.forEach {
            guard (workout.startTime ... workout.endTime).contains($0.date) else {return}
            
            let value = value(asOf: $0.date, distance: appended[$0.date]?.speed)
            let key = key(asOf: $0.date)
            totals[key, default: .zero] += value
        }
    }
    
    func save() {
        if let url = Files.write(totals, to: "totals.json") {log(url)}
    }
    
    func load() {
        guard let totals = Files.read([Key: Value].self, from: "totals.json") else {return}
        self.totals = totals
    }

    // MARK: Implementation
    private let motionGetter: (Date) -> Motion?
    private let isActiveGetter: (Date) -> IsActive?
    private let heartrateGetter: (Date) -> Heartrate?
    private let intensityGetter: (Date) -> Intensity?
    private let distanceGetter: (Date) -> Distance?
    
    private unowned let workout: Workout
    
    private func key(asOf: Date, isActive: Bool? = nil, motionType: MotionType? = nil, intensity: Run.Intensity? = nil) -> Key {
        Key(isActive: isActive ?? isActiveGetter(asOf)?.isActive,
            motionType: motionType ?? motionGetter(asOf)?.motion,
            intensity: intensity ?? intensityGetter(asOf)?.intensity)
    }

    private func value(asOf: Date, heartrate: Int? = nil, distance: CLLocationDistance? = nil) -> Value {
        Value(
            sumHeartrate: heartrate ?? heartrateGetter(asOf)?.heartrate,
            sumDuration: 1,
            sumDistance: distance ?? distanceGetter(asOf)?.speed)
    }
}
