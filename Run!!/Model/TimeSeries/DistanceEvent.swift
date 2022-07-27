//
//  DistanceEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 14.05.22.
//

import Foundation
import CoreLocation

struct DistanceEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "DistanceEvent"
    let vector: VectorElement<None>
    init(_ vector: VectorElement<None>) {self.vector = vector}

    // MARK: Implement specifics
    init(date: Date, distance: CLLocationDistance) {
        vector = VectorElement(date: date, doubles: [distance])
    }
    
    /// Total distance since beginning of time in meter
    var distance: CLLocationDistance {vector.doubles![0]}
    
    static func distance(_ delta: VectorElementDelta?) -> CLLocationDistance? {delta?.doubles![0]}
}

extension TimeSeries where Element == DistanceEvent {
    func parse(_ location: CLLocation, _ prevLocation: CLLocation?) -> [Element] {
        guard let prevLocation = prevLocation else {return []}
        let distance: CLLocationDistance = location.distance(from: prevLocation)

        var result = [Element]()
        if let last = elements.last, last.date != prevLocation.timestamp {
            result.append(last.extrapolate(at: prevLocation.timestamp))
        }
        result.append(
            Element(
                date: location.timestamp,
                distance: distance + (elements.last?.distance ?? 0)))
        return result
    }
}
