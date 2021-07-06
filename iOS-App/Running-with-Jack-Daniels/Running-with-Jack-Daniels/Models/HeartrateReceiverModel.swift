//
//  HeartrateReceiverModel.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 13.06.21.
//

import Foundation
import HealthKit

/// Singleton to continiously receive HR data as it is written to Health
class HeartrateReceiverModel: ObservableObject {
    /// Access shared instance of this singleton
    static var sharedInstance = HeartrateReceiverModel()
    
    /// Get, valid-end time of latest received hartrate value in Health. Time is in UX timeformat, which is seconds since 1970.
    @Published var latestTimeUX: TimeInterval = 0.0
    
    /// Indicates, if Receiver is still active. After calling stop, the receiver will remain active, till a value is received, that was measured after the stop time.
    @Published var receiving: Receiving = .idle
    
    /// The data as it was received so far
    private(set) var data = [(TimeInterval, Int)]()
    
    /// Setup observer. This is called during startup in AppDelegate independent of foreground or background execution.
    func setup() {
        print("setup")
        
        // Is Healthkit avilable on device?
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {self.receiving = .error(HKError(.errorHealthDataUnavailable))}
            return
        }
        healthStore = HKHealthStore()
        
        // Get heartrates
        healthKitType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        
        // Setup Query
        self.observer = HKObserverQuery(sampleType: self.healthKitType, predicate: nil) {
            (query, completionHandler, error) in
            
            defer {
                // If you have subscribed for background updates you must call the completion handler here.
                completionHandler()
            }

            if let error = error {
                DispatchQueue.main.async {self.receiving = .error(error)}
                return
            }
            
            // Get the new heartrates
            print("Get at \(self.latestTimeUX)")
            let hrQuery = HKSampleQuery(
                sampleType: self.healthKitType,
                predicate: HKQuery.predicateForSamples(
                    withStart: Date(timeIntervalSince1970: self.latestTimeUX),
                    end: self.stopAt > self.latestTimeUX ? nil: Date(timeIntervalSince1970: self.stopAt),
                    options: .strictEndDate),
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]) {
                
                query, samples, error in
                
                if let error = error {
                    DispatchQueue.main.async {self.receiving = .error(error)}
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else {
                    print("samples is nil")
                    return
                }
                
                samples
                    .map {($0.endDate, 60 * $0.quantity.doubleValue(for: .hertz()))}
                    .forEach {print($0, $1)}
                if let latest = samples.last?.endDate.timeIntervalSince1970 {
                    DispatchQueue.main.async {
                        self.latestTimeUX = latest
                        if latest >= self.stopAt {self.stopImmediate()}
                    }
                }
            }
            self.healthStore.execute(hrQuery)
        }

        healthStore.enableBackgroundDelivery(for: healthKitType, frequency: .immediate) { success, error in
            print("enableBackgroundDelivery: \(success)")
            
            if let error = error {
                DispatchQueue.main.async {self.receiving = .error(error)}
            }
        }
    }
    
    /// Start receiving data. Ignore any values, that have an earlier timestamp
    func start(at from: TimeInterval) {
        guard case .idle = receiving else {return}
        
        // Requests permission to save and read the specified data types.
        healthStore.requestAuthorization(toShare: nil, read: [healthKitType]) { success, error in
            print("requestAuthorization: \(success)")
            
            if let error = error {
                DispatchQueue.main.async {self.receiving = .error(error)}
                return
            }
            DispatchQueue.main.async {
                self.receiving = .receiving
                self.latestTimeUX = from
                self.healthStore.execute(self.observer)
            }
        }
    }

    /// Stop receiving data. Receiver continues to run till receiving a value, that was actually measured at or after the given end time.
    func stop(at till: TimeInterval) {
        stopAt = till
        receiving = .stopping
    }
    
    enum Receiving {
        case receiving, idle, stopping, error(Error)
    }
    
    // MARK: Private
    
    private var healthStore: HKHealthStore! = nil
    private var observer: HKObserverQuery! = nil
    private var healthKitType: HKQuantityType! = nil
    private var stopAt: TimeInterval = Double.infinity
    
    // Setup Healthkit Store.
    private init() {}
    
    private func stopImmediate() {
        if let observer = observer {healthStore.stop(observer)}
        setup()
        receiving = .idle
    }
}
