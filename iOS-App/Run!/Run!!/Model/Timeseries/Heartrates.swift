//
//  HeartrateCollection.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 16.03.22.
//

import Foundation

struct Heartrate: Codable, Identifiable, Dated {
    var date: Date {timestamp}
    let id: UUID
    let timestamp: Date
    let heartrate: Int
    let isOriginal: Bool
    let peripheralName: String?
    
    // Optional values, if supported by the device and contained in this notification
    let skinIsContacted: Bool?
    let energyExpended: Int?
    let rr: [TimeInterval]?
    
    init(asOf: Date, peripheralName: String?, heartrate: Int) {
        self.timestamp = asOf
        self.heartrate = heartrate
        isOriginal = false
        self.peripheralName = peripheralName
        skinIsContacted = nil
        energyExpended = nil
        rr = nil
        id = UUID()
    }
    
    /// Parse CoreBluetooth characteristic
    init?(_ asOf: Date, _ peripheralName: String?, _ data: Data?) {
        guard let data = data, !data.isEmpty else {return nil}

        timestamp = asOf
        (heartrate, skinIsContacted, energyExpended, rr) = Heartrate.parse(data)
        isOriginal = true
        self.peripheralName = peripheralName
        id = UUID()
    }
    
    /// Interpolate
    init(asOf: Date, h0: Heartrate, h1: Heartrate) {
        timestamp = asOf
        
        let p = (h0.timestamp ..< h1.timestamp).p(asOf)
        if h0.heartrate == h1.heartrate {
            heartrate = h0.heartrate
        } else if h0.heartrate < h1.heartrate {
            heartrate = (h0.heartrate ..< h1.heartrate).mid(p)
        } else {
            heartrate = (h1.heartrate ..< h0.heartrate).mid(1 - p)
        }
        
        isOriginal = false
        
        if let h0EnergyExpended = h0.energyExpended, let h1EnergyExpended = h1.energyExpended {
            if h0EnergyExpended == h1EnergyExpended {
                energyExpended = h0EnergyExpended
            } else if h0EnergyExpended < h1EnergyExpended {
                energyExpended = (h0EnergyExpended ..< h1EnergyExpended).mid(p)
            } else {
                energyExpended = (h1EnergyExpended ..< h0EnergyExpended).mid(1 - p)
            }
        } else if let h0EnergyExpended = h0.energyExpended {
            energyExpended = h0EnergyExpended
        } else if let h1EnergyExpended = h1.energyExpended {
            energyExpended = h1EnergyExpended
        } else {
            energyExpended = nil
        }
        
        peripheralName = h0.peripheralName
        skinIsContacted = h0.skinIsContacted
        rr = nil
        id = UUID()
    }
    
    /// Extrapolate
    init(asOf: Date, heartrate: Heartrate) {
        timestamp = asOf
        self.heartrate = heartrate.heartrate
        
        isOriginal = false
        
        peripheralName = heartrate.peripheralName
        energyExpended = heartrate.energyExpended
        skinIsContacted = heartrate.skinIsContacted
        rr = heartrate.rr
        id = UUID()
    }
    
    private static func parse(_ data: Data) -> (Int, Bool?, Int?, [TimeInterval]?) {
        var i: Int = 0
        
        func uint8() -> Int {
            defer {i += 1}
            return Int(data[i])
        }
        
        func uint16() -> Int {
            defer {i += 2}
            return Int((UInt16(data[i+1]) << 8) | UInt16(data[i]))
        }

        // Read flags field
        let flags = uint8()
        let hrValueFormatIs16Bit = flags & (0x01 << 0) > 0
        let skinContactIsSupported = flags & (0x01 << 2) > 0
        let energyExpensionIsPresent = flags & (0x01 << 3) > 0
        let rrValuesArePresent = flags & (0x01 << 4) > 0

        // Get hr
        let heartrate = hrValueFormatIs16Bit ? uint16() : uint8()
        
        // Get skin contact if suported
        let skinIsContacted = skinContactIsSupported ? (flags & (0x01 << 1) > 0) : nil

        // Energy expended if present
        let energyExpended = energyExpensionIsPresent ? uint16() : nil
        
        // RR's as much as is in the data
        var rr = rrValuesArePresent ? [TimeInterval]() : nil
        while rrValuesArePresent && (i+1 < data.count) {
            rr?.append(TimeInterval(uint16()) / 1024)
        }

        return (heartrate, skinIsContacted, energyExpended, rr)
    }
}

extension Heartrate: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.timestamp == rhs.timestamp else {return false}
        guard lhs.heartrate == rhs.heartrate else {return false}
        guard lhs.isOriginal == rhs.isOriginal else {return false}
        return true
    }
}

class Heartrates {
    // MARK: Initialization
    init(intensities: Intensities, workout: Workout, totals: Totals) {
        self.intensities = intensities
        self.workout = workout
        self.totals = totals
    }
    
    // MARK: Interface
    private(set) var latestOriginal: Heartrate? = nil
    private(set) var heartrates = [Heartrate]()

    func appendOriginal(heartrate: Heartrate) {
        // Replace heartrates if latest original already eists. Insert heartrate if not
        let heartrateChanges: (dropped: [Heartrate], appended: [Heartrate]) = {
            if let latestOriginal = self.latestOriginal {
                return self.heartrates.replace(heartrate, replaceAfter: latestOriginal.date) {
                    Heartrate(asOf: $0, h0: latestOriginal, h1: heartrate)
                }
            } else {
                self.heartrates.append(heartrate)
                return (dropped: [], appended: [heartrate])
            }
        }()
        if !heartrateChanges.appended.isEmpty || !heartrateChanges.dropped.isEmpty {isDirty = true} // Mark dirty
        let intensityChanges = intensities.replace(heartrates: heartrateChanges.appended, replaceAfter: (latestOriginal ?? heartrate).date)
        latestOriginal = heartrate

        // Notify workout and totals about appends and removes
        workout.append(heartrate)
        totals.changed(intensities: intensityChanges.appended, intensityChanges.dropped, heartrateChanges.appended, heartrateChanges.dropped)
    }
    
    func trigger(asOf: Date) {
        guard let last = heartrates.last else {
            //  If HrmTwin is .notA*, create intensity = .cold
            let extendedIntensities = intensities.extend(asOf)
            
            // Notify totals about appends and removes
            totals.changed(intensities: extendedIntensities, [], [], [])
            return
        }

        // For all seconds between last and new time, extrapolate
        let extendedHeartrates = heartrates.extend(asOf) {Heartrate(asOf: $0, heartrate: last)}
        let intensityChanges = intensities.replace(heartrates: extendedHeartrates)
        
        if !extendedHeartrates.isEmpty {isDirty = true} // Mark dirty
        
        // Notify totals about appends and removes
        totals.changed(intensities: intensityChanges.appended, intensityChanges.dropped, extendedHeartrates, [])
    }
    
    func maintain(truncateAt: Date) {
        if heartrates.drop(before: truncateAt).isEmpty {return}
        latestOriginal = heartrates.first {$0.isOriginal}
        isDirty = true
    }
    
    func save() {
        guard isDirty, let url = Files.write(heartrates, to: "heartrates.json") else {return}
        log(url)
        isDirty = false
    }
    
    func load(asOf: Date) {
        guard let heartrates = Files.read(Array<Heartrate>.self, from: "heartrates.json") else {return}
        
        self.heartrates = heartrates.filter {$0.date.distance(to: asOf) <= signalTimeout}
        latestOriginal = self.heartrates.last(where: {$0.isOriginal})
        isDirty = false
    }

    // MARK: Implementation
    private var isDirty: Bool = false
    private unowned let intensities: Intensities
    private unowned let workout: Workout
    private unowned let totals: Totals
}
