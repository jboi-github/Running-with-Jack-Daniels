//
//  AclMotionReceiver.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 07.08.21.
//

import CoreMotion

class AclMotionReceiver: ObservableObject {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    static var sharedInstance = AclMotionReceiver()
    
    /// Use singleton @sharedInstance
    private init() {
        log(CMMotionActivityManager.authorizationStatus().rawValue)
        guard CMMotionActivityManager.isActivityAvailable() else {
            _ = check("Core Motion Activity detection not available")
            motionActivityManager = nil
            return
        }
        motionActivityManager = CMMotionActivityManager()
    }

    // MARK: - Published
    
    public struct IsRunning {
        let isRunning: Bool
        let when: Date
    }
    
    public enum Status {
        case off
        case stationary
        case walking
        case running
        case cycling
        case automotion
    }
    
    /// Indicates, if Receiver is still active.
    @Published public private(set) var receiving = Status.off

    /// Last received location
    @Published public private(set) var isRunning = IsRunning(
        isRunning: false,
        when: Date.distantPast)
    
    public func start() {
        log()
        motionActivityManager?.startActivityUpdates(to: .main) { activity in
            guard let activity = activity else {return}
            log(activity.startDate, activity.confidence.rawValue,
                activity.stationary, activity.unknown, activity.walking, activity.running,
                activity.cycling, activity.automotive)
            
            if let status = self.status(for: activity) {self.receiving = status}

            self.isRunning = IsRunning(
                isRunning: (activity.walking || activity.running || activity.cycling) && !activity.stationary,
                when: activity.startDate)
        }
    }
    
    public func stop() {
        log()
        guard let motionActivityManager = motionActivityManager else {return}
        motionActivityManager.stopActivityUpdates()
        receiving = .off
    }
    
    // MARK: - Private
    private let motionActivityManager: CMMotionActivityManager?
    
    private func status(for activity: CMMotionActivity) -> Status? {
        if activity.stationary {
            return .stationary
        } else if activity.walking {
            return .walking
        } else if activity.running {
            return .running
        } else if activity.cycling {
            return .cycling
        } else if activity.automotive {
            return .automotion
        }
        return nil
    }
}

extension AclMotionReceiver.IsRunning: Codable {}
