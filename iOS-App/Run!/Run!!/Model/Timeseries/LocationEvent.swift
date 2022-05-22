//
//  LocationEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 14.05.22.
//

import Foundation
import CoreLocation

struct LocationEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "LocationEvent"
    let vector: VectorElement<None>
    init(_ vector: VectorElement<None>) {self.vector = vector}

    // MARK: Implement specifics
    init(
        date: Date,
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        altitude: CLLocationDistance,
        ellipsoidalAltitude: CLLocationDistance,
        floor: CLFloor?,
        horizontalAccuracy: CLLocationAccuracy,
        verticalAccuracy: CLLocationAccuracy,
        speed: CLLocationSpeed,
        speedAccuracy: CLLocationSpeedAccuracy,
        course: CLLocationDirection,
        courseAccuracy: CLLocationDirectionAccuracy)
    {
        vector = VectorElement(
            date: date,
            doubles: [latitude, longitude, altitude, ellipsoidalAltitude, horizontalAccuracy, verticalAccuracy, speed, speedAccuracy, course, courseAccuracy],
            optionalInts: [floor?.level])
    }
    
    var latitude: CLLocationDegrees {vector.doubles[0]}
    var longitude: CLLocationDegrees {vector.doubles[1]}
    var altitude: CLLocationDistance {vector.doubles[2]}
    var ellipsoidalAltitude: CLLocationDistance {vector.doubles[3]}
    var floor: Int? {vector.optionalInts[0]}
    var horizontalAccuracy: CLLocationAccuracy {vector.doubles[4]}
    var verticalAccuracy: CLLocationAccuracy {vector.doubles[5]}
    var speed: CLLocationSpeed {vector.doubles[6]}
    var speedAccuracy: CLLocationSpeedAccuracy {vector.doubles[7]}
    var course: CLLocationDirection {vector.doubles[8]}
    var courseAccuracy: CLLocationDirectionAccuracy {vector.doubles[9]}
    
    var clLocation: CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude),
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            course: course,
            courseAccuracy: courseAccuracy,
            speed: speed,
            speedAccuracy: speedAccuracy,
            timestamp: vector.date)
    }
}

extension TimeSeries where Element == LocationEvent {
    func parse(_ location: CLLocation) -> Element {
        Element(
            date: location.timestamp,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            ellipsoidalAltitude: location.ellipsoidalAltitude,
            floor: location.floor,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: location.verticalAccuracy,
            speed: location.speed,
            speedAccuracy: location.speedAccuracy,
            course: location.course,
            courseAccuracy: location.courseAccuracy)
    }
}
