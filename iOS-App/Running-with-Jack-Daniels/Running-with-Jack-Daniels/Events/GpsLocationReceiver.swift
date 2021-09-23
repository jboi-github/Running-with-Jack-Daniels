//
//  GpsLocationRecorder.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 05.08.21.
//

import CoreLocation
import Combine

class GpsLocationReceiver {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    static var sharedInstance = GpsLocationReceiver()
    
    /// Use singleton @sharedInstance
    private init() {}

    // MARK: - Published
    
    /// Indicates, if Receiver is still active.
    public private(set) var receiving: PassthroughSubject<Bool, Error>!

    /// Last received location
    public private(set) var location: PassthroughSubject<CLLocation, Error>!
    
    /// Start receiving data. Ignore any values, that have an earlier timestamp
    public func start() {
        log()
        receiving = PassthroughSubject<Bool, Error>()
        location = PassthroughSubject<CLLocation, Error>()
        serialDispatchQueue.async {self.receiving.send(false)}
        
        locationManager = CLLocationManager()
        guard let locationManager = locationManager else {return}
        
        locationManager.delegate = delegate
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.startUpdatingLocation()
    }

    /// Stop receiving data. Receiver continues to run till receiving a value, that was actually measured at or after the given end time.
    public func stop(with error: Error? = nil) {
        log()
        _stop(with: error)
        serialDispatchQueue.async { [self] in
            if let error = error {
                location.send(completion: .failure(error))
                receiving.send(completion: .failure(error))
            } else {
                location.send(completion: .finished)
                receiving.send(completion: .finished)
            }
        }
    }
    
    static let minRestartTimeout: TimeInterval = 5
    static let maxRestartTimeout: TimeInterval = 120
    static let factorRestartTimeout: TimeInterval = 2
    
    private(set) var restartTimeout: TimeInterval = minRestartTimeout
    
    func reset(with error: Error?) {
        log("\(restartTimeout)")
        _stop(with: error)
        serialDispatchQueue.asyncAfter(deadline: .now() + restartTimeout) {self.start()}
        restartTimeout = min(restartTimeout * Self.factorRestartTimeout, Self.maxRestartTimeout)
    }

    // MARK: - Private
    
    private func _stop(with error: Error?) {
        _ = check(error)
        locationManager?.stopUpdatingLocation()
        serialDispatchQueue.async {self.receiving.send(false)}
    }
    
    private var locationManager: CLLocationManager? = nil
    private var delegate = Delegate()
    
    private class Delegate: NSObject, CLLocationManagerDelegate {
        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            log(manager.allowsBackgroundLocationUpdates,
                manager.isAuthorizedForWidgetUpdates,
                manager.accuracyAuthorization,
                manager.authorizationStatus)
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            GpsLocationReceiver.sharedInstance.reset(with: error)
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            log(locations.count)
            serialDispatchQueue.async {
                GpsLocationReceiver.sharedInstance.receiving.send(true)
                locations.forEach { location in
                    log(location.timestamp, location.coordinate, location.horizontalAccuracy)
                    GpsLocationReceiver.sharedInstance.location.send(location)
                }
            }
        }
        
        func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
            log()
            serialDispatchQueue.async {
                GpsLocationReceiver.sharedInstance.receiving.send(false)
            }
        }
        
        // Will set `receiving` to true, when first location is received.
        func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {log()}
    }
}
