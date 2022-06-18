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
        case xx, yy, zz, aa(date: Date)
    }
    
    func testGetSet() throws {
        let key = UUID().uuidString
        let key2 = UUID().uuidString
        
        @Persistent(key: key) var x: String = "DEFAULT"
        XCTAssertEqual(x, "DEFAULT")

        x = "NON-DEFAULT"
        XCTAssertEqual(x, "NON-DEFAULT")
        
        @Persistent(key: key) var y: String = "DEFAULT"
        XCTAssertEqual(y, "NON-DEFAULT")
        
        @Persistent(key: key2) var y2: String = "DEFAULT2"
        XCTAssertEqual(y2, "DEFAULT2")

        x = $x.defaultValue
        XCTAssertEqual(x, "DEFAULT")
    }
    
    func testGetSetEnum() throws {
        let key = UUID().uuidString
        let key2 = UUID().uuidString
        
        @Persistent(key: key) var x: Enumerated = .xx
        XCTAssertEqual(x, .xx)

        x = .yy
        XCTAssertEqual(x, .yy)
        
        @Persistent(key: key) var y: Enumerated = .xx
        XCTAssertEqual(y, .yy)
        
        @Persistent(key: key2) var y2: Enumerated = .zz
        XCTAssertEqual(y2, .zz)

        x = $x.defaultValue
        XCTAssertEqual(x, .xx)
    }
    
    func testCodableEnum0() throws {
        let x = Enumerated.xx
        let data = try JSONEncoder().encode(x)
        log("**", String(data: data, encoding: .utf8) ?? "EMPTY")
        let y = try JSONDecoder().decode(Enumerated.self, from: data)
        XCTAssertEqual(x, y)
    }
    
    func testCodableEnum1() throws {
        let x = Enumerated.xx
        let data = try Files.encoder.encode(x)
        log("**", String(data: data, encoding: .utf8) ?? "EMPTY")
        let y = try Files.decoder.decode(Enumerated.self, from: data)
        XCTAssertEqual(x, y)
    }
}
