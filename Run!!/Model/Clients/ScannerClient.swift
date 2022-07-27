//
//  ScnTwin.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 05.04.22.
//

import Foundation
import CoreBluetooth

/// Heartrate Monitor Scanner based on BLE
class ScannerClient {
    // MARK: Initialization
    
    // MARK: Public interface
    struct Peripheral: Identifiable {
        var id: UUID
        var isPrimary: Bool {Store.primaryPeripheral == id}
        var isIgnored: Bool {Store.ignoredPeripherals.contains(id)}

        var peripheral: CBPeripheral?
        var rssi: Double = .nan
        var bodySensorLocation: HRM.SensorLocation?
        var batteryLevel: Int?
        var error: Error?
        
        var heartrate: Int?
        var skinIsContacted: Bool?
        var energyExpended: Int?
        var rr: [TimeInterval]?
    }
    
    private(set) var peripherals = [UUID: Peripheral]()
    var sorted: [Peripheral] {
        var result = [Peripheral]()
        
        // Primary first
        if let primaryUuid = Store.primaryPeripheral, let primary = peripherals[primaryUuid] {
            result.append(primary)
        }

        // Descending by RSSI. RSSI = nil at end
        result.append(
            contentsOf: peripherals
                .values
                .filter {
                    if let primaryUuid = Store.primaryPeripheral {
                        return $0.id != primaryUuid
                    }
                    return true
                }
                .sorted {
                    if $0.rssi.isFinite && $1.rssi.isFinite {
                        return $0.rssi >= $1.rssi
                    } else if $0.rssi.isFinite {
                        return true
                    } else if $1.rssi.isFinite {
                        return false
                    } else {
                        return true
                    }
                })

        return result
    }

    func start(asOf: Date, queue: SerialQueue) {
        if case .started = status {return}
        peripherals.removeAll()
        if let primaryUuid = Store.primaryPeripheral {
            peripherals[primaryUuid] = Peripheral(id: primaryUuid)
        }
        Store.ignoredPeripherals.forEach {peripherals[$0] = Peripheral(id: $0)}

        bleTwin.start(
            config: BleClient.Config(
                primaryUuid: Store.primaryPeripheral,
                ignoredUuids: [],
                stopScanningAfterFirst: false,
                restoreId: nil,
                status: status,
                discoveredPeripheral: discoveredPeripheral,
                failedPeripheral: failedPeripheral,
                rssi: rssi,
                servicesCharacteristicsMap: [
                    CBUUID(string: "180D"): (true, [
                        CBUUID(string: "2A37"), // Heartrate measurement
                        CBUUID(string: "2A38") // Body Sensor Location
                    ]),
                    CBUUID(string: "180F"): (false, [
                        CBUUID(string: "2A19") // Battery level
                    ])
                ],
                actions: [
                    CBUUID(string: "2A37"): bleTwin.startNotifying,
                    CBUUID(string: "2A38"): bleTwin.read,
                    CBUUID(string: "2A19"): {self.bleTwin.poll(seconds: 300, $0, $1, $2)}
                ],
                readers: [
                    CBUUID(string: "2A37"): parseHeartrate,
                    CBUUID(string: "2A38"): parseBodySensorLocation,
                    CBUUID(string: "2A19"): parseBatteryLevel
                ]),
            asOf: asOf, queue: queue, transientFailedPeripheralUuid: nil)
        status = .started(since: asOf)
    }

    func stop(asOf: Date) {
        if case .stopped = status {return}
        bleTwin.stop(asOf: asOf)
        status = .stopped(since: asOf)
    }

    // MARK: Status handling
    private(set) var status: ClientStatus = .stopped(since: .distantPast) {
        willSet {
            log(status, newValue)
        }
    }
    
    // MARK: Implementation
    private var bleTwin = BleClient()
    
    private func status(_ bleStatus: ClientStatus) {
        status = bleStatus
    }
    
    private func discoveredPeripheral(_ asOf: Date, _ peripheral: CBPeripheral) {
        peripherals[peripheral.identifier] = Peripheral(id: peripheral.identifier, peripheral: peripheral)
    }
    
    private func failedPeripheral(_ asOf: Date, _ peripheralUuid: UUID, _ error: Error?) {
        peripherals[peripheralUuid]?.error = error
    }
    
    private func rssi(_ asOf: Date, _ peripheralUuid: UUID, _ rssi: NSNumber) {
        peripherals[peripheralUuid]?.rssi = rssi.doubleValue
    }

    private func parseHeartrate(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        guard let (heartrate, skinIsContacted, energyExpended, rr) = HRM.parse(data) else { return }
        peripherals[peripheralUuid]?.heartrate = heartrate
        peripherals[peripheralUuid]?.skinIsContacted = skinIsContacted
        peripherals[peripheralUuid]?.energyExpended = energyExpended
        peripherals[peripheralUuid]?.rr = rr
    }

    private func parseBodySensorLocation(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        peripherals[peripheralUuid]?.bodySensorLocation = HRM.parse(data)
    }

    private func parseBatteryLevel(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        peripherals[peripheralUuid]?.batteryLevel = HRM.parse(data)
    }
}
