//
//  Currents.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 27.03.22.
//

import Foundation
import CoreLocation

class Currents: ObservableObject {
    // MARK: Initialization
    init(
        aclTwin: AclTwin, hrmTwin: HrmTwin, gpsTwin: GpsTwin,
        motions: Motions, heartrates: Heartrates, locations: Locations,
        isActives: IsActives, distances: Distances, intensities: Intensities,
        workout: Workout)
    {
        self.aclTwin = aclTwin
        self.hrmTwin = hrmTwin
        self.gpsTwin = gpsTwin
        self.motions = motions
        self.heartrates = heartrates
        self.locations = locations
        self.isActives = isActives
        self.distances = distances
        self.intensities = intensities
        self.workout = workout
    }
    
    // MARK: Interface
    @Published private(set) var aclStatus: AclStatus = .stopped(since: .distantPast)
    @Published private(set) var hrmStatus: BleStatus = .stopped(since: .distantPast)
    @Published private(set) var gpsStatus: GpsStatus = .stopped(since: .distantPast)
    
    @Published private(set) var motionType: MotionType? = nil
    @Published private(set) var heartrate: Int? = nil
    @Published private(set) var energyExpended: Int? = nil
    
    @Published private(set) var skinIsContacted: Bool? = nil
    @Published private(set) var peripheralName: String? = nil
    @Published private(set) var batteryLevel: Int? = nil

    @Published private(set) var location: Location? = nil
    
    @Published private(set) var isActive: Bool? = nil
    @Published private(set) var speed: CLLocationSpeed? = nil
    @Published private(set) var intensity: Run.Intensity? = nil
    
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var distance: CLLocationDistance = 0
    
    @Published private(set) var vdot: Double? = nil

    func trigger() {
        DispatchQueue.main.async { [self] in
            aclStatus = aclTwin.status
            hrmStatus = hrmTwin.status
            gpsStatus = gpsTwin.status
            
            motionType = motions.latestOriginal?.motion
            heartrate = heartrates.latestOriginal?.heartrate
            energyExpended = heartrates.latestOriginal?.energyExpended
            skinIsContacted = heartrates.latestOriginal?.skinIsContacted
            
            peripheralName = heartrates.latestOriginal?.peripheralName
            batteryLevel = hrmTwin.batteryLevel
            
            location = locations.latestOriginal
            
            isActive = isActives.isActives.last?.isActive
            speed = distances.distances.last?.speed
            intensity = intensities.intensities.last?.intensity
            
            duration = workout.duration
            distance = workout.distance
            
            vdot = {
                guard let heartrate = heartrate else {return nil}
                guard let speed = speed else {return nil}
                guard let limits = Profile.hrLimits.value else {return nil}

                return Run.train(
                    hrBpm: heartrate,
                    paceSecPerKm: 1000 / speed,
                    limits: limits)
            }()
        }
    }
    
    // MARK: Implementation
    private unowned let aclTwin: AclTwin
    private unowned let hrmTwin: HrmTwin
    private unowned let gpsTwin: GpsTwin

    private unowned let motions: Motions
    private unowned let heartrates: Heartrates
    private unowned let locations: Locations

    private unowned let isActives: IsActives
    private unowned let distances: Distances
    private unowned let intensities: Intensities

    private unowned let workout: Workout
}
