//
//  TimerClientTests.swift
//  Run!!Tests
//
//  Created by Jürgen Boiselle on 20.05.22.
//

import XCTest
@testable import Run__

class AnyMoreTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    struct SomeStruct: Equatable {
        var variable: Int
    }
    
    func testMutatingArray() throws {
        var x = [SomeStruct(variable: 0), SomeStruct(variable: 1)]
        XCTAssertEqual(x, [SomeStruct(variable: 0), SomeStruct(variable: 1)])
        
        x[1].variable = 5
        XCTAssertEqual(x, [SomeStruct(variable: 0), SomeStruct(variable: 5)])
        
        var y = x[1]
        y.variable = 6
        XCTAssertEqual(x, [SomeStruct(variable: 0), SomeStruct(variable: 5)])
    }
    
    // MARK: Test Optionals
    func testComparableLess() throws {
        let x0: Int? = 0
        let x1: Int? = 1
        
        XCTAssertTrue(x0 < x1)
        XCTAssertTrue(x0 <= x1)
        XCTAssertFalse(x0 == x1)
        XCTAssertFalse(x0 >= x1)
        XCTAssertFalse(x0 > x1)
        XCTAssertEqual(min(x0, x1), 0)
        XCTAssertEqual(max(x0, x1), 1)
    }
    
    func testComparableEqual() throws {
        let x0: Int? = 0
        let x1: Int? = 0
        
        XCTAssertFalse(x0 < x1)
        XCTAssertTrue(x0 <= x1)
        XCTAssertTrue(x0 == x1)
        XCTAssertTrue(x0 >= x1)
        XCTAssertFalse(x0 > x1)
        XCTAssertEqual(min(x0, x1), 0)
        XCTAssertEqual(max(x0, x1), 0)
    }
    
    func testComparableHigher() throws {
        let x0: Int? = 1
        let x1: Int? = 0
        
        XCTAssertFalse(x0 < x1)
        XCTAssertFalse(x0 <= x1)
        XCTAssertFalse(x0 == x1)
        XCTAssertTrue(x0 >= x1)
        XCTAssertTrue(x0 > x1)
        XCTAssertEqual(min(x0, x1), 0)
        XCTAssertEqual(max(x0, x1), 1)
    }
    
    func testComparableLeftNil() throws {
        let x0: Int? = nil
        let x1: Int? = 1
        
        XCTAssertTrue(x0 < x1)
        XCTAssertTrue(x0 <= x1)
        XCTAssertFalse(x0 == x1)
        XCTAssertFalse(x0 >= x1)
        XCTAssertFalse(x0 > x1)
        XCTAssertEqual(min(x0, x1), nil)
        XCTAssertEqual(max(x0, x1), 1)
    }
    
    func testComparableRightNil() throws {
        let x0: Int? = 0
        let x1: Int? = nil
        
        XCTAssertFalse(x0 < x1)
        XCTAssertFalse(x0 <= x1)
        XCTAssertFalse(x0 == x1)
        XCTAssertTrue(x0 >= x1)
        XCTAssertTrue(x0 > x1)
        XCTAssertEqual(min(x0, x1), nil)
        XCTAssertEqual(max(x0, x1), 0)
    }
    
    func testComparableBothNil() throws {
        let x0: Int? = nil
        let x1: Int? = nil
        
        XCTAssertFalse(x0 < x1)
        XCTAssertTrue(x0 <= x1)
        XCTAssertTrue(x0 == x1)
        XCTAssertTrue(x0 >= x1)
        XCTAssertFalse(x0 > x1)
        XCTAssertEqual(min(x0, x1), nil)
        XCTAssertEqual(max(x0, x1), nil)
    }

    private func makeDt(_ x: Double) -> Date {
        Date(timeIntervalSinceReferenceDate: x)
    }
}
