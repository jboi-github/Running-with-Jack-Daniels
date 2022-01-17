//
//  ConfigService.swift
//  Run!
//
//  Created by Jürgen Boiselle on 03.11.21.
//

import Foundation
import HealthKit
import CoreLocation

enum PeripheralHandling {
    static var primaryUuid: UUID? {
        get {
            return Store.read(for: "BlePrimaryUuidKey")?.1
        }
        set {
            Store.write(newValue, at: Date(), for: "BlePrimaryUuidKey")
        }
    }

    static var ignoredUuids: [UUID] {
        get {
            return Store.read(for: "BleIgnoredUuidsKey")?.1 ?? []
        }
        set {
            Store.write(newValue, at: Date(), for: "BleIgnoredUuidsKey")
        }
    }
}

enum FileHandling {
    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.nonConformingFloatEncodingStrategy = .convertToString(
            positiveInfinity: "+inf",
            negativeInfinity: "-inf",
            nan: "nan")
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }

    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        decoder.dateDecodingStrategy = .millisecondsSince1970
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "+inf",
            negativeInfinity: "-inf",
            nan: "nan")
        return decoder
    }

    private static var directory: URL? {
        do {
            let url = try FileManager
                .default
                .url(
                    for: .documentDirectory,
                       in: .userDomainMask,
                       appropriateFor: nil,
                       create: true)
                .appendingPathComponent("Run", isDirectory: true)
            try FileManager
                .default
                .createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        } catch {
            _ = check(error)
            return nil
        }
    }

    private static func url(for fileName: String) -> URL? {
        guard let directory = directory else {return nil}
        do {
            try FileManager
                .default
                .createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            return directory.appendingPathComponent(fileName)
        } catch {
            _ = check(error)
            return nil
        }
    }

    private static func latestUrl(for prefix: String) -> URL? {
        guard let directory = directory else {return nil}
        
        do {
            let files = try FileManager
                .default
                .contentsOfDirectory(at: directory, includingPropertiesForKeys: [])
            
            let fileName = files
                .map {$0.lastPathComponent}
                .filter {$0.hasPrefix(prefix) && $0.hasSuffix(".json")}
                .sorted()
                .last
            guard let fileName = fileName else {return nil}
            
            return directory.appendingPathComponent(fileName)
        } catch {
            _ = check(error)
            return nil
        }
    }

    @discardableResult static func write<E: Encodable>(_ encodable: E, to: String) -> URL? {
        guard let url = url(for: to) else {return nil}
        
        do {
            let data = try (encoder.encode(encodable) as NSData).compressed(using: .lzfse)
            data.write(to: url, atomically: true)
            return url
        } catch {
            _ = check(error)
            return nil
        }
    }
    
    static func read<D: Decodable>(_ decodable: D.Type, from prefix: String) -> D? {
        guard let url = latestUrl(for: prefix) else {return nil}
        
        do {
            let data = try (Data(contentsOf: url) as NSData).decompressed(using: .lzfse)
            return try decoder.decode(decodable, from: data as Data)
        } catch {
            _ = check(error)
            return nil
        }
    }
}

enum Store {
    private struct KeyValueData<Value: Codable>: Codable {
        let timestamp: Date
        let value: Value
    }

    static func read<Value: Codable>(for key: String) -> (Date, Value)? {
        do {
            guard let data = NSUbiquitousKeyValueStore.default.data(forKey: key) else {return nil}
            let kv = try FileHandling.decoder.decode(KeyValueData<Value>.self, from: data)
            return (kv.timestamp, kv.value)
        } catch {
            _ = check(error)
            return nil
        }
    }

    static func write<Value: Codable>(_ value: Value, at timestamp: Date, for key: String) {
        do {
            let kv = KeyValueData<Value>(timestamp: timestamp, value: value)
            let data = try FileHandling.encoder.encode(kv)
            NSUbiquitousKeyValueStore.default.set(data, forKey: key)
        } catch {
            _ = check(error)
        }
    }
}

enum HealthKitHandling {
    private static var healthstore: HKHealthStore? = {
        guard HKHealthStore.isHealthDataAvailable() else {
            _ = check(HKError(.errorHealthDataUnavailable))
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
                _ = check($1)
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
    
    static func authorizedShareWorkout(
        mainType: IsActiveProducer.ActivityType,
        start: Date, end: Date,
        userPauses: [Range<Date>],
        motionPauses: [Range<Date>],
        distance: CLLocationDistance,
        path: [PathService.PathElement],
        hrGraph: [HrGraphService.Heartrate])
    {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {return}

        authorized { success, healthstore in
            guard success, let healthstore = healthstore else {return}
            
            // Get activity type
            var activityType: HKWorkoutActivityType {
                switch mainType {
                case .walking:
                    return .walking
                case .running:
                    return .running
                case .cycling:
                    return .cycling
                default:
                    return .other
                }
            }
            
            // Get events
            var events: [HKWorkoutEvent] {
                userPauses.map {
                    HKWorkoutEvent(
                        type: .pause,
                        dateInterval: DateInterval(start: $0.lowerBound, duration: 0),
                        metadata: nil)
                } +
                userPauses.map {
                    HKWorkoutEvent(
                        type: .resume,
                        dateInterval: DateInterval(start: $0.upperBound, duration: 0),
                        metadata: nil)
                } +
                motionPauses.map {
                    HKWorkoutEvent(
                        type: .motionPaused,
                        dateInterval: DateInterval(start: $0.lowerBound, duration: 0),
                        metadata: nil)
                } +
                motionPauses.map {
                    HKWorkoutEvent(
                        type: .motionResumed,
                        dateInterval: DateInterval(start: $0.upperBound, duration: 0),
                        metadata: nil)
                }
            }
            
            // Get heartrate samples
            var hrSamples: [HKQuantitySample] {
                hrGraph.compactMap { heartrate in
                    guard let hr = heartrate.heartrate else {return nil}
                    
                    return HKQuantitySample(
                        type: hrType,
                        quantity: HKQuantity(unit: HKUnit(from: "count/min"), doubleValue: Double(hr)),
                        start: heartrate.range.lowerBound,
                        end: heartrate.range.upperBound)
                }
            }
            
            // Get locations
            var route: [CLLocation] {
                path.flatMap { item -> [CLLocation] in
                    if let isActive = item.isActive?.isActive, isActive {
                        return item.locations
                    } else if let avgLocation = item.avgLocation {
                        return [avgLocation]
                    } else {
                        return []
                    }
                }
            }
            
            // Save Workout
            let workout = HKWorkout(
                activityType: activityType,
                start: start, end: end,
                workoutEvents: events,
                totalEnergyBurned: nil,
                totalDistance: HKQuantity(unit: HKUnit.meter(), doubleValue: distance),
                device: nil,
                metadata: nil)
            
            healthstore.save(workout) {guard $0, check($1) else {return}}
            
            // Save Route
            let routeBuilder = HKWorkoutRouteBuilder(healthStore: healthstore, device: nil)
            routeBuilder.insertRouteData(route) { success, error in
                guard success, check(error) else {return}
                
                routeBuilder.finishRoute(with: workout, metadata: nil) { route, error in
                    guard route != nil, check(error) else {return}
                }
            }
            
            // Save heartrates
            healthstore.add(hrSamples, to: workout) {guard $0, check($1) else {return}}
        }
    }
}
