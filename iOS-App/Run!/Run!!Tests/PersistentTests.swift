//
//  PersistentTests.swift
//  Run!!Tests
//
//  Created by Jürgen Boiselle on 10.05.22.
//

import XCTest
@testable import Run__

class PersistentTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGetSet() throws {
        @Persistent(key: "KEY") var X: String = "DEFAULT"
        XCTAssertEqual(X, "DEFAULT")

        X = "NON-DEFAULT"
        XCTAssertEqual(X, "NON-DEFAULT")
        
        @Persistent(key: "KEY") var Y: String = "DEFAULT"
        XCTAssertEqual(Y, "NON-DEFAULT")
        
        @Persistent(key: "KEY2") var Y2: String = "DEFAULT2"
        XCTAssertEqual(Y2, "DEFAULT2")

        X = $X.defaultValue
        XCTAssertEqual(X, "DEFAULT")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
