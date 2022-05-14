//
//  PedometerEventClient.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 27.04.22.
//

import Foundation
import CoreMotion

final class PedometerEventClient: ClientDelegate {
    weak var client: Client<PedometerEventClient>?
    private var pedometer: CMPedometer?
    private unowned let queue: DispatchQueue
    
    init(queue: DispatchQueue) {
        self.queue = queue
    }

    func start(asOf: Date) -> ClientStatus {
        guard CMPedometer.isPedometerEventTrackingAvailable() else {return .notAvailable(since: asOf)}
        if [.denied, .restricted].contains(CMPedometer.authorizationStatus()) {return .notAllowed(since: asOf)}
        
        pedometer = CMPedometer()
        pedometer?.startEventUpdates {
            check($1)
            guard let pe = $0 else {return}
            
            let msg = "\(asOf.timeIntervalSinceReferenceDate)\t\(Date.now.timeIntervalSinceReferenceDate)\t\(pe.date.timeIntervalSinceReferenceDate)\t\(pe.type)\n"
            Files.append(msg, to: "pedometerEventX.txt")
            DispatchQueue.main.async {self.client?.counter += 1}
        }
        return .started(since: asOf)
    }
    
    func stop(asOf: Date) {
        pedometer?.stopUpdates()
        pedometer = nil
    }
}
