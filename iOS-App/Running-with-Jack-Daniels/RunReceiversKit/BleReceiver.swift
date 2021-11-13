//
//  MiBandConnector.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 18.06.21.
//

import Foundation
import CoreBluetooth
import RunFoundationKit

public let BlePrimaryUuidKey = "BlePrimaryUuidKey"
public let BleIgnoredUuidsKey = "BleIgnoredUuidsKey"

public struct Heartrate {
    public let timestamp: Date
    public let heartrate: Int
    
    // Optional values, if supported by the device and contained in this notification
    public let skinIsContacted: Bool?
    public let energyExpended: Int?
    public let rr: [TimeInterval]?
    
    // Offline changed based values
    public let batteryLevel: Double?
    public let bodySensorLocation: BodySensorLocation?
    
    public enum BodySensorLocation: UInt8 {
        case Other, Chest, Wrist, Finger, Hand, EarLobe, Foot
    }
}

private var primaryUuid: UUID? {
    if let primaryString = UserDefaults.standard.string(forKey: BlePrimaryUuidKey) {
        return UUID(uuidString: primaryString)
    } else {
        return nil
    }
}

private var ignoredUuids: [UUID]? {
    if let ignoredStrings = UserDefaults.standard.stringArray(forKey: BleIgnoredUuidsKey) {
        return ignoredStrings.compactMap {UUID(uuidString: $0)}
    } else {
        return nil
    }
}

class BleHeartrateReceiver: ReceiverProtocol {
    typealias Value = Heartrate

    private var centralManager: CBCentralManager?
    private var centralManagerDelegate: CentralManagerDelegate?

    private let value: (Heartrate) -> Void
    private let failed: (Error) -> Void

    private var timer: Timer? = nil

    required init(
        value: @escaping (Heartrate) -> Void,
        failed: @escaping (Error) -> Void)
    {
        self.value = value
        self.failed = failed
    }
    
    func start() {
        (centralManager, centralManagerDelegate) = CentralManagerDelegate.configure(
            value: value,
            failed: failed,
            discovered: {log($0)},
            connectStrategy: .first(primaryUuid: primaryUuid, ignoredUuids: ignoredUuids ?? []),
            serviceUuids: [CBUUID(string: "180D"), CBUUID(string: "180F")],
            characteristicUuids: [
                CBUUID(string: "2A37"), // Heartrate measurement
                CBUUID(string: "2A38"), // Body Sensor Location
                CBUUID(string: "2A39"), // Heart rate control point (reset energy expedition)
                CBUUID(string: "2A19") // Battery Level
            ])
        
        // Read battery level every 5 minutes
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) {
            log($0.fireDate)
            self.centralManagerDelegate?.readBatteryLevelAll()
        }
    }
    
    func stop() {
        guard let centralManager = centralManager else {return}
        if centralManager.isScanning {centralManager.stopScan()}
        timer?.invalidate()
        timer = nil
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
    
    private var timer: Timer? = nil

    required init(value: @escaping (CBPeripheral) -> Void, failed: @escaping (Error) -> Void) {
        self.value = value
        self.failed = failed
    }
    
    func start() {
        (centralManager, centralManagerDelegate) = CentralManagerDelegate.configure(
            value: {log($0)},
            failed: failed,
            discovered: value,
            connectStrategy: .all(
                primaryUuid: primaryUuid,
                ignoredUuids: ignoredUuids ?? []),
            serviceUuids: [CBUUID(string: "0x180D"), CBUUID(string: "180F")],
            characteristicUuids: [CBUUID(string: "2A37"), CBUUID(string: "2A19")])
        
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) {
            log($0.fireDate)
            self.centralManagerDelegate?.readRssiAll()
        }
    }
    
    func stop() {
        guard let centralManager = centralManager else {return}
        if centralManager.isScanning {centralManager.stopScan()}
        timer?.invalidate()
        timer = nil
        centralManagerDelegate?.cancelAll(centralManager)
    }
    
    static func isDuplicate(lhs: CBPeripheral, rhs: CBPeripheral) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

private class CentralManagerDelegate : NSObject, CBCentralManagerDelegate {
    enum ConnectStrategy {
        case first(primaryUuid: UUID?, ignoredUuids: [UUID])
        case all(primaryUuid: UUID?, ignoredUuids: [UUID])
        
        var willNotify: Bool {
            switch self {
            case .first(_,_):
                return true
            case .all(_,_):
                return false
            }
        }
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
            characteristicUuids: characteristicUuids,
            notifyOnUpdateValue: connectStrategy.willNotify)
    }
    
    fileprivate func cancelAll(_ central: CBCentralManager) {
        peripherals.forEach {
            central.cancelPeripheralConnection($0)
        }
        peripherals.removeAll()
    }
    
    fileprivate func readRssiAll() {
        peripherals.forEach {
            log($0.name ?? "no-name")
            $0.readRSSI()
        }
    }
    
    // Battery Level
    fileprivate func readBatteryLevelAll() {
        peripherals.forEach {
            $0.execIfAvailable(
                service: CBUUID(string: "180F"),
                characteristic: CBUUID(string: "2A19"),
                property: .read)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            log("unknown")
        case .resetting:
            log("resetting")
        case .unsupported:
            failed("unsupported")
        case .unauthorized:
            failed("unauthorized")
        case .poweredOff:
            log("powered off")
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
            connect(central, to: peripheral)
        case .all(_, _):
            rssis[peripheral.identifier] = RSSI
        }
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
            case .all(_, _):
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
        case .all(_, _):
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
            
            // Scan for new devices.
            log("Initiate scanning...")
            central.scanForPeripherals(withServices: serviceUuids)

        case .all(let primaryUuid, let ignoredUuids):
            // Try to re-connect primary peripheral
            central
                .retrievePeripherals(
                    withIdentifiers: ignoredUuids + (primaryUuid != nil ? [primaryUuid!] : []))
                .forEach {
                    log("known UUID", $0.name ?? "no-name")
                    discovered($0)
                    connect(central, to: $0)
                }
            
            // Try to connect to any device already connected with the appropriate service
            if let serviceUuids = serviceUuids {
                central
                 .retrieveConnectedPeripherals(withServices: serviceUuids)
                 .forEach {
                     log("already connected with expected service", $0.name ?? "no-name")
                     discovered($0)
                     connect(central, to: $0)
                 }
            }
            
            // Scan for new devices.
            log("Initiate scanning...")
            central.scanForPeripherals(withServices: serviceUuids)
        }
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
    private let notifyOnUpdateValue: Bool

    init(
        value: @escaping (Heartrate) -> Void,
        failed: @escaping (Error) -> Void,
        serviceUuids: [CBUUID]?,
        characteristicUuids: [CBUUID]?,
        notifyOnUpdateValue: Bool)
    {
        self.value = value
        self.failed = failed
        self.serviceUuids = Set<CBUUID>(serviceUuids ?? [])
        self.characteristicUuids = characteristicUuids
        self.notifyOnUpdateValue = notifyOnUpdateValue
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
        
        // Read first time battery level
        peripheral.execIfAvailable(
            service: CBUUID(string: "180F"),
            characteristic: CBUUID(string: "2A19"),
            property: .read)

        // Are we looking for data or just for scanning peripherals?
        guard notifyOnUpdateValue else {return}
        
        // Let's finally get notifications from the first peripheral with
        // HR service, HR characteristics and notification property

        // Heart rate service - notify about heart rate measures
        if !peripheral.execIfAvailable(
            service: CBUUID(string: "180D"),
            characteristic: CBUUID(string: "2A37"),
            property: .notify)
        {
            // Heart rate measures are mandatory
            failed("Cannot notify about heart rate measures")
        }

        // Heart rate service - read Body Sensor Location
        peripheral.execIfAvailable(
            service: CBUUID(string: "180D"),
            characteristic: CBUUID(string: "2A38"),
            property: .read)

        // Heart rate service - write control point
        peripheral.execIfAvailable(
            service: CBUUID(string: "180D"),
            characteristic: CBUUID(string: "2A39"),
            property: .writeWithoutResponse,
            data: Data([UInt8(0x01)]))
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
        log(peripheral.name ?? "no-name", characteristic.uuid, peripheral.state.rawValue)
        if let error = error {failed(error)}

        if characteristic.uuid == CBUUID(string: "2A37") {
            // Heartrate measurement
            if let heartrate = characteristic.asHeartrate() {value(heartrate)}
            log()
        } else if characteristic.uuid == CBUUID(string: "2A38") {
            // Body Sensor Location
            if let value = characteristic.value {
                bodySensorLocations[peripheral.identifier] = Heartrate
                    .BodySensorLocation(rawValue: [UInt8](value)[0])
            }
            log((bodySensorLocations[peripheral.identifier] ?? .Other).rawValue)
        } else if characteristic.uuid == CBUUID(string: "2A19") {
            // Battery Level
            if let value = characteristic.value {
                batteryLevels[peripheral.identifier] = Double([UInt8](value)[0]) / 100
            }
            log("\(batteryLevels[peripheral.identifier] ?? .nan)")
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
    func asHeartrate(_ timestamp: Date = Date()) -> Heartrate? {
        guard let value = value else {return nil}
        let bytes = [UInt8](value)

        var i: Int = 0
        func uint8() -> Int {
            defer {i += 1}
            return Int(bytes[i])
        }
        func uint16() -> Int {
            defer {i += 2}
            return Int((UInt16(bytes[i+1]) << 8) | UInt16(bytes[i]))
        }

        // Read flags field
        let flags = uint8()
        let hrValueFormatIs16Bit = flags & (0x01 << 0) > 0
        let skinContactIsSupported = flags & (0x01 << 2) > 0
        let energyExpensionIsPresent = flags & (0x01 << 3) > 0
        let rrValuesArePresent = flags & (0x01 << 4) > 0

        // Get hr
        let heartrate = hrValueFormatIs16Bit ? uint16() : uint8()
        
        // Get skin contact if suported
        let skinIsContacted = skinContactIsSupported ? (flags & (0x01 << 1) > 0) : nil

        // Energy expended if present
        let energyExpended = energyExpensionIsPresent ? uint16() : nil
        
        var rr = rrValuesArePresent ? [TimeInterval]() : nil
        while rrValuesArePresent && (i+1 < bytes.count) {
            rr?.append(TimeInterval(uint16()) / 1024)
        }

        return Heartrate(
            timestamp: timestamp,
            heartrate: heartrate,
            skinIsContacted: skinIsContacted,
            energyExpended: energyExpended,
            rr: rr,
            batteryLevel: service?.peripheral?.batteryLevel,
            bodySensorLocation: service?.peripheral?.bodySensorLocation)
    }
}

private var rssis = [UUID:NSNumber]()
private var batteryLevels = [UUID:Double]()
private var bodySensorLocations = [UUID:Heartrate.BodySensorLocation]()

extension CBPeripheral {
    /// Latest, read RSSI. A new value can be retrieved by calling `readRSSI`.
    public var rssi: NSNumber? {rssis[identifier]}
    
    /// Latest, read battery level. The value is re-read every 5 minutes.
    public var batteryLevel: Double? {batteryLevels[identifier]}
    
    /// Latest, read body location. A new value is read when connecting.
    public var bodySensorLocation: Heartrate.BodySensorLocation? {bodySensorLocations[identifier]}
    
    /// Ask, if the peripheral claims to be able to handle a given property-action with the given service and characteristic.
    /// if claimed, execute the corresponding action.
    ///
    /// - Note: This should be called earliest after characteristics were discovered.
    /// - Parameters:
    ///   - service: uuid of requested service.
    ///   - characteristic: uuid of requested characteristic
    ///   - property: requested property. Currently supported: `.read, .writeWithoutResponse, .notify`.
    ///     Results are provided by the corresponding delegate-functions.
    ///   - data: data to write with `property == .writeWithoutResponse`. Must not be `nil` to write. Otherwise ignored.
    /// - Returns: true, if the call was succesful, false if combination of property, characteristic and service was not available.
    @discardableResult public func execIfAvailable(
        service: CBUUID,
        characteristic: CBUUID,
        property: CBCharacteristicProperties,
        data: Data? = nil) -> Bool
    {
        for svc in services ?? [] {
            if svc.uuid != service {continue}
            
            for chr in svc.characteristics ?? [] {
                if chr.uuid != characteristic {continue}
                
                if chr.properties.contains(property) {
                    if property == .notify {
                        setNotifyValue(true, for: chr)
                    } else if property == .read {
                        readValue(for: chr)
                    } else if property == .writeWithoutResponse {
                        writeValue(data!, for: chr, type: .withoutResponse)
                    }
                    return true
                }
            }
        }
        return false
    }
}
