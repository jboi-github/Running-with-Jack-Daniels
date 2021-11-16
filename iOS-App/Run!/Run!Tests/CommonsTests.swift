//
//  CommonsTests.swift
//  Run!Tests
//
//  Created by Jürgen Boiselle on 15.11.21.
//

import XCTest
@testable import Run_

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
        XCTAssertEqual((1.0 ..< 10.0).transform(2.5, to: 10 ..< 100), 25)
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
}
