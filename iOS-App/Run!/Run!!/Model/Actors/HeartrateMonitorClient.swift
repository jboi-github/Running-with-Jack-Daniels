//
//  HeartrateMonitorClient.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 11.05.22.
//

import Foundation
import CoreBluetooth

enum BodySensorLocationX: UInt8 {
    case Other, Chest, Wrist, Finger, Hand, EarLobe, Foot
    
    static func parse(_ data: Data?) -> Self? {
        guard let data = data, !data.isEmpty else {return nil}

        return BodySensorLocationX(rawValue: [UInt8](data)[0])
    }
}
final class HeartrateMonitorClient: ClientDelegate {
    private var statusCallback: ((ClientStatus) -> Void)?
    private var bleClient = BleClient()
    private unowned let queue: DispatchQueue
    private unowned let heartrateTimeseries: TimeSeries<HeartrateEvent>
    private unowned let intensityTimeseries: TimeSeries<IntensityEvent>
    private unowned let batteryLevelTimeseries: TimeSeries<BatteryLevelEvent>
    private unowned let bodySensorLocationTimeseries: TimeSeries<BodySensorLocationEvent>
    private unowned let peripheralTimeseries: TimeSeries<PeripheralEvent>

    init(
        queue: DispatchQueue,
        heartrateTimeseries: TimeSeries<HeartrateEvent>,
        intensityTimeseries: TimeSeries<IntensityEvent>,
        batteryLevelTimeseries: TimeSeries<BatteryLevelEvent>,
        bodySensorLocationTimeseries: TimeSeries<BodySensorLocationEvent>,
        peripheralTimeseries: TimeSeries<PeripheralEvent>)
    {
        self.queue = queue
        self.heartrateTimeseries = heartrateTimeseries
        self.intensityTimeseries = intensityTimeseries
        self.batteryLevelTimeseries = batteryLevelTimeseries
        self.bodySensorLocationTimeseries = bodySensorLocationTimeseries
        self.peripheralTimeseries = peripheralTimeseries
    }
    
    func setStatusCallback(_ callback: @escaping (ClientStatus) -> Void) {
        self.statusCallback = callback
    }

    func start(asOf: Date) -> ClientStatus {
        bleClient.start(
            config: BleClient.Config(
                primaryUuid: Store.primaryPeripheral,
                ignoredUuids: Store.ignoredPeripherals,
                stopScanningAfterFirst: true,
                restoreId: "com.apps4live.Run!!.HeartrateMonitorClient.restoreId",
                status: { status in
                    log(status)
                    if case .notAvailable = status {
                        log()
                    }
                    DispatchQueue.main.async {self.statusCallback?(status)}
                },
                discoveredPeripheral: { date, peripheral in
                    self.queue.async{ [self] in
                        peripheralTimeseries.insert(peripheralTimeseries.parse(date, peripheral))
                    }
                },
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
                    CBUUID(string: "2A39"): {self.bleClient.write(data: Data([UInt8(0x01)]), $0, $1, $2)},
                    CBUUID(string: "2A19"): {self.bleClient.poll(seconds: 300, $0, $1, $2)}
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
        bleClient.stop(asOf: asOf)
    }

    private func parseHrMeasure(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        queue.async { [self] in
            guard let heartrate = heartrateTimeseries.parse(timestamp, data) else {return}
            if let intensities = intensityTimeseries.parse(heartrate, heartrateTimeseries.elements.last) {
                intensities.forEach {intensityTimeseries.insert($0)}
            }
            log(heartrate)
            heartrateTimeseries.insert(heartrate)
        }
    }
    
    private func parseBodySensorLocation(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        queue.async { [self] in
            guard let bodySensorLocation = bodySensorLocationTimeseries.parse(timestamp, data) else {return}
            bodySensorLocationTimeseries.insert(bodySensorLocation)
        }
    }

    private func parseBatteryLevel(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        log(peripheralUuid, timestamp)
        queue.async { [self] in
            guard let batteryLevel = batteryLevelTimeseries.parse(timestamp, data) else {return}
            batteryLevelTimeseries.insert(batteryLevel)
        }
    }
}
