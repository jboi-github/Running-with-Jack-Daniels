//
//  RunTimer.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 17.03.22.
//

import Foundation

class RunTimer: ObservableObject {
    // MARK: Initialization
    init(
        isInBackground: @escaping () -> Bool,
        queue: DispatchQueue,
        aclTwin: AclTwin,
        motions: Motions,
        heartrates: Heartrates,
        locations: Locations,
        isActives: IsActives,
        intensities: Intensities,
        distances: Distances)
    {
        self.isInBackground = isInBackground
        
        self.queue = queue
        self.aclTwin = aclTwin

        self.motions = motions
        self.heartrates = heartrates
        self.locations = locations
        
        self.isActives = isActives
        self.intensities = intensities
        self.distances = distances
    }
    
    // MARK: Interface
    @Published private(set) var date: Date = .distantPast
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {t in
            self.queue.async {
                self.task(asOf: t.fireDate)
            }
            self.date = t.fireDate
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: Implementation
    private var timer: Timer? = nil
    
    private let isInBackground: () -> Bool
    
    private unowned let queue: DispatchQueue
    private unowned let aclTwin: AclTwin
    
    private unowned let motions: Motions
    private unowned let heartrates: Heartrates
    private unowned let locations: Locations
    
    private unowned let isActives: IsActives
    private unowned let intensities: Intensities
    private unowned let distances: Distances

    private func task(asOf: Date) {
        motions.trigger(asOf: asOf)
        heartrates.trigger(asOf: asOf)
        distances.trigger(asOf: asOf)
        
        // Maintain motions, heartrates and locations to commit date
        let truncation = aclTwin.status.truncation(asOf: asOf)
        log(truncation)
        motions.maintain(truncateAt: truncation)
        heartrates.maintain(truncateAt: truncation)
        locations.maintain(truncateAt: truncation)
        
        // Save changes, if in background
        if isInBackground() {
            motions.save()
            heartrates.save()
            locations.save()

            isActives.save()
            intensities.save()
            distances.save()
        }
    }
}
