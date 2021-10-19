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
    }

    func start() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            _ = check("motion data not available on current device")
            value(CMMotionActivity())
            return
        }
        
        guard [.notDetermined, .denied].contains(CMMotionActivityManager.authorizationStatus()) else {
            _ = check("access to motion data denied")
            value(CMMotionActivity())
            return
        }

        motionActivityManager = CMMotionActivityManager()
        motionActivityManager?.startActivityUpdates(to: .current ?? .main) { activity in
            guard let activity = activity else {return}
            guard activity.confidence != .low else {return}
            
            log()
            self.value(activity)
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

extension CMMotionActivity {
    /// Return, if user is currently detected in any activity. If motion detection cannot be used, report as active user.
    public var isActive: Bool {((walking || running || cycling) && !stationary) || !Self.canUse}
    
    /// Return true, if device has motion detection and it is authorized by user or authorizaiotn was not yet asked for.
    public static var canUse: Bool {
        CMMotionActivityManager.isActivityAvailable() &&
        [.notDetermined, .authorized].contains(CMMotionActivityManager.authorizationStatus())
    }
    
    public var when: Date {
        startDate > Date(timeIntervalSinceReferenceDate: 3600) ? startDate : Date()
    }
}
