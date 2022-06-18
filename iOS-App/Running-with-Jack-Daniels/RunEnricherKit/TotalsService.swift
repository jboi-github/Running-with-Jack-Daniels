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
import RunDatabaseKit

public class TotalsService {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    public static var sharedInstance = TotalsService()

    /// Use singleton @sharedInstance
    private init() {
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
        
        public var heartrateBpm: Int {
            duration > 0 ? Int(heartrateSec / duration + 0.5) : 0
        }
        
        public var paceSecPerKm: TimeInterval {
            distance > 0 ? 1000.0 * duration / distance : .nan
        }
        
        public var vdot: Double {
            let hrMax = Database.sharedInstance.hrMax.value
            let hrResting = Database.sharedInstance.hrResting.value

            if hrMax.isFinite && hrResting.isFinite {
                return train(
                    hrBpm: heartrateBpm,
                    hrMaxBpm: Int(hrMax + 0.5),
                    restingBpm: Int(hrResting + 0.5),
                    paceSecPerKm: paceSecPerKm) ?? .nan
            } else if hrMax.isFinite {
                return train(
                    hrBpm: heartrateBpm,
                    hrMaxBpm: Int(hrMax + 0.5),
                    paceSecPerKm: paceSecPerKm) ?? .nan
            } else {
                return .nan
            }
        }
    }
    
    /// Add currently last segment to totals up to give time.
    public func current(at: Date = Date()) -> (sum: Total, totals: [(Activity, Intensity, Total)]) {
        // Add up to date extrapolation
        var totals = totals
        if let last = SegmentsService.sharedInstance.segments.last {
            let delta = last.delta(at: at)
            totals[ActivityIntensity.fromDelta(delta), default: Total.zero] += delta
        }
        
        var result = [(Activity, Intensity, Total)]()
        func appendToResult(_ activity: Activity, _ intensity: Intensity) {
            let ai = ActivityIntensity(activity: activity, intensity: intensity)
            guard let total = totals[ai] else {return}
            
            result.append((activity, intensity, total))
        }
        
        appendToResult(.walking, .Cold)
        appendToResult(.walking, .Easy)
        appendToResult(.walking, .Marathon)
        appendToResult(.walking, .Threshold)
        appendToResult(.walking, .Interval)
        appendToResult(.walking, .Repetition)

        appendToResult(.running, .Cold)
        appendToResult(.running, .Easy)
        appendToResult(.running, .Marathon)
        appendToResult(.running, .Threshold)
        appendToResult(.running, .Interval)
        appendToResult(.running, .Repetition)

        appendToResult(.cycling, .Cold)
        appendToResult(.cycling, .Easy)
        appendToResult(.cycling, .Marathon)
        appendToResult(.cycling, .Threshold)
        appendToResult(.cycling, .Interval)
        appendToResult(.cycling, .Repetition)
        
        return (
            totals.filter {$0.key.activity.isActive}.reduce(into: Total.zero) {$0 += $1.value},
            result)
    }

    func drop(_ segment: SegmentsService.Segment) {
        let delta = segment.delta()
        totals[ActivityIntensity.fromDelta(delta), default: Total.zero] -= delta
    }
    
    func add(_ segment: SegmentsService.Segment) {
        let delta = segment.delta()
        totals[ActivityIntensity.fromDelta(delta), default: Total.zero] += delta
    }

    // MARK: - Private
    
    private var totals = [ActivityIntensity: Total]()
}

extension TotalsService.Total {
    public static var zero: Self {
        Self(duration: 0, distance: 0, heartrateSec: 0)
    }

    static func +=(lhs: inout Self, rhs: SegmentsService.Segment.Delta) {
        lhs.duration += rhs.duration
        lhs.distance += rhs.distance
        lhs.heartrateSec += rhs.hrSec
    }

    static func -=(lhs: inout Self, rhs: SegmentsService.Segment.Delta) {
        lhs.duration -= rhs.duration
        lhs.distance -= rhs.distance
        lhs.heartrateSec -= rhs.hrSec
    }

    static func +=(lhs: inout Self, rhs: Self) {
        lhs.duration += rhs.duration
        lhs.distance += rhs.distance
        lhs.heartrateSec += rhs.heartrateSec
    }
}
