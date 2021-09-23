//
//  SegmentIdReceiver.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 15.09.21.
//

import Foundation
import Combine

// Define the segment, which is differated by started, running and intensity.
class SegmentIdReceiver {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    static var sharedInstance = SegmentIdReceiver()
    
    /// Use singleton @sharedInstance
    private init() {}

    // MARK: - Published
    
    public struct SegmentIdChange {
        let segment: Int
        let when: Date
    }

    /// Last received intensity
    public private(set) var segmentIdChange: PassthroughSubject<SegmentIdChange, Error>!
    
    public func start() {
        log()
        segmentIdChange = PassthroughSubject<SegmentIdChange, Error>()
    }
    
    public func stop() {
        log()
        serialDispatchQueue.async {
            self.segmentIdChange.send(completion: .finished)
        }
    }

    /// New categoricals were received
    public func segment(isStarted: Bool, isRunning: Bool, intensity: Intensity, at: Date) {
        if prevSegment != nil && prevSegment! == (isStarted, isRunning, intensity) {return}
        
        log(segmentId)
        let localSegmentId = segmentId
        
        defer {
            self.prevSegment = (isStarted, isRunning, intensity)
            segmentId += 1
        }

        serialDispatchQueue.async {
            self.segmentIdChange.send(SegmentIdChange(segment: localSegmentId, when: at))
        }
    }
    
    // MARK: - Private
    private typealias Segment = (isStarted: Bool, isRunning: Bool, intensity: Intensity)
    
    private var prevSegment: Segment? = nil
    private var segmentId: Int = 0
}
