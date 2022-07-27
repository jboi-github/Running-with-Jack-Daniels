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
    
    var heartrateSeconds: Double {vector.doubles![0]}
    static func heartrateSeconds(_ delta: VectorElementDelta?) -> Double? { delta?.doubles![0] }
}

extension TimeSeries where Element == HeartrateSecondsEvent {
    func parse(_ currHr: HeartrateEvent, _ prevHr: HeartrateEvent?) -> Element? {
        guard let prevHr = prevHr else {return nil}
        
        // Satz von Rolle!
        let duration = prevHr.date.distance(to: currHr.date)
        let heartrateSeconds = Double(currHr.heartrate + prevHr.heartrate) / 2.0 * duration
        
        return Element(
            date: currHr.date,
            heartrateSeconds: heartrateSeconds + (elements.last?.heartrateSeconds ?? 0))
    }
}
