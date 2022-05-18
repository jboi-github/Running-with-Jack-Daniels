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

    enum Enumerated: Codable {
        case X, Y, Z(time: Date)
    }
    
    struct Info: Codable {
        let string: String
        let double: Double
        let bool: Bool
        let int: Int
        let enumerated: Enumerated
        let date: Date
    }
    
    func testGetPerformance() throws {
        @Persistent(key: "KEY_GET_PERFORMANCE") var X = [Info]()
        let N = 100
        (0 ..< N).forEach {
            X.append(
                Info(
                    string: "Test text: \($0)",
                    double: Double($0) / 3.0,
                    bool: $0 % 2 == 0,
                    int: $0,
                    enumerated: .X, date: Date(timeIntervalSinceReferenceDate: TimeInterval($0))))
        }

        self.measure {
            (0 ..< N).shuffled().forEach {let _ = X[$0]}
        }
    }

    func testSetPerformance() throws {
        self.measure {
            
            // Put the code you want to measure the time of here.
        }
    }
    
    func testSetx1Getx5Performance() throws {
        // Test with 5 get per 1 set
        self.measure {
            
            // Put the code you want to measure the time of here.
        }
    }

}
