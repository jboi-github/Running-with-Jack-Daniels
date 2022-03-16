//
//  PeripheralProducer.swift
//  Run!
//
//  Created by Jürgen Boiselle on 03.11.21.
//

import Foundation
import CoreBluetooth

class PeripheralProducer: BodySensorLocationProducer {
    /// To be used by dispatcher to connect to `BleProducer`
    func config(
        discoveredPeripheral: @escaping (CBPeripheral) -> Void,
        failedPeripheral: @escaping (UUID, Error?) -> Void,
        rssi: @escaping (UUID, NSNumber) -> Void,
        heartrate: @escaping (UUID, HeartrateProducer.Heartrate) -> Void,
        bodySensorLocation: @escaping (UUID, HeartrateProducer.BodySensorLocation) -> Void,
        status: @escaping (BleProducer.Status) -> Void) -> BleProducer.Config
    {
        self.heartrate = heartrate
        self.bodySensorLocation = bodySensorLocation

        return BleProducer.Config(
            primaryUuid: PeripheralHandling.primaryUuid,
            ignoredUuids: [],
            stopScanningAfterFirst: false,
            status: status,
            discoveredPeripheral: discoveredPeripheral,
            failedPeripheral: failedPeripheral,
            rssi: rssi,
            servicesCharacteristicsMap: [
                CBUUID(string: "180D") : [
                    CBUUID(string: "2A37"), // Heartrate measurement
                    CBUUID(string: "2A38") // Body Sensor Location
                ]
            ],
            actions: [
                CBUUID(string: "2A37"): notifyHrMeasures,
                CBUUID(string: "2A38"): readBodySensorLocation
            ],
            readers: [
                CBUUID(string: "2A37"): parseHrMeasure,
                CBUUID(string: "2A38"): parseBodySensorLocation
            ])
        // TODO: Battery Level
    }
    
    internal private(set) var bodySensorLocation: ((UUID, HeartrateProducer.BodySensorLocation) -> Void)? = nil
    private var heartrate: ((UUID, HeartrateProducer.Heartrate) -> Void)? = nil

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
    
    private func parseHrMeasure(_ peripheralUuid: UUID, _ data: Data?, _ timestamp: Date) {
        if let hr = HeartrateProducer.parseHrMeasure(peripheralUuid, data, timestamp) {
            self.heartrate?(peripheralUuid, hr)
        }
    }
}
