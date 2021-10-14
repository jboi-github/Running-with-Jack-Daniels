//
//  MiBandConnector.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 18.06.21.
//

import Foundation
import CoreBluetooth
import RunFoundationKit

private let BlePrimaryUuidKey = "BlePrimaryUuidKey"
private let BleIgnoredUuidsKey = "BleIgnoredUuidsKey"

public struct Heartrate {
    public let timestamp: Date
    public let heartrate: Int
}

class BleHeartrateReceiver: ReceiverProtocol {
    typealias Value = Heartrate

    private var centralManager: CBCentralManager?
    private var centralManagerDelegate: CentralManagerDelegate?

    private let value: (Heartrate) -> Void
    private let failed: (Error) -> Void

    required init(
        value: @escaping (Heartrate) -> Void,
        failed: @escaping (Error) -> Void)
    {
        self.value = value
        self.failed = failed
    }
    
    func start() {
        var primaryUuid: UUID? {
            if let primaryString = UserDefaults.standard.string(forKey: BlePrimaryUuidKey) {
                return UUID(uuidString: primaryString)
            } else {
                return nil
            }
        }
        
        var ignoredUuids: [UUID]? {
            if let ignoredStrings = UserDefaults.standard.stringArray(forKey: BleIgnoredUuidsKey) {
                return ignoredStrings.compactMap {UUID(uuidString: $0)}
            } else {
                return nil
            }
        }
        
        (centralManager, centralManagerDelegate) = CentralManagerDelegate.configure(
            value: value,
            failed: failed,
            discovered: {log($0)},
            connectStrategy: .first(primaryUuid: primaryUuid, ignoredUuids: ignoredUuids ?? []),
            serviceUuids: [CBUUID(string: "0x180D"), CBUUID(string: "0xFEE1"), CBUUID(string: "0xFEE0")],
            characteristicUuids: [CBUUID(string: "2A37")])
    }
    
    func stop() {
        guard let centralManager = centralManager else {return}
        if centralManager.isScanning {centralManager.stopScan()}
        centralManagerDelegate?.cancelAll(centralManager)
    }
    
    static func isDuplicate(lhs: Heartrate, rhs: Heartrate) -> Bool {lhs.heartrate == rhs.heartrate}
}

class BlePeripheralReceiver: ReceiverProtocol {
    typealias Value = CBPeripheral

    private var centralManager: CBCentralManager?
    private var centralManagerDelegate: CentralManagerDelegate?

    private let value: (CBPeripheral) -> Void
    private let failed: (Error) -> Void

    required init(value: @escaping (CBPeripheral) -> Void, failed: @escaping (Error) -> Void) {
        self.value = value
        self.failed = failed
    }
    
    func start() {
        (centralManager, centralManagerDelegate) = CentralManagerDelegate.configure(
            value: {log($0)},
            failed: failed,
            discovered: value,
            connectStrategy: .all(readRSSI: 5),
            serviceUuids: [CBUUID(string: "0x180D"), CBUUID(string: "0xFEE1"), CBUUID(string: "0xFEE0")],
            characteristicUuids: [CBUUID(string: "2A37")])
    }
    
    func stop() {
        guard let centralManager = centralManager else {return}
        if centralManager.isScanning {centralManager.stopScan()}
        centralManagerDelegate?.cancelAll(centralManager)
    }
    
    static func isDuplicate(lhs: CBPeripheral, rhs: CBPeripheral) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

private class CentralManagerDelegate : NSObject, CBCentralManagerDelegate {
    enum ConnectStrategy {
        case first(primaryUuid: UUID?, ignoredUuids: [UUID])
        case all(readRSSI: TimeInterval)
    }
    
    static func configure(
        value: @escaping (Heartrate) -> Void,
        failed: @escaping (Error) -> Void,
        discovered: @escaping (CBPeripheral) -> Void,
        connectStrategy: ConnectStrategy,
        serviceUuids: [CBUUID]?,
        characteristicUuids: [CBUUID]?)
    -> (CBCentralManager, CentralManagerDelegate)
    {
        let centralManagerDelegate = CentralManagerDelegate(
            value: value,
            failed: failed,
            discovered: discovered,
            connectStrategy: connectStrategy,
            serviceUuids: serviceUuids,
            characteristicUuids: characteristicUuids)
        let centralManager = CBCentralManager(delegate: centralManagerDelegate, queue: serialQueue)
        
        return (centralManager, centralManagerDelegate)
    }
    
    private let value: (Heartrate) -> Void
    private let failed: (Error) -> Void
    private let discovered: (CBPeripheral) -> Void
    private var connectStrategy: ConnectStrategy
    private let serviceUuids: [CBUUID]?
    private let characteristicUuids: [CBUUID]?
    private let peripheralDelegate: PeripheralDelegate

    private var peripherals = Set<CBPeripheral>()

    private init(
        value: @escaping (Heartrate) -> Void,
        failed: @escaping (Error) -> Void,
        discovered: @escaping (CBPeripheral) -> Void,
        connectStrategy: ConnectStrategy,
        serviceUuids: [CBUUID]?,
        characteristicUuids: [CBUUID]?)
    {
        self.value = value
        self.failed = failed
        self.discovered = discovered
        self.connectStrategy = connectStrategy
        self.serviceUuids = serviceUuids
        self.characteristicUuids = characteristicUuids
        peripheralDelegate = PeripheralDelegate(
            value: value,
            failed: failed,
            serviceUuids: serviceUuids,
            characteristicUuids: characteristicUuids)
    }
    
    fileprivate func cancelAll(_ central: CBCentralManager) {
        peripherals.forEach {
            central.cancelPeripheralConnection($0)
        }
        peripherals.removeAll()
    }
    
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
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber)
    {
        log(peripheral.name ?? "no-name", RSSI)
        discovered(peripheral)
        advertisementData.forEach {log($0.key, $0.value)}

        switch connectStrategy {
        case .first(_, let ignoredUuids):
            if ignoredUuids.contains(peripheral.identifier) {return}
            central.stopScan()
        case .all(let readRSSI):
            rssis[peripheral.identifier] = RSSI
            Timer.scheduledTimer(withTimeInterval: readRSSI, repeats: true) { _ in
                serialQueue.async {peripheral.readRSSI()}
            }
        }
        
        connect(central, to: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log()
        peripheral.discoverServices(serviceUuids)
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState: [String : Any]) {log()}
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?)
    {
        log(peripheral.name ?? "no-name")
        if let error = error {
            switch connectStrategy {
            case .first(let primaryUuid, let ignoredUuids):
                connectStrategy = .first(
                    primaryUuid: primaryUuid,
                    ignoredUuids: ignoredUuids + [peripheral.identifier])
            case .all(_):
                break
            }
            failed(error)
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?)
    {
        log(peripheral.name ?? "no-name")
        switch connectStrategy {
        case .first(let primaryUuid, let ignoredUuids):
            connectStrategy = .first(
                primaryUuid: primaryUuid,
                ignoredUuids: ignoredUuids + [peripheral.identifier])
        case .all(_):
            break
        }
        if let error = error {failed(error)}
    }
    
    func centralManager(
        _ central: CBCentralManager,
        connectionEventDidOccur event: CBConnectionEvent,
        for peripheral: CBPeripheral)
    {
        log(peripheral.name ?? "no-name")
        switch event {
        case .peerDisconnected:
            log("peer disconnected")
        case .peerConnected:
            log("peer connected")
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
    
    private func connectByPrio(_ central: CBCentralManager) {
        switch connectStrategy {
        case .first(let primaryUuid, _):
            // Try to re-connect primary peripheral
            if let primaryUuid = primaryUuid,
               let peripheral = central.retrievePeripherals(withIdentifiers: [primaryUuid]).first
            {
                log("re-connect using primary")
                connect(central, to: peripheral)
                return
            }
            
            // Try to connect to any device already connected with the appropriate service
            if let serviceUuids = serviceUuids,
               let peripheral = central
                .retrieveConnectedPeripherals(withServices: serviceUuids)
                .first
            {
                log("re-connect using already conected peripheral with expected service")
                connect(central, to: peripheral)
                return
            }
        case .all(_):
            break
        }
        
        // Scan for new devices.
        log("Initiate scanning...")
        central.scanForPeripherals(withServices: serviceUuids)
    }
    
    private func connect(_ central: CBCentralManager, to peripheral: CBPeripheral) {
        peripheral.delegate = peripheralDelegate
        peripherals.insert(peripheral)
        central.connect(peripheral)
    }
}

private class PeripheralDelegate: NSObject, CBPeripheralDelegate {
    private let value: (Heartrate) -> Void
    private let failed: (Error) -> Void
    private let serviceUuids: Set<CBUUID>
    private let characteristicUuids: [CBUUID]?

    init(
        value: @escaping (Heartrate) -> Void,
        failed: @escaping (Error) -> Void,
        serviceUuids: [CBUUID]?,
        characteristicUuids: [CBUUID]?)
    {
        self.value = value
        self.failed = failed
        self.serviceUuids = Set<CBUUID>(serviceUuids ?? [])
        self.characteristicUuids = characteristicUuids
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        log(peripheral.name ?? "no-name")
        
        if let error = error {failed(error)}
        guard let services = peripheral.services else {
            log("no services discovered")
            return
        }
        
        services.forEach {peripheral.discoverCharacteristics(characteristicUuids, for: $0)}
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverIncludedServicesFor service: CBService,
        error: Error?)
    {
        log(peripheral.name ?? "no-name")
        if let error = error {failed(error)}
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?)
    {
        log(peripheral.name ?? "no-name", service.uuid)
        if let error = error {failed(error)}

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
            .first(where: {
                (characteristicUuids?.contains($0.uuid) ?? true) && $0.properties.contains(.notify)
            })
        {
            peripheral.setNotifyValue(true, for: charateristic)
            self.peripheral(peripheral, didUpdateValueFor: charateristic, error: nil)
        } else {
            failed("no notification property for characteristics")
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
        error: Error?)
    {
        log(peripheral.name ?? "no-name", characteristic.description)
        characteristic.descriptors?.forEach {log($0)}
        if let error = error {failed(error)}
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?)
    {
        log(peripheral.name ?? "no-name", characteristic.uuid)
        if let error = error {failed(error)}
        if let heartrate = characteristic.asInt {
            self.value(Heartrate(timestamp: Date(), heartrate: heartrate))
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor descriptor: CBDescriptor,
        error: Error?)
    {
        log(peripheral.name ?? "no-name", descriptor)
        if let error = error {failed(error)}
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?)
    {
        log(peripheral.name ?? "no-name", characteristic.uuid)
        if let error = error {failed(error)}
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor descriptor: CBDescriptor,
        error: Error?)
    {
        log(peripheral.name ?? "no-name", descriptor)
        if let error = error {failed(error)}
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
        if let error = error {failed(error)}
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didReadRSSI RSSI: NSNumber,
        error: Error?)
    {
        log(peripheral.name ?? "no-name", RSSI)
        if let error = error {failed(error)}
        rssis[peripheral.identifier] = RSSI
    }
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        log(peripheral.name ?? "no-name")
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didModifyServices invalidatedServices: [CBService])
    {
        log(peripheral.name ?? "no-name", invalidatedServices.map {$0.uuid})
        
        guard serviceUuids.intersection(invalidatedServices.map {$0.uuid}).isEmpty else {
            failed("mandatory service invalidated")
            return
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didOpen channel: CBL2CAPChannel?,
        error: Error?)
    {
        log(peripheral.name ?? "no-name")
        if let error = error {failed(error)}
    }
}

extension CBCharacteristic {
    var asInt: Int? {
        guard let value = value else {return nil}
        let bytes = [UInt8](value)

        if bytes[0] & 0x01 == 0 {
            // Value is in the 2nd byte
            return Int(bytes[1])
        } else {
            // Value is in the 2nd and 3rd bytes
            return (Int(bytes[1]) << 8) + Int(bytes[2])
        }
    }
}

private var rssis = [UUID:NSNumber]()

extension CBPeripheral {
    /// Latest, read RSSI. A new value can be retrieved by calling `readRSSI`.
    var rssi: NSNumber? {rssis[identifier]}
}
