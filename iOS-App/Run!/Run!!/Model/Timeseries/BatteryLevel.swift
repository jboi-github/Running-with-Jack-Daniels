//
//  BatteryLevel.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 13.05.22.
//

import Foundation

struct BatteryLevel: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "com.apps4live.Run!!.BatteryLevel"
    let vector: VectorElement<None>
    init(_ vector: VectorElement<None>) {self.vector = vector}

    // MARK: Implement specifics
    init(date: Date, level: Int) {
        vector = VectorElement(date: date, ints: [level])
    }
    
    var level: Int {vector.ints[0]}
}

extension TimeSeries where Element == BatteryLevel {
    func parse(_ asOf: Date, _ data: Data?) -> Element? {
        guard let data = data, !data.isEmpty else {return nil}
        return Element(date: asOf, level: Int([UInt8](data)[0]))
    }
}
