//
//  SegmentsService.swift
//  RunEnricherKit
//
//  Created by Jürgen Boiselle on 13.10.21.
//

import Foundation
import Combine
import RunFoundationKit
import RunReceiversKit

/// Create and send out segments by finest granular time spans around given events.
/// Events might not arrive in order and therefore segments might be rolled back
class SegmentsService {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    static var sharedInstance = SegmentsService()

    /// Use singleton @sharedInstance
    private init() {
        let h = ReceiverService
            .sharedInstance
            .heartrateValues
            .map {$0.timestamp}
        
        let l = ReceiverService
            .sharedInstance
            .locationValues
            .map {$0.timestamp}
        
        let m = ReceiverService
            .sharedInstance
            .motionValues
            .map {$0.when}
        
        let i = DeltaService
            .sharedInstance
            .intensityStream
            .map {$0.timestamp}
        
        h.merge(with: l, m, i)
            .sinkStore {self.actions(at: $0)}
        
        ReceiverService.sharedInstance.heartrateControl
            .merge(with:
                ReceiverService.sharedInstance.locationControl,
                ReceiverService.sharedInstance.motionControl)
            .sinkStore {
                if case .started = $0 {
                    self.sentOut.removeAll(keepingCapacity: true)
                    self.timestamps.removeAll(keepingCapacity: true)
                }
            }
    }
    
    // MARK: - Published
    enum Action {
        case rollforward, rollback
    }
    
    struct Segment {
        internal init(span: Range<Date>, heartrate: DeltaHeartrate, location: DeltaLocation, motion: DeltaMotion, intensity: DeltaIntensity) {
            self.span = span
            self.heartrate = heartrate
            self.location = location
            self.motion = motion
            self.intensity = intensity
            
            log(span, heartrate, location, motion, intensity)
        }
        
        let span: Range<Date>
        let heartrate: DeltaHeartrate
        let location: DeltaLocation
        let motion: DeltaMotion
        let intensity: DeltaIntensity
    }
    
    typealias SegmentAction = (Segment, Action)
    
    let segmentStream = PassthroughSubject<SegmentAction, Never>()

    // MARK: - Private
    private var sentOut = [Segment]()
    private var timestamps = [Date]()
    
    private func actions(at timestamp: Date) {
        DeltaService.sharedInstance.delta(timestamp) { [self] dh, dl, dm, di in
            let insertIdx = timestamps.insertIndex(for: timestamp) {$0}
            timestamps.insert(timestamp, at: insertIdx)
            
            let impactTime = [
                timestamp,
                dh.impactsAfter,
                dl.impactsAfter,
                dm.impactsAfter,
                di.impactsAfter].min()!
            
            // Rollback
            while let last = sentOut.last, last.span.upperBound > impactTime {
                sentOut.removeLast()
                segmentStream.send((last, .rollback))
            }
            
            // Rollforward
            // Search backwards from insertIdx of timestamp to find impactTime
            let impactIdx = (timestamps.startIndex ... insertIdx)
                .reversed()
                .last {timestamps[$0] >= impactTime} ?? timestamps.startIndex
            
            // From impactTimeIdx, ngram(2) forward
            timestamps[max(timestamps.index(before: impactIdx), timestamps.startIndex)...]
                .ngram(2)
                .forEach {
                    guard $0.count == 2 else {return}
                    let begin = $0[0]
                    let end = $0[1]
                    
                    // Create Segment (2 levels of closures)
                    DeltaService.sharedInstance.delta(begin) { [self] dhb, dlb, dmb, dib in
                        DeltaService.sharedInstance.delta(end) { [self] dhe, dle, dme, die in
                            let segment = Segment(
                                span: begin..<end,
                                heartrate: DeltaHeartrate(
                                    span: begin..<end,
                                    begin: dhb.value(at: begin),
                                    end: dhe.value(at: end)),
                                location: DeltaLocation(
                                    span: begin..<end,
                                    begin: dlb.value(at: begin),
                                    end: dle.value(at: end)),
                                motion: DeltaMotion(
                                    span: begin..<end,
                                    begin: dmb.value(at: begin),
                                    end: dme.value(at: end)),
                                intensity: DeltaIntensity(
                                    span: begin..<end,
                                    begin: dib.value(at: begin),
                                    end: die.value(at: end)))
                            
                            // Send and append
                            sentOut.append(segment)
                            segmentStream.send((segment, .rollforward))
                        }
                    }
                }
        }
    }
}
