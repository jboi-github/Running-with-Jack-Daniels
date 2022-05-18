//
//  MotionActivityClient.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 27.04.22.
//

import Foundation
import CoreMotion

final class MotionActivityClient: ClientDelegate {
    weak var client: Client<MotionActivityClient>?
    private var motionActivityManager: CMMotionActivityManager?
    private unowned let queue: DispatchQueue
    private unowned let motionActivityTimeseries: TimeSeries<MotionActivityEvent>
    @Persistent(key: "com.apps4live.Run!!.MotionActivityClient.lastRun") private var lastRun: Date = .distantPast

    init(queue: DispatchQueue, motionActivityTimeseries: TimeSeries<MotionActivityEvent>) {
        self.queue = queue
        self.motionActivityTimeseries = motionActivityTimeseries
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
    
    // TODO: Call eversy full second while in workout
    func trigger(asOf: Date) {
        guard let motionActivityManager = motionActivityManager else {return}
        let from = max(lastRun, asOf.addingTimeInterval(-workoutTimeout))
        lastRun = from
        
        motionActivityManager.queryActivityStarting(from: from, to: asOf, to: .current ?? .main) {
            check($1)
            guard let activities = $0 else {return}
            
            self.queue.async { [self] in
                log(from, asOf, activities.count)
                activities.forEach { motionActivity in
                    motionActivityTimeseries.insert(motionActivityTimeseries.parse(motionActivity))
                }
            }
        }
    }
}

