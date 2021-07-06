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

    /// Indicates, if Receiver is still active.
    @Published public private(set) var receiving: Bool = false

    /// Indicates, if Receiver is still active.
    @Published public private(set) var localizedError: String = ""

    /// The data as it was received so far
    @Published public private(set) var rawPath = [CLLocation]()
    @Published public private(set) var smoothedPath = [CLLocation]()

    /// Current values
    @Published public private(set) var distanceM = 0.0
    @Published public private(set) var paceSecPerKm = 0

    /// Start receiving data. Ignore any values, that have an earlier timestamp
    public func start() {
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
    
    public func save() {
        print("save \(rawPath.count) path-node(s)")

        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .deferredToData
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.nonConformingFloatEncodingStrategy = .throw
        encoder.outputFormatting = .prettyPrinted
        
        // Get the data
        let codablePath = rawPath.map {
            CodableLocation(
                timestamp: $0.timestamp,
                latitude: $0.coordinate.latitude,
                longitude: $0.coordinate.longitude,
                accuracy: $0.horizontalAccuracy)
        }
        guard let id = Bundle.main.bundleIdentifier else {return}
        guard let path = FileManager
                .default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent(id) else {return}

        do {
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
            try encoder.encode(codablePath).write(
                to: path.appendingPathComponent("path", conformingTo: .json),
                options: [.atomicWrite])
            print("done")
        } catch {
            print(error)
        }
    }
    
    // MARK: Private
    
    private var locationManager: CLLocationManager!
    private var delegate = Delegate()
    
    // Setup Healthkit Store.
    private init() {}
    
    /// Smooth and add new GPS locations to the current path. Then calculate current pace and distance.
    /// - Parameter locations: new GPS locations to add to the current path.
    private func add(locations: [CLLocation]) {
        // Add to raw data
        rawPath += locations
        
        // Smooth path
        locations.forEach {appendSmoothedFoward(raw: $0)}
        distanceM = sumSmoothedDistance()
        if let paceSecPerKm = getSmoothedPace() {self.paceSecPerKm = paceSecPerKm}
    }
    
    private func appendSmoothedFoward(raw: CLLocation) {
        func extrapolate(
            p1: CLLocationDegrees, p2: CLLocationDegrees,
            t1: Date, t2: Date, t3: Date) -> CLLocationDegrees
        {
            guard t1 != t2 else {return p1}
            
            let distance12 = p2 - p1
            let deltaT12 = t1.distance(to: t2)
            let deltaT13 = t1.distance(to: t3)
            return p1 + (distance12 * deltaT13 / deltaT12)
        }

        func interpolate(
            p1: CLLocationDegrees, p2: CLLocationDegrees,
            distance12: CLLocationDistance, distance13: CLLocationDistance) -> CLLocationDegrees
        {
            p1 + (p2 - p1) * distance13 / distance12
        }

        print(" - Got raw: \(raw.coordinate.latitude), \(raw.coordinate.longitude), \(raw.horizontalAccuracy)")
        
        // First location is just added for initial value, velocity = 0
        if smoothedPath.isEmpty {
            smoothedPath.append(raw)
            print(" - was first")
            return
        }

        // Predict future position at constant velocity
        let p = smoothedPath.suffix(2)
        print(" - p got \(p.count) locs")

        let F = raw.moveTo(
            coordinate: CLLocationCoordinate2D(
                latitude: extrapolate(
                    p1: p.first!.coordinate.latitude, p2: p.last!.coordinate.latitude,
                    t1: p.first!.timestamp, t2: p.last!.timestamp, t3: raw.timestamp),
                longitude: extrapolate(
                    p1: p.first!.coordinate.longitude, p2: p.last!.coordinate.longitude,
                    t1: p.first!.timestamp, t2: p.last!.timestamp, t3: raw.timestamp)))
        print(" - F: \(F.coordinate.latitude), \(F.coordinate.longitude), \(F.horizontalAccuracy)")

        // if on path, replace last location with F incl. current timestamp
        let distanceFR = raw.distance(from: F)
        if distanceFR <= raw.horizontalAccuracy {
            print(" - F good enough. Replace last of \(smoothedPath.count) locs.")
            smoothedPath[smoothedPath.count - 1] = F
            return
        }
        
        // else, adjust to closest possible location and append
        // Closest possible location: shortest way from F to raw +- accuracy => minimal steering
        smoothedPath.append(
            raw.moveTo(
                coordinate: CLLocationCoordinate2D(
                    latitude: interpolate(
                        p1: raw.coordinate.latitude,
                        p2: F.coordinate.latitude,
                        distance12: distanceFR,
                        distance13: raw.horizontalAccuracy),
                    longitude: interpolate(
                        p1: raw.coordinate.longitude,
                        p2: F.coordinate.longitude,
                        distance12: distanceFR,
                        distance13: raw.horizontalAccuracy))))
        if let last = smoothedPath.last {
            print(" - Adjusted: \(last.coordinate.latitude), \(last.coordinate.longitude), \(last.horizontalAccuracy)")
        } else {
            print(" - Strange: Last loc disappeared???")
        }
    }
    
    private func sumSmoothedDistance() -> Double {
        var prev: CLLocation? = nil
        
        return smoothedPath
            .map {
                let dist = prev != nil ? $0.distance(from: prev!) : 0.0
                prev = $0
                return dist
            }
            .reduce(0.0, +)
    }
    
    private func getSmoothedPace() -> Int? {
        let p = smoothedPath.suffix(2)
        guard p.count == 2, let first = p.first, let last = p.last else {return nil}
        
        let distanceKm = last.distance(from: first) / 1000.0
        let timeIntervalSec = first.timestamp.distance(to: last.timestamp)
        return Int(timeIntervalSec / distanceKm + 0.5)
    }
    
    private class Delegate: NSObject, CLLocationManagerDelegate {
        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            print("locationManagerDidChangeAuthorization: \(manager.allowsBackgroundLocationUpdates), \(manager.isAuthorizedForWidgetUpdates), \(manager.accuracyAuthorization), \(manager.authorizationStatus)")
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("didFailWithError: \(error)")
            manager.stopUpdatingLocation()
            GpsLocationReceiver.sharedInstance.localizedError = error.localizedDescription
            GpsLocationReceiver.sharedInstance.stop()
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            print("didUpdateLocations: \(locations.count)")
            GpsLocationReceiver.sharedInstance.receiving = true
            GpsLocationReceiver.sharedInstance.add(locations: locations)
        }
        
        func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
            print("locationManagerDidPauseLocationUpdates")
            GpsLocationReceiver.sharedInstance.receiving = false
        }
        
        func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
            print("locationManagerDidResumeLocationUpdates")
        }
    }
    
    private struct CodableLocation: Codable {
        let timestamp: Date
        let latitude: CLLocationDegrees
        let longitude: CLLocationDegrees
        let accuracy: CLLocationAccuracy
    }
}

extension CLLocation: Identifiable {
    public var id: Date {timestamp}
    
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
