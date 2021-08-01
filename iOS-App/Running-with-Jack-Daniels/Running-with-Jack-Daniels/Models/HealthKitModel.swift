//
//  HealthKitConnector.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 14.07.21.
//

import HealthKit

/// Connect to Healthkit and query or save data as requested .
class HealthKitModel {
    /// Access shared instance of this singleton
    static var sharedInstance = HealthKitModel()
    
    public func getBirthday(_ completion: @escaping (Date?, Error?) -> Void) {
        authorizedRead("getBirthday", completion) {try $0.dateOfBirthComponents().date!}
    }
    
    public func getGender(_ completion: @escaping (Gender?, Error?) -> Void) {
        authorizedRead("getGender") { gender, error in
            switch gender {
            case .female:
                completion(.female, nil)
            case .male:
                completion(.male, nil)
            default:
                completion(nil, error ?? HKError(.errorInvalidArgument))
            }
        } getValue: {try $0.biologicalSex().biologicalSex}
    }

    public func getWeightKg(_ completion: @escaping (Double?, Error?) -> Void) {
        authorizedReadLatest("getWeightKg", completion, typeId: .bodyMass, unit: .gramUnit(with: .kilo))
    }

    public func getHeightM(_ completion: @escaping (Double?, Error?) -> Void) {
        authorizedReadLatest("getHeightM", completion, typeId: .height, unit: .meter())
    }

    public func getRestingHr(_ completion: @escaping (Double?, Error?) -> Void) {
        authorizedReadLatest("getRestingHr", { value, error in
            completion(value == nil ? nil : 60.0 * value!, error)
        },
        typeId: .restingHeartRate,
        unit: .hertz())
    }
    
    public func shareWeightKg(_ weight: Double, succeeded: @escaping () -> Void) {
        authorizedShare(
            "shareWeightKg",
            typeId: .bodyMass,
            unit: .gramUnit(with: .kilo),
            value: weight,
            when: Date(),
            succeeded: succeeded)
    }
    
    public func shareHeightM(_ height: Double, succeeded: @escaping () -> Void) {
        authorizedShare(
            "shareHeightM",
            typeId: .height,
            unit: .meter(),
            value: height,
            when: Date(),
            succeeded: succeeded)
    }
    
    public func shareRestingHr(_ hr: Double, succeeded: @escaping () -> Void) {
        authorizedShare(
            "shareRestingHr",
            typeId: .restingHeartRate,
            unit: .hertz(),
            value: hr / 60.0,
            when: Date(),
            succeeded: succeeded)
    }

    private func authorizedShare(
        _ forFunc: String,
        typeId: HKQuantityTypeIdentifier,
        unit: HKUnit,
        value: Double, when: Date = Date(),
        succeeded: @escaping () -> Void)
    {
        log(msg: forFunc)
        guard let type = HKObjectType.quantityType(forIdentifier: typeId) else {return}
        
        authorized { success in
            guard success, let healthStore = self.healthStore else {return}
            
            let sample = HKQuantitySample(
                type: type,
                quantity: HKQuantity(unit: unit, doubleValue: value),
                start: when, end: when)
            
            healthStore.save(sample) { success, error in
                log(msg: "\(forFunc) successfully shared \(value): \(success ? "Yes" : "No")")
                if success {succeeded()}
                _ = check(error)
            }
        }
    }
    
    private var healthStore: HKHealthStore? = nil
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

    private init() {
        log()
        guard HKHealthStore.isHealthDataAvailable() else {
            _ = check(HKError(.errorHealthDataUnavailable))
            return
        }
        healthStore = HKHealthStore()
    }
    
    // Requests permission to save and read the specified data types.
    private func authorized(_ completion: @escaping (Bool) -> Void) {
        guard let healthStore = healthStore else {
            completion(false)
            return
        }
        
        healthStore.requestAuthorization(
            toShare: HealthKitModel.typesToWrite,
            read: HealthKitModel.typesToRead)
        { success, error in
            log(msg: "requestAuthorization: \(success)")
            _ = check(error)
            
            completion(success)
        }
    }
    
    private func authorizedRead<V>(
        _ forFunc: String,
        _ completion: ((V?, Error?) -> Void)? = nil,
        getValue: @escaping (HKHealthStore) throws -> V)
    {
        log(msg: forFunc)
        authorized { success in
            guard success, let healthStore = self.healthStore else {return}
            
            do {
                let v = try getValue(healthStore)
                completion?(v, nil)
            } catch {
                completion?(nil, error)
            }
        }
    }

    private func authorizedReadLatest(
        _ forFunc: String,
        _ completion: ((Double?, Error?) -> Void)? = nil,
        typeId: HKQuantityTypeIdentifier, unit: HKUnit)
    {
        authorizedRead(forFunc) { store in
            guard let type = HKObjectType.quantityType(forIdentifier: typeId) else {return}
            
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil, limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)])
            { query, samples, error in
                let v = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                completion?(v, error)
            }
            store.execute(query)
        }
    }
}
