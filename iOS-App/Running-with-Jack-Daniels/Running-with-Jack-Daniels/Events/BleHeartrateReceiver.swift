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
    
    static let heartRateServiceCBUUID = CBUUID(string: "0x180D")
    static let servicesCBUUID = [
        heartRateServiceCBUUID,
        CBUUID(string: "0xFEE1"),
        CBUUID(string: "0xFEE0")
    ]
    static let heartRateCharacteristicCBUUID = CBUUID(string: "2A37")
    
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
        
        ignoredUuids = (UserDefaults
            .standard
            .array(forKey: BleScannerModel.BleIgnoredUuidsKey) ?? [])
            .compactMap {
                if let uuidString = $0 as? String {return UUID(uuidString: uuidString)}
                return nil
            }
        
        if let uuidString = UserDefaults
            .standard
            .string(forKey: BleScannerModel.BlePrimaryUuidKey)
        {
            primaryUuid = UUID(uuidString: uuidString)
        }

        receiving = PassthroughSubject<Bool, Error>()
        heartrate = PassthroughSubject<Heartrate, Error>()
        serialDispatchQueue.async {self.receiving.send(false)}
        
        centralManager = CBCentralManager(
            delegate: centralManagerDelegate,
            queue: serialDispatchQueue)
    }
    
    /// Stop receiving heartrate measures and disconnect from peripheral if connected. Also stop scanning if currently scanning for peripherals.
    public func stop(with error: Error? = nil) {
        log()
        _stop(with: error)
        
        serialDispatchQueue.async { [self] in
            if let error = error {
                receiving.send(completion: .failure(error))
                heartrate.send(completion: .failure(error))
            } else {
                receiving.send(completion: .finished)
                heartrate.send(completion: .finished)
            }
        }
    }
    
    static let minRestartTimeout: TimeInterval = 5
    static let maxRestartTimeout: TimeInterval = 120
    static let factorRestartTimeout: TimeInterval = 2
    
    private(set) var restartTimeout: TimeInterval = minRestartTimeout
    
    func reset(with error: Error?) {
        log("restart after \(restartTimeout) secs")
        _stop(with: error)
        serialDispatchQueue.asyncAfter(deadline: .now() + restartTimeout) {self.start()}
        restartTimeout = min(restartTimeout * Self.factorRestartTimeout, Self.maxRestartTimeout)
    }

    // MARK: - Private
    
    private func _stop(with error: Error?) {
        if !check(error) {
            primaryUuid = nil
            UserDefaults.standard.removeObject(forKey: BleScannerModel.BlePrimaryUuidKey)
        }
        
        if let centralManager = centralManager, centralManager.isScanning {centralManager.stopScan()}
        if let peripheral = peripheral {centralManager?.cancelPeripheralConnection(peripheral)}
        centralManager = nil
        peripheral = nil
        
        serialDispatchQueue.async {self.receiving.send(false)}
    }

    private var ignoredUuids = [UUID]()
    private var primaryUuid: UUID?
    
    private var centralManager: CBCentralManager?
    private let centralManagerDelegate = CentralManagerDelegate()
    
    private var peripheral: CBPeripheral?
    private let peripheralDelegate = PeripheralDelegate()
    
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
                log("powered on. Connecting...")
                connectByPrio(central)
            @unknown default:
                log("For future use and the future is already here")
            }
        }
        
        private func connectByPrio(_ central: CBCentralManager) {
            // Try to re-connect primary peripheral
            if let primaryUuid = BleHeartrateReceiver.sharedInstance.primaryUuid,
               let peripheral = central.retrievePeripherals(withIdentifiers: [primaryUuid]).first
            {
                log("re-connect using primary")
                connect(central, to: peripheral)
                return
            }
            
            // Try to connect to any device already connected with the appropriate service
            if let peripheral = central
                .retrieveConnectedPeripherals(withServices: [BleHeartrateReceiver.heartRateServiceCBUUID])
                .first
            {
                log("re-connect using already conected heartrate device")
                connect(central, to: peripheral)
                return
            }
            
            // Nothing works. Scan for new devices.
            log("Initiate scanning...")
            central.scanForPeripherals(withServices: BleHeartrateReceiver.servicesCBUUID)
        }
        
        private func connect(_ central: CBCentralManager, to peripheral: CBPeripheral) {
            peripheral.delegate = BleHeartrateReceiver.sharedInstance.peripheralDelegate
            BleHeartrateReceiver.sharedInstance.peripheral = peripheral
            central.connect(peripheral)
        }
        
        func centralManager(
            _ central: CBCentralManager,
            didDiscover peripheral: CBPeripheral,
            advertisementData: [String : Any],
            rssi RSSI: NSNumber)
        {
            log(peripheral.name ?? "no-name", RSSI)
            if BleHeartrateReceiver.sharedInstance.ignoredUuids.contains(peripheral.identifier) {return}
            
            advertisementData.forEach {log($0.key, $0.value)}
            central.stopScan()
            
            connect(central, to: peripheral)
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
            BleHeartrateReceiver.sharedInstance.peripheral = nil
            guard check(error) else {
                BleHeartrateReceiver.sharedInstance.reset(with: error)
                return
            }
        }
        
        func centralManager(
            _ central: CBCentralManager,
            didFailToConnect peripheral: CBPeripheral,
            error: Error?)
        {
            log(peripheral.name ?? "no-name")
            BleHeartrateReceiver.sharedInstance.peripheral = nil
            BleHeartrateReceiver.sharedInstance.reset(with: error)
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
            guard check(error) else {
                BleHeartrateReceiver.sharedInstance.reset(with: error)
                return
            }
            
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
            guard check(error) else {
                BleHeartrateReceiver.sharedInstance.reset(with: error)
                return
            }
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didDiscoverCharacteristicsFor service: CBService,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", service.uuid)
            guard check(error) else {
                BleHeartrateReceiver.sharedInstance.reset(with: error)
                return
            }

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
                    .reset(with: "Device has no notification capability for heart rate monitoring")
            }
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didDiscoverDescriptorsFor characteristic: CBCharacteristic,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", characteristic.description)
            characteristic.descriptors?.forEach {log($0)}
            guard check(error) else {
                BleHeartrateReceiver.sharedInstance.reset(with: error)
                return
            }
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didUpdateValueFor characteristic: CBCharacteristic,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", characteristic.uuid)
            guard check(error) else {
                BleHeartrateReceiver.sharedInstance.reset(with: error)
                return
            }

            serialDispatchQueue.async {
                guard let heartrate = self.heartrate(from: characteristic) else {return}

                BleHeartrateReceiver.sharedInstance.receiving.send(true)
                BleHeartrateReceiver.sharedInstance.heartrate.send(heartrate)
            }
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didUpdateValueFor descriptor: CBDescriptor,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", descriptor)
            guard check(error) else {
                BleHeartrateReceiver.sharedInstance.reset(with: error)
                return
            }
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didWriteValueFor characteristic: CBCharacteristic,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", characteristic.uuid)
            guard check(error) else {
                BleHeartrateReceiver.sharedInstance.reset(with: error)
                return
            }
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didWriteValueFor descriptor: CBDescriptor,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", descriptor)
            guard check(error) else {
                BleHeartrateReceiver.sharedInstance.reset(with: error)
                return
            }
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
            guard check(error) else {
                BleHeartrateReceiver.sharedInstance.reset(with: error)
                return
            }
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didReadRSSI RSSI: NSNumber,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", RSSI)
            guard check(error) else {
                BleHeartrateReceiver.sharedInstance.reset(with: error)
                return
            }
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
            if invalidationFatal {
                BleHeartrateReceiver.sharedInstance.stop(with: "mandatory service invalidated")
            }
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didOpen channel: CBL2CAPChannel?,
            error: Error?)
        {
            log(peripheral.name ?? "no-name")
            guard check(error) else {
                BleHeartrateReceiver.sharedInstance.reset(with: error)
                return
            }
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
