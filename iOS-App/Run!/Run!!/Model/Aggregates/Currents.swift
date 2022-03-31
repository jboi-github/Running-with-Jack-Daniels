//
//  Currents.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 27.03.22.
//

import Foundation
import CoreLocation

class Currents {
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
    var aclStatus: AclStatus {aclTwin.status}
    var hrmStatus: HrmStatus {hrmTwin.status}
    var gpsStatus: GpsStatus {gpsTwin.status}
    
    var motionType: MotionType? {motions.latestOriginal?.motion}
    var heartrate: Int? {heartrates.latestOriginal?.heartrate}
    var energyExpended: Int? {heartrates.latestOriginal?.energyExpended}
    var skinIsContacted: Bool? {heartrates.latestOriginal?.skinIsContacted}
    var location: Location? {locations.latestOriginal}
    
    var isActive: Bool? {isActives.isActives.last?.isActive}
    var speed: CLLocationSpeed? {distances.distances.last?.speed}
    var intensity: Run.Intensity? {intensities.intensities.last?.intensity}
    
    var duration: TimeInterval {workout.duration}
    var distance: CLLocationDistance {workout.distance}
    
    var vdot: Double? {
        guard let heartrate = heartrate else {return nil}
        guard let speed = speed else {return nil}
        guard let limits = Profile.hrLimits.value else {return nil}

        return Run.train(
            hrBpm: heartrate,
            paceSecPerKm: 1000 / speed,
            limits: limits)
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
