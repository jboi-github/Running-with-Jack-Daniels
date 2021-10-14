//
//  Locations.swift
//  RunEnricherKit
//
//  Created by Jürgen Boiselle on 06.10.21.
//

import Foundation
import CoreLocation
import Combine
import RunFoundationKit
import RunReceiversKit

public class LocationsService: ObservableObject {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    public static var sharedInstance = LocationsService()

    /// Use singleton @sharedInstance
    private init() {
        ReceiverService
            .sharedInstance
            .motionValues
            .map {($0.walking || $0.running || $0.cycling) && !$0.stationary}
            .assign(to: &$isActive)

        ReceiverService
            .sharedInstance
            .locationValues
            .filter {_ in self.isActive}
            .map {self.path + [$0]}
            .assign(to: &$path)
        
        ReceiverService.sharedInstance.heartrateControl
            .merge(with:
                ReceiverService.sharedInstance.locationControl,
                ReceiverService.sharedInstance.motionControl)
            .sink {
                if case .started = $0 {
                    self.path.removeAll(keepingCapacity: true)
                    self.isActive = false
                }
            }
            .store(in: &sinks)
    }
    
    // MARK: - Published
    @Published public private(set) var path = [CLLocation]()
    @Published public private(set) var isActive: Bool = false

    // MARK: - Private
}
