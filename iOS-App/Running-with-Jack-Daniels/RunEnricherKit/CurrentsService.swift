//
//  File.swift
//  RunEnricherKit
//
//  Created by Jürgen Boiselle on 05.10.21.
//

import Foundation
import Combine
import RunReceiversKit

public class CurrentsService: ObservableObject {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    public static var sharedInstance = CurrentsService()

    /// Use singleton @sharedInstance
    private init() {
        ReceiverService
            .sharedInstance
            .heartrateValues
            .map {$0.heartrate}
            .assign(to: &$heartrateBpm)
        
        ReceiverService
            .sharedInstance
            .locationValues
            .map {self.isActive ? (1000.0 / $0.speed) : .nan}
            .assign(to: &$paceSecPerKm)
        
        ReceiverService
            .sharedInstance
            .motionValues
            .map {($0.walking || $0.running || $0.cycling) && !$0.stationary}
            .assign(to: &$isActive)
        
        ReceiverService.sharedInstance.heartrateControl.assign(to: &$bleControl)
        ReceiverService.sharedInstance.locationControl.assign(to: &$gpsControl)
        ReceiverService.sharedInstance.motionControl.assign(to: &$aclControl)
    }
    
    // MARK: - Published
    @Published public private(set) var heartrateBpm: Int = 0
    @Published public private(set) var paceSecPerKm: TimeInterval = .nan
    @Published public private(set) var isActive: Bool = false

    @Published public private(set) var bleControl: ReceiverControl = .stopped
    @Published public private(set) var gpsControl: ReceiverControl = .stopped
    @Published public private(set) var aclControl: ReceiverControl = .stopped

    // MARK: - Private
}
