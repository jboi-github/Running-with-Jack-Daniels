//
//  PedometerEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 13.05.22.
//

import Foundation
import CoreMotion

struct PedometerEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "PedometerEvent"
    let vector: VectorElement<Bool>
    init(_ vector: VectorElement<Bool>) {self.vector = vector}

    // MARK: Implement specifics
    init(date: Date, isActive: Bool) {
        vector = VectorElement(date: date, categorical: isActive)
    }
    
    /// Pedometer recognized resumed or paused acitivity
    var isActive: Bool {vector.categorical}
}

extension TimeSeries where Element == PedometerEvent {
    func parse(_ pedometerEvent: CMPedometerEvent) -> Element {
        Element(date: pedometerEvent.date, isActive: pedometerEvent.type == .resume)
    }
}
