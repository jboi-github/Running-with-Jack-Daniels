//
//  DeltaLocation.swift
//  RunEnricherKit
//
//  Created by Jürgen Boiselle on 10.10.21.
//

import Foundation
import CoreLocation

struct DeltaLocation: DeltaProtocol {
    typealias Value = CLLocationDistance
    typealias Source = CLLocation
    
    static var zero: Value = 0
    
    let span: Range<Date>
    let begin: Value
    let end: Value
    var impactsAfter: Date {span.lowerBound}

    static func end(begin: Value, from prev: Source?, to curr: Source) -> Value {
        (prev?.distance(from: curr) ?? .zero) + begin
    }
    
    static func timestamp(for source: Source) -> Date {source.timestamp}
    
    func value(at: Date) -> Value {continuousValue(at: at)}
}
