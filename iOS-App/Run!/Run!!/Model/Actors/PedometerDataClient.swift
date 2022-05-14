//
//  PedometerDataClient.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 27.04.22.
//

import Foundation
import CoreMotion

final class PedometerDataClient: ClientDelegate {
    weak var client: Client<PedometerDataClient>?
    private var pedometer: CMPedometer?
    private unowned let queue: DispatchQueue
    @Persistent(key: "com.apps4live.Run!!.PedometerDataClient.lastRun") private var lastRun: Date = .distantPast
    
    init(queue: DispatchQueue) {
        self.queue = queue
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
        lastRun = from

        pedometer.queryPedometerData(from: from, to: asOf) {
            check($1)
            guard let pd = $0 else {return}
            
            self.queue.async {
                let msg = "\(from.timeIntervalSinceReferenceDate)\t\(asOf.timeIntervalSinceReferenceDate)\t\(Date.now.timeIntervalSinceReferenceDate)\t\(pd.startDate.timeIntervalSinceReferenceDate)\t\(pd.endDate.timeIntervalSinceReferenceDate)\t\(pd.numberOfSteps.intValue)\t\(pd.distance?.doubleValue ?? .nan)\t\(pd.averageActivePace?.doubleValue ?? .nan)\t\(pd.currentPace?.doubleValue ?? .nan)\t\(pd.currentCadence?.doubleValue ?? .nan)\t\(pd.floorsAscended?.doubleValue ?? .nan)\t\(pd.floorsDescended?.doubleValue ?? .nan)\n"
                Files.append(msg, to: "pedometerDataX.txt")
                DispatchQueue.main.async {self.client?.counter += 1}
            }
        }
    }
}
