//
//  Motions.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 16.03.22.
//

import Foundation
import CoreMotion

enum MotionType: String, Codable {
    case unknown, walking, running, cycling
    case pause, invalid
}

struct Motion: Codable, Identifiable, Dated {
    var date: Date {asOf}    
    let id: UUID 
    let asOf: Date
    let motion: MotionType
    let isOriginal: Bool
    
    init(asOf: Date, motion: MotionType) {
        self.asOf = asOf
        self.motion = motion
        self.isOriginal = false
        self.id = UUID()
    }
    
    /// Parse CoreMotion activity
    init(_ motionActivity: CMMotionActivity) {
        asOf = motionActivity.startDate
        motion = Motion.parse(motionActivity)
        isOriginal = true
        self.id = UUID()
    }
    
    /// Interpolate and extrapolate
    init(asOf: Date, motion: Motion) {
        self.asOf = asOf
        self.motion = motion.motion
        isOriginal = false
        self.id = UUID()
    }
    
    private static func parse(_ motionActivity: CMMotionActivity) -> MotionType {
        if motionActivity.stationary {return .pause}
        if motionActivity.walking {return .walking}
        if motionActivity.running {return .running}
        if motionActivity.cycling {return .cycling}
        return .unknown
    }
}

extension Motion: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.asOf == rhs.asOf else {return false}
        guard lhs.motion == rhs.motion else {return false}
        guard lhs.isOriginal == rhs.isOriginal else {return false}
        return true
    }
}

class Motions {
    // MARK: Initialization
    init(isActives: IsActives, workout: Workout, totals: Totals) {
        self.isActives = isActives
        self.workout = workout
        self.totals = totals
    }
    
    // MARK: Interface
    private(set) var latestOriginal: Motion? = nil
    private(set) var motions = [Motion]()

    func appendOriginal(motion: Motion) {
        // drop all from last original to end here and in isActives
        // For all seconds between last and new motion, interpolate
        // append new motion and remember as latest original
        let motionChanges = motions.replace(motion, replaceAfter: (latestOriginal ?? motion).date) {
            Motion(asOf: $0, motion: latestOriginal ?? motion)
        }
        if !motionChanges.appended.isEmpty || !motionChanges.dropped.isEmpty {isDirty = true} // Mark dirty
        
        let isActiveChanges = isActives.replace(motions: motionChanges.appended, replaceAfter: (latestOriginal ?? motion).date)
        latestOriginal = motion
        
        // Notify workout and totals about appends and removes
        workout.changed(isActives: isActiveChanges.appended, isActiveChanges.dropped)
        workout.changed(motions: motionChanges.appended, motionChanges.dropped)
        totals.changed(motions: motionChanges.appended, motionChanges.dropped, isActiveChanges.appended, isActiveChanges.dropped)
    }

    func trigger(asOf: Date) {
        guard let last = motions.last else {return}

        // For all seconds between last and new time, extrapolate
        let extendedMotions = motions.extend(asOf) {Motion(asOf: $0, motion: last)}
        let isActiveChanges = isActives.replace(motions: extendedMotions) // Every new motion creates a new isActive and appends it
        
        if !extendedMotions.isEmpty {isDirty = true} // Mark dirty
        
        // Notify workout and totals about appends and removes
        workout.changed(isActives: isActiveChanges.appended, isActiveChanges.dropped)
        totals.changed(motions: extendedMotions, [], isActiveChanges.appended, isActiveChanges.dropped)
    }
    
    func maintain(truncateAt: Date) {
        if motions.drop(before: truncateAt).isEmpty {return}
        latestOriginal = motions.first {$0.isOriginal}
        isDirty = true
        isActives.maintain(truncateAt: truncateAt)
    }
    
    func save() {
        guard isDirty, let url = Files.write(motions, to: "motions.json") else {return}
        log(url)
        isDirty = false
    }
    
    func load() {
        guard let motions = Files.read(Array<Motion>.self, from: "motions.json") else {return}
        
        self.motions = motions
        latestOriginal = motions.last(where: {$0.isOriginal})
        isDirty = false
    }

    // MARK: Implementation
    private var isDirty: Bool = false
    private unowned let isActives: IsActives
    private unowned let workout: Workout
    private unowned let totals: Totals
}
