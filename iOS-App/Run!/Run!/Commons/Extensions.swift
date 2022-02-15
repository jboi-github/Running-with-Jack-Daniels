//
//  Ranges.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: Work with sets of ranges
public protocol Rangable {
    associatedtype C: Comparable
    
    var range: Range<C> {get}
}

public protocol RangableMergeDelegate {
    associatedtype R: Rangable

    /// Reduce or expand a rangable to a new range. The returning rangables range must be equivalent to `to`.
    func reduce(_ rangable: R, to: Range<R.C>) -> R
    
    /// Resolve between two conflicting/overlapping rangables into a new range. The returning rangables range must be equivalent to `to`.
    func resolve(_ r1: R, _ r2: R, to: Range<R.C>) -> R
    
    /// A rangable element is no longer valid and will be removed.
    func drop(_ rangable: R)
    
    /// A new rangable element gets valid and will be inserted.
    func add(_ rangable: R)
}

extension Array where Element: Rangable {
    /// Self must be a sorted list of ranges without gaps or overlaps. Then `merge` creates the differences to be applied to get a new collection
    /// That is:
    /// - A sorted collection of ranges without gaps and overlaps.
    /// - At least one range starts at the merged rangable and one range ends with the merged rangable.
    /// - Ranges are added only. No merging of consectutive ranges happens.
    /// - The content of the overlapping part of rangeable and an element is determined by a callback.
    public mutating func merge<D: RangableMergeDelegate>(_ rangable: Element, delegate: D)
    where D.R == Element
    {
        // Special case. Self is empty
        if self.isEmpty {
            self.append(rangable)
            delegate.add(rangable)
        }
        
        // Overalpping elements
        var first = endIndex
        var last = startIndex
        for idx in indices.reversed() {
            if self[idx].range.overlaps(rangable.range) {
                if first > idx {first = idx}
                if last < idx {last = idx}
            } else if self[idx].range.isBefore(rangable.range) {
                break
            }
        }
        
        if first <= last {
            // overlapping elements exist
            var replacer = [Element]()
            
            // First overlapping element
            let minLower = Swift.min(rangable.range.lowerBound, self[first].range.lowerBound)
            let maxLower = Swift.max(rangable.range.lowerBound, self[first].range.lowerBound)
            if minLower < maxLower {
                replacer.append(
                    delegate.reduce(
                        rangable.range.lowerBound < self[first].range.lowerBound ? rangable : self[first],
                        to: minLower ..< maxLower))
            }

            replacer.append(
                contentsOf: self[first ... last]
                    .lazy
                    .map {
                        delegate.resolve($0, rangable, to: $0.range.clamped(to: rangable.range))
                    })
            
            // Last overlapping element
            let minUpper = Swift.min(rangable.range.upperBound, self[last].range.upperBound)
            let maxUpper = Swift.max(rangable.range.upperBound, self[last].range.upperBound)
            if minUpper < maxUpper {
                replacer.append(
                    delegate.reduce(
                        rangable.range.upperBound > self[last].range.upperBound ? rangable : self[last],
                        to: minUpper ..< maxUpper))
            }
            
            // Replace existing elements
            self[first ... last].forEach {delegate.drop($0)}
            replacer.forEach {delegate.add($0)}
            self[first ... last] = replacer[replacer.startIndex ..< replacer.endIndex]

        } else if let last = self.last, rangable.range.isAfter(last.range) {
            // range is behind all elements
            self.append(rangable)
            delegate.add(rangable)
        } else if let first = self.first, rangable.range.isBefore(first.range) {
            // range is before all elements
            self.insert(rangable, at: startIndex)
            delegate.add(rangable)
        }
    }
}

// MARK: Transform ranges

extension Range {
    public func isBefore(_ other: Self) -> Bool {upperBound <= other.lowerBound}
    public func isAfter(_ other: Self) -> Bool {lowerBound >= other.upperBound}
}

private extension BinaryFloatingPoint {var d: Double {Double(self)}}
private extension BinaryInteger {var d: Double {Double(self)}}
private extension Date {var d: Double {Double(self.timeIntervalSince1970)}}

extension Range where Bound: BinaryFloatingPoint {
    public func transform<B2: BinaryFloatingPoint>(_ x: Bound, _ to: Range<B2>) -> B2 {
        let p = (x.d - lowerBound.d) / (upperBound.d - lowerBound.d)
        let q = (upperBound.d - x.d) / (upperBound.d - lowerBound.d)
        
        return B2(p * to.upperBound.d + q * to.lowerBound.d)
    }

    public func transform<B2: BinaryInteger>(_ x: Bound, to: Range<B2>) -> B2 {
        B2(transform(x, to.lowerBound.d ..< to.upperBound.d))
    }

    public func transform(_ x: Bound, to: Range<Date>) -> Date {
        Date(timeIntervalSince1970: transform(x, to.lowerBound.d ..< to.upperBound.d))
    }
}

extension Range where Bound: BinaryInteger {
    public func transform<B2: BinaryFloatingPoint>(_ x: Bound, to: Range<B2>) -> B2 {
        B2((lowerBound.d ..< upperBound.d).transform(x.d, to.lowerBound.d ..< to.upperBound.d))
    }

    public func transform<B2: BinaryInteger>(_ x: Bound, to: Range<B2>) -> B2 {
        B2((lowerBound.d ..< upperBound.d).transform(x.d, to.lowerBound.d ..< to.upperBound.d))
    }

    public func transform(_ x: Bound, to: Range<Date>) -> Date {
        Date(
            timeIntervalSince1970: (lowerBound.d ..< upperBound.d)
                .transform(
                    x.d,
                    to.lowerBound.timeIntervalSince1970.d ..< to.upperBound.timeIntervalSince1970.d))
    }
}

extension Range where Bound: Strideable {
    public var distance: Bound.Stride {lowerBound.distance(to: upperBound)}
}

extension Date: Strideable {}

// MARK: Single Values
extension Double {
    public func avg(_ with: Double, _ cntSoFar: Int) -> Double {
        let cnt = Double(cntSoFar) / Double(cntSoFar + 1)
        return self * cnt + with * (1 - cnt)
    }
}

extension String: Identifiable {
    public var id: Self {self}
}

extension CGSize {
    static func *= (lhs: inout Self, rhs: CGFloat) {
        lhs.width *= rhs
        lhs.height *= rhs
    }
}
