//
//  Client.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 27.04.22.
//

import Foundation

protocol ClientDelegate: AnyObject {
    func start(asOf: Date) -> ClientStatus
    func stop(asOf: Date)
    func trigger(asOf: Date)
    
    func setStatusCallback(_ callback: @escaping (ClientStatus) -> Void)
}

extension ClientDelegate {
    func trigger(asOf: Date) {} // Optional function
}

enum ClientStatus {
    case stopped(since: Date)
    case started(since: Date)
    case notAllowed(since: Date)
    case notAvailable(since: Date)
    
    fileprivate var isStopped: Bool {
        switch self {
        case .stopped:
            return true
        default:
            return false
        }
    }
}

class Client: ObservableObject {
    init<Delegate: ClientDelegate>(delegate: Delegate) {
        self.status = .stopped(since: .distantPast)
        self.delegate = delegate
        self.delegate.setStatusCallback({self.statusChanged(to: $0)})
    }

    @Published private(set) var status: ClientStatus
    private let delegate: ClientDelegate

    @discardableResult func start(asOf: Date) -> ClientStatus {
        guard status.isStopped else {return status}
        status = delegate.start(asOf: asOf)
        if status.isStopped {check("Expected any started status, but found \(status)")}
        return status
    }
    
    func stop(asOf: Date) {
        guard !status.isStopped else {return}
        delegate.stop(asOf: asOf)
        status = .stopped(since: asOf)
    }
    
    func statusChanged(to status: ClientStatus) { self.status = status }
    
    func trigger(asOf: Date) {delegate.trigger(asOf: asOf)}
}
