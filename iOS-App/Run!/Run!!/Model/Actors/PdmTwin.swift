//
//  PdmTwin.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.04.22.
//

import Foundation
import CoreMotion

enum PdmStatus{
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
    
    func truncation(asOf: Date, _ tolerance: TimeInterval = -signalTimeout) -> Date {
        switch self {
        case .paused(let since):
            return since.advanced(by: tolerance)
        default:
            return asOf.advanced(by: tolerance)
        }
    }
}

class PdmTwin {
    // MARK: initialization
    init(queue: DispatchQueue, steps: Steps) {
        self.queue = queue
        self.steps = steps
    }
    
    // MARK: Public interface
    func start(asOf: Date) {
        if case .started = status {return}
        
        // If coming from a pause, this is a resume -> do a query first
        if let pausedSince = pausedSince {
            _start(asOf: asOf, paused: pausedSince)
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
    private var pausedSince: Date? {
        if case .paused(let since) = status {return since}
        guard case .stopped = status else {return nil}
        
        if let since = UserDefaults.standard.object(forKey: PdmTwin.key) as? Date {
            status = .paused(since: since)
            return since
        }
        return nil
    }

    private(set) var status: AclStatus = .stopped(since: .distantPast) {
        willSet {
            log(status, newValue)
            if case .paused(let since) = newValue {
                UserDefaults.standard.set(since, forKey: PdmTwin.key)
            } else {
                UserDefaults.standard.removeObject(forKey: PdmTwin.key)
            }
        }
    }
    
    // MARK: Acl Implementation
    private var pedometer: CMPedometer?
    private unowned let queue: DispatchQueue
    private unowned let steps: Steps

    private func _start(asOf: Date, paused since: Date? = nil) {
        guard CMPedometer.isStepCountingAvailable() else {
            check("step counting not available on current device")
            status = .notAvailable(since: asOf)
            queue.async {
                self.steps.appendOriginal(
                    step: Step(
                        asOf: asOf,
                        numberOfSteps: 0,
                        distance: nil,
                        averageActiveSpeed: nil,
                        currentSpeed: nil,
                        currentCadence: nil,
                        metersAscended: nil,
                        metersDescended: nil))
            }
            return
        }

        if [.denied, .restricted].contains(CMPedometer.authorizationStatus()) {
            check("access to step counts denied")
            status = .notAllowed(since: asOf)
            queue.async {
                self.steps.appendOriginal(
                    step: Step(
                        asOf: asOf,
                        numberOfSteps: 0,
                        distance: nil,
                        averageActiveSpeed: nil,
                        currentSpeed: nil,
                        currentCadence: nil,
                        metersAscended: nil,
                        metersDescended: nil))
            }
            return
        }

        pedometer = CMPedometer()
        pedometer?.startUpdates(from: since ?? .now) {
            check($1)
            guard let pedometerData = $0 else {return}
            
            self.queue.async {
                self.steps.appendOriginal(step: Step(asOf: pedometerData.endDate, pedometerData)) // TODO: pedometerData contains a range
            }
        }
        status = .started(since: asOf)
    }

    private func _stop(asOf: Date) {
        pedometer?.stopUpdates()
        pedometer = nil
    }

    private static let key = "com.apps4live.Run!!.PdmPaused"
}

