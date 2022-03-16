//
//  AclTwin.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import Foundation
import CoreMotion
import UIKit

enum AclStatus {
    case stopped
    case started(since: Date)
    case paused(since: Date)
    case notAllowed(since: Date)
    case notAvailable(since: Date)
}

class AclTwin {
    // MARK: Public interface
    func start(asOf: Date) {
        if case .started = status {return}
        
        // If coming from a pause, this is a resume -> do a query first
        if case .paused(let since) = status {
            _start(asOf: asOf, paused: since)
        } else {
            _start(asOf: asOf)
        }
    }
    
    func stop(asOf: Date) {
        if case .stopped = status {return}
        _stop(asOf: asOf)
        AppTwin.shared.workout.stop(asOf: asOf)
        status = .stopped
    }

    func pause(asOf: Date) {
        _stop(asOf: asOf)
        status = .paused(since: asOf)
    }
    
    // MARK: Status handling
    private var isPaused: Bool {
        if case .paused = status {return true}
        guard case .stopped = status else {return false}
        
        if let since = UserDefaults.standard.object(forKey: key) as? Date {
            status = .paused(since: since)
            return true
        }
        return false
    }
    
    private(set) var status: AclStatus = .stopped {
        willSet {
            log(status, newValue)
            if case .paused(let since) = newValue {
                UserDefaults.standard.set(since, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
    
    // MARK: Acl Implementation
    private var motionActivityManager: CMMotionActivityManager?

    private func _start(asOf: Date, paused since: Date? = nil) {
        guard CMMotionActivityManager.isActivityAvailable() else {
            check("motion data not available on current device")
            status = .notAvailable(since: asOf)
            AppTwin.shared.workout.start(asOf: asOf)
            return
        }
        
        if [.denied, .restricted].contains(CMMotionActivityManager.authorizationStatus()) {
            check("access to motion data denied")
            status = .notAllowed(since: asOf)
            AppTwin.shared.workout.start(asOf: asOf)
            return
        }

        motionActivityManager = CMMotionActivityManager()
        if let since = since {
            motionActivityManager?.queryActivityStarting(from: since, to: asOf, to: .current ?? .main) {
                check($1)
                guard let activities = $0 else {return}
                log(activities)
                
                activities.forEach {
                    if $0.isActive {
                        AppTwin.shared.workout.start(asOf: $0.startDate)
                    } else {
                        AppTwin.shared.workout.pause(asOf: $0.startDate)
                    }
                    // TODO: Create IsActive and MotionType and inform corresponding collections
                }
            }
        }
        motionActivityManager?.startActivityUpdates(to: .current ?? .main) {
            guard let activity = $0 else {return}
            if activity.confidence == .low {return} // TODO: Needs a more intelligent filter
            log(activity)
            
            if activity.isActive {
                AppTwin.shared.workout.start(asOf: activity.startDate)
            } else {
                AppTwin.shared.workout.pause(asOf: activity.startDate)
            }
            // TODO: Create IsActive and MotionType and inform corresponding collections
        }
        status = .started(since: asOf)
    }
    
    private func _stop(asOf: Date) {
        motionActivityManager?.stopActivityUpdates()
        motionActivityManager = nil
    }
}

private let key = "com.apps4live.Run!!.AclPaused"

extension CMMotionActivity {
    var isActive: Bool {
        !stationary && (walking || running || cycling)
    }
}
