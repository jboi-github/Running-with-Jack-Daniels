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

/**
 A cleaned locations path as set. CLLocations + ActivityIntensity. Non-active locations are filtered out.
 Hashing for the set treats hr-changes as eauql elements.
 */
public class LocationsService: ObservableObject {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    public static var sharedInstance = LocationsService()

    /// Use singleton @sharedInstance
    private init() {
        ReceiverService.sharedInstance.heartrateControl
            .merge(with:
                ReceiverService.sharedInstance.locationControl,
                ReceiverService.sharedInstance.motionControl)
            .sinkMainStore {
                if case .started = $0 {
                    self.path.removeAll(keepingCapacity: true)
                }
            }
    }
    
    // MARK: - Published
    public struct PathPoint: Hashable {
        public let location: CLLocation
        public let activityIntensity: ActivityIntensity
        
        /// Get path point from segment. If segment contains none-activity, nil is returned.
        static func fromSegment(_ segment: SegmentsService.Segment) -> Self? {
            guard let location = segment.location else {return nil}

            let activityIntensity = ActivityIntensity(
                activity: Activity.from(segment.motion),
                intensity: segment.intensity?.intensity ?? .Cold)
            
            return PathPoint(location: location, activityIntensity: activityIntensity)
        }
    }
    
    @Published public private(set) var path = [PathPoint]()
    
    func drop(_ segment: SegmentsService.Segment) {
        guard let pp = PathPoint.fromSegment(segment) else {return}
        DispatchQueue.main.async { [self] in
            let insertIdx = path.insertIndex(for: pp.location.timestamp) {$0.location.timestamp}
            if insertIdx > path.startIndex {
                self.path.remove(at: path.index(before: insertIdx))
            }
        }
    }
    
    func add(_ segment: SegmentsService.Segment) {
        guard let pp = PathPoint.fromSegment(segment) else {return}
        if pp.activityIntensity.activity.isActive {
            DispatchQueue.main.async { [self] in
                let insertIdx = path.insertIndex(for: pp.location.timestamp) {$0.location.timestamp}
                path.insert(pp, at: insertIdx)
            }
        }
    }

    // MARK: - Private
}
