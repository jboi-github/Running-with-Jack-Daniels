//
//  AclMotionReceiver.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 07.08.21.
//

import CoreMotion
import Combine

class AclMotionReceiver {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    static var sharedInstance = AclMotionReceiver()
    
    /// Use singleton @sharedInstance
    private init() {
        log(CMMotionActivityManager.authorizationStatus().rawValue)
        guard CMMotionActivityManager.isActivityAvailable() else {
            let error = "Core Motion Activity detection not available"
            _ = check(error)
            motionActivityManager = nil
            
            receiving.send(completion: .failure(error))
            isRunning.send(completion: .failure(error))
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
    
    /// Indicates, if Receiver is active.
    public private(set) var receiving: PassthroughSubject<Status, Error>!

    /// Last received location
    public private(set) var isRunning: PassthroughSubject<IsRunning, Error>!
    
    public func start() {
        log()
        
        receiving = PassthroughSubject<Status, Error>()
        isRunning = PassthroughSubject<IsRunning, Error>()
        
        motionActivityManager?.startActivityUpdates(to: .current ?? .main) { activity in
            guard let activity = activity else {return}
            log(activity.startDate, activity.confidence.rawValue,
                activity.stationary, activity.unknown, activity.walking, activity.running,
                activity.cycling, activity.automotive)
            
            guard let status = self.status(for: activity) else {return}
            serialDispatchQueue.async {
                self.receiving.send(status)
                self.isRunning.send(
                    IsRunning(
                        isRunning: [.walking, .running, .cycling].contains(status),
                        when: activity.startDate))
            }
        }
    }
    
    public func stop() {
        log()
        guard let motionActivityManager = motionActivityManager else {return}
        motionActivityManager.stopActivityUpdates()
        
        serialDispatchQueue.async { [self] in
            receiving.send(.off)
            receiving.send(completion: .finished)
            isRunning.send(completion: .finished)
        }
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
