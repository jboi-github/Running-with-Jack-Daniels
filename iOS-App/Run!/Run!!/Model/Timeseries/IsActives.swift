//
//  IsActives.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 17.03.22.
//

import Foundation

struct IsActive: Codable, Identifiable, Dated {
    var date: Date {asOf}
    let id: UUID
    let asOf: Date
    let isActive: Bool
    
    /// Parse Motion from AclTwin if AclTwin works as expected (available and allowed)
    init(_ motion: Motion) {
        asOf = motion.asOf
        isActive = [.walking, .running, .cycling, .invalid].contains(motion.motion)
        id = UUID()
    }
    
    /// Create if AclTwin is either not available or not allowed -> User is always active when timer is active.
    init(asOf: Date, isActive: Bool) {
        self.asOf = asOf
        self.isActive = isActive
        id = UUID()
    }
}

extension IsActive: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.asOf == rhs.asOf else {return false}
        guard lhs.isActive == rhs.isActive else {return false}
        return true
    }
}

class IsActives {
    // MARK: Initialize
    init(workout: Workout) {
        self.workout = workout
    }
    
    // MARK: Interface
    private(set) var isActives = [IsActive]()
    
    func replace(motions: [Motion], replaceAfter: Date = .distantFuture) -> (dropped: [IsActive], appended: [IsActive]) {
        let changes = isActives.replace(motions, replaceAfter: replaceAfter) {IsActive($0)}
        if !changes.dropped.isEmpty || !changes.appended.isEmpty {isDirty = true} // mark dirty
        
        // Notify workout
        changes.appended.forEach {
            if $0.isActive {
                workout.start(asOf: $0.asOf)
            } else {
                workout.pause(asOf: $0.asOf)
            }
        }
        return changes
    }
    
    func maintain(truncateAt: Date) {
        if !isActives.drop(before: truncateAt).isEmpty {isDirty = true}
    }
    
    func save() {
        guard isDirty, let url = Files.write(isActives, to: "isActives.json") else {return}
        log(url)
        isDirty = false
    }
    
    func load(asOf: Date) {
        guard let isActives = Files.read(Array<IsActive>.self, from: "isActives.json") else {return}
        self.isActives = isActives.filter {$0.date.distance(to: asOf) <= signalTimeout}
        isDirty = false
    }

    // MARK: Implementation
    private var isDirty = false
    private unowned let workout: Workout
}
