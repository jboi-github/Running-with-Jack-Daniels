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

public class TotalsService: ObservableObject {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    public static var sharedInstance = TotalsService()

    /// Use singleton @sharedInstance
    private init() {
        SegmentsService
            .sharedInstance
            .segmentStream
            .sinkMainStore { segment, action in
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
        
        ReceiverService.sharedInstance.heartrateControl
            .merge(with:
                ReceiverService.sharedInstance.locationControl,
                ReceiverService.sharedInstance.motionControl)
            .sinkMainStore {
                if case .started = $0 {
                    self.totals.removeAll(keepingCapacity: true)
                }
            }
    }
    
    // MARK: - Published
    public struct Total {
        public fileprivate(set) var duration: TimeInterval
        public fileprivate(set) var distance: CLLocationDistance
        fileprivate var heartrateSec: Double
        
        public var heartrateBpm: Int {Int(heartrateSec / duration + 0.5)}
        public var vdot: Double {.nan} // TODO: Implement
        public var paceSecPerKm: TimeInterval {1000.0 * duration / distance}
    }
    
    public struct ActiveIntensity: Hashable {
        let isActive: Bool
        let intensity: Intensity
        
        public init(isActive: Bool, intensity: Intensity) {
            self.isActive = isActive
            self.intensity = intensity
        }
    }
    
    @Published public private(set) var totals = [ActiveIntensity: Total]()
    
    public var sumTotals: Total {
        totals.reduce(into: Total.zero) {$0 += $1.value}
    }

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
