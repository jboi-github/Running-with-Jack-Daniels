//
//  PathEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 24.06.22.
//

import Foundation
import CoreLocation
import SwiftUI
import MapKit

struct PathEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "PathEvent"
    var vector: VectorElement<Run.Intensity>
    init(_ vector: VectorElement<Run.Intensity>) {self.vector = vector}

    // MARK: Implement specifics
    init(
        date: Date,
        midPoint: CLLocationCoordinate2D,
        accuracyRadius: CLLocationDegrees,
        speedMinRadius: CLLocationDegrees,
        speedMaxRadius: CLLocationDegrees,
        courseMinAngle: CLLocationDirection,
        courseMaxAngle: CLLocationDirection,
        intensity: IntensityEvent?)
    {
        vector = VectorElement(
            date: date,
            doubles: [
                midPoint.latitude,
                midPoint.longitude,
                accuracyRadius,
                speedMinRadius,
                speedMaxRadius,
                courseMinAngle,
                courseMaxAngle
            ],
            categorical: intensity?.intensity)
    }

    var midPoint: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: vector.doubles![0],
            longitude: vector.doubles![1])
    }
    
    var accuracyRadius: CLLocationDegrees {vector.doubles![2]}
    var speedMinRadius: CLLocationDegrees {vector.doubles![3]}
    var speedMaxRadius: CLLocationDegrees {vector.doubles![4]}
    var courseMinAngle: CLLocationDirection {vector.doubles![5]}
    var courseMaxAngle: CLLocationDirection {vector.doubles![6]}

    var intensity: Run.Intensity? {
        get { vector.categorical }
        set { vector.categorical = newValue }
    }
}

extension TimeSeries where Element == PathEvent {
    func parse(_ location: LocationEvent, _ intensity: IntensityEvent?) -> Element {
        let midPoint = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude)
        
        let accuracyRadius = MKCoordinateRegion(
            center: midPoint,
            latitudinalMeters: location.horizontalAccuracy,
            longitudinalMeters: location.horizontalAccuracy)
            .span
        
        let speedMinRadius = MKCoordinateRegion(
            center: midPoint,
            latitudinalMeters: location.speed - location.speedAccuracy,
            longitudinalMeters: location.speed - location.speedAccuracy)
            .span
        
        let speedMaxRadius = MKCoordinateRegion(
            center: midPoint,
            latitudinalMeters: location.speed + location.speedAccuracy,
            longitudinalMeters: location.speed + location.speedAccuracy)
            .span

        return PathEvent(
            date: location.date,
            midPoint: midPoint,
            accuracyRadius: accuracyRadius.latitudeDelta,
            speedMinRadius: speedMinRadius.latitudeDelta,
            speedMaxRadius: speedMaxRadius.latitudeDelta,
            courseMinAngle: location.course - location.courseAccuracy,
            courseMaxAngle: location.course - location.courseAccuracy,
            intensity: intensity)
    }
    
    func reflect(_ intensity: IntensityEvent) {
        // Insert a new Path element at intensity change
        guard var element = self[intensity.date] else {return}
        element.intensity = intensity.intensity
        insert(element)
        
        // Change all path elements after intensity event to new intensity.
        // Note: there cannot be another intensity later then this one
        elements
            .indices
            .suffix { elements[$0].date > intensity.date }
            .forEach { self[$0]?.intensity = intensity.intensity }
    }
}
