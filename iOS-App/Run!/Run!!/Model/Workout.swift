//
//  WorkoutTwin.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import Foundation

enum WorkoutStatus: Equatable {
    case stopped
    case started(since: Date)
    case paused(since: Date)
}

class Workout: ObservableObject {
    @Published private(set) var status: WorkoutStatus = .stopped {
        willSet {
            log(status, newValue)
        }
    }
    
    func start(asOf: Date) {
        if case .started = status {return}
        
        status = .started(since: asOf)
    }
    
    func pause(asOf: Date) {
        if case .paused = status {return}
        
        status = .paused(since: asOf)
    }
    
    func stop(asOf: Date) {
        if case .stopped = status {return}
        
        status = .stopped
    }
}
