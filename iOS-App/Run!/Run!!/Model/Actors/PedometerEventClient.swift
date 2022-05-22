//
//  PedometerEventClient.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 27.04.22.
//

import Foundation
import CoreMotion

final class PedometerEventClient: ClientDelegate {
    private var statusCallback: ((ClientStatus) -> Void)?
    private var pedometer: CMPedometer?
    private unowned let queue: DispatchQueue
    private unowned let pedometerEventTimeseries: TimeSeries<PedometerEvent>
    
    init(queue: DispatchQueue, pedometerEventTimeseries: TimeSeries<PedometerEvent>) {
        self.queue = queue
        self.pedometerEventTimeseries = pedometerEventTimeseries
    }
    
    func setStatusCallback(_ callback: @escaping (ClientStatus) -> Void) {
        self.statusCallback = callback
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
            }
        }
        return .started(since: asOf)
    }
    
    func stop(asOf: Date) {
        pedometer?.stopUpdates()
        pedometer = nil
    }
}
