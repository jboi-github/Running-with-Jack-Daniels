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
    }
    
    private var prev: IntensityEvent? = nil
    private var intensity: ((IntensityEvent) -> Void)?
    
    func start(intensity: @escaping (IntensityEvent) -> Void) {
        prev = nil
        self.intensity = intensity
    }
    
    /// To be used by dispatcher to connect to `HeartrateProducer`
    func heartate(_ curr: HeartrateProducer.Heartrate) {
        func intensity(_ hr: Int, _ prevIntensity: Intensity?)
        -> (intensity: Intensity, range: Range<Int>?)
        {
            let hrMax = ProfileService.sharedInstance.hrMax.value ?? -1
            let hrResting = ProfileService.sharedInstance.hrResting.value ?? -1

            if hrMax > 0 && hrResting > 0 {
                let intensity = intensity4Hr(
                    hrBpm: hr,
                    hrMaxBpm: hrMax,
                    restingBpm: hrResting,
                    prevIntensity: prevIntensity)
                return (intensity, intensity.getHrLimit(hrMaxBpm: hrMax, restingBpm: hrResting))
            } else if hrMax > 0 {
                let intensity = intensity4Hr(
                    hrBpm: hr,
                    hrMaxBpm: hrMax,
                    prevIntensity: prevIntensity)
                return (intensity, intensity.getHrLimit(hrMaxBpm: hrMax))
            } else {
                return (.Cold, nil)
            }
        }

        let intensity = intensity(curr.heartrate, prev?.intensity)
        
        guard let hrRange = intensity.range else {
            self.prev = IntensityEvent(timestamp: curr.timestamp, intensity: intensity.intensity)
            self.intensity?(self.prev!)
            return
        }
        
        guard let prev = prev, prev.intensity != intensity.intensity else {
            self.prev = IntensityEvent(timestamp: curr.timestamp, intensity: intensity.intensity)
            self.intensity?(self.prev!)
            return
        }
        
        // Change in intensities happened.
        let prevTs = prev.timestamp > .distantPast ? prev.timestamp : curr.timestamp
        let t = hrRange.transform(curr.heartrate, to: prevTs ..< curr.timestamp)
        
        self.prev = IntensityEvent(timestamp: t, intensity: intensity.intensity)
        self.intensity?(self.prev!)
    }
}
