//
//  IntensityEventProducer.swift
//  RunEnricherKit
//
//  Created by Jürgen Boiselle on 25.10.21.
//

import Foundation
import Combine
import RunFormulasKit
import RunReceiversKit
import RunDatabaseKit

struct IntensityEvent {
    let timestamp: Date
    let intensity: Intensity
    
    static func fromHr(_ prevEvent: IntensityEvent, _ hrEvent: Heartrate) -> IntensityEvent {
        func intensity(_ prevIntensity: Intensity, _ hr: Int) -> (intensity: Intensity, range: Range<Int>?) {
            let hrMax = Database.sharedInstance.hrMax.value
            let hrResting = Database.sharedInstance.hrResting.value

            if hrMax.isFinite && hrResting.isFinite {
                let intensity = intensity4Hr(
                    hrBpm: hr,
                    hrMaxBpm: Int(hrMax + 0.5),
                    restingBpm: Int(hrResting + 0.5),
                    prevIntensity: prevIntensity)
                return (intensity, intensity.getHrLimit(
                    hrMaxBpm: Int(hrMax + 0.5),
                    restingBpm: Int(hrResting + 0.5)))
            } else if hrMax.isFinite {
                let intensity = intensity4Hr(
                    hrBpm: hr,
                    hrMaxBpm: Int(hrMax + 0.5),
                    prevIntensity: prevIntensity)
                return (intensity, intensity.getHrLimit(hrMaxBpm: Int(hrMax + 0.5)))
            } else {
                return (.Cold, nil)
            }
        }

        let intensity = intensity(prevEvent.intensity, hrEvent.heartrate)
        
        guard let hrRange = intensity.range else {
            return IntensityEvent(timestamp: hrEvent.timestamp, intensity: intensity.intensity)
        }
        guard prevEvent.intensity != intensity.intensity else {
            return IntensityEvent(timestamp: hrEvent.timestamp, intensity: intensity.intensity)
        }
        
        // Change in intensities happened.
        let p = hrRange.relativePosition(of: hrEvent.heartrate)
        let prevTs = prevEvent.timestamp > .distantPast ? prevEvent.timestamp : hrEvent.timestamp
        let dt = prevTs.distance(to: hrEvent.timestamp)
        
        let t = prevEvent.intensity < intensity.intensity ?
            prevTs.advanced(by: p * dt) :
            hrEvent.timestamp.advanced(by: Double(-p) * dt)
        
        return IntensityEvent(timestamp: t, intensity: intensity.intensity)
    }
    
    static var zero: IntensityEvent {IntensityEvent(timestamp: .distantPast, intensity: .Cold)}
    
    static var producer: AnyPublisher<IntensityEvent, Never> {
        ReceiverService
            .sharedInstance
            .heartrateValues
            .scan(IntensityEvent.zero) {IntensityEvent.fromHr($0, $1)}
            .removeDuplicates {$0.intensity == $1.intensity}
            .share()
            .eraseToAnyPublisher()
    }
}
