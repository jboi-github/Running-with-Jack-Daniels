//
//  SumHeartrateEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 29.05.22.
//

import Foundation

struct HeartrateSecondsEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "HeartrateSecondsEvent"
    let vector: VectorElement<None>
    init(_ vector: VectorElement<None>) {self.vector = vector}

    // MARK: Implement specifics
    init(date: Date, heartrateSeconds: Double) {
        vector = VectorElement(date: date, doubles: [heartrateSeconds])
    }
    
    /// Total distance since beginning of time in meter
    var heartrateSeconds: Double {vector.doubles![0]}
}

extension TimeSeries where Element == HeartrateSecondsEvent {
    func parse(_ currHr: HeartrateEvent, _ prevHr: HeartrateEvent?) -> Element? {
        guard let prevHr = prevHr else {return nil}
        
        // Satz von Rolle!
        let heartrateSeconds = Double(currHr.heartrate + prevHr.heartrate) / 2.0 * prevHr.date.distance(to: currHr.date)
        return Element(date: currHr.date, heartrateSeconds: heartrateSeconds + (elements.last?.heartrateSeconds ?? 0))
    }
}
