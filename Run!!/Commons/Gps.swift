//
//  gps.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 02.04.22.
//

import Foundation
import MapKit

extension MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        guard lhs.center.latitude == rhs.center.latitude else {return false}
        guard lhs.center.longitude == rhs.center.longitude else {return false}
        guard lhs.span.latitudeDelta == rhs.span.latitudeDelta else {return false}
        guard lhs.span.longitudeDelta == rhs.span.longitudeDelta else {return false}
        return true
    }
}
