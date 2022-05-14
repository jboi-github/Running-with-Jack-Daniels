//
//  LocationClient.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 27.04.22.
//

import Foundation
import CoreLocation

final class LocationClient: ClientDelegate {
    weak var client: Client<LocationClient>?
    
    private var locationManager: CLLocationManager?
    private var locationManagerDelegate: LocationManagerDelegate?
    private var prev: CLLocation?
    private unowned let queue: DispatchQueue
    
    init(queue: DispatchQueue) {
        self.queue = queue
    }

    func start(asOf: Date) -> ClientStatus {
        locationManager = CLLocationManager()
        locationManagerDelegate = LocationManagerDelegate(
            value: { l in
                self.queue.async {
                    defer {self.prev = l}
                    let msg = "\(asOf.timeIntervalSinceReferenceDate)\t\(Date.now.timeIntervalSinceReferenceDate)\t\(l.timestamp.timeIntervalSinceReferenceDate)\t\(l.coordinate.latitude)\t\(l.coordinate.longitude)\t\(l.altitude)\t\(l.ellipsoidalAltitude)\t\(l.floor?.level ?? 0)\t\(l.horizontalAccuracy)\t\(l.verticalAccuracy)\t\(l.speed)\t\(l.speedAccuracy)\t\(l.course)\t\(l.courseAccuracy)\t\(l.distance(from: self.prev ?? l))\n"
                    Files.append(msg, to: "locationX.txt")
                    DispatchQueue.main.async {self.client?.counter += 1} 
                }
            },
            status: { status in DispatchQueue.main.async {self.client?.statusChanged(to: status)}},
            asOf: asOf)

        guard let locationManager = locationManager, let locationManagerDelegate = locationManagerDelegate else {
            return .notAvailable(since: asOf)
        }
        locationManager.delegate = locationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        locationManager.activityType = .fitness
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        
        return locationManagerDelegate.authorization(locationManager)
    }
    
    func stop(asOf: Date) {
        locationManager?.stopUpdatingLocation()
        locationManager = nil
        locationManagerDelegate = nil
    }

    // MARK: CLLocationManagerDelegate implementation
    private class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
        private let value: (CLLocation) -> Void
        private let status: (ClientStatus) -> Void
        private var startedAt: Date

        init(
            value: @escaping (CLLocation) -> Void,
            status: @escaping (ClientStatus) -> Void,
            asOf: Date)
        {
            self.value = value
            self.status = status
            startedAt = asOf
        }
        
        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            log(manager.allowsBackgroundLocationUpdates,
                manager.isAuthorizedForWidgetUpdates,
                manager.accuracyAuthorization,
                manager.authorizationStatus)
            
            status(authorization(manager))
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            check(error)
            status(.notAvailable(since: startedAt))
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            log(locations.count)
            locations
                .filter {$0.timestamp >= startedAt && $0.horizontalAccuracy >= 0}
                .forEach {
                    log($0.timestamp)
                    value($0)
                }
        }
        
        // Detect pauses based on acceleration and motion detection
        func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {log()}
        
        // Will set `receiving` to true, when first location is received.
        func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {log()}
        
        func authorization(_ manager: CLLocationManager) -> ClientStatus {
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
                return .notAvailable(since: startedAt)
            case .authorizedAlways, .authorizedWhenInUse:
                manager.startUpdatingLocation()
                return .started(since: startedAt)
            case .restricted, .denied:
                return .notAllowed(since: startedAt)
            @unknown default:
                check("unknown default")
                return .notAvailable(since: startedAt)
            }
        }
    }
}
