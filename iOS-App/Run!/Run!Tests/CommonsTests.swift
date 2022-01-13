//
//  CommonsTests.swift
//  Run!Tests
//
//  Created by Jürgen Boiselle on 15.11.21.
//

import XCTest
@testable import Run_
import SwiftUI

class CommonsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCheckError() throws {
        XCTAssertFalse(check("This is an error"))
        XCTAssertTrue(check(nil))
    }
    
    func testLastIndex() throws {
        XCTAssertNil([].lastIndex, "collection empty")
        XCTAssertEqual([1].lastIndex, 0, "collection one")
        XCTAssertEqual([1, 3, 4].lastIndex, 2, "collection many")
    }
    
    func testInsertIndex() throws {
        let x: [Int] = [1000, 2000, 3000]
        
        XCTAssertEqual(x.insertIndex(for: 500, element2key: {$0}), 0)
        XCTAssertEqual(x.insertIndex(for: 1000, element2key: {$0}), 1)
        XCTAssertEqual(x.insertIndex(for: 2500, element2key: {$0}), 2)
        XCTAssertEqual(x.insertIndex(for: 2000, element2key: {$0}), 2)
        XCTAssertEqual(x.insertIndex(for: 3000, element2key: {$0}), 3)
        XCTAssertEqual(x.insertIndex(for: 5000, element2key: {$0}), 3)
        XCTAssertEqual([Int]().insertIndex(for: 500, element2key: {$0}), 0)
    }
    
    struct Rx : Rangable, Equatable {
        typealias C = Double
        let range: Range<Double>
        
        init(_ range: Range<Double>) {self.range = range}
    }
    
    struct Dx: RangableMergeDelegate {
        typealias R = Rx
        
        func reduce(_ rangable: Rx, to: Range<Double>) -> Rx {Rx(to)}
        func resolve(_ r1: Rx, _ r2: Rx, to: Range<Double>) -> Rx {Rx(to)}
        func drop(_ rangable: Rx) {CommonsTests.drops.append(rangable.range)}
        func add(_ rangable: Rx) {CommonsTests.adds.append(rangable.range)}
    }
    
    private static var drops = [Range<Double>]()
    private static var adds = [Range<Double>]()
    
    func testInsertIndexRanges() throws {
        let x: [Rx] = [Rx(0..<1), Rx(1..<2), Rx(2..<3), Rx(8..<9)]
        CommonsTests.drops.removeAll()
        CommonsTests.adds.removeAll()

        r(0.5 ..< 0.75, expected: [Rx(0..<0.5), Rx(0.5..<0.75), Rx(0.75..<1), Rx(1..<2), Rx(2..<3), Rx(8..<9)])
        r(0.5 ..< 1, expected: [Rx(0..<0.5), Rx(0.5..<1), Rx(1..<2), Rx(2..<3), Rx(8..<9)])
        r(0.5 ..< 1.5, expected: [Rx(0..<0.5), Rx(0.5..<1), Rx(1..<1.5), Rx(1.5..<2), Rx(2..<3), Rx(8..<9)])
        r(0.5 ..< 2, expected: [Rx(0..<0.5), Rx(0.5..<1), Rx(1..<2), Rx(2..<3), Rx(8..<9)])
        r(0.5 ..< 2.5, expected: [Rx(0..<0.5), Rx(0.5..<1), Rx(1..<2), Rx(2..<2.5), Rx(2.5..<3), Rx(8..<9)])
        r(2 ..< 2.5, expected: [Rx(0..<1), Rx(1..<2), Rx(2..<2.5), Rx(2.5..<3), Rx(8..<9)])
        r(2.5 ..< 2.75, expected: [Rx(0..<1), Rx(1..<2), Rx(2..<2.5), Rx(2.5..<2.75), Rx(2.75..<3), Rx(8..<9)])
        r(-1 ..< -0.5, expected: [Rx(-1 ..< -0.5), Rx(0..<1), Rx(1..<2), Rx(2..<3), Rx(8..<9)])
        r(10 ..< 10.5, expected: [Rx(0..<1), Rx(1..<2), Rx(2..<3), Rx(8..<9), Rx(10..<10.5)])
        r(8.5 ..< 10, expected: [Rx(0..<1), Rx(1..<2), Rx(2..<3), Rx(8..<8.5), Rx(8.5..<9), Rx(9..<10)])
        r(9 ..< 10, expected: [Rx(0..<1), Rx(1..<2), Rx(2..<3), Rx(8..<9), Rx(9..<10)])
        
        XCTAssertEqual(CommonsTests.drops, [
            0.0..<1.0,
            0.0..<1.0,
            0.0..<1.0,
            1.0..<2.0,
            0.0..<1.0,
            1.0..<2.0,
            0.0..<1.0,
            1.0..<2.0,
            2.0..<3.0,
            2.0..<3.0,
            2.0..<3.0,
            8.0..<9.0
        ])

        XCTAssertEqual(CommonsTests.adds, [
            0.0..<0.5,
            0.5..<0.75,
            0.75..<1.0,
            0.0..<0.5,
            0.5..<1.0,
            0.0..<0.5,
            0.5..<1.0,
            1.0..<1.5,
            1.5..<2.0,
            0.0..<0.5,
            0.5..<1.0,
            1.0..<2.0,
            0.0..<0.5,
            0.5..<1.0,
            1.0..<2.0,
            2.0..<2.5,
            2.5..<3.0,
            2.0..<2.5,
            2.5..<3.0,
            2.0..<2.5,
            2.5..<2.75,
            2.75..<3.0,
            -1.0 ..< -0.5,
            10.0..<10.5,
            8.0..<8.5,
            8.5..<9.0,
            9.0..<10.0,
            9.0..<10.0
        ])

        func r(_ range: Range<Double>, expected: [Rx]) {
            var x = x
            x.merge(Rx(range), delegate: Dx())
            XCTAssertEqual(x, expected, "\(range)")
        }
    }
    
    func testRangeIsBefore() throws {
        XCTAssertTrue((0 ..< 0).isBefore(2 ..< 4))
        XCTAssertTrue((0 ..< 1).isBefore(2 ..< 4))
        XCTAssertTrue((0 ..< 2).isBefore(2 ..< 4))
        XCTAssertFalse((0 ..< 3).isBefore(2 ..< 4))
        XCTAssertFalse((0 ..< 4).isBefore(2 ..< 4))
        XCTAssertFalse((0 ..< 5).isBefore(2 ..< 4))

        XCTAssertTrue((2 ..< 2).isBefore(2 ..< 4))
        XCTAssertFalse((2 ..< 3).isBefore(2 ..< 4))
        XCTAssertFalse((2 ..< 4).isBefore(2 ..< 4))
        XCTAssertFalse((2 ..< 5).isBefore(2 ..< 4))

        XCTAssertFalse((3 ..< 3).isBefore(2 ..< 4))
        XCTAssertFalse((3 ..< 4).isBefore(2 ..< 5))
        XCTAssertFalse((3 ..< 4).isBefore(2 ..< 4))
        XCTAssertFalse((3 ..< 5).isBefore(2 ..< 4))
        
        XCTAssertFalse((4 ..< 4).isBefore(2 ..< 4))
        XCTAssertFalse((4 ..< 5).isBefore(2 ..< 4))

        XCTAssertFalse((5 ..< 5).isBefore(2 ..< 4))
        XCTAssertFalse((5 ..< 6).isBefore(2 ..< 4))
    }
    
    func testRangeIsAfter() throws {
        XCTAssertFalse((0 ..< 0).isAfter(2 ..< 4))
        XCTAssertFalse((0 ..< 1).isAfter(2 ..< 4))
        XCTAssertFalse((0 ..< 2).isAfter(2 ..< 4))
        XCTAssertFalse((0 ..< 3).isAfter(2 ..< 4))
        XCTAssertFalse((0 ..< 4).isAfter(2 ..< 4))
        XCTAssertFalse((0 ..< 5).isAfter(2 ..< 4))

        XCTAssertFalse((2 ..< 2).isAfter(2 ..< 4))
        XCTAssertFalse((2 ..< 3).isAfter(2 ..< 4))
        XCTAssertFalse((2 ..< 4).isAfter(2 ..< 4))
        XCTAssertFalse((2 ..< 5).isAfter(2 ..< 4))

        XCTAssertFalse((3 ..< 3).isAfter(2 ..< 4))
        XCTAssertFalse((3 ..< 4).isAfter(2 ..< 5))
        XCTAssertFalse((3 ..< 4).isAfter(2 ..< 4))
        XCTAssertFalse((3 ..< 5).isAfter(2 ..< 4))
        
        XCTAssertTrue((4 ..< 4).isAfter(2 ..< 4))
        XCTAssertTrue((4 ..< 5).isAfter(2 ..< 4))

        XCTAssertTrue((5 ..< 5).isAfter(2 ..< 4))
        XCTAssertTrue((5 ..< 6).isAfter(2 ..< 4))
    }
    
    func testInsertIndexPerf() throws {
        let x: [Int] = stride(from: 600, to: 1000000*60+600, by: 60).map {$0}
        
        self.measure {
            let _ = x.insertIndex(for: 300, element2key: {$0})
            let _ = x.insertIndex(for: (1000000*60+600) / 2, element2key: {$0})
            let _ = x.insertIndex(for: 1000000*60+600 + 3600, element2key: {$0})
        }
    }

    func testTransform() throws {
        XCTAssertEqual((1 ..< 10).transform(3, to: 10 ..< 100), 30)
        XCTAssertEqual((1.0 ..< 10.0).transform(2.5, 10 ..< 100), 25)
        XCTAssertEqual((1.0 ..< 10.0).transform(1.25, to: Date(timeIntervalSince1970: 1000) ..< Date(timeIntervalSince1970: 10000)).timeIntervalSince1970, 1250, accuracy: 0.01)
    }


    func testDistance() throws {
        XCTAssertEqual((0.0 ..< 2.0).distance, 2.0, accuracy: 0.01)
        XCTAssertEqual((Date(timeIntervalSince1970: 1000) ..< Date(timeIntervalSince1970: 2000)).distance, 1000, accuracy: 0.01)
    }

    func testDoubleAvg() throws {
        XCTAssertEqual(1.0.avg(3.0, 3), 1.5, accuracy: 0.01)
        XCTAssertEqual(1.0.avg(3.0, 0), 3.0, accuracy: 0.01)
        XCTAssertTrue((1.0.avg(.nan, 0)).isNaN)
        XCTAssertTrue((Double.nan.avg(5, 0)).isNaN)
    }
    
    func testPrettyTicks() throws {
        XCTAssertEqual(Chart.prettyTicks(for: 0.0 ..< 3.14), [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5])
        XCTAssertEqual(Chart.prettyTicks(for: 0.0 ..< 3.14, n: 5), [0.0, 1.0, 2.0, 3.0, 4.0])
        XCTAssertEqual(Chart.prettyTicks(for: -10.0 ..< 3.14, n: 5), [-10.0, -5.0, 0.0, 5.0])

        XCTAssertEqual(Chart.prettyTicks(for: 0 ..< 314), [0, 50, 100, 150, 200, 250, 300, 350])
        XCTAssertEqual(Chart.prettyTicks(for: 0 ..< 314, n: 7), [0, 100, 200, 300, 400])
        
        print(Chart.prettyTicks(
            for: Date(timeIntervalSince1970: 0) ..< Date(timeIntervalSince1970: 20000)))
        print(Chart.prettyTicks(
            for: Date(timeIntervalSince1970: 0) ..< Date(timeIntervalSince1970: 20000), n: 7))
        
        print(Chart.prettyTicks(for: -3.14 ..< 3.14, n: 20).map {(-3.5 ..< 3.5).transform($0, 0 ..< 100)})
    }
    
    func testChartDataPointsPrepare() throws {
        struct DP: ChartDataPoint {
            let classifier: String
            let x: Double
            let y: Double
            
            func makeBody(_ canvas: CGRect, _ pos: CGPoint, _ prevPos: CGPoint, _ nearestPos: CGPoint) -> some View {
                EmptyView()
            }
            
            func distance(to: Self) -> Double {
                let dx = x - to.x
                let dy = y - to.y
                return sqrt(dx*dx + dy*dy)
            }
        }
        
        let expected = [
            (-10.0, -20.0, 2.23606797749979),
            (-10.0, -30.0, 3.1622776601683795),
            (-9.0, -18.0, 2.23606797749979),
            (-9.0, -27.0, 3.1622776601683795),
            (-8.0, -16.0, 2.23606797749979),
            (-8.0, -24.0, 3.1622776601683795),
            (-7.0, -14.0, 2.23606797749979),
            (-7.0, -21.0, 3.1622776601683795),
            (-6.0, -12.0, 2.0),
            (-6.0, -18.0, 2.8284271247461903),
            (-5.0, -10.0, 2.23606797749979), (-5.0, -15.0, 2.23606797749979), (-4.0, -8.0, 1.4142135623730951), (-4.0, -12.0, 2.0), (-3.0, -6.0, 1.0), (-3.0, -9.0, 1.4142135623730951), (-2.0, -4.0, 1.4142135623730951), (-2.0, -6.0, 1.0), (-1.0, -2.0, 1.0), (-1.0, -3.0, 1.0), (0.0, 0.0, 0.0), (0.0, 0.0, 0.0), (1.0, 3.0, 1.0), (1.0, 2.0, 1.0), (2.0, 6.0, 1.0), (2.0, 4.0, 1.4142135623730951), (3.0, 9.0, 1.4142135623730951), (3.0, 6.0, 1.0), (4.0, 12.0, 2.0), (4.0, 8.0, 1.4142135623730951), (5.0, 15.0, 2.23606797749979), (5.0, 10.0, 2.23606797749979), (6.0, 18.0, 2.8284271247461903), (6.0, 12.0, 2.0), (7.0, 21.0, 3.1622776601683795), (7.0, 14.0, 2.23606797749979), (8.0, 24.0, 3.1622776601683795), (8.0, 16.0, 2.23606797749979), (9.0, 27.0, 3.1622776601683795), (9.0, 18.0, 2.23606797749979), (10.0, 30.0, 3.1622776601683795), (10.0, 20.0, 2.23606797749979), (11.0, 33.0, 3.1622776601683795), (11.0, 22.0, 2.23606797749979), (12.0, 36.0, 3.1622776601683795), (12.0, 24.0, 2.23606797749979), (13.0, 39.0, 3.1622776601683795), (13.0, 26.0, 2.23606797749979), (14.0, 42.0, 3.1622776601683795), (14.0, 28.0, 2.23606797749979)]
        
        let dps1 = stride(from: -10, to: 15, by: 1)
            .map {DP(classifier: "Sinus", x: Double($0), y: 2.0 * Double($0))}
        let dps2 = stride(from: -10, to: 15, by: 1)
            .map {DP(classifier: "Cosinus", x: Double($0), y: 3.0 * Double($0))}
        
        let result = (dps1 + dps2).shuffled().prepared(nx: 10, ny: 5)
        
        XCTAssertEqual(result.xPrettyTicks, Chart.prettyTicks(for: -10.0 ..< 15, n: 10))
        XCTAssertEqual(result.yPrettyTicks, Chart.prettyTicks(for: -30.0 ..< 45.0, n: 5))

        XCTAssertEqual(result.dps.map {Double($0.dataPoint.x)}, expected.map {$0.0})
        XCTAssertEqual(result.dps.map {Double($0.dataPoint.y)}, expected.map {$0.1})
        XCTAssertEqual(result.dps.map {$0.dataPoint.distance(to: $0.nearest)}, expected.map {$0.2})
    }
}
