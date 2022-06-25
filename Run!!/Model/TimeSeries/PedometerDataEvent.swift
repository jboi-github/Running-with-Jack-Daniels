//
//  PedometerDataEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.05.22.
//

import Foundation
import CoreLocation
import CoreMotion

struct PedometerDataEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "PedometerDataEvent"
    let vector: VectorElement<Speed>
    init(_ vector: VectorElement<Speed>) {self.vector = vector}

    // MARK: Implement specifics
    
    struct Speed: Codable, Equatable {
        let speed: CLLocationSpeed?
    }
    
    init(
        date: Date,
        numberOfSteps: Int,
        distance: CLLocationDistance?,
        activeDuration: TimeInterval?,
        speed: CLLocationSpeed? = nil)
    {
        vector = VectorElement(
            date: date,
            ints: [numberOfSteps],
            optionalDoubles: [distance, activeDuration],
            categorical: Speed(speed: speed))
    }
    
    /// Total number of steps since beginning of time
    var numberOfSteps: Int {vector.ints![0]}
    
    /// Total distance recognized by pedometer since beginning of time
    var distance: CLLocationDistance? {vector.optionalDoubles![0]}
    
    /// Total active time recognized by pedometer since beginning of time
    var activeDuration: TimeInterval? {vector.optionalDoubles![1]}
    
    /// Average speed up to date
    var speed: CLLocationSpeed? {vector.categorical?.speed}
}

extension TimeSeries where Element == PedometerDataEvent {
    func parse(_ pedometerData: CMPedometerData) -> Element {
        var activeDuration: TimeInterval? {
            guard
                let distance = pedometerData.distance,
                let averageActivePace = pedometerData.averageActivePace else {return nil}
            return distance.doubleValue / averageActivePace.doubleValue
        }
        
        return Element(
            date: pedometerData.endDate,
            numberOfSteps: pedometerData.numberOfSteps.intValue + (elements.last?.numberOfSteps ?? 0),
            distance: pedometerData.distance?.doubleValue + (elements.last?.distance ?? 0),
            activeDuration: activeDuration + (elements.last?.activeDuration ?? 0),
            speed: pedometerData.averageActivePace?.doubleValue)
    }
    
    func newElements(_ startDate: Date, _ pedometerDataEvent: Element) -> [Element] {
        var result = [Element]()
        if let prev = elements.last, prev.date != startDate {
            result.append(prev.extrapolate(at: startDate))
        }
        result.append(pedometerDataEvent)
        return result
    }
}
