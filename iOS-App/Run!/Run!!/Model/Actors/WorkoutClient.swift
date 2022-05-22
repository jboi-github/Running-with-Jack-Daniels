//
//  Workout2.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 06.05.22.
//

import Foundation

final class WorkoutClient: ClientDelegate {
    private var statusCallback: ((ClientStatus) -> Void)? {
        didSet {
            statusCallback?(isWorkingOut ? .started(since: .distantPast) : .stopped(since: .distantPast))
        }
    }
    @Persistent(key: "com.apps4live.Run!!.Workout.isWorkingOut") private var isWorkingOut: Bool = false
    
    init(
        queue: DispatchQueue,
        workoutTimeseries: TimeSeries<WorkoutEvent>,
        archive: @escaping (Date) -> Void)
    {
        self.queue = queue
        self.workoutTimeseries = workoutTimeseries
        self.archive = archive
    }
    
    func setStatusCallback(_ callback: @escaping (ClientStatus) -> Void) {
        self.statusCallback = callback
    }

    private unowned let queue: DispatchQueue
    private unowned let workoutTimeseries: TimeSeries<WorkoutEvent>
    private let archive: (Date) -> Void

    func start(asOf: Date) -> ClientStatus {
        set(at: asOf, true)
        return .started(since: asOf)
    }
    
    func stop(asOf at: Date) {set(at: at, false)}
    
    private func set(at: Date, _ isWorkingOut: Bool) {
        self.isWorkingOut = isWorkingOut
        queue.async { [self] in
            workoutTimeseries.insert(WorkoutEvent(date: at, isWorkingOut: isWorkingOut))
            archive(at)
        }
    }
}
