//
//  SegmentsService.swift
//  RunEnricherKit
//
//  Created by Jürgen Boiselle on 13.10.21.
//

import Foundation
import Combine
import CoreLocation
import CoreMotion
import RunFoundationKit
import RunReceiversKit
import RunFormulasKit

/// Create and send out segments by finest granular time spans around given events.
/// Events might not arrive in order and therefore segments might be rolled back
class SegmentsService {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    static var sharedInstance = SegmentsService()

    /// Use singleton @sharedInstance
    private init() {
        ReceiverService
            .sharedInstance
            .heartrateValues
            .sinkStore { [self] in
                segments.merge(
                    Segment(
                        range: $0.timestamp ..< .distantFuture,
                        heartrate: $0,
                        location: nil,
                        motion: nil,
                        intensity: nil,
                        speed: nil),
                    delegate: delegate)
            }
        ReceiverService
            .sharedInstance
            .locationValues
            .sinkStore { [self] in
                segments.merge(
                    Segment(
                        range: $0.timestamp ..< .distantFuture,
                        heartrate: nil,
                        location: $0,
                        motion: nil,
                        intensity: nil,
                        speed: nil),
                    delegate: delegate)
            }
        ReceiverService
            .sharedInstance
            .motionValues
            .sinkStore { [self] in
                segments.merge(
                    Segment(
                        range: $0.startDate ..< .distantFuture,
                        heartrate: nil,
                        location: nil,
                        motion: $0,
                        intensity: nil,
                        speed: nil),
                    delegate: delegate)
            }
        IntensityEvent
            .producer
            .sinkStore { [self] in
                segments.merge(
                    Segment(
                        range: $0.timestamp ..< .distantFuture,
                        heartrate: nil,
                        location: nil,
                        motion: nil,
                        intensity: $0,
                        speed: nil),
                    delegate: delegate)
            }
        SpeedEvent
            .producer
            .sinkStore { [self] in
                segments.merge(
                    Segment(
                        range: $0.timestamp ..< .distantFuture,
                        heartrate: nil,
                        location: nil,
                        motion: nil,
                        intensity: nil,
                        speed: $0),
                    delegate: delegate)
            }
        
        // Reset on start
        ReceiverService.sharedInstance.heartrateControl
            .merge(with:
                ReceiverService.sharedInstance.locationControl,
                ReceiverService.sharedInstance.motionControl)
            .sinkStore {
                if $0 == .started {
                    self.segments.removeAll(keepingCapacity: true)
                }
            }
    }
    
    // MARK: - Published
    struct Segment: Rangable {
        typealias C = Date
        
        let range: Range<Date>
        let heartrate: Heartrate?
        let location: CLLocation?
        let motion: CMMotionActivity?
        
        let intensity: IntensityEvent?
        let speed: SpeedEvent?
        
        struct Delta {
            let asOf: Date
            let inRange: Bool
            
            let intensity: Intensity
            let activity: Activity
            
            let duration: TimeInterval
            let distance: CLLocationDistance
            let hrSec: Double
        }
        
        /// Returns delta up to given date. If date is omitted, returns delta for the full intervall.
        func delta(at: Date? = nil) -> Delta {
            let asOF = at ?? range.upperBound
            let duration = range.lowerBound.distance(to: asOF)
            
            return Delta(
                asOf: asOF, inRange: range.contains(asOF),
                intensity: intensity?.intensity ?? .Cold,
                activity: Activity.from(motion),
                duration: duration,
                distance: duration * (speed?.speedMperSec ?? 0),
                hrSec: duration * Double(heartrate?.heartrate ?? 0))
        }
    }
    
    @Published private(set) var segments = [Segment]()

    // MARK: - Private
    
    private struct Delegate: RangableMergeDelegate {
        typealias R = Segment
        
        func reduce(_ rangable: Segment, to: Range<Date>) -> Segment {
            Segment(
                range: to,
                heartrate: rangable.heartrate,
                location: rangable.location,
                motion: rangable.motion,
                intensity: rangable.intensity,
                speed: rangable.speed)
        }
        
        func resolve(_ r1: Segment, _ r2: Segment, to: Range<Date>) -> Segment {
            Segment(
                range: to,
                heartrate: r2.heartrate ?? r1.heartrate,
                location: r2.location ?? r1.location,
                motion: r2.motion ?? r1.motion,
                intensity: r2.intensity ?? r1.intensity,
                speed: r2.speed ?? r1.speed)
        }
        
        func drop(_ rangable: Segment) {
            // Subtract from totals
            TotalsService.sharedInstance.drop(rangable)
        }
        
        func add(_ rangable: Segment) {
            // Add to totals
            TotalsService.sharedInstance.add(rangable)
            
            // If this is open-end, it's the new current
            if rangable.range.upperBound == .distantFuture {
                CurrentsService.sharedInstance.newCurrent(rangable)
            }
        }
    }
    
    private let delegate = Delegate()
}
