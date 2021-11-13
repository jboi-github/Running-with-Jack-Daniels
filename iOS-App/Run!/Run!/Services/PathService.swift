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
        path.append(
            PathElement(
                range: .distantPast ..< .distantFuture,
                isActive: IsActiveProducer.IsActive(
                    timestamp: .distantPast,
                    isActive: false,
                    type: .unknown),
                locations: [CLLocation]()))
        
        RunService.sharedInstance.subscribe(
            RunService.Config(
                motion: nil,
                aclStatus: nil,
                location: { [self] in path[path.index(before: path.endIndex)].addLocation($0)},
                gpsStatus: {
                    if case .started = $0 {
                        self.path.removeAll(keepingCapacity: true)
                    }
                },
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

        lazy var avgLocation: CLLocation? = {
            guard !locations.isEmpty else {return nil}
            
            let latitude = locations
                .map {$0.coordinate.latitude}
                .reduce(0) {$0 + $1} / Double(locations.count)
            let longitude = locations
                .map {$0.coordinate.longitude}
                .reduce(0) {$0 + $1} / Double(locations.count)
            return CLLocation(latitude: latitude, longitude: longitude)
        }()
        
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
            } else {
                avgLocation = location
            }
            locations.append(location)
        }
    }

    /// `path` elements are ordered by there arrival. Usually, this is also timestamp order.
    @Published private(set) var path = [PathElement]()

    // MARK: - Implementation
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
}
