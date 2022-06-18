//
//  TimeSeriesElementTests.swift
//  Run!!Tests
//
//  Created by Jürgen Boiselle on 13.05.22.
//

import XCTest
@testable import Run__

class TimeSeriesElementTests: XCTestCase {

    private struct TestTimeSeries: GenericTimeseriesElement, Equatable {
        static var key: String = ""

        let vector: VectorElement<Bool>
        init(_ vector: VectorElement<Bool>) {self.vector = vector}

        init(date: Date, int: Int, double: Double, optInt: Int?, optDouble: Double?, categorical: Bool, withClamping: Bool = true) {
            vector = VectorElement(
                date: date,
                doubles: [double],
                ints: [int],
                optionalDoubles: [optDouble],
                optionalInts: [optInt],
                categorical: categorical,
                withClamping: withClamping)
        }
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        TestTimeSeries.key = UUID().uuidString
        log(TestTimeSeries.key)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExtrapolateNil() throws {
        let x = TestTimeSeries(date: makeDt(1000), int: 1, double: 2, optInt: nil, optDouble: nil, categorical: true)
        let expected = TestTimeSeries(date: makeDt(2000), int: 1, double: 2, optInt: nil, optDouble: nil, categorical: true)
        XCTAssertEqual(x.extrapolate(at: makeDt(2000)), expected)
    }

    func testExtrapolateNonNil() throws {
        let x = TestTimeSeries(date: makeDt(1000), int: 1, double: 2, optInt: 3, optDouble: 4, categorical: true)
        let expected = TestTimeSeries(date: makeDt(2000), int: 1, double: 2, optInt: 3, optDouble: 4, categorical: true)
        XCTAssertEqual(x.extrapolate(at: makeDt(2000)), expected)
    }

    func testGradientNonNil() throws {
        let x = TestTimeSeries(date: makeDt(500), int: 1, double: 2, optInt: 3, optDouble: 4, categorical: true)
        let y = TestTimeSeries(date: makeDt(1500), int: 2, double: 4, optInt: 6, optDouble: 8, categorical: true)
        let expected = VectorElementDelta(
            duration: 1.0,
            doubles: [2.0 / 1000.0],
            ints: [1.0 / 1000.0],
            optionalDoubles: [4.0 / 1000.0],
            optionalInts: [3.0 / 1000.0])
        XCTAssertEqual(x.gradient(to: y), expected)
    }

    func testGradientFirstNil() throws {
        let x = TestTimeSeries(date: makeDt(500), int: 1, double: 2, optInt: nil, optDouble: nil, categorical: true)
        let y = TestTimeSeries(date: makeDt(1500), int: 2, double: 4, optInt: 6, optDouble: 8, categorical: true)
        let expected = VectorElementDelta(
            duration: 1.0,
            doubles: [2.0 / 1000.0],
            ints: [1.0 / 1000.0],
            optionalDoubles: [nil],
            optionalInts: [nil])
        XCTAssertEqual(x.gradient(to: y), expected)
    }

    func testGradientLastNil() throws {
        let x = TestTimeSeries(date: makeDt(500), int: 1, double: 2, optInt: 3, optDouble: 4, categorical: true)
        let y = TestTimeSeries(date: makeDt(1500), int: 2, double: 4, optInt: nil, optDouble: nil, categorical: true)
        let expected = VectorElementDelta(
            duration: 1.0,
            doubles: [2.0 / 1000.0],
            ints: [1.0 / 1000.0],
            optionalDoubles: [nil],
            optionalInts: [nil])
        XCTAssertEqual(x.gradient(to: y), expected)
    }

    func testGradientBothNil() throws {
        let x = TestTimeSeries(date: makeDt(500), int: 1, double: 2, optInt: nil, optDouble: nil, categorical: true)
        let y = TestTimeSeries(date: makeDt(1500), int: 2, double: 4, optInt: nil, optDouble: nil, categorical: true)
        let expected = VectorElementDelta(
            duration: 1.0,
            doubles: [2.0 / 1000.0],
            ints: [1.0 / 1000.0],
            optionalDoubles: [nil],
            optionalInts: [nil])
        XCTAssertEqual(x.gradient(to: y), expected)
    }

    func testGradientSameDate() throws {
        let x = TestTimeSeries(date: makeDt(500), int: 1, double: 2, optInt: 3, optDouble: 4, categorical: true)
        let y = TestTimeSeries(date: makeDt(500), int: 2, double: 4, optInt: 6, optDouble: 8, categorical: true)
        
        XCTAssertEqual(x.gradient(to: y).doubles, [.infinity])
        XCTAssertEqual(x.gradient(to: y).ints, [.infinity])
        XCTAssertEqual(x.gradient(to: y).optionalDoubles, [.infinity])
        XCTAssertEqual(x.gradient(to: y).optionalInts, [.infinity])
    }

    func testInterpolateMidNonNil() throws {
        let x = TestTimeSeries(date: makeDt(500), int: 1, double: 2, optInt: 3, optDouble: 4, categorical: true)
        let y = TestTimeSeries(date: makeDt(1500), int: 2, double: 4, optInt: 5, optDouble: 8, categorical: false)

        let expected = TestTimeSeries(
            date: makeDt(1000),
            int: 2,
            double: 3,
            optInt: 4,
            optDouble: 6,
            categorical: true)
        
        XCTAssertEqual(x.interpolate(at: makeDt(1000), y), expected)
    }

    func testInterpolateMidFirstNil() throws {
        let x = TestTimeSeries(date: makeDt(500), int: 1, double: 2, optInt: nil, optDouble: nil, categorical: false)
        let y = TestTimeSeries(date: makeDt(1500), int: 2, double: 4, optInt: 5, optDouble: 8, categorical: true)

        let expected = TestTimeSeries(date: makeDt(1000), int: 2, double: 3, optInt: nil, optDouble: nil, categorical: false)
        
        XCTAssertEqual(x.interpolate(at: makeDt(1000), y), expected)
    }

    func testInterpolateMidLastNil() throws {
        let x = TestTimeSeries(date: makeDt(500), int: 1, double: 2, optInt: 3, optDouble: 4, categorical: true)
        let y = TestTimeSeries(date: makeDt(1500), int: 2, double: 4, optInt: nil, optDouble: nil, categorical: false)

        let expected = TestTimeSeries(date: makeDt(1000), int: 2, double: 3, optInt: nil, optDouble: nil, categorical: true)

        XCTAssertEqual(x.interpolate(at: makeDt(1000), y), expected)
    }

    func testInterpolateMidBothNil() throws {
        let x = TestTimeSeries(date: makeDt(500), int: 1, double: 2, optInt: nil, optDouble: nil, categorical: true)
        let y = TestTimeSeries(date: makeDt(1500), int: 2, double: 4, optInt: nil, optDouble: nil, categorical: true)

        let expected = TestTimeSeries(date: makeDt(1000), int: 2, double: 3, optInt: nil, optDouble: nil, categorical: true)

        XCTAssertEqual(x.interpolate(at: makeDt(1000), y), expected)
    }

    func testInterpolateOnFirst() throws {
        let x = TestTimeSeries(date: makeDt(500), int: 1, double: 2, optInt: 3, optDouble: 4, categorical: true)
        let y = TestTimeSeries(date: makeDt(1500), int: 2, double: 4, optInt: 5, optDouble: 8, categorical: false)

        let expected = TestTimeSeries(date: makeDt(500), int: 1, double: 2, optInt: 3, optDouble: 4, categorical: true)
        
        XCTAssertEqual(x.interpolate(at: makeDt(500), y), expected)
    }
    
    func testInterpolateOnLast() throws {
        let x = TestTimeSeries(date: makeDt(500), int: 1, double: 2, optInt: 3, optDouble: 4, categorical: false)
        let y = TestTimeSeries(date: makeDt(1500), int: 2, double: 4, optInt: 5, optDouble: 8, categorical: true)

        let expected = TestTimeSeries(date: makeDt(1500), int: 2, double: 4, optInt: 5, optDouble: 8, categorical: true)
        
        XCTAssertEqual(x.interpolate(at: makeDt(1500), y), expected)
    }
    
    func testInterpolateBeforeFirstClamped() throws {
        let x = TestTimeSeries(date: makeDt(1000), int: 1, double: 2, optInt: 3, optDouble: 4, categorical: true)
        let y = TestTimeSeries(date: makeDt(2000), int: 2, double: 4, optInt: 6, optDouble: 8, categorical: false)

        let expected = TestTimeSeries(date: makeDt(500), int: 1, double: 2, optInt: 3, optDouble: 4, categorical: true)
        
        XCTAssertEqual(x.interpolate(at: makeDt(500), y), expected)
    }
    
    func testInterpolateAfterLastClamped() throws {
        let x = TestTimeSeries(date: makeDt(1000), int: 1, double: 2, optInt: 3, optDouble: 4, categorical: true)
        let y = TestTimeSeries(date: makeDt(2000), int: 2, double: 4, optInt: 6, optDouble: 8, categorical: false)

        let expected = TestTimeSeries(date: makeDt(4000), int: 2, double: 4, optInt: 6, optDouble: 8, categorical: false)
        
        XCTAssertEqual(x.interpolate(at: makeDt(4000), y), expected)
    }
    
    func testInterpolateBeforeFirstNotClamped() throws {
        let x = TestTimeSeries(date: makeDt(1000), int: 1, double: 2, optInt: 3, optDouble: 4, categorical: true, withClamping: false)
        let y = TestTimeSeries(date: makeDt(2000), int: 2, double: 4, optInt: 6, optDouble: 8, categorical: false, withClamping: false)

        let expected = TestTimeSeries(date: makeDt(500), int: 1, double: 1, optInt: 2, optDouble: 2, categorical: true, withClamping: false)
        
        XCTAssertEqual(x.interpolate(at: makeDt(500), y), expected)
    }
    
    func testInterpolateAfterLastNotClamped() throws {
        let x = TestTimeSeries(date: makeDt(1000), int: 1, double: 2, optInt: 3, optDouble: 4, categorical: true, withClamping: false)
        let y = TestTimeSeries(date: makeDt(2000), int: 2, double: 4, optInt: 6, optDouble: 8, categorical: false, withClamping: false)

        let expected = TestTimeSeries(date: makeDt(4000), int: 4, double: 8, optInt: 12, optDouble: 16, categorical: false, withClamping: false)
        
        XCTAssertEqual(x.interpolate(at: makeDt(4000), y), expected)
    }

    private func makeDt(_ x: Double) -> Date {
        Date(timeIntervalSinceReferenceDate: x)
    }
}
