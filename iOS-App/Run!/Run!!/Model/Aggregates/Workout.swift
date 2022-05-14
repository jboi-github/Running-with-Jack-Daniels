//
//  WorkoutTwin.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import Foundation
import CoreLocation
import HealthKit
import MapKit
import Combine

enum WorkoutStatus: Equatable, Codable {
    case stopped(since: Date)
    case waiting(since: Date)
    case started(since: Date)
    case paused(since: Date)
    
    var canStop: Bool {
        switch self {
        case .stopped:
            return false
        case .waiting:
            return false
        case .started:
            return true
        case .paused:
            return true
        }
    }

    var isStopped: Bool {
        switch self {
        case .stopped:
            return true
        default:
            return false
        }
    }
    
    var since: Date {
        switch self {
        case .stopped(since: let since):
            return since
        case .waiting(since: let since):
            return since
        case .started(since: let since):
            return since
        case .paused(since: let since):
            return since
        }
    }
}

class Workout: ObservableObject {
    // MARK: Initalize
    init(
        stepGetter: @escaping (Date) -> StepX?,
        activityGetter: @escaping (Date) -> ActivityX?,
        heartrateGetter: @escaping (Date) -> HeartrateX?,
        intensityGetter: @escaping (Date) -> IntensityX?,
        distanceGetter: @escaping (Date) -> DistanceX?,
        bodySensorLocationGetter: @escaping () -> BodySensorLocation?)
    {
        self.activityGetter = activityGetter
        self.distanceGetter = distanceGetter
        self.bodySensorLocationGetter = bodySensorLocationGetter
        self.totalsCollector = Totals(
            stepGetter: stepGetter,
            activityGetter: activityGetter,
            heartrateGetter: heartrateGetter,
            intensityGetter: intensityGetter,
            distanceGetter: distanceGetter)
    }
    
    // MARK: Interface
    @Published private(set) var status: WorkoutStatus = .stopped(since: .distantPast)
    @Published private(set) var totals = [Totals.KeyValue]()
    @Published private(set) var distance: CLLocationDistance = 0
    @Published private(set) var startTime: Date = .distantFuture
    private(set) var endTime: Date = .distantFuture
    var duration: TimeInterval {startTime.distance(to: endTime)}
    
    @Published private(set) var heartrates = [HeartrateX]()
    @Published private(set) var locations = [LocationX]()
    
    private(set) var pauses = [Date]()
    private(set) var resumes = [Date]()

    func await(asOf: Date) {
        log(asOf, status)
        guard case .stopped = status else {return}
        
        DispatchQueue.main.async { [self] in
            status = .waiting(since: asOf)
            startTime = asOf
            endTime = asOf
            distance = 0
        }
    }
    
    func start(asOf: Date) {
        log(asOf, status)
        switch status {
        case .waiting(since: let waitAsOf):
            // Start new Workout
            DispatchQueue.main.async { [self] in
                status = .started(since: max(waitAsOf, asOf))
                totalsCollector.reset()
                totals.removeAll()
                startTime = max(waitAsOf, asOf)
                endTime = startTime
                distance = 0
                heartrates.removeAll()
                locations.removeAll()
            }
            pauses.removeAll()
            resumes.removeAll()
        case .paused:
            // Resume to Workout
            DispatchQueue.main.async { [self] in
                status = .started(since: asOf)
            }
            resumes.append(asOf)
        default:
            return
        }
    }
    
    func pause(asOf: Date) {
        log(asOf, status)
        guard case .started = status else {return}
        DispatchQueue.main.async { [self] in
            status = .paused(since: asOf)
        }
        pauses.append(asOf)
    }
    
    func stop(asOf: Date) {
        log(asOf,status)
        guard status.canStop else {return}
        DispatchQueue.main.async { [self] in
            status = .stopped(since: max(endTime, asOf))
            endTime = max(endTime, asOf)
            saveToHK()
        }
    }
    
    func changed(distances appended: [DistanceX], _ removed: [DistanceX]) {
        if status.canStop {endTime = max(endTime, appended.map {$0.asOf}.max() ?? .distantPast)}
        
        var delta = appended.reduce(0.0) {
            guard (startTime ... endTime).contains($1.asOf) else {return $0}
            guard let a = activityGetter($1.asOf) else {return $0}
            guard a.isActive else {return $0}
            
            return $0 + $1.speed
        }
        delta = removed.reduce(delta) {
            guard (startTime ... endTime).contains($1.asOf) else {return $0}
            guard let a = activityGetter($1.asOf) else {return $0}
            guard a.isActive else {return $0}
            
            return $0 - $1.speed
        }
        totalsCollector.changed(distances: appended, removed, startTime ... endTime)
        DispatchQueue.main.async { [self] in
            distance += delta
            totals = totalsCollector.flattend
        }
    }
    
    func changed(activities appendedA: [ActivityX], _ removedA: [ActivityX]) {
        if status.canStop {endTime = max(startTime, endTime, appendedA.map {$0.asOf}.max() ?? .distantPast)}
        
        var delta = appendedA.reduce(0.0) {
            guard (startTime ... endTime).contains($1.asOf) else {return $0}
            guard $1.isActive else {return $0}
            guard let d = distanceGetter($1.asOf) else {return $0}
            
            return $0 + d.speed
        }
        delta = removedA.reduce(delta) {
            guard (startTime ... endTime).contains($1.asOf) else {return $0}
            guard $1.isActive else {return $0}
            guard let d = distanceGetter($1.asOf) else {return $0}
            
            return $0 - d.speed
        }
        
        totalsCollector.changed(activities: appendedA, removedA, startTime ... endTime)
        DispatchQueue.main.async { [self] in
            distance += delta
            totals = totalsCollector.flattend
        }
    }

    func changed(intensities appendedI: [IntensityX], _ removedI: [IntensityX], _ appendedH: [HeartrateX], _ removedH: [HeartrateX]) {
        totalsCollector.changed(intensities: appendedI, removedI, appendedH, removedH, startTime ... endTime)
        DispatchQueue.main.async { [self] in
            totals = totalsCollector.flattend
        }
    }
    
    /// Must be called as the very last thing to ensure `endTime` is already maintained.
    func append(_ heartrate: HeartrateX) {
        guard status.canStop else {return}
        DispatchQueue.main.async { [self] in
            endTime = max(endTime, heartrate.date)
            heartrates.append(heartrate)
        }
    }
    
    /// Must be called as the very last thing to ensure `endTime` is already maintained.
    func append(_ location: LocationX) {
        guard status.canStop else {return}
        DispatchQueue.main.async { [self] in
            endTime = max(endTime, location.date)
            locations.append(location)
        }
    }
    
    func save() {
        let info = Info(
            status: status, totals: totals, distance: distance,
            startTime: startTime, endTime: endTime,
            heartrates: heartrates, locations: locations,
            pauses: pauses, resumes: resumes)
        if let url = Files.write(info, to: "workout.json") {log(url)}
        totalsCollector.save()
    }
    
    func load(asOf: Date) {
        guard let info = Files.read(Info.self, from: "workout.json") else {return}
        totalsCollector.load()
        switch info.status {
        case .stopped(since: let since):
            if since.distance(to: asOf) >= workoutTimeout {return}
        case .waiting(since: let since):
            if since.distance(to: asOf) >= workoutTimeout {return}
        case .started(since: let since):
            if since.distance(to: asOf) >= workoutTimeout {return}
        case .paused(since: let since):
            if since.distance(to: asOf) >= workoutTimeout {return}
        }
        
        DispatchQueue.main.async {
            self.status = info.status
            self.totals = info.totals
            self.distance = info.distance
            self.startTime = info.startTime
            self.endTime = info.endTime
            self.heartrates = info.heartrates
            self.locations = info.locations
        }
        self.pauses = info.pauses
        self.resumes = info.resumes
    }
    
    // MARK: Implementation
    private let activityGetter: (Date) -> ActivityX?
    private let distanceGetter: (Date) -> DistanceX?
    private let bodySensorLocationGetter: () -> BodySensorLocation?
    private let totalsCollector: Totals

    private struct Info: Codable {
        let status: WorkoutStatus
        let totals: [Totals.KeyValue]
        let distance: CLLocationDistance
        let startTime: Date
        let endTime: Date

        let heartrates: [HeartrateX]
        let locations: [LocationX]

        let pauses: [Date]
        let resumes: [Date]
    }

    // Save workout to HealthKit
    private func saveToHK() {
        // Pauses
        let hkPauses: [HKWorkoutEvent] = {
            pauses
                .filter {(startTime ..< endTime).contains($0)}
                .map {HKWorkoutEvent(type: .motionPaused, dateInterval: DateInterval(start: $0, duration: 0), metadata: nil)}
        }()
        
        // Resumes
        let hkResumes: [HKWorkoutEvent] = {
            resumes
                .filter {(startTime ..< endTime).contains($0)}
                .map {HKWorkoutEvent(type: .motionResumed, dateInterval: DateInterval(start: $0, duration: 0), metadata: nil)}
        }()

        // Energy
        let hkEnergy: HKQuantity? = {
            guard let energy = heartrates.compactMap({$0.energyExpended}).max() else {return nil}
            log(energy)
            return HKQuantity(unit: .jouleUnit(with: .kilo), doubleValue: Double(energy))
        }()
        
        // HR Sensor location
        let hkSensorLocation: HKHeartRateSensorLocation = {
            switch bodySensorLocationGetter() {
            case .Other, .none:
                return .other
            case .Chest:
                return .chest
            case .Wrist:
                return .wrist
            case .Finger:
                return .finger
            case .Hand:
                return .hand
            case .EarLobe:
                return .earLobe
            case .Foot:
                return .foot
            }
        }()
        
        log(startTime, endTime, hkPauses, hkResumes, distance)
        let hkWorkout = HKWorkout(
            activityType: .running,
            start: startTime,
            end: endTime,
            workoutEvents: hkPauses + hkResumes,
            totalEnergyBurned: hkEnergy,
            totalDistance: HKQuantity(unit: .meter(), doubleValue: distance),
            metadata: nil)
        
        // locations as [CLLocation]
        var hkLocations: [CLLocation] {
            locations.filter {(startTime ..< endTime).contains($0.date)}.map {$0.asCLLocation}
        }
        
        // heartrates as HK Samples
        var hkHeartrates: [HKQuantitySample] {
            guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {return []}

            var prev: HeartrateX? = nil
            let hkSensorLocation = hkSensorLocation
            return heartrates.filter {(startTime ..< endTime).contains($0.date)}.compactMap { heartrate in
                defer {prev = heartrate}
                guard let prev = prev else {return nil}
                
                log(prev.heartrate, prev.timestamp, heartrate.timestamp, hkSensorLocation)
                return HKQuantitySample(
                    type: hrType,
                    quantity: HKQuantity(unit: HKUnit(from: "count/min"), doubleValue: Double(prev.heartrate)),
                    start: prev.timestamp,
                    end: heartrate.timestamp,
                    metadata: [HKMetadataKeyHeartRateSensorLocation : hkSensorLocation])
            }
        }
        
        // Call share
        Health.authorizedShareWorkout(hkWorkout, heartrates: hkHeartrates, locations: hkLocations)
    }
}
