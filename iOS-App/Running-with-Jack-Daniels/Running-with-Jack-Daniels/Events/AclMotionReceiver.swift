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
    private init() {}

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
        log(CMMotionActivityManager.authorizationStatus().rawValue)
        
        receiving = PassthroughSubject<Status, Error>()
        isRunning = PassthroughSubject<IsRunning, Error>()
        serialDispatchQueue.async {self.receiving.send(.off)}
        
        guard CMMotionActivityManager.isActivityAvailable() else {
            log()
            motionActivityManager = nil
            
            // Simulate "always running"
            receiving.send(.off)
            isRunning.send(IsRunning(isRunning: true, when: Date()))
            return
        }
        motionActivityManager = CMMotionActivityManager()

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
    
    public func stop(with error: Error? = nil) {
        log()
        _stop(with: error)
        serialDispatchQueue.async { [self] in
            receiving.send(completion: .finished)
            isRunning.send(completion: .finished)
        }
    }
    
    static let minRestartTimeout: TimeInterval = 5
    static let maxRestartTimeout: TimeInterval = 120
    static let factorRestartTimeout: TimeInterval = 2
    
    private(set) var restartTimeout: TimeInterval = minRestartTimeout
    
    func reset() {
        log("\(restartTimeout)")
        _stop(with: nil)
        serialDispatchQueue.asyncAfter(deadline: .now() + restartTimeout) {self.start()}
        restartTimeout = min(restartTimeout * Self.factorRestartTimeout, Self.maxRestartTimeout)
        
        serialDispatchQueue.async {self.receiving.send(.off)}
    }

    // MARK: - Private
    private func _stop(with error: Error?) {
        motionActivityManager?.stopActivityUpdates()
    }
    
    private var motionActivityManager: CMMotionActivityManager?
    
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
