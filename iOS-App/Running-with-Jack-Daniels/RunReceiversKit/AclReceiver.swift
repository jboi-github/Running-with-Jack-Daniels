//
//  AclMotionReceiver.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 07.08.21.
//

import CoreMotion
import RunFoundationKit

class AclReceiver: ReceiverProtocol {
    typealias Value = CMMotionActivity

    private var motionActivityManager: CMMotionActivityManager?
    private let value: (CMMotionActivity) -> Void
    private let failed: (Error) -> Void

    required init(value: @escaping (CMMotionActivity) -> Void, failed: @escaping (Error) -> Void) {
        self.value = value
        self.failed = failed
        
        guard CMMotionActivityManager.isActivityAvailable() else {
            log()
            failed("motion data not available on current device")
            return
        }
        
        guard [.notDetermined, .denied].contains(CMMotionActivityManager.authorizationStatus()) else {
            log()
            failed("access to motion data denied")
            return
        }
    }

    func start() {
        motionActivityManager = CMMotionActivityManager()
        let value = self.value

        motionActivityManager?.startActivityUpdates(to: .current ?? .main) { activity in
            guard let activity = activity else {return}
            guard activity.confidence != .low else {return}
            
            log()
            value(activity)
        }
    }
    
    func stop() {
        motionActivityManager?.stopActivityUpdates()
    }

    static func isDuplicate(lhs: CMMotionActivity, rhs: CMMotionActivity) -> Bool {
        lhs.stationary == rhs.stationary &&
        lhs.walking == rhs.walking &&
        lhs.running == rhs.running &&
        lhs.cycling == rhs.cycling
    }
}
