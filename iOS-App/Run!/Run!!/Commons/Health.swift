//
//  Health.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 17.03.22.
//

import Foundation
import HealthKit
import CoreLocation

enum Health {
    private static var healthstore: HKHealthStore? = {
        guard HKHealthStore.isHealthDataAvailable() else {
            check(HKError(.errorHealthDataUnavailable))
            return nil
        }
        return HKHealthStore()
    }()
    
    private static var typesToWrite: Set<HKSampleType> = Set([
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .height)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.workoutType()
    ])
    
    private static var typesToRead: Set<HKObjectType> = Set(typesToWrite + [
        HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
        HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
    ])

    private static func authorized(_ completion: @escaping (Bool, HKHealthStore?) -> Void) {
        if let healthstore = healthstore {
            healthstore.requestAuthorization(toShare: typesToWrite, read: typesToRead) {
                check($1)
                completion($0, healthstore)
            }
        } else {
            completion(false, nil)
            return
        }
    }
    
    static func authorizedReadCharacteristic<V>(
        _ completion: @escaping (Date, V) -> Void,
        value: @escaping (HKHealthStore) throws -> V)
    {
        authorized { success, healthstore in
            guard success, let healthstore = healthstore else {return}
            
            do {
                let v = try value(healthstore)
                completion(.distantPast, v)
            } catch {
                guard check(error) else {return}
            }
        }
    }

    static func authorizedReadLatestSample<V: BinaryFloatingPoint>(
        _ completion: @escaping (Date, V) -> Void,
        typeId: HKQuantityTypeIdentifier,
        unit: HKUnit)
    {
        authorizedReadLatestSampleDouble(
            {completion($0, V($1))},
            typeId: typeId,
            unit: unit)
    }

    static func authorizedReadLatestSample<V: BinaryInteger>(
        _ completion: @escaping (Date, V) -> Void,
        typeId: HKQuantityTypeIdentifier,
        unit: HKUnit)
    {
        authorizedReadLatestSampleDouble(
            {completion($0, V($1 + 0.5))},
            typeId: typeId,
            unit: unit)
    }

    private static func authorizedReadLatestSampleDouble(
        _ completion: @escaping (Date, Double) -> Void,
        typeId: HKQuantityTypeIdentifier,
        unit: HKUnit)
    {
        authorized { success, healthstore in
            guard success, let healthstore = healthstore else {return}
            guard let type = HKObjectType.quantityType(forIdentifier: typeId) else {return}
            
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)])
            { query, samples, error in
                guard check(error) else {return}
                guard let first = samples?.first as? HKQuantitySample else {return}
                
                completion(first.endDate, first.quantity.doubleValue(for: unit))
            }
            healthstore.execute(query)
        }
    }
    
    static func authorizedShare(
        typeId: HKQuantityTypeIdentifier,
        unit: HKUnit,
        value: Double,
        timestamp: Date)
    {
        guard let type = HKObjectType.quantityType(forIdentifier: typeId) else {return}
        
        authorized { success, healthstore in
            guard success, let healthstore = healthstore else {return}
            
            let sample = HKQuantitySample(
                type: type,
                quantity: HKQuantity(unit: unit, doubleValue: value),
                start: timestamp, end: timestamp)
            
            healthstore.save(sample) {if check($1) {log(value, $0)}}
        }
    }
    
    static func authorizedShareWorkout(_ workout: HKWorkout, heartrates: [HKQuantitySample], locations: [CLLocation]) {
        authorized { success, healthstore in
            guard success, let healthstore = healthstore else {return}
            
            healthstore.save(workout) {guard $0, check($1) else {return}}
            
            // Save Route
            let routeBuilder = HKWorkoutRouteBuilder(healthStore: healthstore, device: nil)
            routeBuilder.insertRouteData(locations) { success, error in
                guard success, check(error) else {return}
                
                routeBuilder.finishRoute(with: workout, metadata: nil) { locations, error in
                    guard locations != nil, check(error) else {return}
                }
            }
            
            // Save heartrates
            healthstore.add(heartrates, to: workout) {guard $0, check($1) else {return}}
        }
    }
}
