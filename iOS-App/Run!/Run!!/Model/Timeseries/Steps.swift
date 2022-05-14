//
//  Steps.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 13.04.22.
//

import Foundation
import CoreMotion
import CoreLocation

struct StepX: Codable, Identifiable, Dated {
    var date: Date {asOf}
    let id: UUID
    let isOriginal: Bool
    let asOf: Date
    
    let startDate: Date
    let endDate: Date
    let numberOfSteps: Int
    let distance: CLLocationDistance?
    let averageActiveSpeed: CLLocationSpeed?
    let currentSpeed: CLLocationSpeed?
    let currentCadence: Double?
    let metersAscended: CLLocationDistance?
    let metersDescended: CLLocationDistance?

    /// Standard init
    init(
        asOf: Date,
        startDate: Date = .distantFuture,
        endDate: Date = .distantFuture,
        numberOfSteps: Int = 0,
        distance: CLLocationDistance? = nil,
        averageActiveSpeed: CLLocationSpeed? = nil,
        currentSpeed: CLLocationSpeed? = nil,
        currentCadence: Double? = nil,
        metersAscended: CLLocationDistance? = nil,
        metersDescended: CLLocationDistance? = nil)
    {
        self.asOf = asOf
        self.id = UUID()
        self.isOriginal = false
        self.startDate = startDate
        self.endDate = endDate
        self.numberOfSteps = numberOfSteps
        self.distance = distance
        self.averageActiveSpeed = averageActiveSpeed
        self.currentSpeed = currentSpeed
        self.currentCadence = currentCadence
        self.metersAscended = metersAscended
        self.metersDescended = metersDescended
    }
    
    /// Interploate
    init(asOf: Date, s0: StepX, s1: StepX) {
        self.asOf = asOf
        isOriginal = false
        id = UUID()

        // TODO: Implement
        self.startDate = s0.startDate
        self.endDate = s1.endDate
        self.numberOfSteps = s0.numberOfSteps
        self.distance = s0.distance
        self.averageActiveSpeed = s0.averageActiveSpeed
        self.currentSpeed = s0.currentSpeed
        self.currentCadence = s0.currentCadence
        self.metersAscended = s0.metersAscended
        self.metersDescended = s0.metersDescended
    }
    
    /// Extrapolate
    init(asOf: Date, step: StepX) {
        self.asOf = asOf
        isOriginal = false
        id = UUID()
        
        // TODO: Implement
        self.startDate = step.startDate
        self.endDate = step.endDate
        self.numberOfSteps = step.numberOfSteps
        self.distance = step.distance
        self.averageActiveSpeed = step.averageActiveSpeed
        self.currentSpeed = step.currentSpeed
        self.currentCadence = step.currentCadence
        self.metersAscended = step.metersAscended
        self.metersDescended = step.metersDescended
    }

    /// Parse original from Pedometer
    init(asOf: Date, _ data: CMPedometerData) {
        self.asOf = asOf
        isOriginal = true
        id = UUID()
        
        self.startDate = data.startDate
        self.endDate = data.endDate
        self.numberOfSteps = Int(truncating: data.numberOfSteps)
        self.distance = data.distance.ifNotNull {CLLocationDistance(truncating: $0)}
        self.averageActiveSpeed = data.averageActivePace.ifNotNull {1.0 / Double(truncating: $0)}
        self.currentSpeed = data.currentPace.ifNotNull {1.0 / Double(truncating: $0)}
        self.currentCadence = data.currentCadence.ifNotNull {Double(truncating: $0)}
        self.metersAscended = data.floorsAscended.ifNotNull {Double(truncating: $0) * 3.0}
        self.metersDescended = data.floorsDescended.ifNotNull {Double(truncating: $0) * 3.0}
    }
}

extension StepX: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.asOf == rhs.asOf else {return false}
        guard lhs.isOriginal == rhs.isOriginal else {return false}
        guard lhs.numberOfSteps == rhs.numberOfSteps else {return false}
        guard lhs.distance == rhs.distance else {return false}
        guard lhs.averageActiveSpeed == rhs.averageActiveSpeed else {return false}
        guard lhs.currentSpeed == rhs.currentSpeed else {return false}
        guard lhs.currentCadence == rhs.currentCadence else {return false}
        guard lhs.metersAscended == rhs.metersAscended else {return false}
        guard lhs.metersDescended == rhs.metersDescended else {return false}
        return true
    }
}

class Steps: ObservableObject {
    // MARK: Interface
    private(set) var latestOriginal: StepX? = nil
    private(set) var steps = [StepX]() {
        didSet {
            let steps = steps
            DispatchQueue.main.async {self.stepsUI = steps}
        }
    }
    @Published private(set) var stepsUI = [StepX]()

    func appendOriginal(step: StepX) {
        // drop all from last original to end here and in isActives
        // For all seconds between last and new motion, interpolate
        // append new motion and remember as latest original
        let stepChanges = steps.replace(step, replaceAfter: (latestOriginal ?? step).date) {
            StepX(asOf: $0, step: latestOriginal ?? step)
        }
        if !stepChanges.appended.isEmpty || !stepChanges.dropped.isEmpty {isDirty = true} // Mark dirty
        
        // Notify workout and totals about appends and removes
    }

    func trigger(asOf: Date) {
        guard let last = steps.last else {return}

        // For all seconds between last and new time, extrapolate
        let extendedSteps = steps.extend(asOf) {StepX(asOf: $0, step: last)}
        
        if !extendedSteps.isEmpty {isDirty = true} // Mark dirty
        
        // Notify workout and totals about appends and removes
    }
    
    func maintain(truncateAt: Date) {
        if steps.drop(before: truncateAt).isEmpty {return}
        latestOriginal = steps.first {$0.isOriginal}
        isDirty = true
    }
    
    func save() {
        guard isDirty, let url = Files.write(steps, to: "steps.json") else {return}
        log(url)
        isDirty = false
    }
    
    /// Load and keep only last 10 minutes
    func load(asOf: Date) {
        guard let steps = Files.read(Array<StepX>.self, from: "steps.json") else {return}
        
        self.steps = steps.filter {$0.asOf.distance(to: asOf) <= signalTimeout}
        latestOriginal = self.steps.last(where: {$0.isOriginal})
        isDirty = false
    }

    // MARK: Implementation
    private var isDirty: Bool = false
}