//
//  Store.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 17.03.22.
//

import Foundation
import Combine

enum Store {
    private struct KeyValueData<Value: Codable>: Codable {
        let timestamp: Date
        let value: Value
    }

    static func read<Value: Codable>(for key: String) -> (date: Date, value: Value)? {
        do {
            guard let data = UserDefaults.standard.data(forKey: key) else {return nil}
            let kv = try Files.decoder.decode(KeyValueData<Value>.self, from: data)
            return (kv.timestamp, kv.value)
        } catch {
            _ = check(error)
            return nil
        }
    }

    static func write<Value: Codable>(_ value: Value, at timestamp: Date, for key: String) {
        do {
            let kv = KeyValueData<Value>(timestamp: timestamp, value: value)
            let data = try Files.encoder.encode(kv)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            _ = check(error)
        }
    }
}

// MARK: Persistence Property Wrapper
@propertyWrapper struct Persistent<Value> where Value: Codable {
    init(wrappedValue defaultValue: Value, key: String) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    let key: String
    let defaultValue: Value
    private var cachedValue: Value?

    var wrappedValue: Value {
        mutating get {
            if let chachedValue = cachedValue {return chachedValue}
            cachedValue = Store.read(for: key)?.value ?? defaultValue
            return cachedValue!
        }
        set {
            Store.write(newValue, at: .now, for: key)
            cachedValue = newValue
        }
    }
    
    var projectedValue: Self {self}
}