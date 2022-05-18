//
//  FileBackedArray.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 08.05.22.
//

import Foundation
import SwiftUI

// Done: Archive
// Done: Rename BLe-Twin to Client
// Done: Create HeartrateMonitorClient
// Done: Connect clients to timeseries
// Done: Create Workout-Timeseries with archiving
// Done: Build derived timeseries
// TODO: Build CalulationEngine
// TODO: Local user defaults and archives to icloud

// MARK: Timeseries related Protocols

/// Type, that has a date to form time series.
protocol Dated: Identifiable {
    var date: Date {get}
}

extension Dated {
    var id: Date {date}
}

/// Type, that can be scaled by a double value
protocol Scalable {
    static func *(_ lhs: Self, _ rhs: Double) -> Self
    static func *(_ lhs: Double, _ rhs: Self) -> Self
    static func *=( _ lhs: inout Self, _ rhs: Double)
}

extension Scalable {
    static func *(_ lhs: Double, _ rhs: Self) -> Self {rhs * lhs}
    static func *=( _ lhs: inout Self, _ rhs: Double) {lhs = lhs * rhs}
}

// MARK: Extend common types
extension Date: Strideable {}

extension Double: Scalable {}

extension Int: Scalable {
    static func * (lhs: Int, rhs: Double) -> Int {Int(Double(lhs) * rhs + 0.5)}
}

extension Optional where Wrapped == Double {
    /// Derived from `Stridable`
    func distance(to: Self) -> Self {
        guard let x = self, let y = to else {return nil}
        return y - x
    }
    
    /// Derived from `Stridable`
    func advanced(by: Self) -> Self {
        guard let x = self, let delta = by else {return nil}
        return x + delta
    }
}

extension Optional where Wrapped == Int {
    /// Derived from `Stridable`
    func distance(to: Self) -> Self {
        guard let x = self, let y = to else {return nil}
        return y - x
    }
    
    /// Derived from `Stridable`
    func advanced(by: Self) -> Self {
        guard let x = self, let delta = by else {return nil}
        return x + delta
    }
}

// MARK: Timeseries elements

protocol TimeSeriesElement: Dated, Codable {
    associatedtype Delta: Scalable
    
    /// Derived from `Stridable`
    func distance(to: Self) -> Self.Delta
    
    /// Derived from `Stridable`
    func advanced(by: Self.Delta) -> Self
    
    /// Extrapolation by simply continuing value
    func extrapolate(at: Date) -> Self
}

extension TimeSeriesElement {
    /// Gradient between to elements, normalized to its time interval, e.g. speed in m/s between two GPS-Locations.
    func gradient(to: Self) -> Self.Delta {distance(to: to) * (1 / date.distance(to: to.date))}
    
    /// Linear inter- or extrapolation between `self` and `towards`.
    func interpolate(at: Date, _ towards: Self) -> Self {
        let p = (date ..< towards.date).p(at)
        if p < 1 {
            return advanced(by: distance(to: towards) * p)
        } else {
            return towards.advanced(by: towards.distance(to: self) * (1 - p))
        }
    }
}

protocol KeyedTimeSeriesElement: TimeSeriesElement {
    /// Key into storage to find same elements
    static var key: String {get}
}

// MARK: Generic TimeseriesElement
struct VectorElement<Categorical>: TimeSeriesElement, Equatable where Categorical: Codable, Categorical: Equatable {
    init(
        date: Date,
        doubles: [Double] = [],
        ints: [Int] = [],
        optionalDoubles: [Double?] = [],
        optionalInts: [Int?] = [],
        categorical: Categorical)
    {
        self.date = date
        self.doubles = doubles
        self.ints = ints
        self.optionalDoubles = optionalDoubles
        self.optionalInts = optionalInts
        self.categorical = categorical
    }
    
    init(
        date: Date,
        doubles: [Double] = [],
        ints: [Int] = [],
        optionalDoubles: [Double?] = [],
        optionalInts: [Int?] = [])
    where Categorical == None
    {
        self.date = date
        self.doubles = doubles
        self.ints = ints
        self.optionalDoubles = optionalDoubles
        self.optionalInts = optionalInts
        self.categorical = .unused
    }
    
    func distance(to: VectorElement) -> VectorElementDelta {
        VectorElementDelta(
            duration: date.distance(to: to.date),
            doubles: doubles.indices.map {doubles[$0].distance(to: to.doubles[$0])},
            ints: ints.indices.map {Double(ints[$0].distance(to: to.ints[$0]))},
            optionalDoubles: optionalDoubles.indices.map {optionalDoubles[$0].distance(to: to.optionalDoubles[$0])},
            optionalInts: optionalInts.indices.map {
                if let result = optionalInts[$0].distance(to: to.optionalInts[$0]) {
                    return Double(result)
                } else {
                    return nil
                }
            })
    }
    
    func advanced(by: VectorElementDelta) -> VectorElement {
        VectorElement(
            date: date.advanced(by: by.duration),
            doubles: doubles.indices.map {doubles[$0].advanced(by: by.doubles[$0])},
            ints: ints.indices.map {ints[$0].advanced(by: Int(by.ints[$0] + 0.5))},
            optionalDoubles: optionalDoubles.indices.map {optionalDoubles[$0].advanced(by: by.optionalDoubles[$0])},
            optionalInts: optionalInts.indices.map {
                if let delta = by.optionalInts[$0] {
                    return optionalInts[$0].advanced(by: Int(delta + 0.5))
                } else {
                    return optionalInts[$0].advanced(by: nil)
                }
            },
            categorical: categorical)
    }
    
    func extrapolate(at: Date) -> VectorElement {
        VectorElement(
            date: at,
            doubles: doubles,
            ints: ints,
            optionalDoubles: optionalDoubles,
            optionalInts: optionalInts,
            categorical: categorical)
    }
    
    typealias Delta = VectorElementDelta
    let date: Date
    let doubles: [Double]
    let ints: [Int]
    let optionalDoubles: [Double?]
    let optionalInts: [Int?]
    let categorical: Categorical
}

struct VectorElementDelta: Scalable, Equatable {
    static func * (lhs: VectorElementDelta, rhs: Double) -> VectorElementDelta {
        VectorElementDelta(
            duration: lhs.duration * rhs,
            doubles: lhs.doubles.map {$0 * rhs},
            ints: lhs.ints.map {$0 * rhs},
            optionalDoubles: lhs.optionalDoubles.map {
                if let opt = $0 {
                    return opt * rhs
                } else {
                    return nil
                }
            },
            optionalInts: lhs.optionalInts.map {
                if let opt = $0 {
                    return opt * rhs
                } else {
                    return nil
                }
            })
    }
    
    let duration: TimeInterval
    let doubles: [Double]
    let ints: [Double]
    let optionalDoubles: [Double?]
    let optionalInts: [Double?]
}

protocol GenericTimeseriesElement: KeyedTimeSeriesElement where Delta == VectorElementDelta {
    associatedtype Categorical: Codable, Equatable
    
    var vector: VectorElement<Categorical> {get}
    init(_ vector: VectorElement<Categorical>)
}

extension GenericTimeseriesElement {
    var date: Date {vector.date}
    
    func distance(to: Self) -> Delta {vector.distance(to: to.vector)}
    func advanced(by: Delta) -> Self {Self(vector.advanced(by: by))}
    func extrapolate(at: Date) -> Self {Self(vector.extrapolate(at: at))}
}

enum None: Codable, Equatable {
    case unused
}

// MARK: Timeseries

/// Contains time series elements of variable types and allows to:
/// - Insert a new time series element in any order
/// - Get a single element at a given point in time, either an original-, interpolated- or extrapolated element
/// - Travers through elements in date order
/// - Travers through a number of different timeseries, returning a sequence of tuples or given time series by time. Missing elements are inter- oder extrapolated.
class TimeSeries<Element> where Element: KeyedTimeSeriesElement {
    @Persistent(key: Element.key) private(set) var elements = [Element]()
    
    static func merge(_ d: [Date]...) -> [Date] {
        // TODO: Put into calculation engine
        let dates = d.map {$0}
        var readIdxs = Array<Int>(repeating: 0, count: dates.count)
        var result = [Date]()
        
        var nextMinIdx: Int? {
            dates
                .indices
                .filter {dates[$0].indices.contains(readIdxs[$0])}
                .map {(idx: $0, date: dates[$0][readIdxs[$0]])}
                .min(by: {$0.date < $1.date})?.idx
        }
        
        // Which date is min?
        while let minIdx = nextMinIdx {
            result.append(dates[minIdx][readIdxs[minIdx]])
            readIdxs[minIdx] += 1
        }
        return result
    }
    
    /// Insert a new element, enforce ascending order by date.
    func insert(_ element: Element) {
        let idx = getIdx(for: element.date)
        
        if let at = idx.at {
            elements[at] = element // Replace with newer version
        } else if let after = idx.after {
            elements.insert(element, at: after)
        } else {
            elements.append(element)
        }
    }

    /// Return element of given date. If date is missed, it is inter- or extrapolated.
    subscript (_ asOf: Date) -> Element {
        let idx = getIdx(for: asOf)
        if let element = getByIdx(date: asOf, before: idx.before, at: idx.at, after: idx.after) {
            return element
        } else {
            fatalError("Index out of bounds!")
        }
    }

    /// Return elements for given dates. Dates must be sorted in ascending order. Missing dates are inter- or extrapolated.
    subscript (_ dates: Date...) -> [Element] {
        if elements.isEmpty {return []}
        return dates.map {self[$0]} // TODO: Linear search is more efficient if dates.count * ld(el.count) > el.count
    }

    /// Archive data and truncate in array. Always keep up to two elements which have older or equal date.
    func archive(upTo date: Date) {
        let idx = getIdx(for: date)
        let truncationIdx: Int? = {
            if idx.at != nil, let before = idx.before {
                return before
            } else if let before = idx.before {
                if before > elements.startIndex {return before - 1}
            }
            return nil
        }()

        guard let truncationIdx = truncationIdx, truncationIdx > elements.startIndex else {return}
        Files.write(elements.prefix(upTo: truncationIdx).array(), to: "\(Element.key)-\(Date.now).json")
        elements = elements.suffix(from: truncationIdx).array()
    }
    
    /// For test cases only. Use `archive` instead.
    func reset() {elements.removeAll()}

    private func getByIdx(date: Date, before: Int?, at: Int?, after: Int?) -> Element? {
        if let at = at {
            return elements[at]
        } else if let before = before, let after = after {
            return elements[before].interpolate(at: date, elements[after])
        } else if let before = before {
            if elements.startIndex < before {
                return elements[before - 1].interpolate(at: date, elements[before])
            } else {
                return elements[before].extrapolate(at: date)
            }
        } else if let after = after {
            if elements.endIndex > after+1 {
                return elements[after].interpolate(at: date, elements[after+1])
            } else {
                return elements[after].extrapolate(at: date)
            }
        } else {
            return nil
        }
    }
    
    private func getIdx(for date: Date) -> (before: Int?, at: Int?, after: Int?) {
        if elements.isEmpty {
            return (before: nil, at: nil, after: nil)
        } else if date > elements.last!.date {
            return (before: elements.endIndex - 1, at: nil, after: nil)
        } else if date < elements.first!.date {
            return (before: nil, at: nil, after: elements.startIndex)
        } else {
            let range = binSearch(date, indices: elements.indices)
            if elements[range.lowerBound].date == date {
                return (
                    before: range.lowerBound <= elements.startIndex ? nil : (range.lowerBound - 1),
                    at: range.lowerBound,
                    after: range.upperBound >= elements.endIndex ? nil : range.upperBound)
            } else {
                return (
                    before: range.lowerBound,
                    at: nil,
                    after: range.upperBound >= elements.endIndex ? nil : range.upperBound)
            }
        }
    }
    
    private func binSearch(_ date: Date, indices: Range<Int>) -> Range<Int> {
        if indices.lowerBound.distance(to: indices.upperBound) <= 1 {return indices}
        let midIndex = (indices.lowerBound + indices.upperBound) / 2

        if (elements[indices.lowerBound].date ..< elements[midIndex].date).contains(date) {
            return binSearch(date, indices: indices.lowerBound ..< midIndex)
        } else {
            return binSearch(date, indices: midIndex ..< indices.upperBound)
        }
    }
}
