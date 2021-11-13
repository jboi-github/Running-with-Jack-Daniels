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
        ReceiverService.sharedInstance.heartrateControl.sinkMainStore {self.bleControl = $0}
        ReceiverService.sharedInstance.locationControl.sinkMainStore {self.gpsControl = $0}
        ReceiverService.sharedInstance.motionControl.sinkMainStore {self.aclControl = $0}
    }
    
    // MARK: - Published
    @Published public private(set) var asOf: Date = .distantPast
    @Published public private(set) var heartrateBpm: Int = 0
    @Published public private(set) var batteryLevel: Double = .nan
    @Published public private(set) var paceSecPerKm: TimeInterval = .nan
    @Published public private(set) var activity: Activity = .none

    @Published public private(set) var bleControl: ReceiverControl = .stopped
    @Published public private(set) var gpsControl: ReceiverControl = .stopped
    @Published public private(set) var aclControl: ReceiverControl = .stopped

    func newCurrent(_ segment: SegmentsService.Segment) {
        DispatchQueue.main.async { [self] in
            asOf = segment.range.lowerBound
            heartrateBpm = segment.heartrate?.heartrate ?? 0
            batteryLevel = segment.heartrate?.batteryLevel ?? .nan
            paceSecPerKm = 1000 / (segment.speed?.speedMperSec ?? .nan)
            activity = Activity.from(segment.motion)
        }
    }
    
    // MARK: - Private
}
