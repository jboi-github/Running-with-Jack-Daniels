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
    
    func start(value: @escaping (CMMotionActivity) -> Void, status: @escaping (AclProducer.Status) -> Void)
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

    func start(value: @escaping (CMMotionActivity) -> Void, status: @escaping (Status) -> Void) {
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
