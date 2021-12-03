//
//  IsActiveProducer.swift
//  Run!
//
//  Created by Jürgen Boiselle on 07.11.21.
//

import Foundation
import CoreMotion

class IsActiveProducer {
    struct IsActive: Codable {
        let timestamp: Date
        let isActive: Bool
        let type: ActivityType
        
        static var zero: IsActive {IsActive(timestamp: .distantPast, isActive: false, type: .unknown)}
    }
    
    enum ActivityType: Int, Codable {
        case pause, walking, running, cycling, unknown
    }
    
    private var isActive: ((IsActive) -> Void)?
    private var constantActivity: IsActive?
    
    func start(isActive: @escaping (IsActive) -> Void) {
        self.isActive = isActive
        constantActivity = nil
    }
    
    /// Optionally send a constant activity, e.g. in case of an error or missing authoritization
    func afterStart() {
        guard let constantActivity = constantActivity else {return}
        isActive?(constantActivity)
    }
    
    /// To be used by dispatcher to connect to `AclProducer`
    func value(_ motion: MotionActivityProtocol) {
        isActive?(
            IsActive(
                timestamp: motion.startDate,
                isActive: motion.isActive,
                type: motion.activityType))
    }
    
    /// To be used by dispatcher to connect to `AclProducer`
    func status(_ status: AclProducer.Status) {
        switch status {
        case .nonRecoverableError(let asOf, _):
            constantActivity = IsActive(timestamp: asOf, isActive: true, type: .unknown)
        case .notAuthorized(let asOf):
            constantActivity = IsActive(timestamp: asOf, isActive: true, type: .unknown)
        default:
            constantActivity = nil
        }
    }
}

extension CMMotionActivity: MotionActivityProtocol {
    /// Return true, if device has motion detection and it is authorized by user or authorizaiotn was not yet asked for.
    public static var canUse: Bool {
        CMMotionActivityManager.isActivityAvailable() &&
        [.notDetermined, .authorized].contains(CMMotionActivityManager.authorizationStatus())
    }
}
