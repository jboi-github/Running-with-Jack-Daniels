//
//  AclTwin.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import Foundation
import CoreMotion

enum AclStatus {
    case stopped(since: Date)
    case started(since: Date)
    case paused(since: Date)
    case notAllowed(since: Date)
    case notAvailable(since: Date)
    
    var since: Date {
        switch self {
        case .stopped(let since):
            return since
        case .started(let since):
            return since
        case .paused(let since):
            return since
        case .notAllowed(let since):
            return since
        case .notAvailable(let since):
            return since
        }
    }
    
    func truncation(asOf: Date, _ tolerance: TimeInterval = -600) -> Date {
        switch self {
        case .paused(let since):
            return since.advanced(by: tolerance)
        default:
            return asOf.advanced(by: tolerance)
        }
    }
}

class AclTwin {
    // MARK: initialization
    init(queue: DispatchQueue, motions: Motions) {
        self.queue = queue
        self.motions = motions
    }
    
    // MARK: Public interface
    func start(asOf: Date) {
        if case .started = status {return}
        
        // If coming from a pause, this is a resume -> do a query first
        if isPaused {
            _start(asOf: asOf, paused: status.since)
        } else {
            _start(asOf: asOf)
        }
    }
    
    func stop(asOf: Date) {
        if case .stopped = status {return}
        _stop(asOf: asOf)
        status = .stopped(since: asOf)
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
    
    private(set) var status: AclStatus = .stopped(since: .distantPast) {
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
    private unowned let queue: DispatchQueue
    private unowned let motions: Motions

    private func _start(asOf: Date, paused since: Date? = nil) {
        guard CMMotionActivityManager.isActivityAvailable() else {
            check("motion data not available on current device")
            status = .notAvailable(since: asOf)
            queue.async {self.motions.appendOriginal(motion: Motion(asOf: asOf, motion: .invalid))}
            return
        }
        
        if [.denied, .restricted].contains(CMMotionActivityManager.authorizationStatus()) {
            check("access to motion data denied")
            status = .notAllowed(since: asOf)
            queue.async {self.motions.appendOriginal(motion: Motion(asOf: asOf, motion: .invalid))}
            return
        }

        motionActivityManager = CMMotionActivityManager()
        if let since = since {
            queryActivityStarting(from: since, to: asOf, completion: startActivityUpdates) // Ensure to process query results first
        } else {
            startActivityUpdates()
        }
        status = .started(since: asOf)
    }
    
    private func _stop(asOf: Date) {
        motionActivityManager?.stopActivityUpdates()
        motionActivityManager = nil
    }
    
    private func queryActivityStarting(from: Date, to: Date, completion: (() -> Void)? = nil) {
        motionActivityManager?.queryActivityStarting(from: from, to: to, to: .current ?? .main) {
            check($1)
            guard let activities = $0 else {return}
            log(activities)
            
            self.queue.async {
                activities.forEach {
                    self.motions.appendOriginal(motion: Motion($0))
                }
            }
            completion?()
        }
    }
    
    private func startActivityUpdates() {
        motionActivityManager?.startActivityUpdates(to: .current ?? .main) {
            guard let activity = $0 else {return}
            if activity.confidence == .low {return} // TODO: Needs a more intelligent filter
            log(activity)
            
            self.queue.async {self.motions.appendOriginal(motion: Motion(activity))}
            
        }
    }
}

private let key = "com.apps4live.Run!!.AclPaused"