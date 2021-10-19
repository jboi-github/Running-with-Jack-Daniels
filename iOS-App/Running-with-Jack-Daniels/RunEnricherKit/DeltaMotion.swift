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
    
    static var zero: Value {CMMotionActivity().isActive}
    
    let span: Range<Date>
    let begin: Value
    let end: Value
    var impactsAfter: Date {span.upperBound}

    static func end(begin: Value, from prev: Source?, to curr: Source) -> Value {
        curr.confidence == .high ? curr.isActive : begin
    }
    
    static func timestamp(for source: Source) -> Date {source.when}
    
    func value(at: Date) -> Value {classifyingValue(at: at)}
}
