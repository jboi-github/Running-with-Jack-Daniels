//
//  Locations.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 16.03.22.
//

import Foundation
import CoreLocation

struct LocationX: Codable, Identifiable, Dated {
    var date: Date {timestamp}
    let id: UUID
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let altitude: CLLocationDistance
    let horizontalAccuracy: CLLocationAccuracy
    let verticalAccuracy: CLLocationAccuracy
    let course: CLLocationDirection
    let courseAccuracy: CLLocationDirectionAccuracy
    let speed: CLLocationSpeed
    let speedAccuracy: CLLocationSpeedAccuracy
    let timestamp: Date
    
    /// Parse CoreLocation location
    init(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        altitude = location.altitude
        horizontalAccuracy = location.horizontalAccuracy
        verticalAccuracy = location.verticalAccuracy
        course = location.course
        courseAccuracy = location.courseAccuracy
        speed = location.speed
        speedAccuracy = location.speedAccuracy
        timestamp = location.timestamp
        id = UUID()
    }
    
    var asCLLocation: CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude),
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            course: course,
            courseAccuracy: courseAccuracy,
            speed: speed,
            speedAccuracy: speedAccuracy,
            timestamp: timestamp)
    }
}

extension LocationX: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.timestamp == rhs.timestamp else {return false}
        guard lhs.latitude == rhs.latitude else {return false}
        guard lhs.longitude == rhs.longitude else {return false}
        guard lhs.altitude == rhs.altitude else {return false}
        return true
    }
}

class Locations {
    // MARK: Initialization
    init(distances: Distances, workout: Workout) {
        self.distances = distances
        self.workout = workout
   }
    
    // MARK: Interface
    var latestOriginal: LocationX? {locations.last}
    private(set) var locations = [LocationX]()

    func appendOriginal(location: LocationX) {
        // For all seconds between last and new location, interpolate distances
        let changedDistances = distances.replace(l0: latestOriginal, l1: location)
        
        // append new location
        locations.append(location)
        isDirty = true // Mark dirty
        
        // Notify workout about appends and removes
        workout.changed(distances: changedDistances.appended, changedDistances.dropped)
        workout.append(location)
    }

    func maintain(truncateAt: Date) {
        if locations.drop(before: truncateAt).isEmpty {return}
        isDirty = true
    }

    func save() {
        guard isDirty, let url = Files.write(locations, to: "locations.json") else {return}

        log(url)
        isDirty = false
    }
    
    func load(asOf: Date) {
        guard let locations = Files.read(Array<LocationX>.self, from: "locations.json") else {return}
        
        self.locations = locations.filter {$0.date.distance(to: asOf) <= signalTimeout}
        isDirty = false
    }

    // MARK: Implementation
    private var isDirty: Bool = false
    private unowned let distances: Distances
    private unowned let workout: Workout
}
