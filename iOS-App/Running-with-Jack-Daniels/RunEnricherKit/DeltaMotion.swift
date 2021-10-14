//
//  DeltaMotion.swift
//  RunEnricherKit
//
//  Created by Jürgen Boiselle on 10.10.21.
//

import Foundation
import CoreMotion

struct DeltaMotion: DeltaProtocol {
    typealias Value = Bool
    typealias Source = CMMotionActivity
    
    static var zero: Value = false
    
    let span: Range<Date>
    let begin: Value
    let end: Value
    var impactsAfter: Date {span.upperBound}

    static func end(begin: Value, from prev: Source?, to curr: Source) -> Value {
        curr.confidence == .high ? (curr.walking || curr.running || curr.cycling) && !curr.stationary : begin
    }
    
    static func timestamp(for source: Source) -> Date {source.startDate}
    
    func value(at: Date) -> Value {classifyingValue(at: at)}
}
