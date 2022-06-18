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

    enum Enumerated: Codable, Equatable {
        case XX, YY, ZZ, AA(date: Date)
    }
    
    func testGetSet() throws {
        let key = UUID().uuidString
        let key2 = UUID().uuidString
        
        @Persistent(key: key) var X: String = "DEFAULT"
        XCTAssertEqual(X, "DEFAULT")

        X = "NON-DEFAULT"
        XCTAssertEqual(X, "NON-DEFAULT")
        
        @Persistent(key: key) var Y: String = "DEFAULT"
        XCTAssertEqual(Y, "NON-DEFAULT")
        
        @Persistent(key: key2) var Y2: String = "DEFAULT2"
        XCTAssertEqual(Y2, "DEFAULT2")

        X = $X.defaultValue
        XCTAssertEqual(X, "DEFAULT")
    }
    
    func testGetSetEnum() throws {
        let key = UUID().uuidString
        let key2 = UUID().uuidString
        
        @Persistent(key: key) var X: Enumerated = .XX
        XCTAssertEqual(X, .XX)

        X = .YY
        XCTAssertEqual(X, .YY)
        
        @Persistent(key: key) var Y: Enumerated = .XX
        XCTAssertEqual(Y, .YY)
        
        @Persistent(key: key2) var Y2: Enumerated = .ZZ
        XCTAssertEqual(Y2, .ZZ)

        X = $X.defaultValue
        XCTAssertEqual(X, .XX)
    }
    
    func testCodableEnum0() throws {
        let x = Enumerated.XX
        let data = try JSONEncoder().encode(x)
        log("**", String(data: data, encoding: .utf8) ?? "EMPTY")
        let y = try JSONDecoder().decode(Enumerated.self, from: data)
        XCTAssertEqual(x, y)
    }
    
    func testCodableEnum1() throws {
        let x = Enumerated.XX
        let data = try Files.encoder.encode(x)
        log("**", String(data: data, encoding: .utf8) ?? "EMPTY")
        let y = try Files.decoder.decode(Enumerated.self, from: data)
        XCTAssertEqual(x, y)
    }
}
