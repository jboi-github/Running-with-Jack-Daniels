//
//  ConfigService.swift
//  Run!
//
//  Created by Jürgen Boiselle on 03.11.21.
//

import Foundation
import HealthKit

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
            let data = try (encoder.encode(encodable) as NSData).compressed(using: .zlib)
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
            let data = try (Data(contentsOf: url) as NSData).decompressed(using: .zlib)
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
}
