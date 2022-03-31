//
//  Distances.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 17.03.22.
//

import Foundation
import CoreLocation
import MapKit

struct Distance: Codable, Identifiable, Dated {
    var date: Date {asOf}
    let id: UUID
    let asOf: Date
    let speed: CLLocationSpeed
    
    init(asOf: Date, speed: CLLocationSpeed) {
        self.asOf = asOf
        self.speed = speed
        id = UUID()
    }
    
    /// Extrapolation
    init(asOf: Date, d0: Distance) {
        self.asOf = asOf
        speed = d0.speed
        id = UUID()
    }
    
    /// Interpolation
    static func speed(l0: Location, l1: Location) -> CLLocationSpeed {
        l1.asCLLocation.distance(from: l0.asCLLocation) / l0.timestamp.distance(to: l1.timestamp)
    }
}

extension Distance: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.asOf == rhs.asOf else {return false}
        guard lhs.speed == rhs.speed else {return false}
        return true
    }
}

class Distances {
    // MARK: Initialization
    init(workout: Workout, totals: Totals) {
        self.workout = workout
        self.totals = totals
    }
    
    // MARK: Interface
    private(set) var distances = [Distance]()
    
    func replace(l0: Location?, l1: Location) -> (dropped: [Distance], appended: [Distance]) {
        guard let l0 = l0 else {
            let distance = Distance(asOf: l1.timestamp, speed: 0)
            distances.append(distance)
            isDirty = true
            return ([], [distance])
        }
        
        let speed = Distance.speed(l0: l0, l1: l1)
        let changes = distances.replace(Distance(asOf: l1.timestamp, speed: speed), replaceAfter: l0.timestamp) {Distance(asOf: $0, speed: speed)}
        if !changes.dropped.isEmpty || !changes.appended.isEmpty {isDirty = true} // mark dirty
        return changes
    }
    
    func trigger(asOf: Date) {
        guard let last = distances.last else {return}

        // For all seconds between last and new time, extrapolate
        let appended = distances.extend(asOf) {Distance(asOf: $0, d0: last)}
        if !appended.isEmpty {isDirty = true} // Mark dirty
        
        // Notify workout and totals about appends and removes
        workout.changed(distances: appended, [])
        totals.changed(distances: appended, [])

        // TODO: If GpsTwin is .notA*, read from step counter as second best source
    }
    
    func maintain(truncateAt: Date) {
        if !distances.drop(before: truncateAt).isEmpty {isDirty = true}
    }

    func save() {
        guard isDirty, let url = Files.write(distances, to: "distances.json") else {return}
        
        log(url)
        isDirty = false
    }
    
    func load() {
        guard let distances = Files.read(Array<Distance>.self, from: "distances.json") else {return}
        
        self.distances = distances
        isDirty = false
    }

    // MARK: Implementation
    private var isDirty = false
    private unowned let workout: Workout
    private unowned let totals: Totals
}
