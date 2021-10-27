//
//  SpeedEventProducer.swift
//  RunEnricherKit
//
//  Created by Jürgen Boiselle on 26.10.21.
//

import Foundation
import MapKit
import Combine
import RunReceiversKit

struct SpeedEvent {
    let speedMperSec: CLLocationSpeed
    let speedDegreesPerSec: MKCoordinateSpan
    let timestamp: Date
    
    static var zero: SpeedEvent = SpeedEvent(
        speedMperSec: 0,
        speedDegreesPerSec: MKCoordinateSpan(),
        timestamp: .distantPast)
    
    static func fromLocations(_ prev: CLLocation, _ curr: CLLocation) -> SpeedEvent {
        guard prev.timestamp > .distantPast, prev.timestamp < curr.timestamp else {
            return SpeedEvent(
                speedMperSec: 0,
                speedDegreesPerSec: MKCoordinateSpan(),
                timestamp: curr.timestamp)
        }
        
        let distanceM = curr.distance(from: prev)
        let durationSec = prev.timestamp.distance(to: curr.timestamp)
        let speed = distanceM / durationSec
        let speedDegrees = MKCoordinateSpan(
            latitudeDelta: (curr.coordinate.latitude - prev.coordinate.latitude) / durationSec,
            longitudeDelta: (curr.coordinate.longitude - prev.coordinate.longitude) / durationSec)

        return SpeedEvent(
            speedMperSec: speed,
            speedDegreesPerSec: speedDegrees,
            timestamp: prev.timestamp)
    }
    
    static var producer: AnyPublisher<SpeedEvent, Never> {
        ReceiverService
            .sharedInstance
            .locationValues
            .scan((s: SpeedEvent.zero, l: CLLocation())) {
                (s: SpeedEvent.fromLocations($0.l, $1), l: $1)
            }
            .map {$0.s}
            .share()
            .eraseToAnyPublisher()
    }
}
