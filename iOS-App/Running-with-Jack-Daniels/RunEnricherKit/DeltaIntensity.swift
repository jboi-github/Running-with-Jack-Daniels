//
//  DeltaIntensity.swift
//  RunEnricherKit
//
//  Created by Jürgen Boiselle on 11.10.21.
//

import Foundation
import Combine
import RunFormulasKit
import RunDatabaseKit

struct IntensityEvent {
    let intensity: Intensity
    let timestamp: Date
    
    static func fromHr(_ hr: DeltaHeartrate) -> IntensityEvent? {
        func intensity(hrBpm: Int, prevHrBpm: Int) -> (intensity: Intensity, range: ClosedRange<Int>?) {
            let hrMax = Database.sharedInstance.hrMax.value
            let hrResting = Database.sharedInstance.hrResting.value

            if hrMax.isFinite && hrResting.isFinite {
                let intensity = intensity4Hr(
                    hrBpm: hrBpm,
                    hrMaxBpm: Int(hrMax + 0.5),
                    restingBpm: Int(hrResting + 0.5),
                    prevHrBpm: prevHrBpm)
                return (intensity, intensity.getHrLimit(
                    hrMaxBpm: Int(hrMax + 0.5),
                    restingBpm: Int(hrResting + 0.5)))
                
            } else if hrMax.isFinite {
                let intensity = intensity4Hr(
                    hrBpm: hrBpm,
                    hrMaxBpm: Int(hrMax + 0.5),
                    prevHrBpm: prevHrBpm)
                return (intensity, intensity.getHrLimit(hrMaxBpm: Int(hrMax + 0.5)))
            } else {
                return (.Cold, nil)
            }
        }

        let intensity = intensity(hrBpm: hr.end, prevHrBpm: hr.begin)
        guard let hrLimit = intensity.range, !hrLimit.contains(hr.begin) else {return nil}
        
        let p = (hr.begin ..< hr.end)
            .relativePosition(
                of: hr.begin < hrLimit.lowerBound ? hrLimit.lowerBound: hrLimit.upperBound)
        let l = hr.span.lowerBound.timeIntervalSince1970
        let u = hr.span.upperBound.timeIntervalSince1970
        let t = p * u + (1.0 - p) * l
        
        return IntensityEvent(
            intensity: intensity.intensity,
            timestamp: Date(timeIntervalSince1970: t))
    }
}

struct DeltaIntensity: DeltaProtocol {
    typealias Value = Intensity
    typealias Source = IntensityEvent
    
    static var zero: Value = .Cold
    
    let span: Range<Date>
    let begin: Value
    let end: Value
    var impactsAfter: Date {span.upperBound}

    static func end(begin: Value, from prev: Source?, to curr: Source) -> Value {curr.intensity}
    
    static func timestamp(for source: Source) -> Date {source.timestamp}
    
    func value(at: Date) -> Value {classifyingValue(at: at)}
}
