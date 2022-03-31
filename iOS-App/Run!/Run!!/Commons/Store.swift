//
//  Store.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 17.03.22.
//

import Foundation

enum Store {
    private struct KeyValueData<Value: Codable>: Codable {
        let timestamp: Date
        let value: Value
    }

    static func read<Value: Codable>(for key: String) -> (Date, Value)? {
        do {
            guard let data = NSUbiquitousKeyValueStore.default.data(forKey: key) else {return nil}
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
            NSUbiquitousKeyValueStore.default.set(data, forKey: key)
        } catch {
            _ = check(error)
        }
    }
}
