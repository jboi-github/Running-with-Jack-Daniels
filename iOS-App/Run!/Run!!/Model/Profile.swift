//
//  Profile.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 17.03.22.
//

import Foundation
import Combine
import HealthKit

enum Profile {
    // MARK: Interface
    
    /// Race accomplishments for best detemination of vdot
    struct Race: Codable {
        let duration: TimeInterval
        let distanceM: Int
        let date: Date
    }

    class Attribute<Value>: ObservableObject {
        struct Config {
            let readFromStore: () -> (Date, Value)?
            let readFromHealth: ((@escaping (Date, Value) -> Void) -> Void)?
            let calculate: (() -> Value?)?
            
            let writeToStore: (Date, Value) -> Void
            let writeToHealth: ((Date, Value) -> Void)?
        }
        
        enum Source {
            case store, health, calculated
            case manually
        }

        init(config: Config) {self.config = config}
        
        private let config: Config
        var linked: (() -> Void)? = nil
        
        @Published private(set) var source: Source = .calculated
        @Published private(set) var value: Value?
        @Published private(set) var timestamp: Date = .distantPast
        
        /// Read newest value. Also to be used, when external change happens.
        func onAppear() {
            var v = [(source: Source, timestamp: Date, value: Value)]()
            
            if let store = config.readFromStore() {v.append((.store, store.0, store.1))}
            if let calc = config.calculate?() {v.append((.calculated, .distantPast, calc))}
            if let value = value {v.append((source, timestamp, value))}
            
            if let m = v.max(by: {$0.timestamp < $1.timestamp}) {
                source = m.source
                timestamp = m.timestamp
                value = m.value
            }
            
            // HealthKit works async
            config.readFromHealth? { timestamp, value in
                guard self.value == nil || timestamp > self.timestamp else {return}
                
                self.source = .health
                self.timestamp = timestamp
                self.value = value
                self.linked?()
            }
        }
        
        /// Write newest value if changed or unknown by source.
        func onDisappear() {
            guard let value = value, timestamp > .distantPast else {return}

            if source != .store {config.writeToStore(timestamp, value)}
            if source != .health {config.writeToHealth?(timestamp, value)}
        }
        
        /// Change value
        func onChange(to newValue: Value?, asOf: Date = Date()) {
            source = .manually
            timestamp = asOf
            value = newValue
            
            linked?()
        }
        
        /// Reset value to what was read when screen appeared
        func onReset() {
            source = .calculated
            timestamp = .distantPast
            value = nil
            
            onAppear()
        }
    }
    
    /// setup in AppDelegate at App start.
    static func setup() {
        NotificationCenter
            .default
            .publisher(
                for: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                   object: nil)
            .sink { [self] notification in
                NSUbiquitousKeyValueStore.default.synchronize()
                if let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] {
                    keys.forEach { key in
                        switch key {
                        case "KvsBirthdayKey":
                            birthday.onAppear()
                        case "KvsGenderKey":
                            gender.onAppear()
                        case "KvsWeightKey":
                            weight.onAppear()
                        case "KvsHeightKey":
                            height.onAppear()
                        case "KvsVdotKey":
                            vdot.onAppear()
                        case "KvsHrMaxKey":
                            hrMax.onAppear()
                        case "KvsHrRestingKey":
                            hrResting.onAppear()
                        case "KvsSeasonGoalKey":
                            seasonGoal.onAppear()
                        case "KvsSeasonKey":
                            season.onAppear()
                        case "KvsBreaksKey":
                            breaks.onAppear()
                        case "KvsWeeklySumTimeKey":
                            weeklySumTime.onAppear()
                        case "KvsWeeklyMaxDaysKey":
                            weeklyMaxDays.onAppear()
                        case "KvsWeeklyMaxQsKey":
                            weeklyMaxQs.onAppear()
                        case "KvsHrLimitsKey":
                            hrLimits.onAppear()
                        default:
                            log(key)
                        }
                    }
                }
            }
            .store(in: &Profile.sinks)
        Profile.onAppear()
    }
    
    static func onAppear() {
        // Values might be dependent on other values. Link them together.
        birthday.linked = {
            self.hrMax.onAppear()
        }
        gender.linked = {
            self.hrMax.onAppear()
        }
        weight.linked = {
            self.hrMax.onAppear()
        }
        hrMax.linked = {
            self.hrLimits.onAppear()
        }
        hrResting.linked = {
            self.hrLimits.onAppear()
        }

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
    
    static func onDisappear() {
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
        hrLimits.onDisappear()
    }
    
    // Users profile
    static let birthday = Attribute<Date>(
        config: Attribute<Date>.Config(
            readFromStore: {Store.read(for: "KvsBirthdayKey")},
            readFromHealth: Profile.getBirthday,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsBirthdayKey")},
            writeToHealth: nil))
    static let gender = Attribute<Run.Gender>(
        config: Attribute<Run.Gender>.Config(
            readFromStore: {Store.read(for: "KvsGenderKey")},
            readFromHealth: Profile.getGender,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsGenderKey")},
            writeToHealth: nil))
    static let weight = Attribute<Double>(
        config: Attribute<Double>.Config(
            readFromStore: {Store.read(for: "KvsWeightKey")},
            readFromHealth: Profile.getWeightKg,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsWeightKey")},
            writeToHealth: Profile.shareWeightKg))
    static let height = Attribute<Double>(
        config: Attribute<Double>.Config(
            readFromStore: {Store.read(for: "KvsHeightKey")},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsHeightKey")},
            writeToHealth: Profile.shareHeightM))

    // Users status quo
    static let vdot = Attribute<[Race]>(
        config: Attribute<[Race]>.Config(
            readFromStore: {Store.read(for: "KvsVdotKey")},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsVdotKey")},
            writeToHealth: nil))
    static let hrMax = Attribute<Int>(
        config: Attribute<Int>.Config(
            readFromStore: {Store.read(for: "KvsHrMaxKey")},
            readFromHealth: nil,
            calculate: Profile.calcHrMax,
            writeToStore: {Store.write($1, at: $0, for: "KvsHrMaxKey")},
            writeToHealth: nil))
    static let hrResting = Attribute<Int>(
        config: Attribute<Int>.Config(
            readFromStore: {Store.read(for: "KvsHrRestingKey")},
            readFromHealth: Profile.getRestingHr,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsHrRestingKey")},
            writeToHealth: Profile.shareRestingHr))

    // HR-Limits
    static let hrLimits = Attribute<[Run.Intensity: Range<Int>]>(
        config: Attribute<[Run.Intensity: Range<Int>]>.Config(
            readFromStore: {Store.read(for: "KvsHrLimitsKey")},
            readFromHealth: nil,
            calculate: Profile.calcHrLimits,
            writeToStore: {Store.write($1, at: $0, for: "KvsHrLimitsKey")},
            writeToHealth: nil))

    // Season metadata
    static let seasonGoal = Attribute<Plan.Goal>(
        config: Attribute<Plan.Goal>.Config(
            readFromStore: {Store.read(for: "KvsSeasonGoalKey")},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsSeasonGoalKey")},
            writeToHealth: nil))
    static let season = Attribute<ClosedRange<Date>>(
        config: Attribute<ClosedRange<Date>>.Config(
            readFromStore: {Store.read(for: "KvsSeasonKey")},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsSeasonKey")},
            writeToHealth: nil))
    static let breaks = Attribute<[ClosedRange<Date>]>(
        config: Attribute<[ClosedRange<Date>]>.Config(
            readFromStore: {Store.read(for: "KvsBreaksKey")},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsBreaksKey")},
            writeToHealth: nil))

    // Weekly constraints
    static let weeklySumTime = Attribute<TimeInterval>(
        config: Attribute<TimeInterval>.Config(
            readFromStore: {Store.read(for: "KvsWeeklySumTimeKey")},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsWeeklySumTimeKey")},
            writeToHealth: nil))
    static let weeklyMaxDays = Attribute<Int>(
        config: Attribute<Int>.Config(
            readFromStore: {Store.read(for: "KvsWeeklyMaxDaysKey")},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsWeeklyMaxDaysKey")},
            writeToHealth: nil))
    static let weeklyMaxQs = Attribute<Int>(
        config: Attribute<Int>.Config(
            readFromStore: {Store.read(for: "KvsWeeklyMaxQsKey")},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsWeeklyMaxQsKey")},
            writeToHealth: nil))

    // MARK: - Implementation
    
    private static var sinks = Set<AnyCancellable>()
    
    // MARK: Calculations
    
    private static func calcHrMax() -> Int? {
        let birthday = Profile.birthday.value
        let gender = Profile.gender.value
        let weight = Profile.weight.value
        
        if let birthday = birthday, let gender = gender, let weight = weight {
            return Run.hrMaxBpm(birthday: birthday, gender: gender, weightKg: weight)
        } else if let birthday = birthday, let gender = gender {
            return Run.hrMaxBpm(birthday: birthday, gender: gender)
        } else {
            return nil
        }
    }
    
    private static func calcHrLimits() -> [Run.Intensity: Range<Int>] {
        guard let hrMax = Profile.hrMax.value else {
            return [:]
        }
        guard let hrResting = Profile.hrResting.value else {
            return Run.hrLimits(hrMaxBpm: hrMax)
        }
        return Run.hrLimits(hrMaxBpm: hrMax, restingHrBpm: hrResting)
    }
    
    // MARK: Read from HealthKit
    
    private static func getWeightKg(_ completion: @escaping (Date, Double) -> Void) {
        Health
            .authorizedReadLatestSample(
                completion,
                typeId: .bodyMass,
                unit: .gramUnit(with: .kilo))
    }
    
    private static func getBirthday(_ completion: @escaping (Date, Date) -> Void) {
        Health
            .authorizedReadCharacteristic(completion) {
                guard let birthday = try $0.dateOfBirthComponents().date else {
                    throw HKError(.errorNoData)
                }
                return birthday
            }
    }
    
    private static func getGender(_ completion: @escaping (Date, Run.Gender) -> Void) {
        Health
            .authorizedReadCharacteristic({ timestamp, gender in
                switch gender {
                case .female:
                    completion(timestamp, .female)
                case .male:
                    completion(timestamp, .male)
                default:
                    break
                }
            }, value: {
                try $0.biologicalSex().biologicalSex
            })
    }

    private static func getHeightM(_ completion: @escaping (Date, Double) -> Void) {
        Health
            .authorizedReadLatestSample(
                completion,
                typeId: .height,
                unit: .meter())
    }

    private static func getRestingHr(_ completion: @escaping (Date, Int) -> Void) {
        Health
            .authorizedReadLatestSample(
                {completion($0, $1 * 60)},
                typeId: .restingHeartRate,
                unit: .hertz())
    }

    // MARK: Share with HealthKit
    
    private static func shareWeightKg(_ timestamp: Date, _ weight: Double) {
        Health
            .authorizedShare(
                typeId: .bodyMass,
                unit: .gramUnit(with: .kilo),
                value: weight,
                timestamp: timestamp)
    }
    
    private static func shareHeightM(_ timestamp: Date, _ height: Double) {
        Health
            .authorizedShare(
                typeId: .height,
                unit: .meter(),
                value: height,
                timestamp: timestamp)
    }
    
    private static func shareRestingHr(_ timestamp: Date, _ hr: Int) {
        Health
            .authorizedShare(
                typeId: .restingHeartRate,
                unit: .hertz(),
                value: Double(hr) / 60.0,
                timestamp: timestamp)
    }
}
