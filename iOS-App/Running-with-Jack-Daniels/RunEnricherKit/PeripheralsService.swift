//
//  PeripheralsService.swift
//  RunEnricherKit
//
//  Created by Jürgen Boiselle on 14.10.21.
//

import Foundation
import CoreBluetooth
import RunFoundationKit
import RunReceiversKit

public class PeripheralsService: ObservableObject {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    public static var sharedInstance = PeripheralsService()

    /// Use singleton @sharedInstance
    private init() {
        ReceiverService
            .sharedInstance
            .peripheralValues
            .sinkMainStore {self.peripherals.append($0)}
        
        ReceiverService
            .sharedInstance
            .peripheralControl
            .sinkMainStore {
                if case .started = $0 {
                    self.peripherals.removeAll(keepingCapacity: true)
                }
                self.bleControl = $0
            }
    }
    
    // MARK: - Published
    @Published public private(set) var peripherals = [CBPeripheral]()
    @Published public private(set) var bleControl: ReceiverControl = .stopped

    // MARK: - Private
}
