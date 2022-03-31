//
//  Locations.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 16.03.22.
//

import Foundation
import CoreLocation

struct Location: Codable, Identifiable, Dated {
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

extension Location: Equatable {
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
    init(distances: Distances, workout: Workout, totals: Totals) {
        self.distances = distances
        self.workout = workout
        self.totals = totals
   }
    
    // MARK: Interface
    var latestOriginal: Location? {locations.last}
    private(set) var locations = [Location]()

    func appendOriginal(location: Location) {
        // For all seconds between last and new location, interpolate distances
        let changedDistances = distances.replace(l0: latestOriginal, l1: location)
        
        // append new location
        locations.append(location)
        isDirty = true // Mark dirty
        
        // Notify workout about appends and removes
        workout.changed(distances: changedDistances.appended, changedDistances.dropped)
        workout.append(location)
        totals.changed(distances: changedDistances.appended, changedDistances.dropped)
    }

    func maintain(truncateAt: Date) {
        if locations.drop(before: truncateAt).isEmpty {return}
        isDirty = true
        distances.maintain(truncateAt: truncateAt)
    }

    func save() {
        guard isDirty, let url = Files.write(locations, to: "locations.json") else {return}

        log(url)
        isDirty = false
    }
    
    func load() {
        guard let locations = Files.read(Array<Location>.self, from: "locations.json") else {return}
        
        self.locations = locations
        isDirty = false
    }

    // MARK: Implementation
    private var isDirty: Bool = false
    private unowned let distances: Distances
    private unowned let workout: Workout
    private unowned let totals: Totals
}
