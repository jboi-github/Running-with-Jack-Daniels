//
//  HeartrateProducer.swift
//  Run!
//
//  Created by Jürgen Boiselle on 03.11.21.
//

import Foundation
import CoreBluetooth

protocol BodySensorLocationProducer {
    var bodySensorLocation: ((CBPeripheral, HeartrateProducer.BodySensorLocation) -> Void )? {get}
}

extension BodySensorLocationProducer {
    func readBodySensorLocation(_ characteristic: CBCharacteristic) -> Void {
        log(characteristic)
        guard let peripheral = characteristic.service?.peripheral else {return}
        guard characteristic.properties.contains(.read) else {return}
        
        peripheral.readValue(for: characteristic)
    }
    
    func parseBodySensorLocation(_ peripheral: CBPeripheral, _ data: Data?) {
        guard let data = data, !data.isEmpty else {return}
        log(data.map {String(format: "%02hhX", $0)}.joined(separator: " "))

        if let bsl = HeartrateProducer.BodySensorLocation(rawValue: [UInt8](data)[0]) {
            bodySensorLocation?(peripheral, bsl)
        }
    }

}

class HeartrateProducer: BodySensorLocationProducer {
    struct Heartrate {
        let timestamp: Date
        let heartrate: Int
        
        // Optional values, if supported by the device and contained in this notification
        let skinIsContacted: Bool?
        let energyExpended: Int?
        let rr: [TimeInterval]?
        
        static let zero = Self(
            timestamp: .distantPast,
            heartrate: -1,
            skinIsContacted: nil,
            energyExpended: nil,
            rr: nil)
    }
    
    enum BodySensorLocation: UInt8 {
        case Other, Chest, Wrist, Finger, Hand, EarLobe, Foot
    }
    
    /// To be used by dispatcher to connect to `BleProducer`
    func config(
        heartrate: @escaping (Heartrate) -> Void,
        bodySensorLocation: @escaping (CBPeripheral, BodySensorLocation) -> Void,
        status: @escaping (BleProducer.Status) -> Void) -> BleProducer.Config
    {
        self.heartrate = heartrate
        self.bodySensorLocation = bodySensorLocation
        
        return BleProducer.Config(
            primaryUuid: PeripheralHandling.primaryUuid,
            ignoredUuids: PeripheralHandling.ignoredUuids,
            stopScanningAfterFirst: true,
            status: status,
            discoveredPeripheral: nil,
            failedPeripheral: nil,
            rssi: nil,
            servicesCharacteristicsMap: [
                CBUUID(string: "180D") : [
                    CBUUID(string: "2A37"), // Heartrate measurement
                    CBUUID(string: "2A38"), // Body Sensor Location
                    CBUUID(string: "2A39") // Heart rate control point (reset energy expedition)
                ]
            ],
            actions: [
                CBUUID(string: "2A37"): notifyHrMeasures,
                CBUUID(string: "2A38"): readBodySensorLocation,
                CBUUID(string: "2A39"): writeHrControlPoint
            ],
            readers: [
                CBUUID(string: "2A37"): parseHrMeasure,
                CBUUID(string: "2A38"): parseBodySensorLocation
            ])
    }
    
    private var heartrate: ((Heartrate) -> Void)? = nil
    internal private(set) var bodySensorLocation: ((CBPeripheral, BodySensorLocation) -> Void)? = nil
    
    private func notifyHrMeasures(_ characteristic: CBCharacteristic) -> Void {
        log(characteristic)
        guard let peripheral = characteristic.service?.peripheral else {return}
        guard characteristic.properties.contains(.notify) else {return}
        
        peripheral.setNotifyValue(true, for: characteristic)
    }
    
    private func writeHrControlPoint(_ characteristic: CBCharacteristic) -> Void {
        log(characteristic)
        guard let peripheral = characteristic.service?.peripheral else {return}
        guard characteristic.properties.contains(.write) else {return}
        
        peripheral.writeValue(Data([UInt8(0x01)]), for: characteristic, type: .withResponse)
    }
    
    private func parseHrMeasure(_ peripheral: CBPeripheral, _ data: Data?) {
        guard let bytes = data, !bytes.isEmpty else {return}
        let timestamp = Date()
        log(bytes.map {String(format: "%02hhX", $0)}.joined(separator: " "))

        var i: Int = 0
        
        func uint8() -> Int {
            defer {i += 1}
            return Int(bytes[i])
        }
        
        func uint16() -> Int {
            defer {i += 2}
            return Int((UInt16(bytes[i+1]) << 8) | UInt16(bytes[i]))
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
        while rrValuesArePresent && (i+1 < bytes.count) {
            rr?.append(TimeInterval(uint16()) / 1024)
        }

        // Put it all together and inform
        let hr = Heartrate(
            timestamp: timestamp,
            heartrate: heartrate,
            skinIsContacted: skinIsContacted,
            energyExpended: energyExpended,
            rr: rr)
        self.heartrate?(hr)
    }
}
