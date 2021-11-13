//
//  ProfileService.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import Foundation
import Combine
import HealthKit

/*
 Quellen:
 - User Defaults (immer möglich)
 - HealthKit (wenn lesen erlaubt)
 - Calculation (wenn beide anderen Werte nicht existieren oder nicht erlaubt sind)
 Sind User Defaults und Healthkit verfügbar, dann nimm den neueren Eintrag
 
 Anzeige:
 - Manueller Input (hand)
 - Aus Healthkit (herz)
 - Berechnet/Default-Wert (f(x))
 
 Speicher: (schreiben, wenn verändert wurde)
 - User Defaults (immer, wenn in UserDefault ein anderer Wert steht)
 - HealthKit (wenn erlaubt und HealthKit Wert anders ist)
 
 User öffnet Anzeige <- Daten werden gelesen
 User ändert Werte <- Daten werden als verändert markiert und erhalten als Quelle "manuell"
 User pausiert/schließt Anzeige <- Daten werden geschrieben
 
 Design:
 - Use `NSUbiquitousKeyValueStore` instead of User Defaults
    - Also change for UUID preferences (primary, ignored)
    - Setup capabilities
    - Store always time with the value (always dictionary)
    - Setup notification early in AppDelegate
 
 - Reading:
    - Read from KV-Store, HK where allowed and calculate with `.distantPast` as timestamp.
    - Take newest of the existing values for the attribute.
 
 - On manual change:
    - Mark as `changed` so it will be synced later when writing.
    - Set timestamp to `now`.
 
 - On change from iCloud:
    - Setup notification at start of app.
    - Do re-read value for attribute. Include actual value on screen into prioritized picking.
 
 - Writing:
    - Write whenever App goes to backround.
    - if on-screen is newer then KV-Store -> write to KV-Store
    - if on-screen is newer then HK and HK allowed to write -> write to HK (this will also sync HK from icloud, if changed earlier)
 */

class ProfileService {
    static let sharedInstance = ProfileService()
    
    private init() {}
    
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
            let readFromHealth: ( (@escaping (Date, Value) -> Void) -> Void)?
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
                guard self.value == nil || timestamp >= self.timestamp else {return}
                
                self.source = .health
                self.timestamp = timestamp
                self.value = value
            }
        }
        
        /// Write newest value if changed or unknown by source.
        func onDisappear() {
            guard let value = value, timestamp > .distantPast else {return}

            if source != .store {config.writeToStore(timestamp, value)}
            if source != .health {config.writeToHealth?(timestamp, value)}
        }
        
        /// Change value
        func onChange(to newValue: Value) {
            source = .manually
            timestamp = Date()
            value = newValue
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
    func setupNotification() {
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
            .store(in: &sinks)
    }
    
    func onAppear() {
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
        
        // Values might be dependent on other values. So try a second time for calculations.
        vdot.onAppear()
        hrMax.onAppear()
        hrResting.onAppear()
        season.onAppear()
        hrLimits.onAppear()
    }
    
    func onDisappear() {
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
    let birthday = Attribute<Date>(
        config: Attribute<Date>.Config(
            readFromStore: {Store.read(for: "KvsBirthdayKey")},
            readFromHealth: ProfileService.getBirthday,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsBirthdayKey")},
            writeToHealth: nil))
    let gender = Attribute<Gender>(
        config: Attribute<Gender>.Config(
            readFromStore: {Store.read(for: "KvsGenderKey")},
            readFromHealth: ProfileService.getGender,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsGenderKey")},
            writeToHealth: nil))
    let weight = Attribute<Double>(
        config: Attribute<Double>.Config(
            readFromStore: {Store.read(for: "KvsWeightKey")},
            readFromHealth: ProfileService.getWeightKg,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsWeightKey")},
            writeToHealth: ProfileService.shareWeightKg))
    let height = Attribute<Double>(
        config: Attribute<Double>.Config(
            readFromStore: {Store.read(for: "KvsHeightKey")},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsHeightKey")},
            writeToHealth: ProfileService.shareHeightM))

    // Users status quo
    let vdot = Attribute<[Race]>(
        config: Attribute<[Race]>.Config(
            readFromStore: {Store.read(for: "KvsVdotKey")},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsVdotKey")},
            writeToHealth: nil))
    let hrMax = Attribute<Int>(
        config: Attribute<Int>.Config(
            readFromStore: {Store.read(for: "KvsHrMaxKey")},
            readFromHealth: nil,
            calculate: ProfileService.calcHrMax,
            writeToStore: {Store.write($1, at: $0, for: "KvsHrMaxKey")},
            writeToHealth: nil))
    let hrResting = Attribute<Int>(
        config: Attribute<Int>.Config(
            readFromStore: {Store.read(for: "KvsHrRestingKey")},
            readFromHealth: ProfileService.getRestingHr,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsHrRestingKey")},
            writeToHealth: ProfileService.shareRestingHr))

    // Season metadata
    let seasonGoal = Attribute<Goal>(
        config: Attribute<Goal>.Config(
            readFromStore: {Store.read(for: "KvsSeasonGoalKey")},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsSeasonGoalKey")},
            writeToHealth: nil))
    let season = Attribute<ClosedRange<Date>>(
        config: Attribute<ClosedRange<Date>>.Config(
            readFromStore: {Store.read(for: "KvsSeasonKey")},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsSeasonKey")},
            writeToHealth: nil))
    let breaks = Attribute<[ClosedRange<Date>]>(
        config: Attribute<[ClosedRange<Date>]>.Config(
            readFromStore: {Store.read(for: "KvsBreaksKey")},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsBreaksKey")},
            writeToHealth: nil))

    // Weekly constraints
    let weeklySumTime = Attribute<TimeInterval>(
        config: Attribute<TimeInterval>.Config(
            readFromStore: {Store.read(for: "KvsWeeklySumTimeKey")},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsWeeklySumTimeKey")},
            writeToHealth: nil))
    let weeklyMaxDays = Attribute<Int>(
        config: Attribute<Int>.Config(
            readFromStore: {Store.read(for: "KvsWeeklyMaxDaysKey")},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsWeeklyMaxDaysKey")},
            writeToHealth: nil))
    let weeklyMaxQs = Attribute<Int>(
        config: Attribute<Int>.Config(
            readFromStore: {Store.read(for: "KvsWeeklyMaxQsKey")},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {Store.write($1, at: $0, for: "KvsWeeklyMaxQsKey")},
            writeToHealth: nil))

    // HR-Limits
    let hrLimits = Attribute<[Intensity: Range<Int>]>(
        config: Attribute<[Intensity: Range<Int>]>.Config(
            readFromStore: {Store.read(for: "KvsHrLimitsKey")},
            readFromHealth: nil,
            calculate: ProfileService.calcHrLimits,
            writeToStore: {Store.write($1, at: $0, for: "KvsHrLimitsKey")},
            writeToHealth: nil))

    // MARK: - Implementation
    
    private var sinks = Set<AnyCancellable>()
    
    // MARK: Calculations
    
    private static func calcHrMax() -> Int? {
        let birthday = ProfileService.sharedInstance.birthday.value
        let gender = ProfileService.sharedInstance.gender.value
        let weight = ProfileService.sharedInstance.weight.value
        
        if let birthday = birthday, let gender = gender, let weight = weight {
            return hrMaxBpm(birthday: birthday, gender: gender, weightKg: weight)
        } else if let birthday = birthday, let gender = gender {
            return hrMaxBpm(birthday: birthday, gender: gender)
        } else {
            return nil
        }
    }
    
    private static func calcHrLimits() -> [Intensity: Range<Int>] {
        let hrMax = ProfileService.sharedInstance.hrMax.value
        let hrResting = ProfileService.sharedInstance.hrResting.value
        
        return Intensity.allCases.reduce(into: [Intensity: Range<Int>]()) { partialResult, intensity in
            if let hrMax = hrMax,
                let hrResting = hrResting,
                let hrLimit = intensity.getHrLimit(hrMaxBpm: hrMax, restingBpm: hrResting)
            {
                partialResult[intensity] = hrLimit
            } else if let hrMax = hrMax, let hrLimit = intensity.getHrLimit(hrMaxBpm: hrMax) {
                partialResult[intensity] = hrLimit
            }
        }
    }
    
    // MARK: Read from HealthKit
    
    private static func getWeightKg(_ completion: @escaping (Date, Double) -> Void) {
        HealthKitHandling
            .authorizedReadLatestSample(
                completion,
                typeId: .bodyMass,
                unit: .gramUnit(with: .kilo))
    }
    
    private static func getBirthday(_ completion: @escaping (Date, Date) -> Void) {
        HealthKitHandling
            .authorizedReadCharacteristic(completion) {
                guard let birthday = try $0.dateOfBirthComponents().date else {
                    throw HKError(.errorNoData)
                }
                return birthday
            }
    }
    
    private static func getGender(_ completion: @escaping (Date, Gender) -> Void) {
        HealthKitHandling
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
        HealthKitHandling
            .authorizedReadLatestSample(
                completion,
                typeId: .height,
                unit: .meter())
    }

    private static func getRestingHr(_ completion: @escaping (Date, Int) -> Void) {
        HealthKitHandling
            .authorizedReadLatestSample(
                {completion($0, $1 * 60)},
                typeId: .restingHeartRate,
                unit: .hertz())
    }

    // MARK: Share with HealthKit
    
    private static func shareWeightKg(_ timestamp: Date, _ weight: Double) {
        HealthKitHandling
            .authorizedShare(
                typeId: .bodyMass,
                unit: .gramUnit(with: .kilo),
                value: weight,
                timestamp: timestamp)
    }
    
    private static func shareHeightM(_ timestamp: Date, _ height: Double) {
        HealthKitHandling
            .authorizedShare(
                typeId: .height,
                unit: .meter(),
                value: height,
                timestamp: timestamp)
    }
    
    private static func shareRestingHr(_ timestamp: Date, _ hr: Int) {
        HealthKitHandling
            .authorizedShare(
                typeId: .restingHeartRate,
                unit: .hertz(),
                value: Double(hr) / 60.0,
                timestamp: timestamp)
    }
}
