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
            .sink {self.peripherals.append($0)}
            .store(in: &sinks)
        
        ReceiverService
            .sharedInstance
            .peripheralControl
            .sink {
                if case .started = $0 {
                    self.peripherals.removeAll(keepingCapacity: true)
                }
            }
            .store(in: &sinks)
    }
    
    // MARK: - Published
    @Published public private(set) var peripherals = [CBPeripheral]()

    // MARK: - Private
}
