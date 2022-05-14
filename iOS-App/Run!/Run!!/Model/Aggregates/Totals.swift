//
//  Totals.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 27.03.22.
//

import Foundation
import CoreLocation
import UIKit


class Totals {
    // MARK: Initalize
    init(
        stepGetter: @escaping (Date) -> StepX?,
        activityGetter: @escaping (Date) -> ActivityX?,
        heartrateGetter: @escaping (Date) -> HeartrateX?,
        intensityGetter: @escaping (Date) -> IntensityX?,
        distanceGetter: @escaping (Date) -> DistanceX?)
    {
        self.stepGetter = stepGetter
        self.activityGetter = activityGetter
        self.heartrateGetter = heartrateGetter
        self.intensityGetter = intensityGetter
        self.distanceGetter = distanceGetter
    }
    
    // MARK: Interface
    struct Key: Hashable, Codable, Equatable {
        let isActive: Bool?
        let intensity: Run.Intensity?
    }
    
    struct Value: Codable, AdditiveArithmetic, Equatable {
        var sumHeartrate: Int?
        var sumDuration: TimeInterval?
        var sumDistance: CLLocationDistance?
        var sumCadence: Double?
        
        var avgHeartrate: Int? {
            guard let sumDuration = sumDuration, let sumHeartrate = sumHeartrate, sumDuration > 0 else {return nil}
            return Int(Double(sumHeartrate) / sumDuration + 0.5)
        }
        
        var avgCadence: Double? {
            guard let sumDuration = sumDuration, let sumCadence = sumCadence, sumDuration > 0 else {return nil}
            return sumCadence / sumDuration
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
        static var zero: Value {Value(sumHeartrate: 0, sumDuration: 0, sumDistance: 0, sumCadence: 0.0)}
        
        static func + (lhs: Value, rhs: Value) -> Value {
            Value(
                sumHeartrate: lhs.sumHeartrate + rhs.sumHeartrate,
                sumDuration: lhs.sumDuration + rhs.sumDuration,
                sumDistance: lhs.sumDistance + rhs.sumDistance,
                sumCadence: lhs.sumCadence + rhs.sumCadence)
        }

        static func - (lhs: Value, rhs: Value) -> Value {
            Value(
                sumHeartrate: lhs.sumHeartrate - rhs.sumHeartrate,
                sumDuration: lhs.sumDuration - rhs.sumDuration,
                sumDistance: lhs.sumDistance - rhs.sumDistance,
                sumCadence: lhs.sumCadence - rhs.sumCadence)
        }
    }
    
    struct KeyValue: Codable {
        let key: Key
        let value: Value
    }
    
    private(set) var totals = [Key: Value]() {
        didSet {
            let flattend = totals.map {KeyValue(key: $0.key, value: $0.value)} // TODO: Latest first, best order
            DispatchQueue.main.async {self.flattend = flattend}
        }
    }
    private(set) var flattend = [KeyValue]()
    
    func reset() {
        totals.removeAll()
    }
    
    func changed(activities appendedA: [ActivityX], _ removedA: [ActivityX], _ time: ClosedRange<Date>) {
        // For each removed second
        removedA.forEach {
            guard time.contains($0.date) else {return}

            let key = key(asOf: $0.date, isActive: $0.isActive)
            let value = value(asOf: $0.date)
            totals[key, default: .zero] -= value
        }
        
        // For each appended second
        appendedA.forEach {
            guard time.contains($0.date) else {return}

            let key = key(asOf: $0.date, isActive: $0.isActive)
            let value = value(asOf: $0.date)
            totals[key, default: .zero] += value
        }
    }

    func changed(intensities appendedI: [IntensityX], _ removedI: [IntensityX], _ appendedH: [HeartrateX], _ removedH: [HeartrateX], _ time: ClosedRange<Date>) {
        // For each removed second
        removedI.forEach {
            guard time.contains($0.date) else {return}

            let key = key(asOf: $0.date, intensity: removedI[$0.date]?.intensity)
            let value = value(asOf: $0.date, heartrate: removedH[$0.date]?.heartrate)
            totals[key, default: .zero] -= value
        }
        
        // For each appended second
        appendedI.forEach {
            guard time.contains($0.date) else {return}

            let key = key(asOf: $0.date, intensity: appendedI[$0.date]?.intensity)
            let value = value(asOf: $0.date, heartrate: appendedH[$0.date]?.heartrate)
            totals[key, default: .zero] += value
        }
    }
    
    func changed(distances appended: [DistanceX], _ removed: [DistanceX], _ time: ClosedRange<Date>) {
        removed.forEach {
            guard time.contains($0.date) else {return}
            
            let value = value(asOf: $0.date, distance: removed[$0.date]?.speed)
            let key = key(asOf: $0.date)
            totals[key, default: .zero] -= value
        }
        
        appended.forEach {
            guard time.contains($0.date) else {return}
            
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
    private let stepGetter: (Date) -> StepX?
    private let activityGetter: (Date) -> ActivityX?
    private let heartrateGetter: (Date) -> HeartrateX?
    private let intensityGetter: (Date) -> IntensityX?
    private let distanceGetter: (Date) -> DistanceX?
    
    private func key(asOf: Date, isActive: Bool? = nil, intensity: Run.Intensity? = nil) -> Key {
        Key(isActive: isActive ?? activityGetter(asOf)?.isActive,
            intensity: intensity ?? intensityGetter(asOf)?.intensity)
    }

    private func value(asOf: Date, heartrate: Int? = nil, distance: CLLocationDistance? = nil, cadence: Double? = nil) -> Value {
        Value(
            sumHeartrate: heartrate ?? heartrateGetter(asOf)?.heartrate,
            sumDuration: 1,
            sumDistance: distance ?? distanceGetter(asOf)?.speed,
            sumCadence: cadence ?? stepGetter(asOf)?.currentCadence)
    }
}
