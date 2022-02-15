//
//  HeartrateProducer.swift
//  Run!
//
//  Created by Jürgen Boiselle on 03.11.21.
//

import Foundation
import CoreBluetooth

protocol BodySensorLocationProducer {
    var bodySensorLocation: ((UUID, HeartrateProducer.BodySensorLocation) -> Void )? {get}
}

extension BodySensorLocationProducer {
    func readBodySensorLocation(
        _ producer: BleProducerProtocol,
        _ peripheralUuid: UUID,
        _ characteristicUuid: CBUUID,
        _ properties: CBCharacteristicProperties) -> Void
    {
        log(peripheralUuid, characteristicUuid, properties)
        guard properties.contains(.read) else {return}
        
        producer.readValue(peripheralUuid, characteristicUuid)
    }
    
    func parseBodySensorLocation(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        guard let data = data, !data.isEmpty else {return}
        log(data.map {String(format: "%02hhX", $0)}.joined(separator: " "))

        if let bsl = HeartrateProducer.BodySensorLocation(rawValue: [UInt8](data)[0]) {
            bodySensorLocation?(peripheralUuid, bsl)
        }
    }
}

class HeartrateProducer: BodySensorLocationProducer {
    struct Heartrate {
        let timestamp: Date
        let heartrate: Int
        let peripheralUuid: UUID
        
        // Optional values, if supported by the device and contained in this notification
        let skinIsContacted: Bool?
        let energyExpended: Int?
        let rr: [TimeInterval]?
        
        static let zero = Self(
            timestamp: .distantPast,
            heartrate: -1,
            peripheralUuid: UUID(),
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
        bodySensorLocation: @escaping (UUID, BodySensorLocation) -> Void,
        status: @escaping (BleProducer.Status) -> Void) -> BleProducer.Config
    {
        self.heartrate = heartrate
        self.bodySensorLocation = bodySensorLocation
        constantHeartrate = nil
        
        return BleProducer.Config(
            primaryUuid: PeripheralHandling.primaryUuid,
            ignoredUuids: PeripheralHandling.ignoredUuids,
            stopScanningAfterFirst: true,
            status: {self.status($0, status)},
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
        // TODO: Battery Level for currents
    }
    
    /// Optionally send a constant activity, e.g. in case of an error or missing authoritization
    func afterStart() {
        guard let constantHeartrate = constantHeartrate else {return}
        heartrate?(constantHeartrate)
    }

    private var heartrate: ((Heartrate) -> Void)? = nil
    private(set) var bodySensorLocation: ((UUID, BodySensorLocation) -> Void)? = nil
    private var constantHeartrate: Heartrate? = nil
    
    private func notifyHrMeasures(
        _ producer: BleProducerProtocol,
        _ peripheralUuid: UUID,
        _ characteristicUuid: CBUUID,
        _ properties: CBCharacteristicProperties) -> Void
    {
        log(peripheralUuid, characteristicUuid, properties)
        guard properties.contains(.notify) else {return}
        
        producer.setNotifyValue(peripheralUuid, characteristicUuid, true)
    }
    
    private func writeHrControlPoint(
        _ producer: BleProducerProtocol,
        _ peripheralUuid: UUID,
        _ characteristicUuid: CBUUID,
        _ properties: CBCharacteristicProperties) -> Void
    {
        log(peripheralUuid, characteristicUuid, properties)
        guard properties.contains(.write) else {return}
        
        producer.writeValue(peripheralUuid, characteristicUuid, Data([UInt8(0x01)]))
    }
    
    private func parseHrMeasure(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        guard let bytes = data, !bytes.isEmpty else {return}
        // log(bytes.map {String(format: "%02hhX", $0)}.joined(separator: " "))

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
            peripheralUuid: peripheralUuid,
            skinIsContacted: skinIsContacted,
            energyExpended: energyExpended,
            rr: rr)
        self.heartrate?(hr)
    }
    
    private func status(
        _ status: BleProducer.Status,
        _ completion: @escaping (BleProducer.Status) -> Void)
    {
        switch status {
        case .nonRecoverableError(let asOf, _):
            constantHeartrate = Heartrate(
                timestamp: asOf, heartrate: -1, peripheralUuid: UUID(),
                skinIsContacted: nil, energyExpended: nil, rr: nil)
        case .notAuthorized(let asOf):
            constantHeartrate = Heartrate(
                timestamp: asOf, heartrate: -1, peripheralUuid: UUID(),
                skinIsContacted: nil, energyExpended: nil, rr: nil)
        default:
            constantHeartrate = nil
        }
        completion(status)
    }
}
