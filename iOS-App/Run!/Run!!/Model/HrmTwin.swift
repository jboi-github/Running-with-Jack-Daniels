//
//  BleTwin.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import Foundation
import CoreBluetooth

enum HrmStatus {
    case stopped
    case started(since: Date)
    case notAllowed(since: Date)
    case notAvailable(since: Date)
}

/// Heartrate Monitor (HRM) based on BLE
class HrmTwin: ObservableObject {
    // MARK: Public interface
    @Published private(set) var lastReceived: Date = .distantPast
    
    func start(asOf: Date) {
        if case .started = status {return}
        
        bleTwin.start(
            config: BleTwin.Config(
                primaryUuid: nil, // TODO: Read from user defaults
                ignoredUuids: [UUID](), // TODO: Read from user defaults
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
    }

    static let bleRestoreId = "com.apps4live.run.hrm"

    func stop(asOf: Date) {
        if case .stopped = status {return}
        bleTwin.stop()
    }

    // MARK: Status handling
    private(set) var status: HrmStatus = .stopped {
        willSet {
            log(status, newValue)
        }
    }
    
    // MARK: Implementation
    private var bleTwin = BleTwin()
    
    private func status(_ bleStatus: BleStatus) {
        switch bleStatus {
        case .stopped:
            status = .stopped
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
        DispatchQueue.main.async {
            self.lastReceived = timestamp
        }
        // TODO: Parse and inform collection
    }
    
    private func parseBodySensorLocation(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        // TODO: Parse and inform collection
    }
}
