//
//  SpeedProducer.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import Foundation
import CoreLocation
import MapKit

class SpeedProducer {
    struct Speed {
        let timestamp: Date
        let speedMperSec: CLLocationSpeed
        let speedDegreesPerSec: MKCoordinateSpan
        
        static let zero = Self(
            timestamp: .distantPast,
            speedMperSec: 0,
            speedDegreesPerSec: MKCoordinateSpan())
    }
    
    private var prev: CLLocation? = nil
    private var speed: ((Speed) -> Void)?
    
    func start(speed: @escaping (Speed) -> Void) {
        prev = nil
        self.speed = speed
    }
    
    /// To be used by dispatcher to connect to `GpsProducer`
    func location(_ curr: CLLocation) {
        defer {prev = curr}
        guard let prev = prev else {return}
        
        let distanceM = curr.distance(from: prev)
        let durationSec = prev.timestamp.distance(to: curr.timestamp)
        let speedMperSec = distanceM / durationSec
        let speedDegreesPerSec = MKCoordinateSpan(
            latitudeDelta: (curr.coordinate.latitude - prev.coordinate.latitude) / durationSec,
            longitudeDelta: (curr.coordinate.longitude - prev.coordinate.longitude) / durationSec)

        let speed = Speed(
            timestamp: prev.timestamp,
            speedMperSec: speedMperSec,
            speedDegreesPerSec: speedDegreesPerSec)
        self.speed?(speed)
    }
}
