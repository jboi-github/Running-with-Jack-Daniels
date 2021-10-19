//
//  GpsLocationRecorder.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 05.08.21.
//

import CoreLocation
import RunFoundationKit

class GpsReceiver: ReceiverProtocol {
    typealias Value = CLLocation

    private var locationManager: CLLocationManager?
    private var locationManagerDelegate: CLLocationManagerDelegate?

    private let value: (CLLocation) -> Void
    private let failed: (Error) -> Void

    required init(value: @escaping (CLLocation) -> Void, failed: @escaping (Error) -> Void) {
        self.value = value
        self.failed = failed
    }
    
    func start() {
        (locationManager, locationManagerDelegate) = LocationManagerDelegate
            .configure(value: value, failed: failed)
        locationManager?.startUpdatingLocation()
    }
    
    func stop() {
        locationManager?.stopUpdatingLocation()
    }
    
    static func isDuplicate(lhs: CLLocation, rhs: CLLocation) -> Bool {
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.altitude == rhs.altitude &&
        lhs.horizontalAccuracy == rhs.horizontalAccuracy &&
        lhs.speed == rhs.speed &&
        lhs.course == rhs.course
    }
}

private class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    static func configure(
        value: @escaping (CLLocation) -> Void,
        failed: @escaping (Error) -> Void)
    -> (CLLocationManager, CLLocationManagerDelegate)
    {
        let locationManager = CLLocationManager()
        let delegate = LocationManagerDelegate(value: value, failed: failed)

        locationManager.delegate = delegate
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.requestWhenInUseAuthorization()
        
        return (locationManager, delegate)
    }
    
    private let value: (CLLocation) -> Void
    private let failed: (Error) -> Void
    private var startedAt: Date

    private init(value: @escaping (CLLocation) -> Void, failed: @escaping (Error) -> Void) {
        self.value = value
        self.failed = failed
        startedAt = Date()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        log(manager.allowsBackgroundLocationUpdates,
            manager.isAuthorizedForWidgetUpdates,
            manager.accuracyAuthorization.rawValue,
            manager.authorizationStatus.rawValue)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {failed(error)}
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        log()
        locations
            .filter {$0.timestamp >= startedAt && $0.horizontalAccuracy >= 0}
            .forEach {
                log($0.timestamp, $0.coordinate, $0.horizontalAccuracy)
                value($0)
            }
    }
    
    // Detect pauses based on acceleration and motion detection
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {log()}
    
    // Will set `receiving` to true, when first location is received.
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {log()}
}
