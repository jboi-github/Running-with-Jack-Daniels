//
//  BleScannerModel.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 21.09.21.
//

import Foundation
import CoreBluetooth
import RunFoundationKit
import RunReceiversKit
import RunEnricherKit

class BleScannerModel: ObservableObject {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    static let sharedInstance = BleScannerModel()

    /// Use singleton @sharedInstance
    private init() {
        ReceiverService
            .sharedInstance
            .peripheralValues
            .sinkMainStore { [self] in
                peripherals[$0.identifier] = Peripheral(
                    id: $0.identifier,
                    peripheral: $0,
                    ignore: false)
                applyIgnores()
            }
        
        ReceiverService
            .sharedInstance
            .peripheralControl
            .sinkMainStore {
                if $0 == .started {
                    self.peripherals.removeAll(keepingCapacity: true)
                }
            }
    }

    // MARK: - Published
    
    @Published private(set) var peripherals = [UUID: Peripheral]()
    @Published private(set) var primaryPeripheral =
        UUID(uuidString: UserDefaults.standard.string(forKey: BlePrimaryUuidKey) ?? "") ?? UUID()

    struct Peripheral: Identifiable {
        var id: UUID
        let peripheral: CBPeripheral? // As class might change without further notice
        var ignore: Bool // Might be changed by user
    }
    
    func start() {
        log()
        applyPrimary()
        applyIgnores()
        ReceiverService.sharedInstance.startBleScanner()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            BleScannerModel.sharedInstance.objectWillChange.send()
        }
    }
    
    func stop() {
        log()
        
        timer?.invalidate()
        ReceiverService.sharedInstance.stopBleScanner()
        savePrimary()
        saveIgnores()
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

    private func applyPrimary() {
        if let uuidString = UserDefaults.standard.string(forKey: BlePrimaryUuidKey),
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
        UserDefaults.standard.set(primaryPeripheral.uuidString, forKey: BlePrimaryUuidKey)
        log(UserDefaults.standard.string(forKey: BlePrimaryUuidKey) ?? "-")
    }
    
    private func applyIgnores() {
        guard let ignores = UserDefaults
                .standard
                .array(forKey: BleIgnoredUuidsKey)
        else {return}
        
        ignores
            .forEach {
                guard
                    let uuidString = $0 as? String,
                    let id = UUID(uuidString: uuidString) else {return}
                
                if peripherals[id] != nil {
                    peripherals[id]?.ignore = true
                } else {
                    peripherals[id] = Peripheral(id: id, peripheral: nil, ignore: true)
                }
            }
    }

    private func saveIgnores() {
        UserDefaults.standard.set(
            peripherals.values.filter {$0.ignore}.map {$0.id.uuidString},
            forKey: BleIgnoredUuidsKey)
        log(UserDefaults.standard.array(forKey: BleIgnoredUuidsKey) as? [String] ?? [])
    }
    
    // Timer to get updates when peripheral-class chnages.
    // As class is changed by BLE-System, use polling mechanism.
    private var timer: Timer? = nil
}
