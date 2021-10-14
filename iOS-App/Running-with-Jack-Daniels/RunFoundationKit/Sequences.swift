//
//  Generics.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 09.09.21.
//

import Foundation
import Combine

// MARK: - Extensions for sequences and arrays

/// Very basic thing first: Compare two optionals
extension Optional {
    static func lessThen(
        lhs: Self, rhs: Self,
        isNilMax: Bool,
        by areInIncreasingOrder: (Wrapped, Wrapped) -> Bool) -> Bool
    {
        if let lhs = lhs, let rhs = rhs {
            return areInIncreasingOrder(lhs, rhs)
        } else if lhs != nil { // rhs is nil
            return isNilMax
        } else if rhs != nil {
            return !isNilMax
        } else {
            return false // Both nil is equal, not "less then"
        }
    }
    
    static func lessThen(
        lhs: Self, rhs: Self,
        isNilMax: Bool) -> Bool
    where Wrapped: Comparable
    {
        lessThen(lhs: lhs, rhs: rhs, isNilMax: isNilMax, by: <)
    }
}

// MARK: Sequences

extension Sequence {
    /// N-grams of a Sequence.
    /// - Parameter n: maximal number of elements in one result
    /// - Returns: An arrays with all n-grams. The list includes starting adn ending point, which contain between 1 and n elements in one n-gram.
    public func ngram(_ n: Int) -> AnySequence<Array<Element>> {
        var ngram = [Element]()
        ngram.reserveCapacity(n + 1)
        
        var iterator = makeIterator()
        var i = 0
        var eol = false
        
        return AnySequence { () -> AnyIterator<Array<Element>> in
            AnyIterator {
                if let element = iterator.next() {
                    ngram.append(element)
                    i += 1
                } else {
                    eol = true
                }
                
                if (i > n || eol) && !ngram.isEmpty {ngram.removeFirst()}
                
                return ngram.isEmpty ? nil : ngram
            }
        }
    }

    /// Like `map` but without storing elements in an array. This is the Big Data conformant variant.
    func mapNoStore<T>(_ transform: @escaping (Self.Element) -> T) -> AnySequence<T> {
        var iterator = makeIterator()
        
        return AnySequence {
            AnyIterator {
                guard let row = iterator.next() else {return nil}
                return transform(row)
            }
        }
    }

    /// Like `compactMap` but without storing elements in an array. This is the Big Data conformant variant.
    func compactMapNoStore<T>(_ transform: @escaping (Self.Element) -> T?) -> AnySequence<T> {
        mapNoStore(transform).filterNoStore {$0 != nil}.mapNoStore {$0!}
    }

    /// Like `filter` but without storing elements in an array. This is the Big Data conformant variant.
    func filterNoStore(_ isIncluded: @escaping (Self.Element) -> Bool) -> AnySequence<Self.Element> {
        var iterator = makeIterator()
        
        return AnySequence {
            AnyIterator {
                while let row = iterator.next() {
                    if isIncluded(row) {return row}
                }
                return nil
            }
        }
    }
    
    /// Like `flatMap` but without storing elements in an array. This is the Big Data conformant variant.
    func flatMapNoStore<SegmentOfResult>(_ transform: @escaping (Self.Element) -> SegmentOfResult)
    -> AnySequence<SegmentOfResult.Element>
    where SegmentOfResult: Sequence
    {
        var iterator = makeIterator()
        var pool: SegmentOfResult.Iterator? = nil
        
        return AnySequence {
            AnyIterator {
                var row = pool?.next()
                
                while row == nil {
                    guard let element = iterator.next() else {return nil}
                    pool = transform(element).makeIterator()
                    row = pool?.next()
                }
                
                return row
            }
        }
    }

    /// Ensure a minimal number of elements returned. The appended elements are nil.
    func ensureSize(_ n: Int) -> AnySequence<Element?> {
        var iterator = makeIterator()
        var count = 0
        
        return AnySequence {
            AnyIterator {
                defer {count += 1}
                guard let row = iterator.next() else {
                    if count < n {
                        return Element?(nil)
                    } else {
                        return Element??(nil) // wierd...
                    }
                }
                return row
            }
        }
    }

    /// Merge multiple sequences of an element into one sequence.
    /// It is expected, that each source-sequence is ordered by the means of `areInIncreasingOrder`.
    ///
    /// - Returns: A seqeunce of elements in sorted order and merged from all source sequences.
    /// The returned `offset` points to the source-sequence, that did hold the element. `element` is the element itself.
    func mapMerged() -> AnySequence<(offset: Int, elements: [Element.Element?])>
    where Element: Sequence, Element.Element: Comparable
    {
        mapMerged(by: <)
    }
    
    /// Merge multiple sequences of an element into one sequence.
    /// It is expected, that each source-sequence is ordered by the means of `areInIncreasingOrder`.
    ///
    /// - Parameter areInIncreasingOrder:A predicate that returns `true`
    ///   if its first argument should be ordered before its second
    ///   argument; otherwise, `false`.
    ///
    /// - Returns: A sequence of elements in sorted order and merged from all source sequences.
    /// The returned `offset` points to the source-sequence, that did hold the element. `element` is the element itself.
    func mapMerged(by areInIncreasingOrder: @escaping (Element.Element, Element.Element) -> Bool)
    -> AnySequence<(offset: Int, elements: [Element.Element?])>
    where Element: Sequence
    {
        var iterators = map {$0.makeIterator()}
        var nexts = iterators.indices.map {iterators[$0].next()}
        
        return AnySequence {
            AnyIterator {
                guard !nexts.allSatisfy({$0 == nil}) else {return nil}
                
                guard let offset = nexts.minIndex(by: {
                    Element.Element?.lessThen(lhs: $0, rhs: $1, isNilMax: true, by: areInIncreasingOrder)
                }) else {return nil}
                
                defer {nexts[offset] = iterators[offset].next()}
                return (offset, nexts)
            }
        }
    }

    /// Traverse through this sequence and call the gien closures before the first element, for each element and after the last element.
    /// - Parameters:
    ///   - before: Closure to be called before the first element. Parameter is the first element.
    ///   - mid: Closure to be called on each row with previous and current element as parameter.
    ///   - after: Closure to be called after last element was processed. Parameter is the last row.
    func mapExtended<T>(
        before: @escaping (Element?) -> T,
        mid: @escaping (Element, Element) -> T,
        after: @escaping (Element?) -> T)
    -> AnySequence<T>
    {
        var firstRow = true
        var prevRow: [Element]? = nil
        
        return ngram(2)
            .ensureSize(2)
            .mapNoStore { (rows) -> T in
                defer {
                    prevRow = rows
                    if firstRow {firstRow = false}
                }
                if let rows = rows {
                    if rows.count < 2 {
                        if firstRow {
                            return before(rows[0])
                        } else {
                            return after(rows[0])
                        }
                    } else {
                        return mid(rows[0], rows[1])
                    }
                } else {
                    if firstRow {
                        return before(nil)
                    } else {
                        return after(prevRow?.last)
                    }
                }
            }
    }
}

// MARK: Collections

extension Collection {
    func indexOrNil(after: Index) -> Index? {
        let afterIdx = index(after: after)
        return indices.contains(afterIdx) ? afterIdx : nil
    }
    
    func after(_ after: Index) -> Element? {
        guard let idx = indexOrNil(after: after) else {return nil}
        return self[idx]
    }
    
    func minIndex(by areInIncreasingOrder: (Element, Element) -> Bool) -> Index? {
        indices.min(by: {areInIncreasingOrder(self[$0], self[$1])})
    }

    func minIndex() -> Index? where Element: Comparable {
        indices.min(by: {self[$0] < self[$1]})
    }
    
    func maxIndex(by areInIncreasingOrder: (Element, Element) -> Bool) -> Index? {
        indices.max(by: {areInIncreasingOrder(self[$0], self[$1])})
    }

    func maxIndex() -> Index? where Element: Comparable {
        indices.max(by: {self[$0] < self[$1]})
    }
}

extension BidirectionalCollection {
    var lastIndex: Index? {isEmpty ? nil : index(before: endIndex)}
    
    func indexOrNil(before: Index) -> Index? {
        let beforeIdx = index(before: before)
        return indices.contains(beforeIdx) ? beforeIdx : nil
    }
    
    func before(_ before: Index) -> Element? {
        guard let idx = indexOrNil(before: before) else {return nil}
        return self[idx]
    }
}

// MARK: Insert an Element

extension RandomAccessCollection {
    /// Look forward, backwards or by binary search to get insertion point. Expects collection to be increasingly sorted.
    public func insertIndex<Key>(for key: Key, element2key: (Element) -> Key) -> Index where Key: Comparable {
        func forward() -> Index {
            var i = startIndex
            while i < endIndex && key >= element2key(self[i]) {i = index(after: i)}
            
            return i
        }
        
        func backward() -> Index {
            var i = index(before: endIndex)
            while i >= startIndex && key < element2key(self[i]) {i = index(before: i)}
            
            return index(after: i)
        }
        
        func binarySearch(_ indices: Range<Index>) -> Index {
            if indices.isEmpty {return indices.lowerBound}
            
            let midIndex = index(
                indices.lowerBound,
                offsetBy: distance(from: indices.lowerBound, to: indices.upperBound) / 2)
            
            if key >= element2key(self[midIndex]) {
                return binarySearch(index(after: midIndex) ..< indices.upperBound)
            } else {
                return binarySearch(indices.lowerBound ..< midIndex)
            }
        }
        
        let ld2 = 64 - UInt64(count).leadingZeroBitCount // Estimate for ld
        let upper = startIndex ..< Swift.max(startIndex, index(endIndex, offsetBy: -ld2))
        let lower = Swift.min(index(startIndex, offsetBy: ld2), endIndex) ..< endIndex

        if let last = self[upper].last, element2key(last) < key {
            return backward()
        } else if let first = self[lower].first, element2key(first) > key {
            return forward()
        } else {
            return binarySearch(startIndex ..< endIndex)
        }
    }
}

// MARK: Single values and ranges

/// Global, serial dispatch queue for event handling tasks.
public let serialQueue = DispatchQueue(
    label: "com.apps4live.Running-with-Jack-Daniels",
    qos: .userInitiated)

public var sinks = Set<AnyCancellable>()

extension Double {
    func addWithError(_ other: Double) -> (sum: Double, error: Double) {
        (self + other, ((self + other) - self) - other)
    }
    
    static func addWithError(_ first: Double, _ second: Double) -> (sum: Double, error: Double) {
        first.addWithError(second)
    }

    var asRadians: Self {self * .pi / 180}
    var asDegrees: Self {self * 180 / .pi}
}

struct AvgBuilder {
    private var _avg: Double = .zero
    private var _n: Double = .zero
    private var _error: Double = .zero // Only 1st level error is stored.
    
    var avg: Double {_avg - _error}
    
    init() {}
    
    mutating func merge(_ x: Double) {
        let (localAvg, localError) = Double.addWithError(_avg * (_n / (_n + 1)), x / (_n + 1))
        _avg = localAvg
        _error += localError
        _n += 1
    }
}

extension Range where Bound: AdditiveArithmetic {
    public func offset(by offset: Bound) -> Range<Bound> {
        (lowerBound + offset) ..< (upperBound + offset)
    }
    
    public var span: Bound {upperBound - lowerBound}
}

extension Range where Bound: Strideable, Bound.Stride: BinaryFloatingPoint {
    public func relativePosition(of bound: Bound) -> Double {
        Double(lowerBound.distance(to: bound)) / Double(lowerBound.distance(to: upperBound))
    }
}

extension Range where Bound: Strideable, Bound.Stride: BinaryInteger {
    public func relativePosition(of bound: Bound) -> Double {
        Double(lowerBound.distance(to: bound)) / Double(lowerBound.distance(to: upperBound))
    }
}

extension Date: Strideable {}

// MARK: Array, based on discontinuous storage
struct MultipleArrays<R: RandomAccessCollection>: RandomAccessCollection {
    typealias Element = R.Element
    typealias Index = Int
    typealias Indices = Range<Int>
    
    private let arrays: [R]
    let startIndex: Index
    let endIndex: Index
    
    init(_ arrays: R...) {
        precondition(!arrays.isEmpty, "must provide at least one collection")
        
        self.arrays = arrays
        self.startIndex = 0
        self.endIndex = arrays.reduce(0, {$0 + $1.count})
    }
    
    func index(before: Index) -> Index {before - 1}
    
    subscript(position: Index) -> Element {
        var offset = position
        let array = arrays.first { array in
            if (0 ..< array.count).contains(offset) {
                return true
            } else {
                offset -= array.count
                return false
            }
        }
        
        guard let array = array else {
            preconditionFailure(
                "Index out of bounds \(position) not in \(arrays.map {0 ..< $0.count})"
            )
        }
        return array[array.index(array.startIndex, offsetBy: offset)]
    }
}
