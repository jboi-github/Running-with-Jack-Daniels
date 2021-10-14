//
//  TotalsService.swift
//  RunEnricherKit
//
//  Created by Jürgen Boiselle on 08.10.21.
//

import Foundation
import Combine
import CoreLocation
import RunFoundationKit
import RunFormulasKit
import RunReceiversKit
import RunEnricherKit

public class TotalsService: ObservableObject {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    public static var sharedInstance = TotalsService()

    /// Use singleton @sharedInstance
    private init() {
        SegmentsService
            .sharedInstance
            .segmentStream
            .sink { segment, action in
                let activeIntensity = ActiveIntensity(
                    isActive: segment.motion.end,
                    intensity: segment.intensity.end)
                let total = Total(
                    duration: segment.span.lowerBound.distance(to: segment.span.upperBound),
                    distance: segment.location.end - segment.location.begin,
                    heartrateSec: segment.heartrate.duration * Double(segment.heartrate.end))

                switch action {
                case .rollback:
                    self.totals -= (activeIntensity, total)
                case .rollforward:
                    self.totals += (activeIntensity, total)
                }
            }
            .store(in: &sinks)
        
        ReceiverService.sharedInstance.heartrateControl
            .merge(with:
                ReceiverService.sharedInstance.locationControl,
                ReceiverService.sharedInstance.motionControl)
            .sink {
                if case .started = $0 {
                    self.totals.removeAll(keepingCapacity: true)
                }
            }
            .store(in: &sinks)
    }
    
    // MARK: - Published
    public struct Total {
        var duration: TimeInterval
        var distance: CLLocationDistance
        fileprivate var heartrateSec: Double
        
        var heartrateBpm: Int {Int(heartrateSec / duration + 0.5)}
        var vdot: Double {.nan} // TODO: Implement
        var paceSecPerKm: TimeInterval {1000.0 * duration / distance}
    }
    
    public struct ActiveIntensity: Hashable {
        let isActive: Bool
        let intensity: Intensity
    }
    
    @Published public private(set) var totals = [ActiveIntensity: Total]()

    // MARK: - Private
}

extension TotalsService.Total {
    static var zero: Self {
        Self(duration: 0, distance: 0, heartrateSec: 0)
    }

    static func +=(lhs: inout Self, rhs: Self) {
        lhs.duration += rhs.duration
        lhs.distance += rhs.distance
        lhs.heartrateSec += rhs.heartrateSec
    }

    static func -=(lhs: inout Self, rhs: Self) {
        lhs.duration -= rhs.duration
        lhs.distance -= rhs.distance
        lhs.heartrateSec -= rhs.heartrateSec
    }
}

extension Dictionary where Key == TotalsService.ActiveIntensity, Value == TotalsService.Total {
    static var zero: Self {Self()}
    
    static func +=(lhs: inout Self, rhs: Element) {
        lhs[rhs.key, default: Value.zero] += rhs.value
    }
    static func -=(lhs: inout Self, rhs: Element) {
        lhs[rhs.key, default: Value.zero] -= rhs.value
    }
}
