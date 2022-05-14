//
//  HeartrateMonitorClient.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 11.05.22.
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
final class HeartrateMonitorClient: ClientDelegate {
    weak var client: Client<HeartrateMonitorClient>?
    
    // TODO: Put in timeseries.
    private(set) var bodySensorLocation: BodySensorLocation? = nil
    private(set) var batteryLevel: Int? = nil
    private(set) var peripherals = [UUID: CBPeripheral]() // TODO: Put latest name in time series

    private var bleClient: BleClient?
    private unowned let queue: DispatchQueue
    
    init(queue: DispatchQueue) {
        self.queue = queue
    }
    
    func start(asOf: Date) -> ClientStatus {
        bleClient = BleClient()
        guard let bleClient = bleClient else {return .notAvailable(since: asOf)}
        
        bleClient.start(
            config: BleClient.Config(
                primaryUuid: Store.primaryPeripheral,
                ignoredUuids: Store.ignoredPeripherals,
                stopScanningAfterFirst: true,
                restoreId: "com.apps4live.Run!!.HeartrateMonitorClient.restoreId",
                status: { status in DispatchQueue.main.async {self.client?.statusChanged(to: status)}},
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
                    CBUUID(string: "2A37"): bleClient.startNotifying,
                    CBUUID(string: "2A38"): bleClient.read,
                    CBUUID(string: "2A39"): {bleClient.write(data: Data([UInt8(0x01)]), $0, $1, $2)},
                    CBUUID(string: "2A19"): {bleClient.poll(seconds: 300, $0, $1, $2)}
                ],
                readers: [
                    CBUUID(string: "2A37"): parseHrMeasure,
                    CBUUID(string: "2A38"): parseBodySensorLocation,
                    CBUUID(string: "2A19"): parseBatteryLevel
                ]),
            asOf: asOf, transientFailedPeripheralUuid: nil)
        return .started(since: asOf)
    }
    
    func stop(asOf: Date) {
        bleClient?.stop(asOf: asOf)
        bleClient = nil
    }

    private func parseHrMeasure(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        queue.async {
            if let heartrate = HeartrateX(timestamp, self.peripherals[peripheralUuid]?.name, data) {
                Files.append("\(timestamp.ISO8601Format(.iso8601))\t" +
                             "\(heartrate.heartrate)\t" +
                             "\(heartrate.isOriginal)\t" +
                             "\(String(describing: heartrate.peripheralName))\t" +
                             "\(String(describing: heartrate.skinIsContacted))\t" +
                             "\(String(describing: heartrate.energyExpended))\n", to: "heartrate.txt")
            }
        }
    }
    
    private func parseBodySensorLocation(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        bodySensorLocation = BodySensorLocation.parse(data)
        Files.append("\(timestamp.ISO8601Format(.iso8601))\t\(String(describing: bodySensorLocation))\n", to: "bodySensorLocation.txt")    }

    private func parseBatteryLevel(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        guard let data = data, !data.isEmpty else {return}
        batteryLevel = Int([UInt8](data)[0])
        Files.append("\(timestamp.ISO8601Format(.iso8601))\t\(String(describing: batteryLevel))\n", to: "batterylevel.txt")
    }
}
