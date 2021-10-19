//
//  File.swift
//  RunEnricherKit
//
//  Created by Jürgen Boiselle on 05.10.21.
//

import Foundation
import Combine
import CoreMotion
import RunFoundationKit
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
            .sinkMainStore {self.heartrateBpm = $0.heartrate}
        
        ReceiverService
            .sharedInstance
            .locationValues
            .sinkMainStore {self.paceSecPerKm = self.activity.isActive ? (1000.0 / $0.speed) : .nan}
        
        ReceiverService
            .sharedInstance
            .motionValues
            .sinkMainStore {self.activity = $0}
        
        ReceiverService.sharedInstance.heartrateControl.sinkMainStore {self.bleControl = $0}
        ReceiverService.sharedInstance.locationControl.sinkMainStore {self.gpsControl = $0}
        ReceiverService.sharedInstance.motionControl.sinkMainStore {self.aclControl = $0}
    }
    
    // MARK: - Published
    @Published public private(set) var heartrateBpm: Int = 0
    @Published public private(set) var paceSecPerKm: TimeInterval = .nan
    @Published public private(set) var activity: CMMotionActivity = CMMotionActivity()

    @Published public private(set) var bleControl: ReceiverControl = .stopped
    @Published public private(set) var gpsControl: ReceiverControl = .stopped
    @Published public private(set) var aclControl: ReceiverControl = .stopped

    // MARK: - Private
}
