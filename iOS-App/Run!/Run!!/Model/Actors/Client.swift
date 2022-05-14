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
    
    var client: Client<Self>? {get set}
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

class Client<Delegate: ClientDelegate>: ObservableObject {
    init(delegate: Delegate) {
        self.status = .stopped(since: .distantPast)
        self.delegate = delegate
        self.delegate.client = self
    }

    @Published var counter: Int = 0
    @Published private(set) var status: ClientStatus
    private let delegate: Delegate

    @discardableResult func start(asOf: Date) -> ClientStatus {
        status = delegate.start(asOf: asOf)

        if status.isStopped {check("Expected any started status, but found \(status)")}
        return status
    }
    
    func stop(asOf: Date) {
        guard !status.isStopped else {return}
        delegate.stop(asOf: asOf)
        status = .stopped(since: asOf)
    }
    
    func statusChanged(to status: ClientStatus) {
        if status.isStopped {check("Expected any started status, but found \(status)")}
        self.status = status
    }
}
