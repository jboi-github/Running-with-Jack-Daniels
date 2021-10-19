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
            .sinkMainStore {self.isActive = $0.isActive}

        ReceiverService
            .sharedInstance
            .locationValues
            .filter {_ in self.isActive}
            .sinkMainStore {self.path.append($0)} // FIXME: Insert in order of timestamp

        ReceiverService.sharedInstance.heartrateControl
            .merge(with:
                ReceiverService.sharedInstance.locationControl,
                ReceiverService.sharedInstance.motionControl)
            .sinkMainStore {
                if case .started = $0 {
                    self.path.removeAll(keepingCapacity: true)
                    self.isActive = false
                }
            }
    }
    
    // MARK: - Published
    @Published public private(set) var path = [CLLocation]()
    @Published public private(set) var isActive: Bool = false

    // MARK: - Private
}
