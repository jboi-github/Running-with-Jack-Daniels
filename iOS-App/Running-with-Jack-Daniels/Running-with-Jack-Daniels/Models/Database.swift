//
//  Data.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 07.07.21.
//

import Foundation
import SwiftUI

/// Keep data for users profile, goal, status quo, current planning and wekly constraints.
/// The data is taken from either manual input, health or a calculated default value. Manual input has highest prio, defaults lowest.
/// All data is written to UserDefaults and, if allowed by user and a corresponding variable exists, to health.
///
/// Events:
/// - init: Read from user defaults, overwrite by health where possible and allowed to. If variable is still empty, set to default.
/// - `hrMax` might be manually overwritten or calculated, using birthday, gender and optionally weight. So, if one of these changes, re-evaluate `hrMax`.
/// - If any variable changes, write it back to user defaults.
public class Database {
    // MARK: Initialization
    public static let sharedInstance = Database()
    private init() {}

    // MARK: Published and public
    // Users profile
    public let birthday = Attribute<Date>(
        forKey: "birthday", Date(),
        readHK: HealthKitModel.sharedInstance.getBirthday,
        onChange: {Database.sharedInstance.hrMax.recalc()})
    public let gender = Attribute<Gender>(
        forKey: "gender", .other,
        readHK: HealthKitModel.sharedInstance.getGender,
        onChange: {Database.sharedInstance.hrMax.recalc()})
    public let weight = Attribute<Double>(
        forKey: "weight", Double.nan,
        readHK: HealthKitModel.sharedInstance.getWeightKg,
        shareHK: HealthKitModel.sharedInstance.shareWeightKg,
        onChange: {Database.sharedInstance.hrMax.recalc()})
    public let height = Attribute<Double>(
        forKey: "height", Double.nan,
        readHK: HealthKitModel.sharedInstance.getHeightM,
        shareHK: HealthKitModel.sharedInstance.shareHeightM)

    // Users status quo
    public let vdot = Attribute<[Race]>(forKey: "vdot", [Race]())
    public let hrMax = Attribute<Double>(
        forKey: "hrMax", Double.nan,
        calc: calcHrMax,
        onChange: {Database.sharedInstance.hrLimits.recalc()})
    public let hrResting = Attribute<Double>(
        forKey: "hrResting", Double.nan,
        readHK: HealthKitModel.sharedInstance.getRestingHr,
        shareHK: HealthKitModel.sharedInstance.shareRestingHr,
        onChange: {
            Database.sharedInstance.hrMax.recalc()
            Database.sharedInstance.hrLimits.recalc()
        })

    // Season metadata
    public let seasonGoal = Attribute<Goal>(forKey: "seasonGoal", .mid5kTo15kOrCrossCountry)
    public let season = Attribute<ClosedRange<Date>>(
        forKey: "season",
        Date()...Date().addingTimeInterval(7*24*3600))
    public let breaks = Attribute<[ClosedRange<Date>]>(forKey: "breaks", [ClosedRange<Date>]())
    
    // Weekly constraints
    public let weeklySumTime = Attribute<TimeInterval>(forKey: "weeklySumTime", 0.0)
    public let weeklyMaxDays = Attribute<Int>(forKey: "weeklyMaxDays", 0)
    public let weeklyMaxQs = Attribute<Int>(forKey: "weeklyMaxQs", 0)
    
    /// HR-Limits are read-only and always calculated. Updated according to the underlying attributes like hrMax.
    public let hrLimits = Attribute<[Intensity : ClosedRange<Int>]>(
        forKey: "hrLimits",
        [Intensity:ClosedRange<Int>](),
        calc: calcHrLimits)

    /// Race accomplishments for best detemination of vdot
    public struct Race: Codable, Equatable {
        let duration: TimeInterval
        let distanceM: Int
        let date: Date
    }
    
    public enum Source {
        case manual, healthkit, calculated
    }
    
    public func onAppear() {
        birthday.onAppear()
        gender.onAppear()
        weight.onAppear()
        height.onAppear()
        
        vdot.onAppear()
        hrMax.onAppear()
        hrResting.onAppear()
        
        seasonGoal.onAppear()
        season.onAppear()
        breaks.onAppear()
        
        weeklySumTime.onAppear()
        weeklyMaxDays.onAppear()
        weeklyMaxQs.onAppear()
        
        hrLimits.onAppear()
    }
    
    public func onDisappear() {
        birthday.onDisappear()
        gender.onDisappear()
        weight.onDisappear()
        height.onDisappear()
        
        vdot.onDisappear()
        hrMax.onDisappear()
        hrResting.onDisappear()
        
        seasonGoal.onDisappear()
        season.onDisappear()
        breaks.onDisappear()
        
        weeklySumTime.onDisappear()
        weeklyMaxDays.onDisappear()
        weeklyMaxQs.onDisappear()
    }
    
    /// An attribute in the database. An attribute might be shared with healthkit or calculated or manually entered - in any combination.
    ///
    ///     Possbile combinations and the corresponding parameters:
    ///
    ///         | Calculated | Healthkit | Manually || onAppear | onDisppear | onChange
    ///         |      -     |     -     |    -     ||     -    |      -     |     -
    ///         |      -     |     -     |    X     ||   R-UD   |    W-UD    |     -
    ///         |      -     |     X     |    -     ||   R-HK   |    W-HK    |     -
    ///         |      -     |     X     |    X     ||  R-UD,HK |  W-UD,HK   |     C
    ///         |      X     |     -     |    -     ||    Cx    |      -     |     -
    ///         |      X     |     -     |    X     || R-UD,Cx  |    W-UD    |     C
    ///         |      X     |     X     |    -     || R-HK,Cx  |    W-HK    |     -
    ///         |      X     |     X     |    X     ||R-UD,HK,Cx|  W-UD,HK   |     C
    ///
    /// Here, the acronyms mean:
    /// - R-UD: Read from UserDefaults, set source to "manual".
    /// - W-UD: Check, if value has actually changed since `onAppear`and write to UserDefaults if so.
    /// - R-HK: Read from Healthkit with provided function. Set source to healthkit.
    /// - W-HK: Check, if value has actually changed since `onAppear`, check if function to share with healthkit was provided and share.
    /// - R-UD,HK: Read from UserDefaults like R-UD. If not present, read from healthkit like R-HK.
    /// - W-UD,HK: Share with healthkit like W-HK. If source indicates manual input write like W-UD, else and HK was successful remove from UD.
    /// - C: Set source to manual.
    /// - Cx: Calculate, if a function was provided
    /// - R-UD,HK,Cx: R-UD ?? R-HK ?? Cx
    public class Attribute<V>: ObservableObject where V: Codable, V: Equatable {
        fileprivate init(
            forKey: String, _ value: V,
            readHK: ((@escaping (V?, Error?) -> Void) -> Void)? = nil,
            shareHK: ((V, @escaping () -> Void) -> Void)? = nil,
            calc: (() -> V?)? = nil,
            onChange: (() -> Void)? = nil)
        {
            self.key = forKey
            self.value = value
            self.shadow = value
            self.readHK = readHK
            self.shareHK = shareHK
            self.calc = calc
            self.onChange = onChange
        }

        @Published public private(set) var source: Source = .calculated
        @Published public private(set) var value: V
        
        public func onAppear() {
            if let value: V = UserDefaults.read(forKey: key) {
                self.value = value
                self.source = .manual
                self.onChange?()
            } else if let calculation = self.calc?() {
                self.value = calculation
                self.source = .calculated
            }
            if let readHK = readHK {
                readHK { value, error in
                    _ = check(error)
                    if let value = value {
                        if self.source != .manual || value == self.value {
                            DispatchQueue.main.async {
                                self.value = value
                                self.source = .healthkit
                                self.onChange?()
                            }
                        }
                    } else if let calculation = self.calc?() {
                        DispatchQueue.main.async {
                            self.value = calculation
                            self.source = .calculated
                        }
                    }
                }
            }
            self.shadow = self.value
        }
        
        public func onDisappear() {
            if let value = value as? Double, !value.isFinite {return}

            if source == .manual {
                if shadow != value {UserDefaults.write(forKey: key, v: value)}
            } else {
                UserDefaults.write(forKey: key, v: V?(nil))
            }
            if shadow != value {shareHK?(value, {UserDefaults.write(forKey: self.key, v: V?(nil))})}
        }
        
        public var bound: Binding<V> {
            Binding<V> {
                self.value
            } set: {
                self.value = $0
                self.source = .manual
                self.onChange?()
            }
        }
        
        public var hasCalculator: Bool {calc != nil}
        public func recalc(force: Bool = false) {
            guard force || self.source == .calculated else {return}
            guard let value = calc?() else {return}
            
            self.value = value
            if force {self.source = .calculated}
            self.onChange?()
        }
        
        private let key: String
        private let readHK: ((@escaping (V?, Error?) -> Void) -> Void)?
        private let shareHK: ((V, @escaping () -> Void) -> Void)?
        private let calc: (() -> V?)?
        private var onChange: (() -> Void)?
        private var shadow: V // Check for changes.
    }
    
    public static func calcHrMax() -> Double
    {
        if let hrMax =
            hrMaxBpm(
                birthday: Database.sharedInstance.birthday.value,
                gender: Database.sharedInstance.gender.value,
                weightKg: Database.sharedInstance.weight.value) ??
            hrMaxBpm(
                birthday: Database.sharedInstance.birthday.value,
                gender: Database.sharedInstance.gender.value)
        {
            return Double(hrMax)
        } else {
            return Double.nan
        }
    }
    
    public static func calcHrLimits() -> [Intensity: ClosedRange<Int>] {
        if Database.sharedInstance.hrMax.value.isFinite && Database.sharedInstance.hrResting.value.isFinite {
            return Running_with_Jack_Daniels.hrLimits(
                hrMaxBpm: Int(Database.sharedInstance.hrMax.value),
                restingHrBpm: Int(Database.sharedInstance.hrResting.value))
        } else if Database.sharedInstance.hrMax.value.isFinite {
            return Running_with_Jack_Daniels.hrLimits(hrMaxBpm: Int(Database.sharedInstance.hrMax.value))
        } else {
            return [Intensity: ClosedRange<Int>]()
        }
    }
}

extension UserDefaults {
    /// Read from standard UserDefaults with the given key. Decode stored data as JSON document.
    /// - Parameter forKey: key to get data from in user defaults.
    /// - Returns: Decoded value of a `Codable` or `nil` if value with key was not found in user defaults or could not be decoded.
    static func read<V>(forKey: String) -> V? where V: Codable {
        if let data = standard.value(forKey: forKey) as? Data,
           let v = try? JSONDecoder().decode(V.self, from: data)
        {
            return v
        }
        return nil
    }
    
    /// Write to User Defaults if value was given. If value is `nil` remove entry from user defaults.
    /// - Parameters:
    ///   - forKey: key to put data to in user defaults.
    ///   - v: Value to be written or, if `nil` indicate to remove key.
    static func write<V>(forKey: String, v: V?) where V: Codable {
        if let v = v,
           let data = try? JSONEncoder().encode(v) {
            UserDefaults.standard.set(data, forKey: forKey)
        } else if v == nil {
            UserDefaults.standard.removeObject(forKey: forKey)
        }
    }
}

extension Double {
    public func format(_ format: String, ifNan: String = "NaN") -> String {
        String(format: self.isFinite ? format : ifNan, self)
    }
}
