//
//  Running_with_Jack_DanielsTests.swift
//  Running-with-Jack-DanielsTests
//
//  Created by Jürgen Boiselle on 16.06.21.
//

import XCTest
@testable import Running_with_Jack_Daniels

class Running_with_Jack_DanielsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

    
    private func formatPaces(paces: (lower: Double, upper: Double)) -> String {
        func f1(pace: Double) -> String {
            let p = 1000.0 / (60.0 * pace)
            let pMin = floor(p)
            let pSec = (p - pMin) * 60.0
            return "\(String(format: "%2.0f", pMin)):\(String(format: "%02.0f", pSec))"
        }
        
        return "\(f1(pace: paces.lower)) - \(f1(pace: paces.upper))"
    }
}
