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
    
    // MARK: Interface
    @Published private(set) var stcStatus: ClientStatus = .stopped(since: .distantPast)
    @Published private(set) var hrmStatus: ClientStatus = .stopped(since: .distantPast)
    @Published private(set) var gpsStatus: ClientStatus = .stopped(since: .distantPast)
    
    @Published private(set) var cadence: Double? = nil
    @Published private(set) var heartrate: Int? = nil
    @Published private(set) var energyExpended: Int? = nil
    
    @Published private(set) var skinIsContacted: Bool? = nil
    @Published private(set) var peripheralName: String? = nil
    @Published private(set) var batteryLevel: Int? = nil

    @Published private(set) var location: LocationX? = nil
    
    @Published private(set) var isActive: Bool? = nil
    @Published private(set) var speed: CLLocationSpeed? = nil
    @Published private(set) var intensity: Run.Intensity? = nil
    
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var distance: CLLocationDistance = 0
    
    @Published private(set) var vdot: Double? = nil

    func trigger() {
//        DispatchQueue.main.async { [self] in
//            stcStatus = stcTwin.status
//            hrmStatus = hrmTwin.status
//            gpsStatus = gpsTwin.status
//            
//            cadence = steps.latestOriginal?.currentCadence
//            heartrate = heartrates.latestOriginal?.heartrate
//            energyExpended = heartrates.latestOriginal?.energyExpended
//            skinIsContacted = heartrates.latestOriginal?.skinIsContacted
//            
//            peripheralName = heartrates.latestOriginal?.peripheralName
//            batteryLevel = hrmTwin.batteryLevel
//            
//            location = locations.latestOriginal
//            
//            isActive = activities.activities.last?.isActive
//            speed = distances.distances.last?.speed
//            intensity = intensities.intensities.last?.intensity
//            
//            duration = workout.duration
//            distance = workout.distance
//            
//            vdot = {
//                guard let heartrate = heartrate else {return nil}
//                guard let speed = speed else {return nil}
//                guard let limits = Profile.hrLimits.value else {return nil}
//
//                return Run.train(
//                    hrBpm: heartrate,
//                    paceSecPerKm: 1000 / speed,
//                    limits: limits)
//            }()
//        }
    }
    
    // MARK: Implementation
}
