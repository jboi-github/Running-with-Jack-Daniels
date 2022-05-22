//
//  MotionActivityClient.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 27.04.22.
//

import Foundation
import CoreMotion

final class MotionActivityClient: ClientDelegate {
    private var statusCallback: ((ClientStatus) -> Void)?
    private var motionActivityManager: CMMotionActivityManager?
    private unowned let queue: DispatchQueue
    private unowned let motionActivityTimeseries: TimeSeries<MotionActivityEvent>
    @Persistent(key: "com.apps4live.Run!!.MotionActivityClient.lastRun") private var lastRun: Date = .distantPast

    init(queue: DispatchQueue, motionActivityTimeseries: TimeSeries<MotionActivityEvent>) {
        self.queue = queue
        self.motionActivityTimeseries = motionActivityTimeseries
    }
    
    func setStatusCallback(_ callback: @escaping (ClientStatus) -> Void) {
        self.statusCallback = callback
    }

    func start(asOf: Date) -> ClientStatus {
        guard CMMotionActivityManager.isActivityAvailable() else {return .notAvailable(since: asOf)}
        if [.denied, .restricted].contains(CMMotionActivityManager.authorizationStatus()) {return .notAllowed(since: asOf)}
        
        motionActivityManager = CMMotionActivityManager()
        trigger(asOf: asOf)
        return .started(since: asOf)
    }
    
    func stop(asOf: Date) {
        motionActivityManager?.stopActivityUpdates()
        motionActivityManager = nil
    }
    
    func trigger(asOf: Date) {
        guard let motionActivityManager = motionActivityManager else {return}
        let from = max(lastRun, asOf.addingTimeInterval(-workoutTimeout))
        lastRun = asOf
        
        motionActivityManager.queryActivityStarting(from: from, to: asOf, to: .current ?? .main) {
            check($1)
            guard let activities = $0 else {return}
            
            self.queue.async { [self] in
                activities.forEach { motionActivity in
                    guard let motionActivityEvent = motionActivityTimeseries.parse(motionActivity) else {return}
                    motionActivityTimeseries.insert(motionActivityEvent)
                }
            }
        }
    }
}

