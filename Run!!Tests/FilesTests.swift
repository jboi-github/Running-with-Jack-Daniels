//
//  FilesTests.swift
//  Run!!Tests
//
//  Created by Jürgen Boiselle on 22.03.22.
//

import XCTest
@testable import Run__

class FilesTests: XCTestCase {

    let queue = DispatchQueue(label: "run-testing", qos: .userInitiated)

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    struct TestObjectForFile: Codable, Equatable {
        var x: Double
        var s: String = "xyz"
        var d: Int = Int(Date.now.timeIntervalSinceReferenceDate)
    }
    
    func testNormal() throws {
        Files.initDirectory()
        let x = TestObjectForFile(x: 123)
        Files.write(x, to: "X")
        let x2: TestObjectForFile? = Files.read(from: "X")
        XCTAssertEqual(x, x2)
    }
    
    func testDuplicates() throws {
        Files.initDirectory()
        let x = TestObjectForFile(x: 1)
        let y = TestObjectForFile(x: 2)
        
        Files.write(x, to: "X")
        let x2: TestObjectForFile? = Files.read(from: "X")
        XCTAssertEqual(x, x2)

        Files.write(y, to: "X")
        let y2: TestObjectForFile? = Files.read(from: "X")
        XCTAssertEqual(y, y2)
    }
    
    struct TestObjectFileHandling: Codable, Equatable {
        let date: Date
        let double: Double
        let doubleNaN: Double
        let doublePosInf: Double
        let doubleNegInf: Double
        let int: Int
        let string: String
        let stringEmpty: String
        let stringNil: String?
    }
    
    func testFileHandling() throws {
        let expectedVar = TestObjectFileHandling(
            date: Date(), double: 1.0, doubleNaN: .nan,
            doublePosInf: .infinity, doubleNegInf: -.infinity,
            int: 4711, string: "Hällo wörld", stringEmpty: "",
            stringNil: nil)
        
        Files.write(expectedVar, to: "testFileHandling.json")
        let x: TestObjectFileHandling? = Files.read(from: "testFileHandling.json")
        
        XCTAssertNotNil(x)
        
        guard let x = x else {return}
        XCTAssertEqual(x.date.timeIntervalSince1970, expectedVar.date.timeIntervalSince1970, accuracy: 0.1)
        XCTAssertEqual(x.double, expectedVar.double, accuracy: 0.001)
        XCTAssertTrue(x.doubleNaN.isNaN)
        XCTAssertTrue(x.doublePosInf.isInfinite)
        XCTAssertTrue(x.doubleNegInf.isInfinite)
        XCTAssertEqual(x.int, expectedVar.int)
        XCTAssertEqual(x.string, expectedVar.string)
        XCTAssertEqual(x.stringEmpty, expectedVar.stringEmpty)
        XCTAssertEqual(x.stringEmpty, expectedVar.stringEmpty)
        XCTAssertEqual(x.stringNil, expectedVar.stringNil)
    }
    
    // MARK: Test property wrapper `Synced`

    enum Enumerated: Int, Codable, Equatable {
        case x, y, z
    }
    
    struct Info: Codable, Equatable {
        let string: String
        let double: Double
        let bool: Bool
        let int: Int
        let enumerated: Enumerated
        let date: Date
    }
}
