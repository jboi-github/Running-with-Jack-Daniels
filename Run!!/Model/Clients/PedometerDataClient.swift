//
//  PedometerDataClient.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 27.04.22.
//

import Foundation
import CoreMotion

final class PedometerDataClient: ClientDelegate {
    private var statusCallback: ((ClientStatus) -> Void)?
    private var pedometer: CMPedometer?
    private unowned let queue: DispatchQueue
    private unowned let timeseriesSet: TimeSeriesSet
    private unowned let pedometerDataTimeseries: TimeSeries<PedometerDataEvent, None>
    @Persistent(key: "com.apps4live.Run!!.PedometerDataClient.lastRun") private var lastRun: Date = .distantPast
    
    init(
        queue: DispatchQueue,
        timeseriesSet: TimeSeriesSet,
        pedometerDataTimeseries: TimeSeries<PedometerDataEvent, None>)
    {
        self.queue = queue
        self.timeseriesSet = timeseriesSet
        self.pedometerDataTimeseries = pedometerDataTimeseries
    }
    
    func setStatusCallback(_ callback: @escaping (ClientStatus) -> Void) {
        self.statusCallback = callback
    }

    func start(asOf: Date) -> ClientStatus {
        guard CMPedometer.isStepCountingAvailable() else {return .notAvailable(since: asOf)}
        if [.denied, .restricted].contains(CMPedometer.authorizationStatus()) {return .notAllowed(since: asOf)}

        pedometer = CMPedometer()
        trigger(asOf: asOf)
        return .started(since: asOf)
    }
    
    func stop(asOf: Date) {
        pedometer?.stopUpdates()
        pedometer = nil
    }
    
    func trigger(asOf: Date) {
        guard let pedometer = pedometer else {return}
        let from = max(lastRun, asOf.addingTimeInterval(-workoutTimeout))
        lastRun = asOf

        pedometer.queryPedometerData(from: from, to: asOf) {
            check($1)
            guard let pedometerData = $0 else {return}
            
            // Empty?
            if pedometerData.numberOfSteps == 0 &&
                pedometerData.distance == 0.0 &&
                pedometerData.floorsAscended == 0 &&
                pedometerData.floorsDescended == 0 &&
                pedometerData.currentPace == nil &&
                pedometerData.averageActivePace == nil
            {
                return
            }

            log(from, asOf, pedometerData)
            self.queue.async { [self] in
                timeseriesSet.reflect(pedometerDataTimeseries.parse(pedometerData), pedometerData.startDate)
            }
        }
    }
}
