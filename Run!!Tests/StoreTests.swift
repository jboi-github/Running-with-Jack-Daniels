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

    struct TestObjectToStore: Codable, Equatable {
        var x: Double
        var s: String = "xyz"
        var d: Int = Int(Date.now.timeIntervalSinceReferenceDate)
    }

    func testStore() throws {
        let x = TestObjectToStore(x: 1)
        Store.write(x, at: .now, for: "X")

        guard let x2: TestObjectToStore = Store.read(for: "X")?.1 else {XCTFail(); return}
        XCTAssertEqual(x, x2)
    }
    
    func testNoKey() throws {
        let x: TestObjectToStore? = Store.read(for: "Y")?.1
        XCTAssertNil(x)
    }
}
