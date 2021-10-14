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
            .share()
            .eraseToAnyPublisher()

        ReceiverService
            .sharedInstance
            .heartrateValues
            .delta {self.deltaHeartrates.last}
            .sink {self.deltaHeartrates.append($0)}
            .store(in: &sinks)
        ReceiverService
            .sharedInstance
            .locationValues
            .delta {self.deltaLocations.last}
            .sink {self.deltaLocations.append($0)}
            .store(in: &sinks)
        ReceiverService
            .sharedInstance
            .motionValues
            .delta {self.deltaMotions.last}
            .sink {self.deltaMotions.append($0)}
            .store(in: &sinks)
        intensityStream
            .delta {self.deltaIntensities.last}
            .sink {self.deltaIntensities.append($0)}
            .store(in: &sinks)

        ReceiverService
            .sharedInstance
            .heartrateControl
            .sink {
                if case .started = $0 {
                    self.deltaHeartrates.removeAll(keepingCapacity: true)
                    self.deltaIntensities.removeAll(keepingCapacity: true)
                }
            }
            .store(in: &sinks)
        ReceiverService
            .sharedInstance
            .locationControl
            .sink {
                if case .started = $0 {
                    self.deltaLocations.removeAll(keepingCapacity: true)
                }
            }
            .store(in: &sinks)
        ReceiverService
            .sharedInstance
            .motionControl
            .sink {
                if case .started = $0 {
                    self.deltaMotions.removeAll(keepingCapacity: true)
                }
            }
            .store(in: &sinks)
    }
    
    // MARK: - Published
    let intensityStream: AnyPublisher<IntensityEvent, Never>
    
    func delta(
        _ at: Date,
        deltas: @escaping (DeltaHeartrate, DeltaLocation, DeltaMotion, DeltaIntensity) -> Void)
    {
        serialQueue.async { [self] in
            deltas(
                deltaHeartrates[at],
                deltaLocations[at],
                deltaMotions[at],
                deltaIntensities[at])
        }
    }
    
    // MARK: - Private
    private var deltaHeartrates = [DeltaHeartrate]() {
        didSet {
            guard let last = deltaHeartrates.last else {return}
            if let event = IntensityEvent.fromHr(last) {
                serialQueue.async {self._intensityStream.send(event)}
            }
        }
    }
    private var deltaLocations = [DeltaLocation]()
    private var deltaMotions = [DeltaMotion]()
    private var deltaIntensities = [DeltaIntensity]()

    private let _intensityStream = PassthroughSubject<IntensityEvent, Never>()
}
