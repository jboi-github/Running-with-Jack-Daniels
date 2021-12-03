//
//  PathService.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import Foundation
import CoreLocation
import CoreMotion

class PathService: ObservableObject {
    static let sharedInstance = PathService()
    
    private init() {
        RunService.sharedInstance.subscribe(
            RunService.Config(
                motion: nil,
                aclStatus: nil,
                location: { [self] in
                    let idx = path.insertIndex(for: $0.timestamp) {$0.range.upperBound}
                    path[idx].addLocation($0)
                },
                gpsStatus: gpsStatus,
                heartrate: nil,
                bodySensorLocation: nil,
                bleStatus: nil,
                isActive: {
                    self.path.merge(
                        PathElement(
                            range: $0.timestamp ..< .distantFuture,
                            isActive: $0,
                            locations: [CLLocation]()),
                        delegate: MergeDelegate())
                },
                speed: nil,
                intensity: nil))
    }
    
    // MARK: - Interface
    struct PathElement: Rangable {
        let range: Range<Date>
        let isActive: IsActiveProducer.IsActive?
        private(set) var locations: [CLLocation]
        private(set) var avgLocation: CLLocation?
        
        init(
            range: Range<Date>,
            isActive: IsActiveProducer.IsActive?,
            locations: [CLLocation])
        {
            self.range = range
            self.isActive = isActive
            self.locations = locations
            
            if locations.isEmpty {
                self.avgLocation = nil
            } else {
                let latitude = locations
                    .map {$0.coordinate.latitude}
                    .reduce(0) {$0 + $1} / Double(locations.count)
                let longitude = locations
                    .map {$0.coordinate.longitude}
                    .reduce(0) {$0 + $1} / Double(locations.count)
                self.avgLocation = CLLocation(latitude: latitude, longitude: longitude)
            }
        }
        
        mutating func addLocation(_ location: CLLocation) {
            if let avgLocation = avgLocation {
                self.avgLocation = CLLocation(
                    latitude: avgLocation
                        .coordinate
                        .latitude
                        .avg(location.coordinate.latitude, locations.count),
                    longitude: avgLocation
                        .coordinate
                        .longitude
                        .avg(location.coordinate.longitude, locations.count))
            } else if !(isActive?.isActive ?? false) {
                avgLocation = location
            }
            locations.append(location)
        }
    }

    /// `path` elements are ordered by there arrival. Usually, this is also timestamp order.
    @Published private(set) var path = [PathElement]()

    // MARK: - Implementation
    private struct CodableLocation: Codable {
        let latitude: CLLocationDegrees
        let longitude: CLLocationDegrees
        let altitude: CLLocationDistance
        let horizontalAccuracy: CLLocationAccuracy
        let verticalAccuracy: CLLocationAccuracy
        let course: CLLocationDirection
        let courseAccuracy: CLLocationDirectionAccuracy
        let speed: CLLocationSpeed
        let speedAccuracy: CLLocationSpeedAccuracy
        let timestamp: Date
        
        func toLocation() -> CLLocation {
            CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: latitude,
                    longitude: longitude),
                altitude: altitude,
                horizontalAccuracy: horizontalAccuracy,
                verticalAccuracy: verticalAccuracy,
                course: course,
                courseAccuracy: courseAccuracy,
                speed: speed,
                speedAccuracy: speedAccuracy,
                timestamp: timestamp)
        }
        
        static func from(location: CLLocation) -> CodableLocation {
            CodableLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                altitude: location.altitude,
                horizontalAccuracy: location.horizontalAccuracy,
                verticalAccuracy: location.verticalAccuracy,
                course: location.course,
                courseAccuracy: location.courseAccuracy,
                speed: location.speed,
                speedAccuracy: location.speedAccuracy,
                timestamp: location.timestamp)
        }
    }
    
    private struct CodablePathElement: Codable {
        let range: Range<Date>
        let isActive: IsActiveProducer.IsActive?
        let locations: [CodableLocation]
        
        func toPathElement() -> PathElement {
            PathElement(
                range: range,
                isActive: isActive,
                locations: locations.map {$0.toLocation()})
        }
        
        static func from(pathElement: PathElement) -> CodablePathElement {
            CodablePathElement(
                range: pathElement.range,
                isActive: pathElement.isActive,
                locations: pathElement.locations.map {CodableLocation.from(location: $0)})
        }
    }

    private var fileName = ""
    
    private struct MergeDelegate: RangableMergeDelegate {
        typealias R = PathElement

        func reduce(_ rangable: R, to: Range<Date>) -> R {
            R(  range: to,
                isActive: rangable.isActive,
                locations: rangable.locations.filter {to.contains($0.timestamp)})
        }
        
        func resolve(_ r1: R, _ r2: R, to: Range<Date>) -> R {
            R(  range: to,
                isActive: r2.isActive ?? r1.isActive,
                locations:
                    r2.locations.filter {to.contains($0.timestamp)}
                    +
                    r1.locations.filter {to.contains($0.timestamp)})
        }
        
        func drop(_ rangable: R) {}
        func add(_ rangable: R) {}
    }
    
    private func gpsStatus(_ status: GpsProducer.Status) {
        let now = Date()
        
        switch status {
        case .started:
            path.removeAll(keepingCapacity: true)
            path.append(
                PathElement(
                    range: .distantPast ..< .distantFuture,
                    isActive: IsActiveProducer.IsActive(
                        timestamp: .distantPast,
                        isActive: false,
                        type: .unknown),
                    locations: [CLLocation]()))
            fileName = "locations-\(now).json"
        case .stopped:
            if let last = path.last, last.range.upperBound == .distantFuture {
                path[path.lastIndex!] = MergeDelegate()
                    .reduce(last, to: last.range.clamped(to: .distantPast ..< now))
            }
            FileHandling.write(path.map {CodablePathElement.from(pathElement: $0)}, to: fileName)
        case .resumed:
            path = (FileHandling.read([CodablePathElement].self, from: "locations-") ?? [])
                .map {$0.toPathElement()}
        default:
            FileHandling.write(path.map {CodablePathElement.from(pathElement: $0)}, to: fileName)
        }
    }
}
