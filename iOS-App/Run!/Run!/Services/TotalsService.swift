//
//  TotalsService.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import Foundation
import CoreLocation

class TotalsService: ObservableObject {
    static let sharedInstance = TotalsService()
    
    private init() {
        RunService.sharedInstance.subscribe(
            RunService.Config(
                motion: nil,
                aclStatus: aclStatus,
                location: nil,
                gpsStatus: gpsStatus,
                heartrate: nil,
                bodySensorLocation: nil,
                bleStatus: bleStatus,
                isActive: isActive,
                speed: speed,
                intensity: intensity))
    }

    // MARK: - Interface
    struct ActiveIntensity: Hashable, Codable {
        let activityType: IsActiveProducer.ActivityType
        let intensity: Intensity
        
        fileprivate static func from(section: Section) -> ActiveIntensity? {
            let activityType = section.activity?.type
            let intensity = section.intensity?.intensity
            
            guard let activityType = activityType, let intensity = intensity else {return nil}
            
            return ActiveIntensity(activityType: activityType, intensity: intensity)
        }
    }
    
    struct Aggregated {
        var duration: TimeInterval = 0
        var distance: CLLocationDistance = 0
    }
    
    struct Total: Codable {
        let activityType: IsActiveProducer.ActivityType
        let intensity: Intensity

        let durationSec: TimeInterval
        let distanceM: CLLocationDistance
        let heartrateBpm: Int
        let paceSecPerKm: TimeInterval
        let vdot: Double
    }
    
    @Published private(set) var totals = [ActiveIntensity: Aggregated]()
    
    func totals(upTo: Date) -> [ActiveIntensity: Total] {
        let aggTotals: [ActiveIntensity: Aggregated] = {
            guard let last = sections.last,
                    last.range.upperBound == .distantFuture else {return self.totals}
            guard let ai = ActiveIntensity.from(section: last) else {return self.totals}

            var totals = self.totals
            totals[ai, default: .zero].add(
                Section(
                    range: last.range.clamped(to: .distantPast ..< upTo),
                    speed: last.speed,
                    intensity: last.intensity,
                    activity: last.activity))
            return totals
        }()
        
        let hrSecs: [Intensity: HrGraphService.HrTotal] = {
            HrGraphService.sharedInstance.hrSecs(upTo: upTo)
        }()
        
        let hrlimits = ProfileService.sharedInstance.hrLimits.value

        var totals = [ActiveIntensity: Total]()
        for aggTotal in aggTotals {
            guard aggTotal.value.duration > 0 else {continue}

            let distanceM: Double = {
                if case .pause = aggTotal.key.activityType {
                    return 0
                } else {
                    return aggTotal.value.distance
                }
            }()
            
            let heartrate = hrSecs[aggTotal.key.intensity]?.avgHeartrate ?? -1
            let paceSecPerMin = distanceM > 0 ? 1000 * aggTotal.value.duration / distanceM : .nan
            
            let vdot: Double = {
                guard distanceM > 0 else {return .nan}
                guard heartrate > 0 else {return .nan}
                
                if let hrLimits = hrlimits {
                    return train(
                        hrBpm: heartrate,
                        paceSecPerKm: paceSecPerMin,
                        limits: hrLimits) ?? .nan
                } else {
                    return .nan
                }
            }()
            
            totals[aggTotal.key] = Total(
                activityType: aggTotal.key.activityType,
                intensity: aggTotal.key.intensity,
                durationSec: aggTotal.value.duration,
                distanceM: distanceM,
                heartrateBpm: heartrate,
                paceSecPerKm: paceSecPerMin,
                vdot: vdot)
        }
        return totals
    }

    // MARK: Implementation
    fileprivate struct Section: Rangable {
        let range: Range<Date>
        let speed: SpeedProducer.Speed?
        let intensity: IntensityProducer.IntensityEvent?
        let activity: IsActiveProducer.IsActive?
    }
    
    private struct MergeDelegate: RangableMergeDelegate {
        typealias R = Section
        
        func reduce(_ rangable: Section, to: Range<Date>) -> Section {
            Section(
                range: to,
                speed: rangable.speed,
                intensity: rangable.intensity,
                activity: rangable.activity)
        }
        
        func resolve(_ r1: Section, _ r2: Section, to: Range<Date>) -> Section {
            Section(
                range: to,
                speed: r2.speed ?? r1.speed,
                intensity: r2.intensity ?? r1.intensity,
                activity: r2.activity ?? r1.activity)
        }
        
        func drop(_ rangable: Section) {
            guard rangable.range.upperBound < .distantFuture else {return}
            guard let ai = ActiveIntensity.from(section: rangable) else {return}
            TotalsService.sharedInstance.totals[ai, default: .zero].sub(rangable)
        }
        
        func add(_ rangable: Section) {
            guard rangable.range.upperBound < .distantFuture else {return}
            guard let ai = ActiveIntensity.from(section: rangable) else {return}
            TotalsService.sharedInstance.totals[ai, default: .zero].add(rangable)
        }
    }
    
    private var sections = [Section]()
    
    var dumpSections: [(TimeInterval, TimeInterval, TimeInterval?, Intensity?, Bool?, IsActiveProducer.ActivityType?)] {
        sections.map {
            (
                $0.range.lowerBound.timeIntervalSince1970,
                $0.range.upperBound.timeIntervalSince1970,
                $0.speed?.speedMperSec,
                $0.intensity?.intensity,
                $0.activity?.isActive,
                $0.activity?.type
            )
        }
        .sorted {$0.0 <= $1.0}
    }
    
    private func aclStatus(_ status: AclProducer.Status) {
        if case .started = status {
            sections.removeAll(keepingCapacity: true)
            totals.removeAll(keepingCapacity: true)
        }
    }
    
    private func gpsStatus(_ status: GpsProducer.Status) {
        if case .started = status {
            sections.removeAll(keepingCapacity: true)
            totals.removeAll(keepingCapacity: true)
        }
    }
    
    private func bleStatus(_ status: BleProducer.Status) {
        if case .started = status {
            sections.removeAll(keepingCapacity: true)
            totals.removeAll(keepingCapacity: true)
        }
    }
    
    private func isActive(_ isActive: IsActiveProducer.IsActive) {
        sections.merge(
            Section(
                range: isActive.timestamp ..< .distantFuture,
                speed: nil,
                intensity: nil,
                activity: isActive),
            delegate: MergeDelegate())
    }
    
    private func speed(_ speed: SpeedProducer.Speed) {
        sections.merge(
            Section(
                range: speed.timestamp ..< .distantFuture,
                speed: speed,
                intensity: nil,
                activity: nil),
            delegate: MergeDelegate())
    }
    
    private func intensity(_ intensity: IntensityProducer.IntensityEvent) {
        sections.merge(
            Section(
                range: intensity.timestamp ..< .distantFuture,
                speed: nil,
                intensity: intensity,
                activity: nil),
            delegate: MergeDelegate())
    }
}

extension TotalsService.Aggregated {
    fileprivate mutating func add(_ section: TotalsService.Section) {
        let deltaDuration = section.range.distance
        duration += deltaDuration
        distance += (section.speed?.speedMperSec ?? 0) * deltaDuration
    }
    
    fileprivate mutating func sub(_ section: TotalsService.Section) {
        let deltaDuration = section.range.distance
        duration -= deltaDuration
        distance -= (section.speed?.speedMperSec ?? 0) * deltaDuration
    }
    
    static var zero: TotalsService.Aggregated {TotalsService.Aggregated()}
}
