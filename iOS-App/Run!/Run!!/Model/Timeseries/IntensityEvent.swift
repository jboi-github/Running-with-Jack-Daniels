//
//  Intensity.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 15.05.22.
//

import Foundation

struct IntensityEvent: GenericTimeseriesElement, Equatable {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "IntensityEvent"
    let vector: VectorElement<Run.Intensity>
    init(_ vector: VectorElement<Run.Intensity>) {self.vector = vector}

    // MARK: Implement specifics
    init(date: Date, intensity: Run.Intensity) {
        vector = VectorElement(date: date, categorical: intensity)
    }
    
    var intensity: Run.Intensity {vector.categorical}
}

extension TimeSeries where Element == IntensityEvent {
    func parse(_ currentHr: HeartrateEvent, _ prevHr: HeartrateEvent?) -> [Element]? {
        guard let hrLimits = Profile.hrLimits.value else {return nil}
        let buckets = (elements.last?.intensity ?? .Cold).getHrBuckets(for: hrLimits)
        return buckets
            .compactMap {
                if let prevHr = prevHr {
                    guard let p = p($0.value, prev: prevHr.heartrate, curr: currentHr.heartrate) else {return nil}
                    return Element(date: (prevHr.date ..< currentHr.date).mid(p), intensity: $0.key)
                } else {
                    guard $0.value.contains(currentHr.heartrate) else {return nil}
                    return Element(date: currentHr.date, intensity: $0.key)
                }
            }
            .filter {
                guard let last = elements.last else {return true}
                return last != $0
            }
            .sorted {$0.date <= $1.date}
    }
    
    private func p(_ bucket: Range<Int>, prev: Int, curr: Int) -> Double? {
        let range = min(prev, curr) ..< max(prev, curr)
        let intersection = range.clamped(to: bucket)
        if intersection.isEmpty {return nil}
        
        var ps = [range.p(intersection.lowerBound), range.p(intersection.upperBound)]
        if curr < prev {ps = ps.map {1 - $0}}
        
        return ps.min()
    }
}
