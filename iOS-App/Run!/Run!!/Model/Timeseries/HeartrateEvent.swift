//
//  HeartrateEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 13.05.22.
//

import Foundation

struct HeartrateEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "HeartrateEvent"
    let vector: VectorElement<Bool?>
    init(_ vector: VectorElement<Bool?>) {self.vector = vector}

    // MARK: Implement specifics
    init(date: Date, heartrate: Int, skinIsContacted: Bool?, energyExpended: Int?) {
        vector = VectorElement(date: date, ints: [heartrate], optionalInts: [energyExpended], categorical: skinIsContacted)
    }
    
    var heartrate: Int {vector.ints[0]}
    var energyExpended: Int? {vector.optionalInts[0]}
    var skinIsContacted: Bool? {vector.categorical}
}

extension TimeSeries where Element == HeartrateEvent {
    /// Parse CoreBluetooth characteristic
    func parse(_ asOf: Date, _ data: Data?) -> Element? {
        guard let data = data, !data.isEmpty else {return nil}
        let (heartrate, skinIsContacted, energyExpended, _) = TimeSeries.parse(data)
        return Element(date: asOf, heartrate: heartrate, skinIsContacted: skinIsContacted, energyExpended: energyExpended)
    }
    
    private static func parse(_ data: Data) -> (Int, Bool?, Int?, [TimeInterval]?) {
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
}
