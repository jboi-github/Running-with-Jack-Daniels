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
    let vector: VectorElement<Info>
    init(_ vector: VectorElement<Info>) {self.vector = vector}
    
    // MARK: Implement specifics
    struct Info: Codable, Equatable {
        let isWorkingOut: Bool
        let originalDate: Date
    }

    init(date: Date, isWorkingOut: Bool) {
        vector = VectorElement(date: date, categorical: Info(isWorkingOut: isWorkingOut, originalDate: date))
    }
    
    /// User started or stopped workout
    var isWorkingOut: Bool {vector.categorical!.isWorkingOut}
    
    /// Time when user originally started or stopped workout
    var originalDate: Date {vector.categorical!.originalDate}
}
