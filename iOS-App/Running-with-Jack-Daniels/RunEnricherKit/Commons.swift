//
//  ActivityIntensity.swift
//  RunEnricherKit
//
//  Created by Jürgen Boiselle on 27.10.21.
//

import Foundation
import CoreMotion
import Combine
import RunFormulasKit

public enum Activity: Hashable {
    case none, walking, running, cycling, getMoved
    
    static func from(_ motion: CMMotionActivity?) -> Activity {
        guard let motion = motion else {return .none}
        if motion.stationary {return .none}
        if motion.walking {return .walking}
        if motion.running {return .running}
        if motion.cycling {return .cycling}
        return .getMoved
    }
}

public struct ActivityIntensity: Hashable {
    public let activity: Activity
    public let intensity: Intensity
    
    static func fromDelta(_ delta: SegmentsService.Segment.Delta) -> Self {
        Self(activity: delta.activity, intensity: delta.intensity)
    }
}

extension Publisher where Failure == Never{
    public func sinkMainStore(receiveValue: @escaping (Self.Output) -> Void) {
        sinkStore {value in DispatchQueue.main.async {receiveValue(value)}}
    }
    
    func sinkStore(receiveValue: @escaping (Self.Output) -> Void) {
        self
            .sink {receiveValue($0)}
            .store(in: &sinks)
    }
}

private var sinks = Set<AnyCancellable>()
