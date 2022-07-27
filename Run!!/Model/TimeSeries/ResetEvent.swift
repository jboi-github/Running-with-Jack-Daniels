//
//  ResetEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 14.05.22.
//

import Foundation

struct ResetEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "ResetEvent"
    var vector: VectorElement<Date>
    init(_ vector: VectorElement<Date>) {self.vector = vector}
    
    // MARK: Implement specifics
    init(date: Date) {
        vector = VectorElement(date: date, categorical: date)
    }
    
    /// Time when user originally switched to next reset
    var originalDate: Date {vector.categorical!}
}
