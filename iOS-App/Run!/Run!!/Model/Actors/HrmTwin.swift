//
//  BleTwin.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import Foundation
import CoreBluetooth

enum HrmStatus {
    case stopped(since: Date)
    case started(since: Date)
    case notAllowed(since: Date)
    case notAvailable(since: Date)
}

enum BodySensorLocation: UInt8 {
    case Other, Chest, Wrist, Finger, Hand, EarLobe, Foot
}

/// Heartrate Monitor (HRM) based on BLE
class HrmTwin {
    // MARK: Initialization
    init(queue: DispatchQueue, heartrates: Heartrates) {
        self.queue = queue
        self.heartrates = heartrates
    }
    
    // MARK: Public interface
    private(set) var bodySensorLocation: BodySensorLocation = .Other
    
    func start(asOf: Date) {
        if case .started = status {return}
        
        bleTwin.start(
            config: BleTwin.Config(
                primaryUuid: Store.read(for: primaryKey)?.1,
                ignoredUuids: Store.read(for: ignoredKey)?.1 ?? [UUID](),
                stopScanningAfterFirst: true,
                restoreId: HrmTwin.bleRestoreId,
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
                ]),
            asOf: asOf, transientFailedPeripheralUuid: nil)
        // TODO: Read Battery Level every 5 minutes and after going to foreground
        
        status = .started(since: asOf)
    }

    static let bleRestoreId = "com.apps4live.run.hrm"

    func stop(asOf: Date) {
        if case .stopped = status {return}
        bleTwin.stop(asOf: asOf)
        status = .stopped(since: asOf)
    }

    // MARK: Status handling
    private(set) var status: HrmStatus = .stopped(since: .distantPast) {
        willSet {
            log(status, newValue)
        }
    }
    
    // MARK: Implementation
    private var bleTwin = BleTwin()
    private unowned let queue: DispatchQueue
    private unowned let heartrates: Heartrates
    
    private func status(_ bleStatus: BleStatus) {
        switch bleStatus {
        case .stopped(since: let since):
            status = .stopped(since: since)
        case .started(since: let since):
            status = .started(since: since)
        case .notAllowed(since: let since):
            status = .notAllowed(since: since)
        case .notAvailable(since: let since):
            status = .notAvailable(since: since)
        }
    }

    private func notifyHrMeasures(
        _ peripheralUuid: UUID,
        _ characteristicUuid: CBUUID,
        _ properties: CBCharacteristicProperties) -> Void
    {
        log(peripheralUuid, characteristicUuid, properties)
        guard properties.contains(.notify) else {return}
        
        bleTwin.setNotifyValue(peripheralUuid, characteristicUuid, true)
    }
    
    private func readBodySensorLocation(
        _ peripheralUuid: UUID,
        _ characteristicUuid: CBUUID,
        _ properties: CBCharacteristicProperties) -> Void
    {
        log(peripheralUuid, characteristicUuid, properties)
        guard properties.contains(.read) else {return}
        
        bleTwin.readValue(peripheralUuid, characteristicUuid)
    }

    private func writeHrControlPoint(
        _ peripheralUuid: UUID,
        _ characteristicUuid: CBUUID,
        _ properties: CBCharacteristicProperties) -> Void
    {
        log(peripheralUuid, characteristicUuid, properties)
        guard properties.contains(.write) else {return}
        
        bleTwin.writeValue(peripheralUuid, characteristicUuid, Data([UInt8(0x01)]))
    }
    
    private func parseHrMeasure(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        
        queue.async {
            if let heartrate = Heartrate(timestamp, data) {
                self.heartrates.appendOriginal(heartrate: heartrate)
            }
        }
    }
    
    private func parseBodySensorLocation(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        guard let data = data, !data.isEmpty else {return}

        bodySensorLocation = BodySensorLocation(rawValue: [UInt8](data)[0]) ?? .Other
    }
}

private let primaryKey = "com.apps4live.Run!!.PrimaryUUID"
private let ignoredKey = "com.apps4live.Run!!.IgnoredUUIDs"
