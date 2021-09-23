//
//  BleScannerModel.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 21.09.21.
//

import Foundation
import CoreBluetooth

class BleScannerModel: ObservableObject {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    static let sharedInstance = BleScannerModel()

    /// Use singleton @sharedInstance
    private init() {}

    // MARK: - Published
    
    @Published private(set) var peripherals = [UUID: Peripheral]()
    @Published private(set) var primaryPeripheral =
        UUID(uuidString: UserDefaults.standard.string(forKey: BlePrimaryUuidKey) ?? "") ?? UUID()

    struct Peripheral: Identifiable {
        var id: UUID {peripheral.identifier}
        fileprivate let peripheral: CBPeripheral
        var name: String // Might be chaged by peripheral
        var ignore: Bool // Might be changed by user
        var available: Bool // Changes, when device is connected
        var rssi: Double // Re-read every minute
    }
    
    func start() {
        log()
        peripherals.removeAll()
        applyPrimary()
        applyIgnores()
        centralManager = CBCentralManager(
            delegate: centralManagerDelegate,
            queue: serialDispatchQueue)
    }
    
    func stop() {
        log()
        savePrimary()
        saveIgnores()
        if let centralManager = centralManager, centralManager.isScanning {centralManager.stopScan()}
        peripherals.values.forEach {centralManager?.cancelPeripheralConnection($0.peripheral)}
    }
    
    func setPrimary(_ uuid: UUID) {
        primaryPeripheral = uuid
        savePrimary()
    }
    
    func setIgnore(_ uuid: UUID, ignore: Bool) {
        peripherals[uuid]?.ignore = ignore
        saveIgnores()
    }

    // MARK: - Private

    static let BlePrimaryUuidKey = "BlePrimaryUuidKey"
    static let BleIgnoredUuidsKey = "BleIgnoredUuidsKey"

    private var centralManager: CBCentralManager?
    private let centralManagerDelegate = CentralManagerDelegate()
    private let centralPeripheralDelegate = PeripheralDelegate()
    
    private func applyPrimary() {
        if let uuidString = UserDefaults.standard.string(forKey: BleScannerModel.BlePrimaryUuidKey),
           let uuid = UUID(uuidString: uuidString)
        {
            primaryPeripheral = uuid
        } else {
            if let uuid = peripherals.first?.key {
                primaryPeripheral = uuid
                savePrimary()
            }
        }
    }

    private func savePrimary() {
        UserDefaults.standard.set(primaryPeripheral.uuidString, forKey: BleScannerModel.BlePrimaryUuidKey)
        log(UserDefaults.standard.string(forKey: BleScannerModel.BlePrimaryUuidKey) ?? "-")
    }
    
    private func applyIgnores() {
        guard let ignores = UserDefaults
                .standard
                .array(forKey: BleScannerModel.BleIgnoredUuidsKey)
        else {return}
        
        ignores
            .compactMap {
                if let uuidString = $0 as? String {return UUID(uuidString: uuidString)}
                return nil
            }
            .forEach {peripherals[$0]?.ignore = true}
    }

    private func saveIgnores() {
        UserDefaults.standard.set(
            peripherals.values.filter {$0.ignore}.map {$0.id.uuidString},
            forKey: BleScannerModel.BleIgnoredUuidsKey)
        log(UserDefaults.standard.array(forKey: BleScannerModel.BleIgnoredUuidsKey) as? [String] ?? [])
    }

    private class CentralManagerDelegate: NSObject, CBCentralManagerDelegate {
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
            
            peripheral.delegate = BleScannerModel.sharedInstance.centralPeripheralDelegate
            DispatchQueue.main.async {
                BleScannerModel.sharedInstance.peripherals[peripheral.identifier] = Peripheral(
                    peripheral: peripheral,
                    name: peripheral.name ?? "no-name",
                    ignore: false,
                    available: false,
                    rssi: Double(truncating: RSSI))
                BleScannerModel.sharedInstance.applyIgnores()
                BleScannerModel.sharedInstance.applyPrimary()
            }
            
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
            _ = check(error)
            DispatchQueue.main.async {
                BleScannerModel.sharedInstance.peripherals[peripheral.identifier]?.available = false
            }
        }
        
        func centralManager(
            _ central: CBCentralManager,
            didFailToConnect peripheral: CBPeripheral,
            error: Error?)
        {
            log(peripheral.name ?? "no-name")
            _ = check(error)
            DispatchQueue.main.async {
                BleScannerModel.sharedInstance.peripherals[peripheral.identifier]?.available = false
            }
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
            _ = check(error)

            guard let services = peripheral.services else {
                log("no services discovered")
                return
            }
            
            services.forEach {
                peripheral.discoverCharacteristics([BleHeartrateReceiver.heartRateCharacteristicCBUUID], for: $0)
            }
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didDiscoverIncludedServicesFor service: CBService,
            error: Error?)
        {
            log(peripheral.name ?? "no-name")
            _ = check(error)
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didDiscoverCharacteristicsFor service: CBService,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", service.uuid)
            _ = check(error)

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

            let isAvailable = service
                .characteristics?
                .contains {
                    $0.uuid == BleHeartrateReceiver.heartRateCharacteristicCBUUID && $0.properties.contains(.notify)
                } ?? false
            DispatchQueue.main.async {
                BleScannerModel.sharedInstance.peripherals[peripheral.identifier]?.available = isAvailable
            }
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didDiscoverDescriptorsFor characteristic: CBCharacteristic,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", characteristic.description)
            characteristic.descriptors?.forEach {log($0)}
            _ = check(error)
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didUpdateValueFor characteristic: CBCharacteristic,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", characteristic.uuid)
            _ = check(error)
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didUpdateValueFor descriptor: CBDescriptor,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", descriptor)
            _ = check(error)
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didWriteValueFor characteristic: CBCharacteristic,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", characteristic.uuid)
            _ = check(error)
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didWriteValueFor descriptor: CBDescriptor,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", descriptor)
            _ = check(error)
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
            _ = check(error)
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didReadRSSI RSSI: NSNumber,
            error: Error?)
        {
            log(peripheral.name ?? "no-name", RSSI)
            guard check(error) else {return}
            
            DispatchQueue.main.async {
                BleScannerModel.sharedInstance.peripherals[peripheral.identifier]?.rssi = Double(truncating: RSSI)
            }
        }
        
        func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
            log(peripheral.name ?? "no-name")
            DispatchQueue.main.async {
                BleScannerModel
                    .sharedInstance
                    .peripherals[peripheral.identifier]?
                    .name = peripheral.name ?? "no-name"
            }
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didModifyServices invalidatedServices: [CBService])
        {
            log(peripheral.name ?? "no-name", invalidatedServices.map {$0.uuid})
            
            let invalidationFatal = invalidatedServices
                .contains {$0.uuid == BleHeartrateReceiver.heartRateServiceCBUUID}
            if invalidationFatal {
                DispatchQueue.main.async {
                    BleScannerModel.sharedInstance.peripherals[peripheral.identifier]?.available = false
                }
            }
        }
        
        func peripheral(
            _ peripheral: CBPeripheral,
            didOpen channel: CBL2CAPChannel?,
            error: Error?)
        {
            log(peripheral.name ?? "no-name")
            _ = check(error)
        }
    }
}
