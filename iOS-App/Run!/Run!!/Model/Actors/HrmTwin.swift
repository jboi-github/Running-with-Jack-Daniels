//
//  BleTwin.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import Foundation
import CoreBluetooth

enum BodySensorLocation: UInt8 {
    case Other, Chest, Wrist, Finger, Hand, EarLobe, Foot
    
    static func parse(_ data: Data?) -> Self? {
        guard let data = data, !data.isEmpty else {return nil}

        return BodySensorLocation(rawValue: [UInt8](data)[0])
    }
}

/// Heartrate Monitor (HRM) based on BLE
class HrmTwin {
    // MARK: Initialization
    init(queue: DispatchQueue, heartrates: Heartrates) {
        self.queue = queue
        self.heartrates = heartrates
    }
    
    // MARK: Public interface
    private(set) var bodySensorLocation: BodySensorLocation? = nil
    private(set) var batteryLevel: Int? = nil
    private(set) var peripherals = [UUID: CBPeripheral]()
    
    func start(asOf: Date) {
        if case .started = status {return}
        
        bleTwin.start(
            config: BleTwin.Config(
                primaryUuid: Store.primaryPeripheral,
                ignoredUuids: Store.ignoredPeripherals,
                stopScanningAfterFirst: true,
                restoreId: HrmTwin.bleRestoreId,
                status: status,
                discoveredPeripheral: {self.peripherals[$1.identifier] = $1},
                failedPeripheral: nil,
                rssi: nil,
                servicesCharacteristicsMap: [
                    CBUUID(string: "180D") : (true, [
                        CBUUID(string: "2A37"), // Heartrate measurement
                        CBUUID(string: "2A38"), // Body Sensor Location
                        CBUUID(string: "2A39") // Heart rate control point (reset energy expedition)
                    ]),
                    CBUUID(string: "180F") : (false, [
                        CBUUID(string: "2A19") // Battery level
                    ])
                ],
                actions: [
                    CBUUID(string: "2A37"): bleTwin.startNotifying,
                    CBUUID(string: "2A38"): bleTwin.read,
                    CBUUID(string: "2A39"): {self.bleTwin.write(data: Data([UInt8(0x01)]), $0, $1, $2)},
                    CBUUID(string: "2A19"): {self.bleTwin.poll(seconds: 300, $0, $1, $2)}
                ],
                readers: [
                    CBUUID(string: "2A37"): parseHrMeasure,
                    CBUUID(string: "2A38"): parseBodySensorLocation,
                    CBUUID(string: "2A19"): parseBatteryLevel
                ]),
            asOf: asOf, transientFailedPeripheralUuid: nil)
        status = .started(since: asOf)
    }

    static let bleRestoreId = "com.apps4live.run.hrm"

    func stop(asOf: Date) {
        if case .stopped = status {return}
        bleTwin.stop(asOf: asOf)
        status = .stopped(since: asOf)
    }

    // MARK: Status handling
    private(set) var status: BleStatus = .stopped(since: .distantPast) {
        willSet {
            log(status, newValue)
        }
    }
    
    // MARK: Implementation
    private var bleTwin = BleTwin()
    private unowned let queue: DispatchQueue
    private unowned let heartrates: Heartrates
    
    private func status(_ bleStatus: BleStatus) {
        status = bleStatus
    }

    private func parseHrMeasure(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        queue.async {
            if let heartrate = Heartrate(timestamp, self.peripherals[peripheralUuid]?.name, data) {
                self.heartrates.appendOriginal(heartrate: heartrate)
            }
        }
    }
    
    private func parseBodySensorLocation(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        self.bodySensorLocation = BodySensorLocation.parse(data)
    }

    private func parseBatteryLevel(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        guard let data = data, !data.isEmpty else {return}
        self.batteryLevel = Int([UInt8](data)[0])
    }
}
