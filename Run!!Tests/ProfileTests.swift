//
//  ProfileTests.swift
//  Run!!Tests
//
//  Created by Jürgen Boiselle on 31.03.22.
//

import XCTest
@testable import Run__

class ProfileTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testProfileAttribute1() throws {
        // Test 1: Value not in kv-store, not in health, not to be calculated
        let x1 = Profile.Attribute<Int>(
            config: Profile.Attribute<Int>.Config(
                readFromStore: {nil},
                readFromHealth: {_ in},
                calculate: nil,
                writeToStore: {_, _ in XCTFail()},
                writeToHealth: {_, _ in XCTFail()}))
        x1.onAppear()
        x1.onDisappear()

        // Test 2: Value in kv-store, not in health, not to be calculated. Stays unchanged
        var mustGetHere2: Bool = false
        let expectedDate2: Date = Date(timeIntervalSince1970: 1000)
        let x2 = Profile.Attribute<Int>(
            config: Profile.Attribute<Int>.Config(
                readFromStore: {(expectedDate2, 4711)},
                readFromHealth: {_ in},
                calculate: nil,
                writeToStore: {_, _ in XCTFail()},
                writeToHealth: {
                    XCTAssertEqual($0, expectedDate2)
                    XCTAssertEqual($1, 4711)
                    mustGetHere2 = true
                }))
        x2.onAppear()
        x2.onDisappear()
        XCTAssertTrue(mustGetHere2)

        // Test 3: Value in kv-store, not in health, not to be calculated. Changed by user
        var mustGetHere3: Int = 0
        let expectedDate3: Date = Date()
        let x3 = Profile.Attribute<Int>(
            config: Profile.Attribute<Int>.Config(
                readFromStore: {(Date(timeIntervalSince1970: 2000), 4711)},
                readFromHealth: {_ in},
                calculate: nil,
                writeToStore: {
                    XCTAssertEqual(
                        $0.timeIntervalSince1970,
                        expectedDate3.timeIntervalSince1970,
                        accuracy: 1)
                    XCTAssertEqual($1, 4712)
                    mustGetHere3 += 1
                },
                writeToHealth: {
                    XCTAssertEqual(
                        $0.timeIntervalSince1970,
                        expectedDate3.timeIntervalSince1970,
                        accuracy: 1)
                    XCTAssertEqual($1, 4712)
                    mustGetHere3 += 1
                }))
        x3.onAppear()
        x3.onChange(to: 4712)
        x3.onDisappear()
        XCTAssertEqual(mustGetHere3, 2)

        // Test 4: Value in kv-store, not in health, not to be calculated. Changed and reset by user
        var mustGetHere4: Int = 0
        let x4 = Profile.Attribute<Int>(
            config: Profile.Attribute<Int>.Config(
                readFromStore: {(Date(timeIntervalSince1970: 2000), 4711)},
                readFromHealth: {_ in},
                calculate: nil,
                writeToStore: {_, _ in XCTFail()},
                writeToHealth: {
                    XCTAssertEqual($0, Date(timeIntervalSince1970: 2000))
                    XCTAssertEqual($1, 4711)
                    mustGetHere4 += 1
                }))
        x4.onAppear()
        x4.onChange(to: 4712)
        x4.onReset()
        x4.onDisappear()
        XCTAssertEqual(mustGetHere4, 1)
    }
    
    func testProfileAttribute2() throws {
        // Test 1: Value in kv-store, older in health, to be calculated
        var mustGetHere1: Int = 0
        let x1 = Profile.Attribute<Int>(
            config: Profile.Attribute<Int>.Config(
                readFromStore: {(Date(timeIntervalSince1970: 2000), 4711)},
                readFromHealth: {$0(Date(timeIntervalSince1970: 1000), 4712)},
                calculate: {4713},
                writeToStore: {_, _ in
                    XCTFail()
                },
                writeToHealth: {
                    XCTAssertEqual($0, Date(timeIntervalSince1970: 2000))
                    XCTAssertEqual($1, 4711)
                    mustGetHere1 += 1
                }))
        x1.onAppear()
        x1.onDisappear()
        XCTAssertEqual(mustGetHere1, 1)

        // Test 2: Value in kv-store, newer in health, to be calculated
        var mustGetHere2: Int = 0
        let x2 = Profile.Attribute<Int>(
            config: Profile.Attribute<Int>.Config(
                readFromStore: {(Date(timeIntervalSince1970: 1000), 4711)},
                readFromHealth: {$0(Date(timeIntervalSince1970: 2000), 4712)},
                calculate: {4713},
                writeToStore: {
                    XCTAssertEqual($0, Date(timeIntervalSince1970: 2000))
                    XCTAssertEqual($1, 4712)
                    mustGetHere2 += 1
                },
                writeToHealth: {_, _ in XCTFail()}))
        x2.onAppear()
        x2.onDisappear()
        XCTAssertEqual(mustGetHere2, 1)

        // Test 3: Value not in kv-store, not in health, to be calculated
        let x3 = Profile.Attribute<Int>(
            config: Profile.Attribute<Int>.Config(
                readFromStore: {nil},
                readFromHealth: {_ in},
                calculate: {4713},
                writeToStore: {_, _ in XCTFail()},
                writeToHealth: {_, _ in XCTFail()}))
        x3.onAppear()
        x3.onDisappear()
    }
    
    func testProfileAttribute3() throws {
        // Attribute 1 is calculated using value of attribute 0. Change in 0 should trigger 1
        let x0 = Profile.Attribute<Int>(
            config: Profile.Attribute<Int>.Config(
                readFromStore: {nil},
                readFromHealth: {_ in},
                calculate: {0},
                writeToStore: {_, _ in },
                writeToHealth: {_, _ in }))
        let x1 = Profile.Attribute<Int>(
            config: Profile.Attribute<Int>.Config(
                readFromStore: {nil},
                readFromHealth: {_ in},
                calculate: {(x0.value ?? -1) + 5},
                writeToStore: {_, _ in },
                writeToHealth: {_, _ in }))

        x0.onAppear()
        x1.onAppear()
        XCTAssertEqual(x0.value, 0)
        XCTAssertEqual(x1.value, 5)

        x0.linked = {x1.onAppear()}
        x0.onChange(to: 3)
        XCTAssertEqual(x0.value, 3)
        XCTAssertEqual(x1.value, 8)

        x0.onDisappear()
        x1.onDisappear()
        
        // Attribute 1b is calculated using value of attribute 0b.
        // Change in 1b preceding change in 0b should NOT trigger 1b
        let x0b = Profile.Attribute<Int>(
            config: Profile.Attribute<Int>.Config(
                readFromStore: {nil},
                readFromHealth: {_ in},
                calculate: {0},
                writeToStore: {_, _ in },
                writeToHealth: {_, _ in }))
        let x1b = Profile.Attribute<Int>(
            config: Profile.Attribute<Int>.Config(
                readFromStore: {nil},
                readFromHealth: {_ in},
                calculate: {(x0b.value ?? -1) + 5},
                writeToStore: {_, _ in },
                writeToHealth: {_, _ in }))

        x0b.onAppear()
        x1b.onAppear()
        XCTAssertEqual(x0b.value, 0)
        XCTAssertEqual(x1b.value, 5)

        x1b.onChange(to: 13)
        XCTAssertEqual(x0b.value, 0)
        XCTAssertEqual(x1b.value, 13)

        x0b.onChange(to: 3)
        XCTAssertEqual(x0b.value, 3)
        x1b.onAppear()
        XCTAssertEqual(x1b.value, 13)

        x0b.onDisappear()
        x1b.onDisappear()
    }
}
