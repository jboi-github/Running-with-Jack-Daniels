//
//  GpsLocationRecorder.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 05.08.21.
//

import CoreLocation

class GpsLocationReceiver: ObservableObject {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    static var sharedInstance = GpsLocationReceiver()
    
    /// Use singleton @sharedInstance
    private init() {}

    // MARK: - Published
    /// Indicates, if Receiver is still active.
    @Published public private(set) var receiving = false

    /// Indicates, if Receiver is still active.
    @Published public private(set) var localizedError = ""

    /// Last received location
    @Published public private(set) var location: CLLocation? = nil
    
    /// Start receiving data. Ignore any values, that have an earlier timestamp
    public func start() {
        location = nil
        reset()
    }
    
    /// Reset receiving data after error.
    public func reset() {
        localizedError = ""
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
    public func stop() {
        guard let locationManager = locationManager else {return}

        locationManager.stopUpdatingLocation()
        receiving = false
    }

    // MARK: - Private
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
            _ = check(error)
            manager.stopUpdatingLocation()
            GpsLocationReceiver.sharedInstance.localizedError = error.localizedDescription
            GpsLocationReceiver.sharedInstance.stop()
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            log(locations.count)
            GpsLocationReceiver.sharedInstance.receiving = true
            locations.forEach { location in
                DispatchQueue.main.async {
                    log(location.timestamp, location.coordinate, location.horizontalAccuracy)
                    GpsLocationReceiver.sharedInstance.location = location
                }
            }
        }
        
        func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
            log()
            GpsLocationReceiver.sharedInstance.receiving = false
        }
        
        func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {log()}
    }
}

// MARK: - Extensions

extension CLLocation {
    /// Create copy with all fields copied over but moved to given location.
    func moveTo(
        coordinate: CLLocationCoordinate2D,
        horizontalAccuracy: CLLocationAccuracy? = nil,
        timestamp: Date? = nil) -> CLLocation
    {
        CLLocation(
            coordinate: coordinate,
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy ?? self.horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            course: course,
            courseAccuracy: courseAccuracy,
            speed: speed,
            speedAccuracy: speedAccuracy,
            timestamp: timestamp ?? self.timestamp)
    }
    
    /// Interpolate towards a location at the given point in time. A linear movement from `self` to the given location is assumend.
    /// - Parameters:
    ///   - to: location moving towards.
    ///   - at: point in time to interpolate location.
    /// - Returns: a new created location at the given time.
    func interpolate(to: CLLocation, at: Date) -> CLLocation {
        let fullDuration = timestamp.distance(to: to.timestamp)
        guard fullDuration > 0 else {return self}
        
        let partDuration = timestamp.distance(to: at)
        
        let deltaLat = to.coordinate.latitude - coordinate.latitude
        let deltaLon = to.coordinate.longitude - coordinate.longitude
        
        var newAcc: CLLocationAccuracy {
            if partDuration <= 0 {
                return horizontalAccuracy
            } else if partDuration >= fullDuration {
                return to.horizontalAccuracy
            } else {
                let deltaAcc = to.horizontalAccuracy - horizontalAccuracy
                return horizontalAccuracy + deltaAcc * partDuration / fullDuration
            }
        }
        
        return moveTo(
            coordinate: CLLocationCoordinate2D(
                latitude: coordinate.latitude + deltaLat * partDuration / fullDuration,
                longitude: coordinate.longitude + deltaLon * partDuration / fullDuration),
            horizontalAccuracy: newAcc)
    }
}
