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
    @Persistent(key: "com.apps4live.Run!!.MotionActivityClient.lastRun") private var lastRun: Date = .distantPast

    init(queue: DispatchQueue) {
        self.queue = queue
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
        guard let  motionActivityManager = motionActivityManager else {return}
        let from = max(lastRun, asOf.addingTimeInterval(-workoutTimeout))
        lastRun = from
        
        motionActivityManager.queryActivityStarting(from: from, to: asOf, to: .current ?? .main) {
            check($1)
            guard let activities = $0 else {return}
            
            self.queue.async {
                activities.forEach { a in
                    let msg = "\(from.timeIntervalSinceReferenceDate)\t\(asOf.timeIntervalSinceReferenceDate)\t\(Date.now.timeIntervalSinceReferenceDate)\t\(a.startDate.timeIntervalSinceReferenceDate)\t\(a.confidence)\t\(a.stationary)\t\(a.walking)\t\(a.running)\t\(a.automotive)\t\(a.cycling)\t\(a.unknown)\n"
                    Files.append(msg, to: "motionActivityX.txt")
                    DispatchQueue.main.async {self.client?.counter += 1}
                }
            }
        }
    }
}
