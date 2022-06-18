//
//  IntensityProducer.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import Foundation

class IntensityProducer {
    struct IntensityEvent {
        let timestamp: Date
        let intensity: Intensity
        
        static var zero: IntensityEvent {IntensityEvent(timestamp: .distantPast, intensity: .Cold)}
    }
    
    private var intensity: ((IntensityEvent) -> Void)?
    private var constantIntensity: IntensityEvent? = nil
    
    private var prevHeartrate: Int = -1
    private var prevIntensity = Intensity.Cold
    private var prevTimestamp = Date.distantPast
    
    func start(intensity: @escaping (IntensityEvent) -> Void) {
        prevHeartrate = -1
        prevIntensity = .Cold
        prevTimestamp = .distantPast
        
        self.intensity = intensity
        constantIntensity = nil
    }
    
    /// Optionally send a constant activity, e.g. in case of an error or missing authoritization
    func afterStart() {
        guard let constantIntensity = constantIntensity else {return}
        intensity?(constantIntensity)
    }

    /// To be used by dispatcher to connect to `HeartrateProducer`
    func heartate(_ curr: HeartrateProducer.Heartrate) {
        guard let hrLimits = ProfileService.sharedInstance.hrLimits.value else {return}
        let intensity = intensity4Hr(
            hrBpm: curr.heartrate,
            prevIntensity: prevIntensity,
            limits: hrLimits)
        defer {
            self.prevHeartrate = curr.heartrate
            self.prevIntensity = intensity
            self.prevTimestamp = curr.timestamp
        }

        // No change -> no update, except first
        if prevIntensity == intensity && prevTimestamp > .distantPast {return}
        
        // First time change
        guard let limit = hrLimits[intensity], prevTimestamp > .distantPast else {
            self.intensity?(IntensityEvent(timestamp: curr.timestamp, intensity: intensity))
            return
        }
        
        // When exactly did the change happen? Two limit crossings are possible
        let crossingAt = prevHeartrate <= curr.heartrate ?
            (prevHeartrate ..< curr.heartrate)
                .transform(limit.lowerBound, to: prevTimestamp ..< curr.timestamp)
        :
            curr
                .timestamp
                .advanced(
                    by: -(curr.heartrate ..< prevHeartrate)
                        .transform(
                            limit.upperBound,
                            to: 0.0 ..< prevTimestamp.distance(to: curr.timestamp)))
        let crossingAtNormalized = min(curr.timestamp, max(prevTimestamp, crossingAt))
        self.intensity?(IntensityEvent(timestamp: crossingAtNormalized, intensity: intensity))
    }
    
    /// To be used by dispatcher to connect to `BleProducer`
    func status(_ status: BleProducer.Status) {
        switch status {
        case .nonRecoverableError(let asOf, _):
            constantIntensity = IntensityEvent(timestamp: asOf, intensity: .Cold)
        case .notAuthorized(let asOf):
            constantIntensity = IntensityEvent(timestamp: asOf, intensity: .Cold)
        case .started(let asOf):
            constantIntensity = IntensityEvent(timestamp: asOf, intensity: .Cold)
        default:
            constantIntensity = nil
        }
    }
}
