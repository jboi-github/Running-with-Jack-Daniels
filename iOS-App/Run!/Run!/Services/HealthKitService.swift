//
//  HealthKitService.swift
//  Run!
//
//  Created by Jürgen Boiselle on 19.01.22.
//

import Foundation
import CoreLocation

/// Collect events and provide data for HealthKit Wotkouts
class HealthKitService {
    static let sharedInstance = HealthKitService()

    private init() {}

    // MARK: - Interface
    func start(asOf: Date) {self.start = asOf}
    func stop(asOf: Date, completion: ((
        _ mainType: IsActiveProducer.ActivityType,
        _ start: Date, _ end: Date,
        _ userPauses: [Date],
        _ userResumes: [Date],
        _ motionPauses: [Date],
        _ motionResumes: [Date],
        _ distance: CLLocationDistance,
        _ route: [CLLocation],
        _ heartrates: [(time: Range<Date>, heartrate: Int)]) -> Void)? = nil)
    {
        let totals = getTotals(asOf: asOf)
        let mainType = getTotalActivity(totals: totals)
        let distance = getTotalDistance(totals: totals)
        
        // Get locations
        let route: [CLLocation] = {
            PathService
                .sharedInstance
                .path
                .flatMap { item -> [CLLocation] in
                    if let isActive = item.isActive?.isActive, isActive {
                        return item.locations
                    } else if let avgLocation = item.avgLocation {
                        return [avgLocation]
                    } else {
                        return []
                    }
                }
                .filter {(start ..< asOf).contains($0.timestamp)}
        }()

        // Get heartrates
        let heartrates: [(time: Range<Date>, heartrate: Int)] = {
            HrGraphService
                .sharedInstance
                .graph
                .compactMap {
                    guard let heartrate = $0.heartrate else {return nil}
                    
                    return ($0.range.clamped(to: (start ..< asOf)), heartrate)
                }
        }()
        
        HealthKitHandling.authorizedShareWorkout(
            mainType: mainType,
            start: start, end: asOf,
            userPauses: userPauses.map {max(start, min(asOf, $0))},
            userResumes: userResumes.map {max(start, min(asOf, $0))},
            motionPauses: motionPauses.map {max(start, min(asOf, $0))},
            motionResumes: motionResumes.map {max(start, min(asOf, $0))},
            distance: distance,
            route: route,
            heartrates: heartrates)
        
        completion?(
            mainType, start, asOf,
            userPauses, userResumes,
            motionPauses, motionResumes,
            distance, route, heartrates)
        
        reset()
    }
    func pause(asOf: Date) {userPauses.append(asOf)}
    func resume(asOf: Date) {userResumes.append(asOf)}
    func motionPause(asOf: Date) {motionPauses.append(asOf)}
    func motionResume(asOf: Date) {motionResumes.append(asOf)}
    
    // MARK: - Implementation
    private var start: Date = .distantFuture
    
    private var userPauses = [Date]()
    private var userResumes = [Date]()

    private var motionPauses = [Date]()
    private var motionResumes = [Date]()

    private func reset() {
        start = .distantFuture
        
        userPauses.removeAll(keepingCapacity: true)
        userResumes.removeAll(keepingCapacity: true)

        motionPauses.removeAll(keepingCapacity: true)
        motionResumes.removeAll(keepingCapacity: true)
    }
    
    private func getTotals(asOf: Date) -> [TotalsService.Total] {
        TotalsService
            .sharedInstance
            .totals(upTo: asOf)
            .values
            .array()
    }
    
    private func getTotalDistance(totals: [TotalsService.Total]) -> CLLocationDistance {
        totals.map {$0.distanceM}.reduce(0.0) {$0 + $1}
    }
    
    private func getTotalActivity(totals: [TotalsService.Total]) -> IsActiveProducer.ActivityType {
        totals
            .map {($0.activityType, $0.durationSec)}
            .reduce(into: [IsActiveProducer.ActivityType: TimeInterval]()) {
                $0[$1.0, default: 0] += $1.1
            }
            .max {$0.value <= $1.value}?
            .key ?? .unknown
    }
}
