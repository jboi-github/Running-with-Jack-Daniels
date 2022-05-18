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
    private unowned let queue: DispatchQueue
    private unowned let locationTimeseries: TimeSeries<LocationEvent>
    private unowned let distanceTimeseries: TimeSeries<DistanceEvent>
    
    init(
        queue: DispatchQueue,
        locationTimeseries: TimeSeries<LocationEvent>,
        distanceTimeseries: TimeSeries<DistanceEvent>)
    {
        self.queue = queue
        self.locationTimeseries = locationTimeseries
        self.distanceTimeseries = distanceTimeseries
    }

    func start(asOf: Date) -> ClientStatus {
        locationManager = CLLocationManager()
        locationManagerDelegate = LocationManagerDelegate(
            value: { location in
                self.queue.async { [self] in
                    locationTimeseries.insert(locationTimeseries.parse(location))
                    distanceTimeseries
                        .parse(location, locationTimeseries.elements.last?.clLocation)
                        .forEach {distanceTimeseries.insert($0)}
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
