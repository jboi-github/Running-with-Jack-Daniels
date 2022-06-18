//
//  Arrays.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 29.03.22.
//

import Foundation
import SwiftUI

extension Date {
    var seconds: Int {Int(timeIntervalSinceReferenceDate)}
    init(seconds: Int) {
        self.init(timeIntervalSinceReferenceDate: TimeInterval(seconds))
    }
}

extension Sequence {
    func array() -> [Element] {Array(self)}
    
    /// Like map on a window of `n` elements.
    func ngram(_ n: Int) -> [[Element]] {
        guard n >= 1 else {return []}
        return enumerated()
            .map {dropFirst($0.offset).prefix(n).array()}
            .filter {$0.count == n}
    }
}

/// An array of `Dated` elements is expected to store its elements continously second by second without gaps.
/// Existing functions to drop ranges and to append elements help maintaining the expectation.
extension Array where Element: Dated {
    private func getIdx(at: Date) -> Index? {
        guard let first = first?.date.seconds else {return nil}
        let idx = at.seconds - first
        return indices.contains(idx) ? idx : nil
    }
    
    /// Return the element with the given date.
    subscript(date: Date) -> Element? {
        guard let idx = getIdx(at: date) else {return nil}
        return self[idx]
    }
    
    /// Drops/removes all elements after given date and returns the dropped elements.
    @discardableResult mutating func drop(after: Date) -> [Element] {
        guard let last = last, last.date > after else {return []}
        let dropped = filter {$0.date > after}
        removeAll {$0.date > after}
        
        return dropped
    }
    
    /// Drops/removes all elements before given date and returns the dropped elements.
    @discardableResult mutating func drop(before: Date) -> [Element] {
        guard let first = first, first.date < before else {return []}
        let dropped = filter {$0.date < before}
        removeAll {$0.date < before}
        
        return dropped
    }
    
    /// Appends new element and asks for interpolation between currently last element and all seconds up to new element
    /// Returns all appended elements
    @discardableResult mutating func append(_ element: Element, interpolated: (Date) -> Element) -> [Element] {
        var appended = [Element]()
        
        if let last = last {
            appended += stride(from: last.date.seconds + 1, to: element.date.seconds, by: 1).map {interpolated(Date(seconds: $0))}
            append(contentsOf: appended)
        }
        append(element)
        return appended + [element]
    }
    
    /// Appends new elements and asks for extrapolation after cureently last element and all seconds up to given date.
    /// Returns all appended elements
    @discardableResult mutating func extend(_ through: Date, extrapolate: (Date) -> Element) -> [Element] {
        if let last = last {
            let extended = stride(from: last.date.seconds + 1, through: through.seconds, by: 1).map {extrapolate(Date(seconds: $0))}
            append(contentsOf: extended)
            return extended
        } else {
            return []
        }
    }
    
    /// Master replacement function for new original values. Returns all appended and extended elements
    mutating func replace(_ element: Element, replaceAfter: Date, extendThrough: Date = .distantPast, interpolated: (Date) -> Element, extrapolate: ((Date) -> Element)? = nil)
    -> (dropped: [Element], appended: [Element])
    {
        let dropped = drop(after: replaceAfter)
        let appended = append(element, interpolated: interpolated)
        let extended = extendThrough > .distantPast ? extend(extendThrough, extrapolate: extrapolate!) : []
        return (dropped, appended + extended)
    }

    /// Slave replacement function when new master original value came in.
    mutating func replace<Master>(_ masters: [Master], replaceAfter: Date, slave: (Master) -> Element) -> (dropped: [Element], appended: [Element]) {
        let dropped = drop(after: replaceAfter)
        let appended = masters.map {slave($0)}
        append(contentsOf: appended)
        return (dropped, appended)
    }
}
