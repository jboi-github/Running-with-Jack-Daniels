//
//  PedometerData.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.05.22.
//

import Foundation
import CoreLocation
import CoreMotion

struct PedometerData: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "com.apps4live.Run!!.PedometerData"
    let vector: VectorElement<None>
    init(_ vector: VectorElement<None>) {self.vector = vector}

    // MARK: Implement specifics
    init(date: Date, numberOfSteps: Int, distance: CLLocationDistance?, activeDuration: TimeInterval?) {
        vector = VectorElement(date: date, ints: [numberOfSteps], optionalDoubles: [distance, activeDuration])
    }
    
    /// Total number of steps since beginning of time
    var numberOfSteps: Int {vector.ints[0]}
    
    /// Total distance recognized by pedometer since beginning of time
    var distance: CLLocationDistance? {vector.optionalDoubles[0]}
    
    /// Total active time recognized by pedometer since beginning of time
    var activeDuration: TimeInterval? {vector.optionalDoubles[1]}
}

extension TimeSeries where Element == PedometerData {
    func parse(_ pedometerData: CMPedometerData) -> [Element] {
        var activeDuration: TimeInterval? {
            guard let distance = pedometerData.distance, let averageActivePace = pedometerData.averageActivePace else {return nil}
            return distance.doubleValue / averageActivePace.doubleValue
        }
        
        var result = [Element]()
        if let prev = elements.last, prev.date != pedometerData.startDate {
            result.append(prev.extrapolate(at: pedometerData.startDate))
        }
        result.append(Element(
            date: pedometerData.endDate,
            numberOfSteps: pedometerData.numberOfSteps.intValue + (elements.last?.numberOfSteps ?? 0),
            distance: pedometerData.distance?.doubleValue + (elements.last?.distance ?? 0),
            activeDuration: activeDuration + (elements.last?.activeDuration ?? 0)))
        return result
    }
}
