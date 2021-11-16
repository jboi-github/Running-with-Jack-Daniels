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
    }
    
    enum ActivityType: Codable {
        case pause, walking, running, cycling, unknown
    }
    
    private var isActive: ((IsActive) -> Void)?
    
    func start(isActive: @escaping (IsActive) -> Void) {
        self.isActive = isActive
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
        case .nonRecoverableError(_):
            isActive?(IsActive(timestamp: Date(), isActive: true, type: .unknown))
        case .notAuthorized:
            isActive?(IsActive(timestamp: Date(), isActive: true, type: .unknown))
        default:
            break
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
