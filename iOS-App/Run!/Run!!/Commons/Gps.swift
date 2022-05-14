//
//  gps.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 02.04.22.
//

import Foundation
import MapKit

extension MKCoordinateRegion {
    init(location: LocationX, radiusFactor: Double = 2.0) {
        self.init(
            center: CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude),
            latitudinalMeters: location.horizontalAccuracy * radiusFactor,
            longitudinalMeters: location.horizontalAccuracy * radiusFactor)
    }
    
    func union(_ other: Self) -> Self {
        let minLatitude = min(center.latitude - span.latitudeDelta / 2, other.center.latitude - other.span.latitudeDelta / 2)
        let minLongitude = min(center.longitude - span.longitudeDelta / 2, other.center.longitude - other.span.longitudeDelta / 2)
        let maxLatitude = max(center.latitude + span.latitudeDelta / 2, other.center.latitude + other.span.latitudeDelta / 2)
        let maxLongitude = max(center.longitude + span.longitudeDelta / 2, other.center.longitude + other.span.longitudeDelta / 2)

        return Self(
            center: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2),
            span: MKCoordinateSpan(
                latitudeDelta: maxLatitude - minLatitude,
                longitudeDelta: maxLongitude - minLongitude))
    }
}

extension MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        guard lhs.center.latitude == rhs.center.latitude else {return false}
        guard lhs.center.longitude == rhs.center.longitude else {return false}
        guard lhs.span.latitudeDelta == rhs.span.latitudeDelta else {return false}
        guard lhs.span.longitudeDelta == rhs.span.longitudeDelta else {return false}
        return true
    }
}
