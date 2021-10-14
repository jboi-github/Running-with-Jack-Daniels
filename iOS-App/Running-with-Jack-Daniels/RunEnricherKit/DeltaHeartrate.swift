//
//  DeltaHeartrate.swift
//  RunEnricherKit
//
//  Created by Jürgen Boiselle on 10.10.21.
//

import Foundation
import RunReceiversKit

struct DeltaHeartrate: DeltaProtocol {
    typealias Value = Int
    typealias Source = Heartrate
    
    static var zero: Int = 0
    
    let span: Range<Date>
    let begin: Value
    let end: Value
    var impactsAfter: Date {span.lowerBound}

    static func end(begin: Value, from prev: Source?, to curr: Source) -> Value {curr.heartrate}
    
    static func timestamp(for source: Source) -> Date {source.timestamp}
    
    func value(at: Date) -> Value {continuousValue(at: at)}
}
