//
//  StoreTests.swift
//  Run!!Tests
//
//  Created by Jürgen Boiselle on 22.03.22.
//

import XCTest
@testable import Run__

class StoreTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    struct X: Codable, Equatable {
        var x: Double
        var s: String = "xyz"
        var d: Int = Date.now.seconds
    }

    func testStore() throws {
        let x = X(x: 1)
        Store.write(x, at: .now, for: "X")

        guard let x2: X = Store.read(for: "X")?.1 else {XCTFail(); return}
        XCTAssertEqual(x, x2)
    }
    
    func testNoKey() throws {
        let x: X? = Store.read(for: "Y")?.1
        XCTAssertNil(x)
    }
}
