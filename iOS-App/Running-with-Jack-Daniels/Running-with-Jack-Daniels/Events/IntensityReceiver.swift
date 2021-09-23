//
//  IntensityReceiver.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 15.09.21.
//

import Foundation
import Combine

/// Calculate the Intensity
class IntensityReceiver {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    static var sharedInstance = IntensityReceiver()
    
    /// Use singleton @sharedInstance
    private init() {}

    // MARK: - Published
    
    public struct IntensityChange {
        let intensity: Intensity
        let when: Date
    }

    /// Last received intensity
    public private(set) var intensityChange: PassthroughSubject<IntensityChange, Error>!
    
    public func start() {
        log()
        intensityChange = PassthroughSubject<IntensityChange, Error>()
        
        prevAt = nil
        prevHrBpm = nil
        prevIntensity = .Easy
    }
    
    public func stop() {
        log()
        serialDispatchQueue.async {
            self.intensityChange.send(completion: .finished)
        }
    }

    /// New hertrate was received
    public func heartrate(_ hrBpm: Int, at: Date) {
        if hrBpm == prevHrBpm {return}
        
        let intensity = calcIntensity(hrBpm: hrBpm)
        send(intensity, at: calcAt(at))
        
        prevAt = at
        prevHrBpm = hrBpm
        prevIntensity = intensity
    }
    
    // MARK: - Private
    private var prevIntensity: Intensity = .Easy
    private var prevHrBpm: Int? = nil
    private var prevAt: Date? = nil
    
    private func calcIntensity(hrBpm: Int) -> Intensity {
        let hrMax = Database.sharedInstance.hrMax.value
        let hrResting = Database.sharedInstance.hrResting.value
        
        if hrMax.isFinite && hrResting.isFinite {
            return intensity4Hr(
                hrBpm: hrBpm,
                hrMaxBpm: Int(hrMax + 0.5),
                restingBpm: Int(hrResting + 0.5),
                prevIntensity: prevIntensity) ?? .Easy
        } else if hrMax.isFinite {
            return intensity4Hr(
                hrBpm: hrBpm,
                hrMaxBpm: Int(hrMax + 0.5),
                prevIntensity: prevIntensity) ?? .Easy
        } else {
            return .Easy
        }
    }
    
    private func calcAt(_ at: Date) -> Date {
        guard let prevAt = prevAt else {return at}
        
        return prevAt.advanced(by: prevAt.distance(to: at) / 2.0)
    }
    
    private func send(_ intensity: Intensity, at: Date) {
        guard prevIntensity != intensity else {return}

        serialDispatchQueue.async {
            self.intensityChange.send(IntensityChange(intensity: intensity, when: at))
        }
    }
}
