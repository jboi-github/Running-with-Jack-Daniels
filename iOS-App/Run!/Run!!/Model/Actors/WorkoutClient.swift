//
//  Workout2.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 06.05.22.
//

import Foundation

final class WorkoutClient: ClientDelegate {
    weak var client: Client<WorkoutClient>? {
        didSet {
            client?.statusChanged(to: isWorkingOut ? .started(since: .distantPast) : .stopped(since: .distantPast))
        }
    }
    
    @Persistent(key: "com.apps4live.Run!!.Workout.isWorkingOut") private var isWorkingOut: Bool = false
    
    init(queue: DispatchQueue) {
        self.queue = queue
    }
    
    private unowned let queue: DispatchQueue

    func start(asOf: Date) -> ClientStatus {
        set(at: asOf, true)
        return .started(since: asOf)
    }
    
    func stop(asOf at: Date) {set(at: at, false)}
    
    private func set(at: Date, _ isWorkingOut: Bool) {
        self.isWorkingOut = isWorkingOut
        queue.async {
            Files.append("\(at.timeIntervalSinceReferenceDate)\t\(isWorkingOut)", to: "workoutX.txt")
        }

    }
}
