//
//  BodySensorLocationEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 14.05.22.
//

import Foundation

struct BodySensorLocationEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "BodySensorLocationEvent"
    let vector: VectorElement<HRM.SensorLocation>
    init(_ vector: VectorElement<HRM.SensorLocation>) {self.vector = vector}

    // MARK: Implement specifics
    init(date: Date, sensorLocation: HRM.SensorLocation) {
        vector = VectorElement(date: date, categorical: sensorLocation)
    }
    
    var sensorLocation: HRM.SensorLocation {vector.categorical!}
}

extension TimeSeries where Element == BodySensorLocationEvent {
    func parse(_ asOf: Date, _ data: Data?) -> Element? {
        let result = Element(date: asOf, sensorLocation: HRM.parse(data))
        if let last = elements.last, last.sensorLocation == result.sensorLocation {return nil}
        return result
    }
}
