//
//  DeltaService.swift
//  RunEnricherKit
//
//  Created by Jürgen Boiselle on 12.10.21.
//

import Foundation
import Combine
import CoreLocation
import CoreMotion
import RunReceiversKit
import RunDatabaseKit
import RunFormulasKit
import RunFoundationKit

/// Delta detection, store and retrieve as a service
class DeltaService {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    static var sharedInstance = DeltaService()

    /// Use singleton @sharedInstance
    private init() {
        intensityStream = _intensityStream
            .removeDuplicates {$0.intensity == $1.intensity}
            .share()
            .eraseToAnyPublisher()

        ReceiverService
            .sharedInstance
            .heartrateValues
            .delta {self.deltaHeartrates.last}
            .sinkStore {self.deltaHeartrates.append($0)}
        ReceiverService
            .sharedInstance
            .locationValues // FIXME: Sort by timestamp
            .delta {self.deltaLocations.last}
            .sinkStore {self.deltaLocations.append($0)}
        ReceiverService
            .sharedInstance
            .motionValues
            .delta {self.deltaMotions.last}
            .sinkStore {self.deltaMotions.append($0)}
        intensityStream
            .delta {self.deltaIntensities.last}
            .sinkStore {self.deltaIntensities.append($0)}

        ReceiverService
            .sharedInstance
            .heartrateControl
            .sinkStore {
                if case .started = $0 {
                    self.deltaHeartrates.removeAll(keepingCapacity: true)
                    self.deltaIntensities.removeAll(keepingCapacity: true)
                }
            }
        ReceiverService
            .sharedInstance
            .locationControl
            .sinkStore {
                if case .started = $0 {
                    self.deltaLocations.removeAll(keepingCapacity: true)
                }
            }
        ReceiverService
            .sharedInstance
            .motionControl
            .sinkStore {
                if case .started = $0 {
                    self.deltaMotions.removeAll(keepingCapacity: true)
                }
            }
    }
    
    // MARK: - Published
    let intensityStream: AnyPublisher<IntensityEvent, Never>
    
    func delta(
        _ at: Date,
        deltas: @escaping (DeltaHeartrate, DeltaLocation, DeltaMotion, DeltaIntensity) -> Void)
    {
        serialQueue.async { [self] in
            let dh = deltaHeartrates[at]
            let dl = deltaLocations[at]
            let dm = deltaMotions[at]
            let di = deltaIntensities[at]
            
            deltas(dh, dl, dm, di)
        }
    }
    
    // MARK: - Private
    private var deltaHeartrates = [DeltaHeartrate]() {
        didSet {
            if let last = deltaHeartrates.last {log(last)}
            if let event = IntensityEvent.fromHr(deltaHeartrates.last, deltaMotions.last) {
                serialQueue.async {self._intensityStream.send(event)}
            }
        }
    }
    private var deltaLocations = [DeltaLocation]() {
        didSet {
            if let last = deltaLocations.last {log(last)}
        }
    }
    private var deltaMotions = [DeltaMotion]() {
        didSet {
            if let last = deltaMotions.last {log(last)}
            if let event = IntensityEvent.fromHr(deltaHeartrates.last, deltaMotions.last) {
                serialQueue.async {self._intensityStream.send(event)}
            }
        }
    }
    private var deltaIntensities = [DeltaIntensity]() {
        didSet {
            if let last = deltaIntensities.last {log(last)}
        }
    }
    private let _intensityStream = PassthroughSubject<IntensityEvent, Never>()
}
