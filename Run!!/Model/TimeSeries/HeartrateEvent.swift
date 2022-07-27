//
//  HeartrateEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 13.05.22.
//

import Foundation

struct HeartrateEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "HeartrateEvent"
    let vector: VectorElement<Bool?>
    init(_ vector: VectorElement<Bool?>) {self.vector = vector}

    // MARK: Implement specifics
    init(date: Date, heartrate: Int, skinIsContacted: Bool?, energyExpended: Int?) {
        vector = VectorElement(
            date: date,
            ints: [heartrate],
            optionalInts: [energyExpended],
            categorical: skinIsContacted)
    }
    
    var heartrate: Int { vector.ints![0] }
    var energyExpended: Int? { vector.optionalInts![0] }
    var skinIsContacted: Bool? { vector.categorical ?? nil}
    
    static func energyExpended(_ delta: VectorElementDelta?) -> Double? { delta?.optionalInts![0] }
}

extension TimeSeries where Element == HeartrateEvent {
    /// Parse CoreBluetooth characteristic
    func parse(_ asOf: Date, _ data: Data?) -> Element? {
        guard let (heartrate, skinIsContacted, energyExpended, _) = HRM.parse(data) else {return nil}
        return Element(
            date: asOf,
            heartrate: heartrate,
            skinIsContacted: skinIsContacted,
            energyExpended: energyExpended)
    }
}
