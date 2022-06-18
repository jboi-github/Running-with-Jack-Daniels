//
//  TimerClient.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 19.05.22.
//

import Foundation
import SwiftUI

final class TimerClient: ClientDelegate {
    private var statusCallback: ((ClientStatus) -> Void)?
    init(_ clients: [Client]) {
        self.clients = clients
    }
    
    func setStatusCallback(_ callback: @escaping (ClientStatus) -> Void) {self.statusCallback = callback}

    private var timer: Timer? = nil
    private let clients: [Client]

    func start(asOf: Date) -> ClientStatus {
        let actualStart = Date.now
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            let asOf = asOf.advanced(by: actualStart.distance(to: $0.fireDate))
            self.trigger(asOf: asOf)
        }
        return .started(since: asOf)
    }
    
    func stop(asOf: Date) {
        timer?.invalidate()
        timer = nil
    }
    
    func trigger(asOf: Date) {
        clients.forEach {$0.trigger(asOf: asOf)}
    }
}
