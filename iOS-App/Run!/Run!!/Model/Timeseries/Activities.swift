//
//  Activities.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 16.04.22.
//

import Foundation
import CoreMotion

struct ActivityX: Codable, Identifiable, Dated {
    var date: Date {asOf}
    let id: UUID
    let asOf: Date
    let isActive: Bool
    let isOriginal: Bool
    
    /// Standard
    init(asOf: Date, isActive: Bool, isOriginal: Bool = false) {
        self.id = UUID()
        self.asOf = asOf
        self.isActive = isActive
        self.isOriginal = isOriginal
    }
    
    /// Interpolate and extrapolate
    init(asOf: Date, activity: ActivityX) {
        self.init(asOf: asOf, isActive: activity.isActive)
    }
    
    /// Parse
    init(_ pedometerEvent: CMPedometerEvent) {
        self.init(asOf: pedometerEvent.date, isActive: pedometerEvent.type == .resume, isOriginal: true)
    }
}

extension ActivityX: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.asOf == rhs.asOf else {return false}
        guard lhs.isActive == rhs.isActive else {return false}
        return true
    }
}

class Activities: ObservableObject {
    // MARK: Initialize
    init(workout: WorkoutX) {
        self.workout = workout
    }
    
    // MARK: Interface
    private(set) var latestOriginal: ActivityX? = nil
    private(set) var activities = [ActivityX]() {
        didSet {
            let activities = activities
            DispatchQueue.main.async {self.activitiesUI = activities}
        }
    }
    @Published private(set) var activitiesUI = [ActivityX]()
    
    func appendOriginal(activity: ActivityX) {
        // drop all from last original to end here and in isActives
        // For all seconds between last and new motion, interpolate
        // append new motion and remember as latest original
        let activityChanges = activities.replace(activity, replaceAfter: (latestOriginal ?? activity).date) {
            ActivityX(asOf: $0, activity: latestOriginal ?? activity)
        }
        if !activityChanges.appended.isEmpty || !activityChanges.dropped.isEmpty {isDirty = true} // Mark dirty
        
        latestOriginal = activity
        
        // Notify workout and totals about appends and removes
        workout.changed(activities: activityChanges.appended, activityChanges.dropped)
    }

    func trigger(asOf: Date) {
        guard let last = activities.last else {return}

        // For all seconds between last and new time, extrapolate
        let extendedActivities = activities.extend(asOf) {ActivityX(asOf: $0, activity: last)}
        if !extendedActivities.isEmpty {isDirty = true} // Mark dirty
        
        // Notify workout and totals about appends and removes
        workout.changed(activities: extendedActivities, [])
    }
    
    func maintain(truncateAt: Date) {
        if activities.drop(before: truncateAt).isEmpty {return}
        latestOriginal = activities.first {$0.isOriginal}
        isDirty = true
    }
    
    func save() {
        guard isDirty, let url = Files.write(activities, to: "activities.json") else {return}
        log(url)
        isDirty = false
    }
    
    func load(asOf: Date) {
        guard let activities = Files.read(Array<ActivityX>.self, from: "activities.json") else {return}
        
        self.activities = activities.filter {$0.asOf.distance(to: asOf) <= signalTimeout}
        latestOriginal = self.activities.last(where: {$0.isOriginal})
        isDirty = false
    }

    // MARK: Implementation
    private var isDirty = false
    private unowned let workout: WorkoutX
}
