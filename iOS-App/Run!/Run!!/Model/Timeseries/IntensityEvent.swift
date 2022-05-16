//
//  Intensity.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 15.05.22.
//

import Foundation

struct IntensityEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "com.apps4live.Run!!.IntensityEvent"
    let vector: VectorElement<Run.Intensity>
    init(_ vector: VectorElement<Run.Intensity>) {self.vector = vector}

    // MARK: Implement specifics
    init(date: Date, intensity: Run.Intensity) {
        vector = VectorElement(date: date, categorical: intensity)
    }
    
    var intensity: Run.Intensity {vector.categorical}
}

extension TimeSeries where Element == IntensityEvent {
    func parse(_ heartrate: HeartrateEvent) -> [Element]? {
        guard let hrLimits = Profile.hrLimits.value else {return nil}

    }
    
    private func bucketize() {
        
    }
}
