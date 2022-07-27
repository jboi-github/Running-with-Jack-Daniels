//
//  BatteryLevelEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 13.05.22.
//

import Foundation

struct BatteryLevelEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "BatteryLevelEvent"
    let vector: VectorElement<None>
    init(_ vector: VectorElement<None>) {self.vector = vector}

    // MARK: Implement specifics
    init(date: Date, level: Int) {
        vector = VectorElement(date: date, ints: [level])
    }
    
    var level: Int {vector.ints![0]}
}

extension TimeSeries where Element == BatteryLevelEvent {
    func parse(_ asOf: Date, _ data: Data?) -> Element? {
        guard let level: Int = HRM.parse(data) else {return nil}
        let result = Element(date: asOf, level: level)
        
        if let last = elements.last, last.level == result.level {return nil}
        return result
    }
}
