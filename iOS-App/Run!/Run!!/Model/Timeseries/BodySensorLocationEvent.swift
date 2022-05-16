//
//  BodySensorLocationEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 14.05.22.
//

import Foundation

struct BodySensorLocationEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "com.apps4live.Run!!.BodySensorLocationEvent"
    let vector: VectorElement<SensorLocation>
    init(_ vector: VectorElement<SensorLocation>) {self.vector = vector}

    // MARK: Implement specifics
    enum SensorLocation: UInt8, Codable {
        case other, chest, wrist, finger, hand, earLobe, foot
    }
    
    init(date: Date, sensorLocation: SensorLocation) {
        vector = VectorElement(date: date, categorical: sensorLocation)
    }
    
    var sensorLocation: SensorLocation {vector.categorical}
}

extension TimeSeries where Element == BodySensorLocationEvent {
    func parse(_ asOf: Date, _ data: Data?) -> Element? {
        guard let data = data, !data.isEmpty else {return nil}
        return Element(
            date: asOf,
            sensorLocation: BodySensorLocationEvent.SensorLocation(rawValue: [UInt8](data)[0]) ?? .other)
    }
}
