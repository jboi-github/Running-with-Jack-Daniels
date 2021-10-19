//
//  RunFoundationKitTests.swift
//  RunFoundationKitTests
//
//  Created by Jürgen Boiselle on 05.10.21.
//

import XCTest
@testable import RunFoundationKit

class RunFoundationKitTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testAddWithError() throws {
        let bigNumber: Double = exp(500.0)
        let smallNumber: Double = exp(-1.0)
        
        print(bigNumber, smallNumber, bigNumber.addWithError(smallNumber).error)
        XCTAssertNotEqual(bigNumber.addWithError(smallNumber).error, 0)
    }
    
    func testAvgBuilder() throws {
        let smallNumber: Double = exp(-10.0)
        let x = [Double](repeating: smallNumber, count: 1000000)
        
        XCTAssertLessThan(
            abs(smallNumber - x.reduce(into: AvgBuilder()) {$0.merge($1)}.avg),
            abs(smallNumber - x.reduce(Double.zero, +) / Double(x.count)))
        
        XCTAssertLessThan(
            abs(smallNumber - x.reduce(into: AvgBuilder()) {$0.merge($1)}.avg),
            abs(smallNumber - x.reduce(Double.zero, {$0 + $1 / Double(x.count)})))
    }
    
    func testNgramN() throws {
        let actual = Array([1,3,4,6,2,7,3,7,9,1].ngram(3))
        let expected = [[1], [1, 3], [1, 3, 4], [3, 4, 6], [4, 6, 2], [6, 2, 7], [2, 7, 3], [7, 3, 7], [3, 7, 9], [7, 9, 1], [9, 1], [1]]
        
        XCTAssertEqual(actual.count, expected.count, "same count")
        (0 ..< expected.endIndex).forEach { i in
            assertIntArrays(array1: Array(actual[i]), array2: expected[i], message: "same")
        }
    }

    func testNgram1() throws {
        let actual = Array([1].ngram(3))
        let expected = [[1]]
        
        print(actual)
        XCTAssertEqual(actual.count, expected.count, "same count")
        (0 ..< expected.endIndex).forEach { i in
            assertIntArrays(array1: Array(actual[i]), array2: expected[i], message: "same")
        }
    }

    func testNgram0() throws {
        let actual = Array([Int]().ngram(3))
        let expected: [[Int]] = []
        
        print(actual)
        XCTAssertEqual(actual.count, expected.count, "same count")
        (0 ..< expected.endIndex).forEach { i in
            assertIntArrays(array1: Array(actual[i]), array2: expected[i], message: "same")
        }
    }
    
    func testFlatMapNoStore() throws {
        XCTAssertEqual(Array([Int]().flatMapNoStore {[$0, $0 * -1]}), [Int]())
        XCTAssertEqual(Array([1].flatMapNoStore {[$0, $0 * -1]}), [1, -1])
        XCTAssertEqual(Array([1,2].flatMapNoStore {[$0, $0 * -1]}), [1, -1, 2, -2])
        XCTAssertEqual(Array([1,2].flatMapNoStore {$0 == 1 ? [] : [15, 20, 30]}), [15, 20, 30])
    }
    
    func testEnsureSize() throws {
        let x1 = [1].ensureSize(2)
        XCTAssertEqual(Array(x1), [1,nil])

        let x2 = [1, 2].ensureSize(2)
        XCTAssertEqual(Array(x2), [1,2])

        let x3 = [1,2,3].ensureSize(2)
        XCTAssertEqual(Array(x3), [1,2,3])

        let x0 = [Int]().ensureSize(2)
        XCTAssertEqual(Array(x0), [nil,nil])
    }
    
    func testForEachMerged() throws {
        let x = [[0,1,2,3,4,5,6,7,8,9], [3,6,7,9], [], [2,5,7]]
        XCTAssertEqual(Array(x.mapMerged().map {$0.offset}), [0,0,0,3,0,1,0,0,3,0,1,0,1,3,0,0,1])
        XCTAssertEqual(
            Array(x.mapMerged().map {$0.elements}),
            [
                [  0,   3, nil,   2],
                [  1,   3, nil,   2],
                [  2,   3, nil,   2],
                [  3,   3, nil,   2],
                [  3,   3, nil,   5],
                [  4,   3, nil,   5],
                [  4,   6, nil,   5],
                [  5,   6, nil,   5],
                [  6,   6, nil,   5],
                [  6,   6, nil,   7],
                [  7,   6, nil,   7],
                [  7,   7, nil,   7],
                [  8,   7, nil,   7],
                [  8,   9, nil,   7],
                [  8,   9, nil, nil],
                [  9,   9, nil, nil],
                [nil,   9, nil, nil],
            ])
        
        XCTAssertEqual(Array([[Int]]().mapMerged().map {$0.offset}), [Int]())
        XCTAssertEqual(Array([[Int]]().mapMerged().map {$0.elements}), [[Int]]())
    }

    func testMapExtended() throws {
        let actual = [1,3,4,9,15]
            .mapExtended{[$0]}
                mid: {[$0, $1]}
                after: {[$0]}
        
        let expected = [
            [1],
            [1,3],
            [3,4],
            [4,9],
            [9,15],
            [15]
        ]

        XCTAssertEqual(Array(actual), expected)
    }

    func testMapExtended1() throws {
        let actual: [[Int?]] = Array([0]
            .mapExtended{[$0]}
                mid: {[$0, $1]}
                after: {[$0]})
        
        let expected: [[Int?]] = [[0], [0]]

        XCTAssertEqual(actual, expected)
    }

    func testMapExtended0() throws {
        let actual: [[Int?]] = Array([]
            .mapExtended{[$0]}
                mid: {[$0, $1]}
                after: {[$0]})
        
        let expected: [[Int?]] = [[nil],[nil]]

        XCTAssertEqual(actual, expected)
    }

    func testMinIndex() {
        XCTAssertNil([String]().minIndex(by: {$0 < $1}))
        XCTAssertEqual(["A", "B", "0", "A"].minIndex(by: {$0 < $1}), 2)
    }

    func testMaxIndex() {
        XCTAssertNil([String]().maxIndex(by: {$0 < $1}))
        XCTAssertEqual(["A", "B", "0", "A"].maxIndex(by: {$0 < $1}), 1)
    }

    func testLastIndex() throws {
        XCTAssertNil([].lastIndex, "collection empty")
        XCTAssertEqual([1].lastIndex, 0, "collection one")
        XCTAssertEqual([1, 3, 4].lastIndex, 2, "collection many")
    }
    
    func testIndexOrNilBefore() throws {
        XCTAssertNil([].indexOrNil(before: 10), "collection empty")
        XCTAssertNil([3,5,2].indexOrNil(before: 10), "collection out of range")
        XCTAssertNil([3,5,2].indexOrNil(before: 0), "collection at start")

        XCTAssertEqual([1, 3, 4].indexOrNil(before: 1), 0, "collection at start")
        XCTAssertEqual([1, 3, 4].indexOrNil(before: 2), 1, "collection at end")
        XCTAssertEqual([1, 3, 4].indexOrNil(before: 3), 2, "collection behind end")
    }
    
    func testIndexOrNilAfter() throws {
        XCTAssertNil([].indexOrNil(after: 10), "collection empty")
        XCTAssertNil([3,5,2].indexOrNil(after: -10), "collection out of range")
        XCTAssertNil([3,5,2].indexOrNil(after: 2), "collection at end")

        XCTAssertEqual([1, 3, 4].indexOrNil(after: 1), 2, "collection at end")
        XCTAssertEqual([1, 3, 4].indexOrNil(after: 0), 1, "collection at start")
        XCTAssertEqual([1, 3, 4].indexOrNil(after: -1), 0, "collection before start")
    }
    
    func testBefore() throws {
        XCTAssertNil([].before(10), "collection empty")
        XCTAssertNil([3,5,2].before(10), "collection out of range")
        XCTAssertNil([3,5,2].before(0), "collection at start")

        XCTAssertEqual(["a", "b", "x"].before(1), "a", "collection at start")
        XCTAssertEqual(["a", "b", "x"].before(2), "b", "collection at end")
        XCTAssertEqual(["a", "b", "x"].before(3), "x", "collection behind end")
    }
    
    func testAfter() throws {
        XCTAssertNil([].after(10), "collection empty")
        XCTAssertNil([3,5,2].after(-10), "collection out of range")
        XCTAssertNil([3,5,2].after(2), "collection at end")

        XCTAssertEqual(["a", "b", "x"].after(1), "x", "collection at end")
        XCTAssertEqual(["a", "b", "x"].after(0), "b", "collection at start")
        XCTAssertEqual(["a", "b", "x"].after(-1), "a", "collection before start")
    }
    
    func testTwoArray() throws {
        let x = MultipleArrays([1,2,3,4,5], [6,7,8,9], [0,-1,-2])
        let expected = [1,2,3,4,5,6,7,8,9, 0, -1, -2]
        
        XCTAssertEqual(x.map {$0}, expected)
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
    
    func testInsertIndexPerf() throws {
        let x: [Int] = stride(from: 600, to: 1000000*60+600, by: 60).map {$0}
        
        self.measure {
            let _ = x.insertIndex(for: 300, element2key: {$0})
            let _ = x.insertIndex(for: (1000000*60+600) / 2, element2key: {$0})
            let _ = x.insertIndex(for: 1000000*60+600 + 3600, element2key: {$0})
        }
    }
    
    private func assertIntArrays(array1: [Int], array2: [Int], message: String) {
        XCTAssertEqual(array1.count, array2.count, message)
        (0 ..< array2.endIndex).forEach { i in
            XCTAssertEqual(array1[i], array2[i], "\(message) at \(i)")
        }
    }
}
