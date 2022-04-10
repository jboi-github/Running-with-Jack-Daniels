//
//  Intensities.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 17.03.22.
//

import Foundation

struct Intensity: Codable, Identifiable {
    let id: UUID
    let asOf: Date
    let intensity: Run.Intensity
    
    init(asOf: Date, intensity: Run.Intensity) {
        self.asOf = asOf
        self.intensity = intensity
        id = UUID()
    }

    /// Parse heartrate
    init(_ heartrate: Heartrate, prev: Run.Intensity?) {
        asOf = heartrate.timestamp
        
        if let hrLimits = Profile.hrLimits.value {
            intensity = Run.intensity4Hr(
                hrBpm: heartrate.heartrate,
                prevIntensity: prev,
                limits: hrLimits)
        } else {
            intensity = .Cold
        }
        id = UUID()
    }
}

extension Intensity: Equatable, Dated {
    var date: Date {asOf}
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.asOf == rhs.asOf else {return false}
        guard lhs.intensity == rhs.intensity else {return false}
        return true
    }
}

class Intensities {
    // MARK: Interface
    private(set) var intensities = [Intensity]()
    
    func replace(heartrates: [Heartrate], replaceAfter: Date = .distantFuture) -> (dropped: [Intensity], appended: [Intensity]) {
        var prev: Run.Intensity? = {
            if let prev = intensities[replaceAfter] {return prev.intensity}
            if let last = intensities.last, replaceAfter > last.date {return last.intensity}
            return nil
        }()
        let changes = intensities.replace(heartrates, replaceAfter: replaceAfter) {
            let intensity = Intensity($0, prev: prev)
            prev = intensity.intensity
            return intensity
        }
        if !changes.dropped.isEmpty || !changes.appended.isEmpty {isDirty = true} // mark dirty
        return changes
    }

    func extend(_ through: Date) -> [Intensity] {
        if let last = intensities.last {
            return intensities.extend(through) {Intensity(asOf: $0, intensity: last.intensity)}
        } else {
            let intensity = Intensity(asOf: through, intensity: .Cold)
            intensities.append(intensity)
            return [intensity]
        }
    }

    func maintain(truncateAt: Date) {
        if !intensities.drop(before: truncateAt).isEmpty {isDirty = true}
    }
    
    func save() {
        guard isDirty, let url = Files.write(intensities, to: "intensities.json") else {return}
        log(url)
        isDirty = false
    }
    
    func load(asOf: Date) {
        guard let intensities = Files.read(Array<Intensity>.self, from: "intensities.json") else {return}
        self.intensities = intensities.filter {$0.date.distance(to: asOf) <= signalTimeout}
        isDirty = false
    }
    
    // MARK: Implementation
    private var isDirty = false
}
