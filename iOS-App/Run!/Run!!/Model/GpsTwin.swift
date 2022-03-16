//
//  GpsTwin.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import Foundation
import CoreLocation

enum GpsStatus {
    case stopped
    case started(since: Date)
    case notAllowed(since: Date)
    case notAvailable(since: Date)
}

class GpsTwin {
    // MARK: Public interface
    func start(asOf: Date) {
        if case .started = status {return}
        
        _start(asOf: asOf)
    }
    
    func stop(asOf: Date) {
        if case .stopped = status {return}

        status = .stopped
    }

    // MARK: Status handling
    private(set) var status: GpsStatus = .stopped {
        willSet {
            log(status, newValue)
            switch newValue {
            case .stopped:
                locationManager?.stopUpdatingLocation()
                locationManager = nil
                locationManagerDelegate = nil
            case .started:
                locationManager.startUpdatingLocation()
            case .notAllowed:
                locationManager = nil
                locationManagerDelegate = nil
            case .notAvailable:
                locationManager = nil
                locationManagerDelegate = nil
                
                // Retry after some time
                DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
                    if case .notAvailable = self.status {
                        self._start(asOf: .now)
                    }
                }
            }
        }
    }
    
    // MARK: Gps Implementation
    private var locationManager: CLLocationManager!
    private var locationManagerDelegate: CLLocationManagerDelegate?
    
    private func _start(asOf: Date) {
        locationManager = CLLocationManager()
        locationManagerDelegate = LocationManagerDelegate(
            value: {log($0)}, // TODO: Parse and inform collection
            status: {self.status = $0},
            asOf: asOf)

        locationManager.delegate = locationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        locationManager.activityType = .fitness
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            status = locationManager.isAuthorized ? .started(since: asOf) : .notAllowed(since: asOf)
        }
    }
}

private class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    private let value: (CLLocation) -> Void
    private let status: (GpsStatus) -> Void
    private var startedAt: Date

    init(
        value: @escaping (CLLocation) -> Void,
        status: @escaping (GpsStatus) -> Void,
        asOf: Date)
    {
        self.value = value
        self.status = status
        startedAt = asOf
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        log(manager.allowsBackgroundLocationUpdates,
            manager.isAuthorizedForWidgetUpdates,
            manager.accuracyAuthorization.rawValue,
            manager.authorizationStatus.rawValue)
        
        status(manager.isAuthorized ? .started(since: startedAt) : .notAllowed(since: startedAt))
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
}

extension CLLocationManager {
    var isAuthorized: Bool {
        [.authorizedWhenInUse, .authorizedAlways].contains(authorizationStatus)
    }
}
