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
    private unowned let pedometerEventTimeseries: TimeSeries<PedometerEvent>
    
    init(queue: DispatchQueue, pedometerEventTimeseries: TimeSeries<PedometerEvent>) {
        self.queue = queue
        self.pedometerEventTimeseries = pedometerEventTimeseries
    }

    func start(asOf: Date) -> ClientStatus {
        guard CMPedometer.isPedometerEventTrackingAvailable() else {return .notAvailable(since: asOf)}
        if [.denied, .restricted].contains(CMPedometer.authorizationStatus()) {return .notAllowed(since: asOf)}
        
        pedometer = CMPedometer()
        pedometer?.startEventUpdates {
            check($1)
            guard let pedometerEvent = $0 else {return}
            
            self.queue.async { [self] in
                pedometerEventTimeseries.insert(pedometerEventTimeseries.parse(pedometerEvent))
                DispatchQueue.main.async {self.client?.counter += 1}
            }
        }
        return .started(since: asOf)
    }
    
    func stop(asOf: Date) {
        pedometer?.stopUpdates()
        pedometer = nil
    }
}
