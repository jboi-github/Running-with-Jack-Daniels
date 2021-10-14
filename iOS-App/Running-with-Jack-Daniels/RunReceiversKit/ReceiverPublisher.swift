//
//  ReceiverProtocol.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 28.09.21.
//

import Foundation
import Combine
import RunFoundationKit

protocol ReceiverProtocol {
    associatedtype Value
    
    mutating func start()
    mutating func stop()
    
    init(value: @escaping (Value) -> Void, failed: @escaping (Error) -> Void)
    
    static func isDuplicate(lhs: Value, rhs: Value) -> Bool
}

public enum ReceiverControl {
    case started, stopped
    case reseting(error: Error, delay: TimeInterval)
}

class ReceiverPublisher<Receiver: ReceiverProtocol> {
    private var receiver: Receiver!
    
    var valueStream: AnyPublisher<Receiver.Value, Never>
    private var _valueStream: PassthroughSubject<Receiver.Value, Never>
    
    let controlStream: AnyPublisher<ReceiverControl, Never>
    private let _controlStream: PassthroughSubject<ReceiverControl, Never>
    
    private let minRestartTimeout: TimeInterval = 5
    private let maxRestartTimeout: TimeInterval = 120
    private let factorRestartTimeout: TimeInterval = 2
    
    private var restartTimeout: TimeInterval
    
    init() {
        restartTimeout = minRestartTimeout
        
        _valueStream = PassthroughSubject<Receiver.Value, Never>()
        valueStream = _valueStream
            .removeDuplicates(by: Receiver.isDuplicate)
            .share()
            .eraseToAnyPublisher()
        
        _controlStream = PassthroughSubject<ReceiverControl, Never>()
        controlStream = _controlStream
            .removeDuplicates {
                switch ($0, $1) {
                case (.started, .started):
                    return true
                case (.stopped, .stopped):
                    return true
                case (.reseting, .reseting):
                    return true
                default:
                    return false
                }
            }
            .share()
            .eraseToAnyPublisher()

        receiver = Receiver(
            value: {value in serialQueue.async {self._valueStream.send(value)}},
            failed: {error in serialQueue.async {self.reset(error)}})
    }
    
    func start() {
        log()
        receiver.start()
        serialQueue.async {self._controlStream.send(.started)}
    }
    
    func stop() {
        log()
        receiver.stop()
        serialQueue.async {self._controlStream.send(.stopped)}
    }
    
    private func reset(_ error: Error) {
        _ = check(error)
        stop()
        _controlStream.send(.reseting(error: error, delay: restartTimeout))
        serialQueue.asyncAfter(deadline: .now() + restartTimeout) {self.start()}
        restartTimeout = min(restartTimeout * factorRestartTimeout, maxRestartTimeout)
    }
}
