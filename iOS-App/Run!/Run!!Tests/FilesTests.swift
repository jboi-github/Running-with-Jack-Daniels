//
//  FilesTests.swift
//  Run!!Tests
//
//  Created by Jürgen Boiselle on 22.03.22.
//

import XCTest
@testable import Run__

class FilesTests: XCTestCase {

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
    
    func testNormal() throws {
        Files.initDirectory()
        let x = X(x: 123)
        Files.write(x, to: "X")
        let x2: X? = Files.read(from: "X")
        XCTAssertEqual(x, x2)
    }
    
    func testDuplicates() throws {
        Files.initDirectory()
        let x = X(x: 1)
        let y = X(x: 2)
        
        Files.write(x, to: "X")
        let x2: X? = Files.read(from: "X")
        XCTAssertEqual(x, x2)

        Files.write(y, to: "X")
        let y2: X? = Files.read(from: "X")
        XCTAssertEqual(y, y2)
    }
    
    struct FH: Codable, Equatable {
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
        let expectedVar = FH(
            date: Date(), double: 1.0, doubleNaN: .nan,
            doublePosInf: .infinity, doubleNegInf: -.infinity,
            int: 4711, string: "Hällo wörld", stringEmpty: "",
            stringNil: nil)
        
        Files.write(expectedVar, to: "testFileHandling.json")
        let x: FH? = Files.read(from: "testFileHandling.json")
        
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
        case X, Y, Z
    }
    
    struct Info: Codable, Equatable {
        let string: String
        let double: Double
        let bool: Bool
        let int: Int
        let enumerated: Enumerated
        let date: Date
    }
    
    func testSyncedGet() throws {
        let fName = UUID().uuidString
        @Synced(fileName: fName, isInBackground: false) var x: Info = Info(
            string: "DEFAULT", double: 1.0, bool: false, int: 13, enumerated: .Y, date: Date(timeIntervalSinceReferenceDate: 4711))

        // Should not be saved by now
        @Synced(fileName: fName, isInBackground: false) var y: Info = Info(
            string: "DEFAULT-Y", double: .infinity, bool: true, int: 10, enumerated: .X, date: Date(timeIntervalSinceReferenceDate: 1000))
        
        XCTAssertEqual(
            x,
            Info(string: "DEFAULT", double: 1.0, bool: false, int: 13, enumerated: .Y, date: Date(timeIntervalSinceReferenceDate: 4711)))
        XCTAssertEqual(
            y,
            Info(string: "DEFAULT-Y", double: .infinity, bool: true, int: 10, enumerated: .X, date: Date(timeIntervalSinceReferenceDate: 1000)))
    }

    func testSyncedSetForeground() throws {
        let fName = UUID().uuidString
        @Synced(fileName: fName, isInBackground: false) var x: Info = Info(
            string: "DEFAULT", double: 1.0, bool: false, int: 13, enumerated: .Y, date: Date(timeIntervalSinceReferenceDate: 4711))
        x = Info(string: "CHANGED", double: 1.0, bool: false, int: 13, enumerated: .Y, date: Date(timeIntervalSinceReferenceDate: 4712))
        
        @Synced(fileName: fName, isInBackground: false) var y: Info = Info(
            string: "DEFAULT-Y", double: .infinity, bool: true, int: 10, enumerated: .X, date: Date(timeIntervalSinceReferenceDate: 1000))
        
        XCTAssertEqual(x,
            Info(string: "CHANGED", double: 1.0, bool: false, int: 13, enumerated: .Y, date: Date(timeIntervalSinceReferenceDate: 4712)))
        XCTAssertEqual(
            y,
            Info(string: "DEFAULT-Y", double: .infinity, bool: true, int: 10, enumerated: .X, date: Date(timeIntervalSinceReferenceDate: 1000)))
    }

    func testSyncedSetForegroundMoveBack() throws {
        let fName = UUID().uuidString
        @Synced(fileName: fName, isInBackground: false) var x: Info = Info(
            string: "DEFAULT", double: 1.0, bool: false, int: 13, enumerated: .Y, date: Date(timeIntervalSinceReferenceDate: 4711))
        x = Info(string: "CHANGED", double: 1.0, bool: false, int: 13, enumerated: .Y, date: Date(timeIntervalSinceReferenceDate: 4712))
        
        $x.isInBackground = true // Should save here
        @Synced(fileName: fName, isInBackground: false) var y: Info = Info(
            string: "DEFAULT-Y", double: .infinity, bool: true, int: 10, enumerated: .X, date: Date(timeIntervalSinceReferenceDate: 1000))
        
        
        XCTAssertEqual(x, Info(string: "CHANGED", double: 1.0, bool: false, int: 13, enumerated: .Y, date: Date(timeIntervalSinceReferenceDate: 4712)))
        XCTAssertEqual(y, Info(string: "CHANGED", double: 1.0, bool: false, int: 13, enumerated: .Y, date: Date(timeIntervalSinceReferenceDate: 4712)))
    }

    func testSyncedSetWhileBackground() throws {
        let fName = UUID().uuidString
        @Synced(fileName: fName, isInBackground: false) var x: Info = Info(
            string: "DEFAULT", double: 1.0, bool: false, int: 13, enumerated: .Y, date: Date(timeIntervalSinceReferenceDate: 4711))

        $x.isInBackground = true // Should save here and again, on each further change
        x = Info(string: "CHANGED", double: 1.0, bool: false, int: 13, enumerated: .Y, date: Date(timeIntervalSinceReferenceDate: 4712))
        
        @Synced(fileName: fName, isInBackground: false) var y: Info = Info(
            string: "DEFAULT-Y", double: .infinity, bool: true, int: 10, enumerated: .X, date: Date(timeIntervalSinceReferenceDate: 1000))
        
        XCTAssertEqual(x, Info(string: "CHANGED", double: 1.0, bool: false, int: 13, enumerated: .Y, date: Date(timeIntervalSinceReferenceDate: 4712)))
        XCTAssertEqual(y, Info(string: "CHANGED", double: 1.0, bool: false, int: 13, enumerated: .Y, date: Date(timeIntervalSinceReferenceDate: 4712)))
    }
}
