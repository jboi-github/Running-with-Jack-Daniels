//
//  Hrm.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 05.07.22.
//

import Foundation

enum HRM {
    /// Sensor location on body
    enum SensorLocation: UInt8, Codable {
        case other, chest, wrist, finger, hand, earLobe, foot
    }
    
    /// Get sensor location
    static func parse(_ data: Data?) -> SensorLocation {
        guard let data = data, !data.isEmpty else {return .other}
        return SensorLocation(rawValue: [UInt8](data)[0]) ?? .other
    }
    
    // Get heartrate and additonal information (skin contact, energy expended, RR) if provided
    static func parse(_ data: Data?) -> (Int, Bool?, Int?, [TimeInterval]?)? {
        guard let data = data, !data.isEmpty else {return nil}
        var i: Int = 0
        
        func uint8() -> Int {
            defer {i += 1}
            return Int(data[i])
        }
        
        func uint16() -> Int {
            defer {i += 2}
            return Int((UInt16(data[i+1]) << 8) | UInt16(data[i]))
        }

        // Read flags field
        let flags = uint8()
        let hrValueFormatIs16Bit = flags & (0x01 << 0) > 0
        let skinContactIsSupported = flags & (0x01 << 2) > 0
        let energyExpensionIsPresent = flags & (0x01 << 3) > 0
        let rrValuesArePresent = flags & (0x01 << 4) > 0

        // Get hr
        let heartrate = hrValueFormatIs16Bit ? uint16() : uint8()
        
        // Get skin contact if suported
        let skinIsContacted = skinContactIsSupported ? (flags & (0x01 << 1) > 0) : nil

        // Energy expended if present
        let energyExpended = energyExpensionIsPresent ? uint16() : nil
        
        // RR's as much as is in the data
        var rr = rrValuesArePresent ? [TimeInterval]() : nil
        while rrValuesArePresent && (i+1 < data.count) {
            rr?.append(TimeInterval(uint16()) / 1024)
        }

        return (heartrate, skinIsContacted, energyExpended, rr)
    }
    
    // Get battery level
    static func parse(_ data: Data?) -> Int? {
        guard let data = data, !data.isEmpty else {return nil}
        return Int([UInt8](data)[0])
    }
}
