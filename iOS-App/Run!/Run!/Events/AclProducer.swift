//
//  AclProducer.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import Foundation
import CoreMotion

protocol AclProducerProtocol {
    static var sharedInstance: AclProducerProtocol {get}
    
    func start(
        value: @escaping (MotionActivityProtocol) -> Void,
        status: @escaping (AclProducer.Status) -> Void)
    func stop()
    func pause()
    func resume()
}

extension AclProducerProtocol {
    static func isDuplicate(_ lhs: CMMotionActivity, _ rhs: CMMotionActivity) -> Bool {
        lhs.stationary == rhs.stationary &&
        lhs.walking == rhs.walking &&
        lhs.running == rhs.running &&
        lhs.cycling == rhs.cycling
    }
}

protocol MotionActivityProtocol {
    static var canUse: Bool {get}
    
    var startDate: Date {get}
    var stationary: Bool {get}
    var walking: Bool {get}
    var running: Bool {get}
    var cycling: Bool {get}
    var confidence: CMMotionActivityConfidence {get}
}

extension MotionActivityProtocol {
    /// Either walking, running or cycling. If Acl is not available, consider User as always active.
    var isActive: Bool {!stationary && (walking || running || cycling) || !Self.canUse}
    
    var activityType: IsActiveProducer.ActivityType {
        if !Self.canUse {return .unknown}
        if stationary {return .pause}
        
        if walking {return .walking}
        if running {return .running}
        if cycling {return .cycling}
        return .pause
    }
}

class AclProducer: AclProducerProtocol {
    static let sharedInstance: AclProducerProtocol = AclProducer()

    private init() {}

    private var motionActivityManager: CMMotionActivityManager?
    private var value: ((CMMotionActivity) -> Void)?
    private var status: ((Status) -> Void)?
    private var prev: CMMotionActivity? = nil
    
    enum Status {
        case started, stopped, paused, resumed, nonRecoverableError(Error), notAuthorized
    }

    func start(value: @escaping (MotionActivityProtocol) -> Void, status: @escaping (Status) -> Void) {
        self.status = status
        self.value = value

        guard CMMotionActivityManager.isActivityAvailable() else {
            _ = check("motion data not available on current device")
            status(.nonRecoverableError("motion data not available on current device"))
            return
        }
        
        if [.notDetermined, .denied].contains(CMMotionActivityManager.authorizationStatus()) {
            _ = check("access to motion data denied")
            status(.notAuthorized)
            return
        }

        _start()
        status(.started)
    }
    
    func stop() {
        _stop()
        status?(.stopped)
    }
    
    func pause() {
        _stop()
        status?(.paused)
    }
    
    func resume() {
        _start()
        status?(.resumed)
    }
    
    private func _start() {
        motionActivityManager = CMMotionActivityManager()
        motionActivityManager?.startActivityUpdates(to: .current ?? .main, withHandler: update)
    }
    
    private func _stop() {
        motionActivityManager?.stopActivityUpdates()
        motionActivityManager = nil
    }

    private func update(_ activity: CMMotionActivity?) {
        guard let activity = activity else {return}
        if activity.confidence == .low {return}
        if let prev = prev, AclProducer.isDuplicate(activity, prev) {return}
        
        log()
        value?(activity)
        prev = activity
    }
}
