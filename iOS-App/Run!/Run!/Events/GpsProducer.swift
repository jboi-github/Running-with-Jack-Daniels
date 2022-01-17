//
//  GpsProvider.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import Foundation
import CoreLocation

protocol GpsProducerProtocol {
    static var sharedInstance: GpsProducerProtocol {get}

    func start(
        value: @escaping (CLLocation) -> Void,
        status: @escaping (GpsProducer.Status) -> Void,
        asOf: Date)
    func stop()
    func pause()
    func resume()
}

class GpsProducer: GpsProducerProtocol {
    static let sharedInstance: GpsProducerProtocol = GpsProducer()

    private init() {}
    
    private var locationManager: CLLocationManager!
    private var locationManagerDelegate: CLLocationManagerDelegate!

    private var status: ((Status) -> Void)?
    
    enum Status {
        case started(asOf: Date), stopped, paused, resumed
        case nonRecoverableError(asOf: Date, error: Error), notAuthorized(asOf: Date)
    }

    func start(
        value: @escaping (CLLocation) -> Void,
        status: @escaping (Status) -> Void,
        asOf: Date)
    {
        self.status = status
        locationManager = CLLocationManager()
        locationManagerDelegate = LocationManagerDelegate(value: value, status: status, asOf: asOf)

        locationManager.delegate = locationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = true
        if locationManager.authorizationStatus == .notDetermined {locationManager.requestWhenInUseAuthorization()}

        _start()
        status([.denied, .restricted].contains(locationManager.authorizationStatus) ?
                .notAuthorized(asOf: asOf) : .started(asOf: asOf))
    }
    
    func stop() {
        _stop()
        status?(.stopped)
    }
    
    func pause() {
        _stop()
        status?(.paused)
    }
    
    func resume() {
        _start()
        status?(.resumed)
    }
    
    private func _start() {
        locationManager?.startUpdatingLocation()
    }
    
    private func _stop() {
        locationManager?.stopUpdatingLocation()
        locationManager = nil
    }
}

private class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    private let value: (CLLocation) -> Void
    private let status: (GpsProducer.Status) -> Void
    private var startedAt: Date

    init(
        value: @escaping (CLLocation) -> Void,
        status: @escaping (GpsProducer.Status) -> Void,
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
        
        if ![.authorizedWhenInUse, .authorizedAlways].contains(manager.authorizationStatus) {status(.notAuthorized(asOf: startedAt))}
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {status(.nonRecoverableError(asOf: startedAt, error: error))}
    
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