//
//  BleHrScannerService.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import Foundation
import CoreBluetooth

class ScannerService: ObservableObject {
    static let sharedInstance = ScannerService()
    
    private init() {}
    
    // MARK: - Interface
    struct Peripheral: Identifiable {
        var id: UUID
        var isPrimary: Bool {PeripheralHandling.primaryUuid == id}
        var isIgnored: Bool {PeripheralHandling.ignoredUuids.contains(id)}

        var peripheral: CBPeripheral? = nil
        var rssi: Double = .nan
        var bodySensorLocation: HeartrateProducer.BodySensorLocation = .Other
        var error: Error? = nil
    }
    
    @Published private(set) var peripherals = [UUID: Peripheral]()
    @Published private(set) var status = BleProducer.Status.stopped
    
    func start(producer: BleProducerProtocol) {
        peripherals.removeAll()
        PeripheralHandling.ignoredUuids.forEach {peripherals[$0] = Peripheral(id: $0)}
        
        let config = PeripheralProducer().config(
            discoveredPeripheral: discoveredPeripheral,
            failedPeripheral: failedPeripheral,
            rssi: rssi,
            bodySensorLocation: bodySensorLocation,
            status: status)
        producer.start(config: config, transientFailedPeripheralUuid: nil)
    }
    
    func stop(producer: BleProducerProtocol) {
        producer.stop()
    }
    func pause(producer: BleProducerProtocol) {
        producer.pause()
    }
    func resume(producer: BleProducerProtocol) {
        producer.resume()
    }

    // MARK: - Implementation

    // MARK: Connect to PeripheralProducer
    private func discoveredPeripheral(_ peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.peripherals[peripheral.identifier] = Peripheral(
                id: peripheral.identifier,
                peripheral: peripheral)
        }
    }
    
    private func failedPeripheral(_ peripheralUuid: UUID, _ error: Error?) {
        DispatchQueue.main.async {
            self.peripherals[peripheralUuid]?.error = error
        }
    }
    
    private func rssi(_ peripheralUuid: UUID, _ rssi: NSNumber) {
        DispatchQueue.main.async {
            self.peripherals[peripheralUuid]?.rssi = rssi.doubleValue
        }
    }
    
    private func bodySensorLocation(
        _ peripheralUuid: UUID,
        _ bodySensorLocation: HeartrateProducer.BodySensorLocation)
    {
        DispatchQueue.main.async {
            self.peripherals[peripheralUuid]?.bodySensorLocation = bodySensorLocation
        }
    }
    
    private func status(_ status: BleProducer.Status) {
        DispatchQueue.main.async {self.status = status}
    }
}
