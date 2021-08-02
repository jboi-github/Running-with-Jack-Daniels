//
//  LocationReceiverModel.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 14.06.21.
//

import Foundation
import CoreLocation
import MapKit

/// Singleton to continiously receive Location Updates
class GpsLocationReceiver: ObservableObject {
    /// Access shared instance of this singleton
    static var sharedInstance = GpsLocationReceiver()

    public struct Velocity {
        let direction: MKCoordinateSpan // Degrees per second
        let distanceM: CLLocationDistance
        let timeInterval: TimeInterval
        let timestamp: Date
        
        init(from: CLLocation, to: CLLocation) {
            timestamp = to.timestamp
            timeInterval = to.timestamp.timeIntervalSince(from.timestamp)
            distanceM = to.distance(from: from)
            direction = MKCoordinateSpan(
                latitudeDelta: (to.coordinate.latitude - from.coordinate.latitude) / timeInterval,
                longitudeDelta: (to.coordinate.longitude - from.coordinate.longitude) / timeInterval)
        }
        
        var paceSecPerKm: TimeInterval {1000.0 * timeInterval / distanceM}
    }
    
    /// Indicates, if Receiver is still active.
    @Published public private(set) var receiving: Bool = false

    /// Indicates, if Receiver is still active.
    @Published public private(set) var localizedError: String = ""

    /// Current values
    @Published public private(set) var prevLocation: CLLocation? = nil
    @Published public private(set) var prevVelocity: Velocity? = nil
    @Published public private(set) var prevDistanceM = 0.0 // Sum of distance since start
    @Published public private(set) var region = MKCoordinateRegion()
    
    /// Current, up to the minute distance
    public var currentDistanceM: Double {
        guard let prevVelocity = prevVelocity else {return prevDistanceM}
        
        let timeElapsed = Date().timeIntervalSince(prevVelocity.timestamp)
        let deltaDistanceM = timeElapsed * prevVelocity.distanceM / prevVelocity.timeInterval
        guard deltaDistanceM.isFinite else {return prevDistanceM}
        
        return prevDistanceM + deltaDistanceM
    }
    
    /// Current, up to the minute location
    public var currentLocation: CLLocation? {
        guard let prevCoordinate = prevLocation?.coordinate else {return nil}
        guard let prevDirection = prevVelocity?.direction,
              let prevTimestamp = prevVelocity?.timestamp else
        {
            return prevLocation
        }

        let timeElapsed = Date().timeIntervalSince(prevTimestamp)
        let coordinate = CLLocationCoordinate2D(
            latitude: prevCoordinate.latitude + prevDirection.latitudeDelta * timeElapsed,
            longitude: prevCoordinate.longitude + prevDirection.longitudeDelta * timeElapsed)
        
        return prevLocation?.moveTo(coordinate: coordinate)
    }

    /// Start receiving data. Ignore any values, that have an earlier timestamp
    public func start() {
        prevLocation = nil
        prevVelocity = nil
        prevDistanceM = 0.0
        region = MKCoordinateRegion()
        
        reset()
    }
    
    /// Reset receiving data after error.
    public func reset() {
        localizedError = ""
        locationManager = CLLocationManager()
        locationManager.delegate = delegate
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.startUpdatingLocation()
    }

    /// Stop receiving data. Receiver continues to run till receiving a value, that was actually measured at or after the given end time.
    public func stop() {
        locationManager.stopUpdatingLocation()
        receiving = false
    }
    
    // MARK: Private
    
    private var locationManager: CLLocationManager!
    private var delegate = Delegate()
    
    // Setup Healthkit Store.
    private init() {}
    
    /// Smooth and add new GPS locations to the current path. Then calculate current pace and distance.
    /// - Parameter locations: new GPS locations to add to the current path.
    private func add(locations: [CLLocation]) {
        guard !locations.isEmpty else {return}
        let localLocation = locations.last
        
        DispatchQueue.global(qos: .utility).async {
            // Increment cumulated distance
            var deltaDistance = (1..<locations.count)
                .map {locations[$0 - 1].distance(from: locations[$0])}
                .reduce(0.0, +)
            if let prevLocation = self.prevLocation {deltaDistance += locations[0].distance(from: prevLocation)}
            
            // Get Velocity
            var nextVelocity:Velocity? = nil
            if let prevLocation = self.prevLocation, locations.count == 1 {
                // We got one new location and have an old one
                nextVelocity = Velocity(from: prevLocation, to: locations[0])
            } else if locations.count >= 2 {
                // We got many new locations
                nextVelocity = Velocity(from: locations[locations.count - 2], to: locations[locations.count - 1])
            }
            
            // Expand region by new locations
            let region = self.getRegion(locations)
            
            // Set published attributes
            DispatchQueue.main.async {
                self.prevDistanceM += deltaDistance
                self.region = region
                if let nextVelocity = nextVelocity {self.prevVelocity = nextVelocity}
                self.prevLocation = localLocation
            }
        }
    }
    
    private func getRegion(_ locations: [CLLocation]) -> MKCoordinateRegion {
        guard let lastLocation = locations.last,
              let minLat = locations.map({$0.coordinate.latitude}).min(),
              let maxLat = locations.map({$0.coordinate.latitude}).max(),
              let minLon = locations.map({$0.coordinate.longitude}).min(),
              let maxLon = locations.map({$0.coordinate.longitude}).max()
        else {return region}
        
        if prevLocation == nil {
            return MKCoordinateRegion(
                center: lastLocation.coordinate,
                latitudinalMeters: lastLocation.horizontalAccuracy * 2,
                longitudinalMeters: lastLocation.horizontalAccuracy * 2)
        } else {
            let minminLat = min(minLat, region.minLat)
            let maxmaxLat = max(maxLat, region.maxLat)
            let minminLon = min(minLon, region.minLon)
            let maxmaxLon = max(maxLon, region.maxLon)

            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: (minminLat + maxmaxLat) / 2.0,
                    longitude: (minminLon + maxmaxLon) / 2.0),
                span: MKCoordinateSpan(
                    latitudeDelta: (maxmaxLat - minminLat),
                    longitudeDelta: (maxmaxLon - minminLon)))
        }
    }
    
    private class Delegate: NSObject, CLLocationManagerDelegate {
        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            log("\(manager.allowsBackgroundLocationUpdates), \(manager.isAuthorizedForWidgetUpdates), \(manager.accuracyAuthorization), \(manager.authorizationStatus)")
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            _ = check(error)
            manager.stopUpdatingLocation()
            GpsLocationReceiver.sharedInstance.localizedError = error.localizedDescription
            GpsLocationReceiver.sharedInstance.stop()
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            log("\(locations.count)")
            GpsLocationReceiver.sharedInstance.receiving = true
            GpsLocationReceiver.sharedInstance.add(locations: locations)
        }
        
        func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
            log()
            GpsLocationReceiver.sharedInstance.receiving = false
        }
        
        func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {log()}
    }
}

extension CLLocation {
    /// Create copy with all fields copied over but moved to given location.
    func moveTo(coordinate: CLLocationCoordinate2D) -> CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            course: course,
            courseAccuracy: courseAccuracy,
            speed: speed,
            speedAccuracy: speedAccuracy,
            timestamp: timestamp)
    }
}

extension MKCoordinateRegion {
    var minLat: CLLocationDegrees {center.latitude - span.latitudeDelta / 2.0}
    var maxLat: CLLocationDegrees {center.latitude + span.latitudeDelta / 2.0}
    var minLon: CLLocationDegrees {center.longitude - span.longitudeDelta / 2.0}
    var maxLon: CLLocationDegrees {center.longitude + span.longitudeDelta / 2.0}
}
