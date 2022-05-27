//
//  WorkoutEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 14.05.22.
//

import Foundation

struct WorkoutEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "WorkoutEvent"
    let vector: VectorElement<Bool>
    init(_ vector: VectorElement<Bool>) {self.vector = vector}

    // MARK: Implement specifics
    init(date: Date, isWorkingOut: Bool) {
        vector = VectorElement(date: date, categorical: isWorkingOut)
    }
    
    /// Pedometer recognized resumed or paused acitivity
    var isWorkingOut: Bool {vector.categorical!}
}
