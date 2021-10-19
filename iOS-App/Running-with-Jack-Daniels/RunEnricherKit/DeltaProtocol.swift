//
//  DeltaCollector.swift
//  RunEnricherKit
//
//  Created by Jürgen Boiselle on 10.10.21.
//

import Foundation
import Combine
import SwiftUI
import RunFoundationKit
import RunReceiversKit

/// Create for a stream of incoming signals deltas and collect them.
/// Furthermore allow to search for time ranges and inter/extrapolate into it.
/// Note that, the time-range must be a subrange of one delta range.
protocol DeltaProtocol {
    associatedtype Value
    associatedtype Source

    var span: Range<Date> {get}
    var begin: Value {get}
    var end: Value {get}
    var impactsAfter: Date {get}

    static func end(begin: Value, from prev: Source?, to curr: Source) -> Value
    static func timestamp(for source: Source) -> Date
    
    static var zero: Value {get}
    
    init(span: Range<Date>, begin: Value, end: Value)
    
    func value(at: Date) -> Value
}

extension DeltaProtocol {
    var duration: TimeInterval {span.lowerBound.distance(to: span.upperBound)}
    
    init(_ soFar: Self?, prev: Source?, curr: Source) {
        let begin = soFar?.end ?? Self.zero
        let end = Self.end(begin: begin, from: prev, to: curr)
        let span = Self.timestamp(for: prev ?? curr) ..< Self.timestamp(for: curr)
        
        self.init(span: span, begin: begin, end: end)
    }
    
    func classifyingValue(at: Date) -> Value {at < span.upperBound ? begin : end}
    
    func continuousValue(at: Date) -> Value where Value: BinaryFloatingPoint {
        let v = continuousValue(at: at, begin: Double(begin), end: Double(end))
        return v.isFinite ? Self.Value(v) : classifyingValue(at: at)
    }
    
    func continuousValue(at: Date) -> Value where Value: BinaryInteger {
        let v = continuousValue(at: at, begin: Double(begin), end: Double(end))
        return v.isFinite ? Self.Value(v + 0.5) : classifyingValue(at: at)
    }
    
    private func continuousValue(at: Date, begin: Double, end: Double) -> Double {
        if span.isEmpty {return .nan}
        
        let p = span.relativePosition(of: at)
        return p * Double(end) + (1 - p) * Double(begin)
    }
}

extension Publisher where Failure == Never{
    func delta<D: DeltaProtocol>(last: @escaping () -> D?) -> Publishers.Map<Self, D>
    where D.Source == Self.Output
    {
        var prev: D.Source? = nil
        
        return map { source in
            defer {prev = source}
            return D(last(), prev: prev, curr: source)
        }
    }
    
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

extension Array where Element: DeltaProtocol {
    subscript(_ at: Date) -> Element {
        let idx = insertIndex(for: at) {$0.span.lowerBound}
        guard indices.contains(idx) else {
            return Element(span: at ..< at, begin: Element.zero, end: Element.zero)
        }

        if self[idx].span.contains(at) {return self[idx]}
        return self[Swift.max(startIndex, index(before: idx))]
    }
}
