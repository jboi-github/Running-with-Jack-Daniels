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
    case stopped, started, received
    case reset(error: Error, delay: TimeInterval)
    case retried(error: Error)
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
            .removeDuplicates {$0 == $1}
            .share()
            .eraseToAnyPublisher()

        receiver = Receiver(
            value: {value in
                serialQueue.async {
                    self._controlStream.send(.received)
                    self._valueStream.send(value)
                }
            },
            failed: {error in serialQueue.async {self.reset(error)}})
    }
    
    func start() {
        log()
        serialQueue.async {self._controlStream.send(.started)}
        receiver.start()
    }
    
    func stop() {
        log()
        receiver.stop()
        serialQueue.async {self._controlStream.send(.stopped)}
    }
    
    // Is called within serialQueue
    private func reset(_ error: Error) {
        _ = check(error)
        defer {restartTimeout = min(restartTimeout * factorRestartTimeout, maxRestartTimeout)}

        receiver.stop()
        _controlStream.send(.reset(error: error, delay: restartTimeout))
        
        serialQueue.asyncAfter(deadline: .now() + restartTimeout) {
            serialQueue.async {self._controlStream.send(.retried(error: error))}
            self.receiver.start()
        }
    }
}

extension ReceiverControl: Equatable {
    public static func == (lhs: ReceiverControl, rhs: ReceiverControl) -> Bool {
        switch (lhs, rhs) {
        case (.stopped, .stopped):
            return true
        case (.started, .started):
            return true
        case (.reset, .reset):
            return true
        case (.retried, .retried):
            return true
        case (.received, .received):
            return true
        default:
            return false
        }
    }
}
