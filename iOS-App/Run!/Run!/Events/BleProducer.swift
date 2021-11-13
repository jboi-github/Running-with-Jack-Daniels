//
//  BleProvider.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import Foundation
import CoreBluetooth

// MARK: - Producer Protocol
protocol BleProducerProtocol {
    static var sharedInstance: BleProducerProtocol {get}

    func start(config: BleProducer.Config, transientFailedPeripheralUuid: UUID?)
    func stop()
    func pause()
    func resume()
}

// MARK: - Producer
class BleProducer: BleProducerProtocol {
    /// Access shared instance of this singleton
    static let sharedInstance: BleProducerProtocol = BleProducer()

    /// Use singleton @sharedInstance
    private init() {}
    
    // MARK: Interface
    struct Config {
        /// Primary peripheral, if defined. This peripheral will be connected in a preferred way.
        let primaryUuid: UUID?
        
        /// Ignored peripherals. If discovered these peripherals are ignored and not connected.
        let ignoredUuids: [UUID]
        
        /// Behaviour definition. If `true` the process stops scanning for further peripherals, after the first one was discovered
        /// If `false`, scanning and connecting continues till the process is stopped.
        let stopScanningAfterFirst: Bool
        
        /// Callback for overall status of BLE.
        let status: (Status) -> Void
        
        /// Callback, whenever a peripheral was discovered or recognized.
        let discoveredPeripheral: ((CBPeripheral) -> Void)?
        
        /// Callback, whenever a peripheral was disconnected
        let failedPeripheral: ((CBPeripheral, Error?) -> Void)?
        
        /// Callback, whenever a new RSSI is detected for a device.
        /// If not `nil`, a timer runs every 5seconds to re-read RSSI.
        /// If `nil` bo timer is started.
        let rssi: ((CBPeripheral, NSNumber) -> Void)?
        
        /// Services and corresponding characteristics to be detected.
        let servicesCharacteristicsMap: [CBUUID : [CBUUID]]
        
        /// Action to be taken, when one charactersitcs is detected.
        /// The actual characteristic is given as parameter. It contains initial data, properties and a link to the corresponding service.
        /// Actions can depend on properties and start writing, reading, polling or getting notified.
        let actions: [CBUUID : (CBCharacteristic) -> Void]
        
        /// Callback, when data is received for a given characteristic.This can be due to reading, polling or getting notified.
        let readers: [CBUUID : (CBPeripheral, Data?) -> Void]
    }
    
    enum Status {
        case started, stopped, paused, resumed, nonRecoverableError(Error), notAuthorized
        case error(CBPeripheral, Error)
    }

    func start(config: Config, transientFailedPeripheralUuid: UUID? = nil) {
        self.config = config
        
        let pu = transientFailedPeripheralUuid == config.primaryUuid ? nil : config.primaryUuid
        let iu = config.ignoredUuids + [transientFailedPeripheralUuid].compactMap {$0}
        
        centralManagerDelegate = CentralManagerDelegate(
            status: config.status,
            stopScanningAfterFirst: config.stopScanningAfterFirst,
            discoveredPeripheral: discoveredPeripheral,
            failedPeripheral: failedPeripheral,
            rssi: config.rssi,
            primaryUuid: pu,
            ignoredUuids: iu,
            serviceUuids: config.servicesCharacteristicsMap.keys.map {$0})
        
        peripheralDelegate = PeripheralDelegate(
            characteristicUuids: config.servicesCharacteristicsMap,
            actions: config.actions,
            readers: config.readers,
            rssi: config.rssi)
        
        if config.rssi != nil {
            rssiTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) {
                log($0.fireDate)
                self.peripherals.forEach {$0.readRSSI()}
            }
        }
        
        _start()
        config.status([.denied, .restricted].contains(CBCentralManager.authorization) ?
                .notAuthorized : .started)
    }
    
    func stop() {
        _stop()
        config?.status(.stopped)
    }
    
    func pause() {
        _stop()
        config?.status(.paused)
    }
    
    func resume() {
        _start()
        config?.status(.resumed)
    }

    // MARK: Private
    private var config: Config?
    
    private var centralManagerDelegate: CBCentralManagerDelegate?
    private var peripheralDelegate: CBPeripheralDelegate?
    private var rssiTimer: Timer?
    
    private var centralManager: CBCentralManager?
    private var peripherals = Set<CBPeripheral>()
    
    private func _start() {
        centralManager = CBCentralManager(
            delegate: centralManagerDelegate,
            queue: .global(qos: .userInitiated))
    }
    
    private func _stop() {
        guard let centralManager = centralManager else {return}
        if centralManager.isScanning {centralManager.stopScan()}
        peripherals.forEach {
            centralManager.cancelPeripheralConnection($0)
        }
        peripherals.removeAll()
    }
    
    private func discoveredPeripheral(_ peripheral: CBPeripheral) {
        peripheral.delegate = peripheralDelegate
        peripherals.insert(peripheral)
        config?.discoveredPeripheral?(peripheral)
        
        if config?.rssi != nil {peripheral.readRSSI()}
    }

    private func failedPeripheral(_ peripheral: CBPeripheral, _ error: Error?) {
        peripherals.remove(peripheral)
        config?.failedPeripheral?(peripheral, error)
        
        // If no more peripherals are discovered and central manager is not currently scanning, restart it.
        if peripherals.isEmpty && centralManager?.isScanning ?? false {
            // Ignore the failed peripheral in this scan.
            stop()
            DispatchQueue
                .global(qos: .userInteractive)
                .asyncAfter(deadline: .now() + 10) { [self] in
                    if let config = config {
                        start(config: config, transientFailedPeripheralUuid: peripheral.identifier)
                    }
                }
        }
        
        if let error = error {config?.status(.error(peripheral, error))}
    }
}

// MARK: - Central Manager Delegate
private class CentralManagerDelegate : NSObject, CBCentralManagerDelegate {
    fileprivate init(
        status: @escaping (BleProducer.Status) -> Void,
        stopScanningAfterFirst: Bool,
        discoveredPeripheral: @escaping (CBPeripheral) -> Void,
        failedPeripheral: @escaping (CBPeripheral, Error?) -> Void,
        rssi: ((CBPeripheral, NSNumber) -> Void)?,
        primaryUuid: UUID?, ignoredUuids: [UUID], serviceUuids: [CBUUID])
    {
        self.status = status
        self.stopScanningAfterFirst = stopScanningAfterFirst
        self.discoveredPeripheral = discoveredPeripheral
        self.failedPeripheral = failedPeripheral
        self.rssi = rssi
        self.primaryUuid = primaryUuid
        self.ignoredUuids = ignoredUuids
        self.serviceUuids = serviceUuids
    }
    
    /// Overall status of the BLE
    private let status: (BleProducer.Status) -> Void
    private let stopScanningAfterFirst: Bool // Should be true by default

    ///  Events along peripherals
    private let discoveredPeripheral: (CBPeripheral) -> Void
    private let failedPeripheral: (CBPeripheral, Error?) -> Void
    private let rssi: ((CBPeripheral, NSNumber) -> Void)?
    
    /// Uuid's to look for or ignore
    private let primaryUuid: UUID?
    private let ignoredUuids: [UUID]
    private let serviceUuids: [CBUUID]

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            log("unknown")
        case .resetting:
            log("resetting")
        case .unsupported:
            status(.nonRecoverableError("unsupported"))
        case .unauthorized:
            status(.notAuthorized)
        case .poweredOff:
            log("powered off")
        case .poweredOn:
            log("powered on. Connecting...")
            discover(central)
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
        log(peripheral.name ?? "no-name", RSSI, advertisementData.map {"\($0.key): \($0.value)"})
        discoveredPeripheral(peripheral)
        rssi?(peripheral, RSSI)
        
        guard !ignoredUuids.contains(peripheral.identifier) else {return}
        
        central.connect(peripheral)
        if stopScanningAfterFirst {central.stopScan()}
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log(peripheral.name ?? "no-name")
        peripheral.discoverServices(serviceUuids)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?)
    {
        log(peripheral.name ?? "no-name")
        if !check(error) {failedPeripheral(peripheral, error)}
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?)
    {
        log(peripheral.name ?? "no-name")
        if !check(error) {failedPeripheral(peripheral, error)}
    }
    
    private func discover(_ central: CBCentralManager) {
        func connect(_ peripheral: CBPeripheral) {
            discoveredPeripheral(peripheral)
            
            central.connect(peripheral)
            if stopScanningAfterFirst {central.stopScan()}
        }
        
        // Try to re-connect primary peripheral
        if let primaryUuid = primaryUuid,
           let peripheral = central.retrievePeripherals(withIdentifiers: [primaryUuid]).first
        {
            log("re-connect using primary")
            connect(peripheral)
            if stopScanningAfterFirst {return}
        }
        
        // Try to connect to any device already connected with the appropriate service
        if let peripheral = central
            .retrieveConnectedPeripherals(withServices: serviceUuids)
            .first
        {
            log("re-connect using already connected peripheral with expected service")
            connect(peripheral)
            if stopScanningAfterFirst {return}        }

        // Scan for new devices.
        log("Initiate scanning...")
        central.scanForPeripherals(withServices: serviceUuids)
    }
}

// MARK: - Peripheral Delegate
private class PeripheralDelegate: NSObject, CBPeripheralDelegate {
    fileprivate init(
        characteristicUuids: [CBUUID : [CBUUID]],
        actions: [CBUUID : (CBCharacteristic) -> Void],
        readers: [CBUUID : (CBPeripheral, Data?) -> Void],
        rssi: ((CBPeripheral, NSNumber) -> Void)?)
    {
        self.characteristicUuids = characteristicUuids
        self.actions = actions
        self.readers = readers
        self.rssi = rssi
    }
    
    private let characteristicUuids: [CBUUID: [CBUUID]]
    private let actions: [CBUUID: (CBCharacteristic) -> Void]
    private let readers: [CBUUID: (CBPeripheral, Data?) -> Void]
    private let rssi: ((CBPeripheral, NSNumber) -> Void)?
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        log(peripheral.name ?? "no-name")
        guard check(error) else {return}
        
        peripheral.services?.forEach {
            if let characteristicUuids = characteristicUuids[$0.uuid] {
                peripheral.discoverCharacteristics(characteristicUuids, for: $0)
            }
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?)
    {
        log(peripheral.name ?? "no-name")
        guard check(error) else {return}

        service.characteristics?.forEach {actions[$0.uuid]?($0)}
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?)
    {
        log(peripheral.name ?? "no-name")
        guard check(error) else {return}

        readers[characteristic.uuid]?(peripheral, characteristic.value)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        log(peripheral.name ?? "no-name")
        guard check(error) else {return}

        rssi?(peripheral, RSSI)
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?)
    {
        log(peripheral.name ?? "no-name")
        guard check(error) else {return}
    }
}
