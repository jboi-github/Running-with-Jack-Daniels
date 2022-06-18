//
//  PeripheralEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 14.05.22.
//

import Foundation
import CoreBluetooth

struct PeripheralEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "PeripheralEvent"
    let vector: VectorElement<Info>
    init(_ vector: VectorElement<Info>) {self.vector = vector}

    // MARK: Implement specifics
    enum State: Int, Codable, Equatable {
        case disconnected, connecting, connected, disconnecting
    }
    
    struct Info: Codable, Equatable {
        let name: String?
        let state: State
    }
    
    init(date: Date, name: String?, state: State) {
        vector = VectorElement(date: date, categorical: Info(name: name, state: state))
    }
    
    var name: String? {vector.categorical!.name}
    var state: State {vector.categorical!.state}
}

extension TimeSeries where Element == PeripheralEvent {
    func parse(_ asOf: Date, _ peripheral: CBPeripheral) -> Element? {
        let result = Element(date: asOf, name: peripheral.name,
                             state: PeripheralEvent.State(rawValue: peripheral.state.rawValue) ?? .disconnected)
        if let last = elements.last, last.name == result.name && last.state == result.state {return nil}
        return result
    }
}
