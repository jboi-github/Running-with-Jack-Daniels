//
//  MotionActivityEvent.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 14.05.22.
//

import Foundation
import CoreMotion

struct MotionActivityEvent: GenericTimeseriesElement {
    // MARK: Implement GenericTimeseriesElement
    static let key: String = "com.apps4live.Run!!.MotionActivityEvent"
    let vector: VectorElement<Info>
    init(_ vector: VectorElement<Info>) {self.vector = vector}

    // MARK: Implement specifics
    enum Confidence: Int, Codable {
        case low, medium, high
    }
    
    enum Motion: Codable, Equatable {
        case stationary, walking, running, cycling, other
    }
    
    struct Info: Codable, Equatable {
        let confidence: Confidence
        let motion: Motion
    }

    init(date: Date, confidence: Confidence, motion: Motion) {
        vector = VectorElement(date: date, categorical: Info(confidence: confidence, motion: motion))
    }
    
    var confidence: Confidence {vector.categorical.confidence}
    var motion: Motion {vector.categorical.motion}
}

extension TimeSeries where Element == MotionActivityEvent {
    func parse(_ motionActivity: CMMotionActivity) -> Element {
        var confidence: MotionActivityEvent.Confidence {
            MotionActivityEvent.Confidence(rawValue: motionActivity.confidence.rawValue) ?? .low
        }
        
        var motion: MotionActivityEvent.Motion {
            if motionActivity.stationary {
                return .stationary
            } else if motionActivity.walking {
                return .walking
            } else if motionActivity.running {
                return .running
            } else if motionActivity.cycling {
                return .cycling
            } else {
                return .other
            }
        }
        
        return Element(date: motionActivity.startDate, confidence: confidence, motion: motion)
    }
}
