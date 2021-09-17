//
//  MiBandConnector.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 18.06.21.
//

import Foundation
import CoreBluetooth
import Combine

public class BleHeartrateReceiver {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    static let sharedInstance = BleHeartrateReceiver()

    /// Use singleton @sharedInstance
    private init() {}

    // MARK: - Published
    
    public struct Heartrate {
        let heartrate: Int
        let when: Date
    }
    
    /// Indicates, if Receiver is still active.
    public private(set) var receiving: PassthroughSubject<Bool, Error>!

    /// Current heartrate
    public private(set) var heartrate: PassthroughSubject<Heartrate, Error>!

    /// Scan for a heartrate measuring peripherals, connect and start receiving heartrates into `heartrate` form the first peripheral found
    /// that provides the necessary capabilities.
    public func start() {
        log()
        
        receiving = PassthroughSubject<Bool, Error>()
        heartrate = PassthroughSubject<Heartrate, Error>()
        
        centralManager = CBCentralManager(
            delegate: centralManagerDelegate,
            queue: serialDispatchQueue)
    }
    
    /// Stop receiving heartrate measures and disconnect from peripheral if connected. Also stop scanning if currently scanning for peripherals.
    public func stop(with error: Error? = nil) {
        log()
        guard let centralManager = centralManager else {return}
        if centralManager.isScanning {centralManager.stopScan()}
        
        guard let peripheral = peripheral else {return}
        centralManager.cancelPeripheralConnection(peripheral)
        
        serialDispatchQueue.async { [self] in
            receiving.send(false)
            if let error = error {
                receiving.send(completion: .failure(error))
                heartrate.send(completion: .failure(error))
            } else {
                receiving.send(completion: .finished)
                heartrate.send(completion: .finished)
            }
        }
    }
    
    // MARK: - Private
    
    private func check(_ error: Error?) {
        _ = Running_with_Jack_Daniels.check(error)
        guard let error = error else {return} // No real issue
        
        stop(with: error)
    }

    private var centralManager: CBCentralManager?
    private let centralManagerDelegate = CentralManagerDelegate()
    
    private var peripheral: CBPeripheral?
    private let peripheralDelegate = PeripheralDelegate()
    
    private static let heartRateServiceCBUUID = CBUUID(string: "0x180D")
    private static let servicesCBUUID = [
        heartRateServiceCBUUID,
        CBUUID(string: "0xFEE1"),
        CBUUID(string: "0xFEE0")
    ]
    private static let heartRateCharacteristicCBUUID = CBUUID(string: "2A37")
    
    private class CentralManagerDelegate : NSObject, CBCentralManagerDelegate {
        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            switch central.state {
            case .unknown:
                log("unknown", central.isScanning)
            case .resetting:
                log("resetting", central.isScanning)
            case .unsupported:
                log("unsupported", central.isScanning)
            case .unauthorized:
                log("unauthorized", central.isScanning)
            case .poweredOff:
                log("powered off", central.isScanning)
            case .poweredOn:
                log("powered on. Initiate scanning...")
                central.scanForPeripherals(withServices: BleHeartrateReceiver.servicesCBUUID)
            @unknown default:
                log("For future use and the future is already here")
            }
        }
        
        func centralManager(
            _ central: CBCentralManager,
            didDiscover peripheral: CBPeripheral,
            advertisementData: [String : Any],
            rssi RSSI: NSNumber)
        {
            log(peripheral.name ?? "no-name", RSSI)
            advertisementData.forEach {log($0.key, $0.value)}
            
            peripheral.delegate = BleHeartrateReceiver.sharedInstance.peripheralDelegate
            BleHeartrateReceiver.sharedInstance.peripheral = peripheral
            
            //central.stopScan() // FIXME!
            central.connect(peripheral)
        }
        
        func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            log()
            peripheral.discoverServices([BleHeartrateReceiver.heartRateServiceCBUUID])
        }
        
        func centralManager(_ central: CBCentralManager, willRestoreState: [String : Any]) {log()}
        
        func centralManager(
            _ central: CBCentralManager,
            didDisconnectPeripheral peripheral: CBPeripheral,
            error: Error?)
        {
            log(peripheral.name ?? "no-name")
            BleHeartrateReceiver.sharedInstance.check(error)
            BleHeartrateReceiver.sharedInstance.stop()
        }
        
        func centralManager(
            _ central: CBCentralManager,
            didFailToConnect peripheral: CBPeripheral,
            error: Error?)
        {
            log(peripheral.name ?? "no-name")
            BleHeartrateReceiver.sharedInstance.check(error)
        }
        
        func centralManager(
            _ central: CBCentralManager,
            connectionEventDidOccur event: CBConnectionEvent,
            for peripheral: CBPeripheral)
        {
            log(peripheral.name ?? "no-name")
            switch event {
            case .peerDisconnected:
                log("peerDisconnected")
            case .peerConnected:
                log("peerConnected")
            @unknown default:
                log("For future use and the future is already here")
            }
        }
        
        func centralManager(
            _ central: CBCentralManager,
            didUpdateANCSAuthorizationFor peripheral: CBPeripheral)
        {
            log(peripheral.name ?? "no-name", peripheral.ancsAuthorized)
        }
    }
    
    private class PeripheralDelegate: NSObject, CBPeripheralDelegate {
        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            log(peripheral.name ?? "no-name")
            BleHeartrateReceiver.sharedInstance.check(error)
            
            guard let services = peripheral.services else {
                log("no services discovered")
                return
            }
            
            services.forEach {peripheral.discoverCharacteristics([heartRateCharacteristicCBUUID], for: $0)}
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didDiscoverIncludedServicesFor service: CBService,
            error: Error?)
        {
            log(peripheral.name ?? "no-name")
            BleHeartrateReceiver.sharedInstance.check(error)
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didDiscoverCharacteristicsFor service: CBService,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", service.uuid)
            BleHeartrateReceiver.sharedInstance.check(error)
            
            service.characteristics?.forEach {
                log($0)
                [
                    "authenticatedSignedWrites": $0.properties.contains(.authenticatedSignedWrites),
                    "broadcast": $0.properties.contains(.broadcast),
                    "extendedProperties": $0.properties.contains(.extendedProperties),
                    "indicate": $0.properties.contains(.indicate),
                    "indicateEncryptionRequired": $0.properties.contains(.indicateEncryptionRequired),
                    "notify": $0.properties.contains(.notify),
                    "notifyEncryptionRequired": $0.properties.contains(.notifyEncryptionRequired),
                    "read": $0.properties.contains(.read),
                    "write": $0.properties.contains(.write),
                    "writeWithoutResponse": $0.properties.contains(.writeWithoutResponse)
                ]
                .filter {$0.value}
                .forEach {log($0.key)}
            }

            // Let's finally get notifications from the first peripheral with
            // HR service, HR characteristics and notification property
            if let charateristic = service
                .characteristics?
                .first(where: {$0.uuid == heartRateCharacteristicCBUUID && $0.properties.contains(.notify)})
            {
                peripheral.setNotifyValue(true, for: charateristic)
                self.peripheral(peripheral, didUpdateValueFor: charateristic, error: error)
            } else {
                BleHeartrateReceiver
                    .sharedInstance
                    .check("Device has no notification capability for heart rate monitoring")
            }
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didDiscoverDescriptorsFor characteristic: CBCharacteristic,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", characteristic.description)
            characteristic.descriptors?.forEach {log($0)}
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didUpdateValueFor characteristic: CBCharacteristic,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", characteristic.uuid)
            BleHeartrateReceiver.sharedInstance.check(error)
            
            serialDispatchQueue.async {
                guard let heartrate = self.heartrate(from: characteristic) else {return}
                
                BleHeartrateReceiver.sharedInstance.heartrate.send(heartrate)
                BleHeartrateReceiver.sharedInstance.receiving.send(true)
            }
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didUpdateValueFor descriptor: CBDescriptor,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", descriptor)
            BleHeartrateReceiver.sharedInstance.check(error)
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didWriteValueFor characteristic: CBCharacteristic,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", characteristic.uuid)
            BleHeartrateReceiver.sharedInstance.check(error)
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didWriteValueFor descriptor: CBDescriptor,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", descriptor)
            BleHeartrateReceiver.sharedInstance.check(error)
        }
        
        func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
            log(peripheral.name ?? "no-name")
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didUpdateNotificationStateFor characteristic: CBCharacteristic,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", characteristic.uuid, characteristic.isNotifying)
            BleHeartrateReceiver.sharedInstance.check(error)
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didReadRSSI RSSI: NSNumber,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", RSSI)
            BleHeartrateReceiver.sharedInstance.check(error)
        }
        
        func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
            log(peripheral.name ?? "no-name")
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didModifyServices invalidatedServices: [CBService])
        {
            log(peripheral.name ?? "no-name", invalidatedServices.map {$0.uuid})
            
            let invalidationFatal = invalidatedServices
                .contains {$0.uuid == BleHeartrateReceiver.heartRateServiceCBUUID}
            if invalidationFatal {BleHeartrateReceiver.sharedInstance.stop()}
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didOpen channel: CBL2CAPChannel?,
            error: Error?)
        {
            log(peripheral.name ?? "no-name")
            BleHeartrateReceiver.sharedInstance.check(error)
        }
        
        private func heartrate(from characteristic: CBCharacteristic, when: Date = Date()) -> Heartrate? {
            guard let value = characteristic.value else {return nil}
            let bytes = [UInt8](value)

            if bytes[0] & 0x01 == 0 {
                // Heart Rate Value Format is in the 2nd byte
                return Heartrate(heartrate: Int(bytes[1]), when: when)
            } else {
                // Heart Rate Value Format is in the 2nd and 3rd bytes
                return Heartrate(heartrate: (Int(bytes[1]) << 8) + Int(bytes[2]), when: when)
            }
        }
    }
}
