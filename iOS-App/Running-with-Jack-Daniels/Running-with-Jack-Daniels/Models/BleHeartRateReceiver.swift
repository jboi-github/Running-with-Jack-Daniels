//
//  MiBandConnector.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 18.06.21.
//

import Foundation
import CoreBluetooth

public class BleHeartRateReceiver: ObservableObject {
    static let sharedInstance = BleHeartRateReceiver()
    
    /// Scan for a heartrate measuring peripherals, connect and start receiving heartrates into `heartrate` form the first peripheral found
    /// that provides the necessary capabilities.
    public func start() {
        print("start")
        localizedError = ""
        
        centralManager = CBCentralManager(
            delegate: centralManagerDelegate,
            queue: .global(qos: .userInteractive))
    }
    
    /// Stop receiving heartrate measures and disconnect from peripheral if connected. Also stop scanning if currently scanning for peripherals.
    public func stop() {
        print("stop")
        
        guard let centralManager = centralManager else {return}
        if centralManager.isScanning {centralManager.stopScan()}
        
        guard let peripheral = peripheral else {return}
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    @Published public private(set) var receiving: Bool = false
    @Published public private(set) var heartrate: Int = 0
    @Published public private(set) var latestTimeStamp: Date = Date()
    @Published public private(set) var localizedError: String = ""

    // MARK: Private
    
    private init() {}

    private static func check(_ error: Error?) {
        guard let error = error else {return}
        print(error.localizedDescription)
        
        BleHeartRateReceiver.sharedInstance.stop()
        DispatchQueue.main.async {
            BleHeartRateReceiver.sharedInstance.localizedError = error.localizedDescription
        }
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
                print("State: unknown. Is scanning: \(central.isScanning)")
            case .resetting:
                print("State: resetting. Is scanning: \(central.isScanning)")
            case .unsupported:
                print("State: unsupported. Is scanning: \(central.isScanning)")
            case .unauthorized:
                print("State: unauthorized. Is scanning: \(central.isScanning)")
            case .poweredOff:
                print("State: powered off. Is scanning: \(central.isScanning)")
            case .poweredOn:
                print("State: powered on. Initiate scanning...")
                central.scanForPeripherals(withServices: BleHeartRateReceiver.servicesCBUUID)
            @unknown default:
                print("For future use and the future is already here")
            }
        }
        
        func centralManager(
            _ central: CBCentralManager,
            didDiscover peripheral: CBPeripheral,
            advertisementData: [String : Any],
            rssi RSSI: NSNumber)
        {
            print("didDiscover peripheral \"\(peripheral.name ?? "no-name")\". Signal strength: \(RSSI)")
            advertisementData.forEach { (key: String, value: Any) in
                print("\t\(key): \(value)")
            }
            
            peripheral.delegate = BleHeartRateReceiver.sharedInstance.peripheralDelegate
            BleHeartRateReceiver.sharedInstance.peripheral = peripheral
            
            central.stopScan()
            central.connect(peripheral)
        }
        
        func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            print("didConnect")
            peripheral.discoverServices([BleHeartRateReceiver.heartRateServiceCBUUID])
        }
        
        func centralManager(_ central: CBCentralManager, willRestoreState: [String : Any]) {
            print("willRestoreState")
        }
        
        func centralManager(
            _ central: CBCentralManager,
            didDisconnectPeripheral peripheral: CBPeripheral,
            error: Error?)
        {
            print("didDisconnectPeripheral: \(peripheral.name ?? "no-name")")
            BleHeartRateReceiver.check(error)
            DispatchQueue.main.async {
                BleHeartRateReceiver.sharedInstance.receiving = false
            }
        }
        
        func centralManager(
            _ central: CBCentralManager,
            didFailToConnect peripheral: CBPeripheral,
            error: Error?)
        {
            print("didFailToConnect: \(peripheral.name ?? "no-name")")
            BleHeartRateReceiver.check(error)
        }
        
        func centralManager(
            _ central: CBCentralManager,
            connectionEventDidOccur event: CBConnectionEvent,
            for peripheral: CBPeripheral)
        {
            print("connectionEventDidOccur: \(peripheral.name ?? "no-name")")
            switch event {
            case .peerDisconnected:
                print("peerDisconnected")
            case .peerConnected:
                print("peerConnected")
            @unknown default:
                print("For future use and the future is already here")
            }
        }
        
        func centralManager(
            _ central: CBCentralManager,
            didUpdateANCSAuthorizationFor peripheral: CBPeripheral)
        {
            print("didUpdateANCSAuthorizationFor: \(peripheral.name ?? "no-name") to \(peripheral.ancsAuthorized)")
        }
    }
    
    private class PeripheralDelegate: NSObject, CBPeripheralDelegate {
        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            print("didDiscoverServices: \(peripheral.name ?? "no-name")")
            
            if let error = error {
                print(error)
                return
            }
            
            guard let services = peripheral.services else {
                print("no services discovered")
                return
            }
            
            services.forEach {peripheral.discoverCharacteristics([heartRateCharacteristicCBUUID], for: $0)}
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didDiscoverIncludedServicesFor service: CBService,
            error: Error?)
        {
            print("didDiscoverIncludedServicesFor: \(peripheral.name ?? "no-name")")
            BleHeartRateReceiver.check(error)
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didDiscoverCharacteristicsFor service: CBService,
            error: Error?)
        {
            print("didDiscoverCharacteristicsFor: \(peripheral.name ?? "no-name") -> service: \(service.uuid)")

            if let error = error {
                print(error)
                return
            }
            
            service.characteristics?.forEach {
                print("\t\($0)")
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
                .forEach {print("\t\t\($0.key)")}
            }

            // Let's finally get notifications from the first peripheral with
            // HR service, HR characteristics and notification property
            if let charateristic = service
                .characteristics?
                .first(where: {$0.uuid == heartRateCharacteristicCBUUID && $0.properties.contains(.notify)})
            {
                peripheral.setNotifyValue(true, for: charateristic)
                DispatchQueue.main.async {
                    BleHeartRateReceiver.sharedInstance.latestTimeStamp = Date()
                    BleHeartRateReceiver.sharedInstance.heartrate = self.heartRate(from: charateristic) ?? 0
                    BleHeartRateReceiver.sharedInstance.receiving = true
                }
                return
            }
            BleHeartRateReceiver.check("Device has no notification capability for heart rate monitoring")
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didDiscoverDescriptorsFor characteristic: CBCharacteristic,
            error: Error?)
        {
            print("didDiscoverDescriptorsFor: \(peripheral.name ?? "no-name") -> characteristic: \(characteristic.description)")
            characteristic.descriptors?.forEach {print("\t\($0)")}
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didUpdateValueFor characteristic: CBCharacteristic,
            error: Error?)
        {
            print("didUpdateValueFor: \(peripheral.name ?? "no-name") -> characteristic: \(characteristic.uuid)")
            BleHeartRateReceiver.check(error)
            
            guard let heartRate = heartRate(from: characteristic) else {return}
            
            DispatchQueue.main.async {
                BleHeartRateReceiver.sharedInstance.latestTimeStamp = Date()
                BleHeartRateReceiver.sharedInstance.heartrate = heartRate
            }
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didUpdateValueFor descriptor: CBDescriptor,
            error: Error?)
        {
            print("didUpdateValueFor: \(peripheral.name ?? "no-name") -> descriptor: \(descriptor)")
            BleHeartRateReceiver.check(error)
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didWriteValueFor characteristic: CBCharacteristic,
            error: Error?)
        {
            print("didWriteValueFor: \(peripheral.name ?? "no-name") -> characteristic: \(characteristic.uuid)")
            BleHeartRateReceiver.check(error)
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didWriteValueFor descriptor: CBDescriptor,
            error: Error?)
        {
            print("didWriteValueFor: \(peripheral.name ?? "no-name") -> descriptor: \(descriptor)")
            BleHeartRateReceiver.check(error)
        }
        
        func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
            print("peripheralIsReadytoSendWriteWithoutResponse: \(peripheral.name ?? "no-name")")
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didUpdateNotificationStateFor characteristic: CBCharacteristic,
            error: Error?)
        {
            print("didUpdateNotificationStateFor: \(peripheral.name ?? "no-name") -> characteristic: \(characteristic.uuid) to \(characteristic.isNotifying)")
            BleHeartRateReceiver.check(error)
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didReadRSSI RSSI: NSNumber,
            error: Error?)
        {
            print("didReadRSSI: \(peripheral.name ?? "no-name") -> RSSI: \(RSSI)")
            BleHeartRateReceiver.check(error)
        }
        
        func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
            print("peripheralDidUpdateName: \(peripheral.name ?? "no-name")")
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didModifyServices invalidatedServices: [CBService])
        {
            print("didModifyServices: \(peripheral.name ?? "no-name") -> invalidated: \(invalidatedServices.map {$0.uuid})")
            
            let invalidationFatal = invalidatedServices
                .contains {$0.uuid == BleHeartRateReceiver.heartRateServiceCBUUID}
            if invalidationFatal {BleHeartRateReceiver.sharedInstance.stop()}
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didOpen channel: CBL2CAPChannel?,
            error: Error?)
        {
            print("didOpen channel: \(peripheral.name ?? "no-name")")
            BleHeartRateReceiver.check(error)
        }
        
        private func heartRate(from characteristic: CBCharacteristic) -> Int? {
            guard let value = characteristic.value else {return nil}
            let bytes = [UInt8](value)

            if bytes[0] & 0x01 == 0 {
                // Heart Rate Value Format is in the 2nd byte
                return Int(bytes[1])
            } else {
                // Heart Rate Value Format is in the 2nd and 3rd bytes
                return (Int(bytes[1]) << 8) + Int(bytes[2])
            }
        }
    }
}

extension String: LocalizedError {
    public var errorDescription: String? {self}
}
