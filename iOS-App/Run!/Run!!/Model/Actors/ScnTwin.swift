//
//  ScnTwin.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 05.04.22.
//

import Foundation
import CoreBluetooth

/// Heartrate Monitor Scanner based on BLE
class ScnTwin {
    // MARK: Initialization
    
    // MARK: Public interface
    struct Peripheral: Identifiable {
        var id: UUID
        var isPrimary: Bool {Store.primaryPeripheral == id}
        var isIgnored: Bool {Store.ignoredPeripherals.contains(id)}

        var peripheral: CBPeripheral? = nil
        var rssi: Double = .nan
        var heartrate: HeartrateX? = nil
        var bodySensorLocation: BodySensorLocation?
        var batteryLevel: Int? = nil
        var error: Error? = nil
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

    func start(asOf: Date) {
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
                    CBUUID(string: "180D") : (true, [
                        CBUUID(string: "2A37"), // Heartrate measurement
                        CBUUID(string: "2A38") // Body Sensor Location
                    ]),
                    CBUUID(string: "180F") : (false, [
                        CBUUID(string: "2A19") // Battery level
                    ])
                ],
                actions: [
                    CBUUID(string: "2A37"): bleTwin.startNotifying,
                    CBUUID(string: "2A38"): bleTwin.read,
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

    private func parseHrMeasure(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)

        if let heartrate = HeartrateX(timestamp, peripherals[peripheralUuid]?.peripheral?.name, data) {
            peripherals[peripheralUuid]?.heartrate = heartrate
        }
    }

    private func parseBodySensorLocation(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        peripherals[peripheralUuid]?.bodySensorLocation = BodySensorLocation.parse(data)
    }

    private func parseBatteryLevel(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        guard let data = data, !data.isEmpty else {return}

        peripherals[peripheralUuid]?.batteryLevel = Int([UInt8](data)[0])
    }
}
