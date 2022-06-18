//
//  HeartrateMonitorClient.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 11.05.22.
//

import Foundation
import CoreBluetooth

final class HeartrateMonitorClient: ClientDelegate {
    private var statusCallback: ((ClientStatus) -> Void)?
    private let bleClient = BleClient()
    private unowned let queue: DispatchQueue
    private unowned let timeseriesSet: TimeSeriesSet
    private unowned let heartrateTimeseries: TimeSeries<HeartrateEvent, None>
    private unowned let batteryLevelTimeseries: TimeSeries<BatteryLevelEvent, None>
    private unowned let bodySensorLocationTimeseries: TimeSeries<BodySensorLocationEvent, None>
    private unowned let peripheralTimeseries: TimeSeries<PeripheralEvent, None>

    init(
        queue: DispatchQueue,
        timeseriesSet: TimeSeriesSet,
        heartrateTimeseries: TimeSeries<HeartrateEvent, None>,
        batteryLevelTimeseries: TimeSeries<BatteryLevelEvent, None>,
        bodySensorLocationTimeseries: TimeSeries<BodySensorLocationEvent, None>,
        peripheralTimeseries: TimeSeries<PeripheralEvent, None>)
    {
        self.queue = queue
        self.timeseriesSet = timeseriesSet
        self.heartrateTimeseries = heartrateTimeseries
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
                        guard let event = peripheralTimeseries.parse(date, peripheral) else {return}
                        peripheralTimeseries.insert(event)
                    }
                },
                failedPeripheral: nil,
                rssi: nil,
                servicesCharacteristicsMap: [
                    CBUUID(string: "180D"): (true, [
                        CBUUID(string: "2A37"), // Heartrate measurement
                        CBUUID(string: "2A38"), // Body Sensor Location
                        CBUUID(string: "2A39") // Heart rate control point (reset energy expedition)
                    ]),
                    CBUUID(string: "180F"): (false, [
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
            guard let heartrateEvent = heartrateTimeseries.parse(timestamp, data) else {return}
            timeseriesSet.reflect(heartrateEvent)
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
