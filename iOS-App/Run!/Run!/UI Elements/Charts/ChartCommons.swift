//
//  ChartCommons.swift
//  Run!
//
//  Created by Jürgen Boiselle on 01.01.22.
//

import Foundation
import SwiftUI

enum Chart {
    /// Position ticks on a chart in a pretty way.
    ///
    ///  see [Stackoverflow answer](https://stackoverflow.com/questions/8506881/nice-label-algorithm-for-charts-with-minimum-ticks) for the algorithm in use.
    ///
    /// - Parameters:
    ///   - for: Range of values to fit on chart-axis
    ///   - n: Number of ticks. Defaults to 10.
    /// - Returns: strides from min through (including) max with spacing between ticks in actual value-range, not screen-positions.
    static func prettyTicks<Value>(for range: Range<Value>, n: Int = 10) -> [Value]
    where Value: BinaryFloatingPoint, Value.Stride: BinaryFloatingPoint
    {
        /// Get nice number for any `double` value.
        ///
        ///  see [Stackoverflow answer](https://stackoverflow.com/questions/8506881/nice-label-algorithm-for-charts-with-minimum-ticks) for the algorithm in use.
        ///
        /// - Parameters:
        ///   - uglyNum: `double` value. Must a positive number >= 0.
        ///   - round: result is rounded or rounded up.
        /// - Returns: Prettified number.
        func niceNumber(uglyNum: Double, round: Bool) -> Double {
            let digits = pow(10, floor(log10(uglyNum)))
            let significant = uglyNum / digits
            
            if round {
                if significant < 1.5 {
                    return digits
                } else if significant < 3 {
                    return digits * 2
                } else if significant < 7 {
                    return digits * 5
                } else {
                    return digits * 10
                }
            } else {
                if significant <= 1 {
                    return digits
                } else if significant <= 2 {
                    return digits * 2
                } else if significant <= 5 {
                    return digits * 5
                } else {
                    return digits * 10
                }
            }
        }
        
        let niceRange = niceNumber(uglyNum: Double(range.distance), round: false)
        let niceSpacing = niceNumber(uglyNum: niceRange / Double(n - 1), round: true)
        let niceMin = floor(Double(range.lowerBound) / niceSpacing) * niceSpacing
        let niceMax = ceil(Double(range.upperBound) / niceSpacing) * niceSpacing
        
        return Array(stride(from: Value(niceMin), through: Value(niceMax), by: Value.Stride(niceSpacing)))
    }
    
    /// Position ticks on a chart in a pretty way.
    ///
    ///  see [Stackoverflow answer](https://stackoverflow.com/questions/8506881/nice-label-algorithm-for-charts-with-minimum-ticks) for the algorithm in use.
    ///
    /// - Parameters:
    ///   - for: Range of values to fit on chart-axis
    ///   - n: Number of ticks. Defaults to 10.
    /// - Returns: strides from min through (including) max with spacing between ticks in actual value-range, not screen-positions.
    static func prettyTicks<Value>(for range: Range<Value>, n: Int = 10) -> [Value]
    where Value: BinaryInteger
    {
        let strides = prettyTicks(
            for: Double(range.lowerBound) ..< Double(range.upperBound),
            n: n)
        return strides.map {Value($0)}
    }
    
    /// Position ticks on a chart in a pretty way.
    ///
    ///  see [Stackoverflow answer](https://stackoverflow.com/questions/8506881/nice-label-algorithm-for-charts-with-minimum-ticks) for the algorithm in use.
    ///
    /// - Parameters:
    ///   - for: Range of values to fit on chart-axis
    ///   - n: Number of ticks. Defaults to 10.
    /// - Returns: strides from min through (including) max with spacing between ticks in actual value-range, not screen-positions.
    static func prettyTicks(for range: Range<Date>, n: Int = 10) -> [Date] {
        let strides = prettyTicks(
            for: range.lowerBound.timeIntervalSince1970 ..< range.upperBound.timeIntervalSince1970,
            n: n)
        return strides.map {Date(timeIntervalSince1970: $0)}
    }
    
    enum Axis {
        case X, Y
    }

    struct AnyDataPoint<Body: View>: ChartDataPoint {
        private let getClassifier: () -> String
        private let getX: () -> Double
        private let getY: () -> Double
        private let getMakeBody: (CGRect, CGPoint, CGPoint, CGPoint) -> Body

        init<DataPoint: ChartDataPoint>(_ dataPoint: DataPoint) where DataPoint.Body == Body {
            getClassifier = {dataPoint.classifier}
            getX = {dataPoint.x}
            getY = {dataPoint.y}
            getMakeBody = dataPoint.makeBody
        }
        
        var classifier: String {getClassifier()}
        var x: Double {getX()}
        var y: Double {getY()}
        func makeBody(_ canvas: CGRect, _ pos: CGPoint, _ prevPos: CGPoint, _ nearestPos: CGPoint) -> Body {
            getMakeBody(canvas, pos, prevPos, nearestPos)
        }
    }
    
    struct DataPointPrepared<DataPoint: ChartDataPoint>: Identifiable {
        let id = UUID()
        let dataPoint: DataPoint
        let previous: DataPoint
        let nearest: DataPoint
        
        fileprivate init(_ dataPoint: DataPoint, previous: DataPoint?, nearest: DataPoint?) {
            self.dataPoint = dataPoint
            self.previous = previous ?? dataPoint
            self.nearest = nearest ?? dataPoint
        }
    }
}

protocol ChartDataPoint {
    var classifier: String {get}
    var x: Double {get}
    var y: Double {get}
    
    associatedtype Body: View
    func makeBody(_ canvas: CGRect, _ pos: CGPoint, _ prevPos: CGPoint, _ nearestPos: CGPoint) -> Body
}

extension ChartDataPoint {
    var anyDataPoint: Chart.AnyDataPoint<Body> {Chart.AnyDataPoint(self)}
}

extension Array where Element: ChartDataPoint {
    typealias Prepared = (
        xPrettyTicks: [Double],
        yPrettyTicks: [Double],
        dps: [Chart.DataPointPrepared<Element>])

    /// Prepare data points for chart.
    /// Data will be enriched by nearest x/y position, range of x and y values.
    /// Data points are returned as sorted array by x (ascending) and y (descending)
    /// As this function does a significant amount of number crunching, it should run when necessary.
    func prepared(nx: Int, ny: Int) -> Prepared {
        // Get ranges
        let xRange = range((self.min {$0.x < $1.x}!.x), (self.max {$0.x < $1.x}!.x))
        let yRange = range((self.min {$0.y < $1.y}!.y), (self.max {$0.y < $1.y}!.y))
        
        // Get sorted elements
        let sorted = self.sorted {$0.x == $1.x ? ($0.y > $1.y) : ($0.x < $1.x)}

        // Get nearest elements
        let nearest = sorted.indices
            .map { i -> Element? in
                let n: (Element, Double)? = sorted.indices
                    .filter {$0 != i}
                    .map { j in
                        let dx = sorted[j].x - sorted[i].x
                        let dy = sorted[j].y - sorted[i].y
                        return (sorted[j], dx * dx + dy * dy)
                    }
                    .min {$0.1 < $1.1}
                return n?.0
            }
        
        // Get previous elements
        var prev: Element? = nil
        let previous: [Element?] = sorted.map { element in
            defer {prev = element}
            return prev
        }
        
        // Create prepared data points
        let dataPoints = sorted
            .indices
            .map {
                Chart.DataPointPrepared<Element>(sorted[$0], previous: previous[$0], nearest: nearest[$0])
            }
        
        return (
            Chart.prettyTicks(for: xRange, n: nx),
            Chart.prettyTicks(for: yRange, n: ny),
            dataPoints
        )
    }
    
    private func range(
        _ lower: Double,
        _ upper: Double,
        spanPad: Double = 0.1,
        minPad: Double = 1)
    -> Range<Double>
    {
        var pad = (upper - lower) * spanPad
        if pad < minPad {pad = minPad}
        return (lower - pad) ..< (upper + pad)
    }
}

extension Double: Identifiable {
    public var id: Double {self}
}
