//
//  ServicesTests.swift
//  Run!Tests
//
//  Created by Jürgen Boiselle on 16.11.21.
//

import XCTest
@testable import Run_

class ServicesTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // Tests also `Store`
    func testPeripheralHandling() throws {
        let expectedUuid = UUID()
        
        PeripheralHandling.primaryUuid = nil
        XCTAssertNil(PeripheralHandling.primaryUuid)
        PeripheralHandling.primaryUuid = expectedUuid
        XCTAssertEqual(PeripheralHandling.primaryUuid, expectedUuid)
        
        PeripheralHandling.ignoredUuids.removeAll()
        XCTAssertEqual(PeripheralHandling.ignoredUuids, [UUID]())
        PeripheralHandling.ignoredUuids.append(expectedUuid)
        PeripheralHandling.ignoredUuids.append(expectedUuid)
        XCTAssertEqual(PeripheralHandling.ignoredUuids, [expectedUuid, expectedUuid])
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
        
        FileHandling.write(expectedVar, to: "testFileHandling.json")
        let x = FileHandling.read(FH.self, from: "testFileHandling")
        
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

    func testFileHandlingLatest() throws {
        let expectedVars = [
            FH(
                date: Date(), double: 0.0, doubleNaN: .nan,
                doublePosInf: .infinity, doubleNegInf: -.infinity,
                int: 4710, string: "Hällo wörld - 000", stringEmpty: "",
                stringNil: nil),
            FH(
                date: Date(), double: 1.0, doubleNaN: .nan,
                doublePosInf: .infinity, doubleNegInf: -.infinity,
                int: 4711, string: "Hällo wörld - 001", stringEmpty: "",
                stringNil: nil),
            FH(
                date: Date(), double: 2.0, doubleNaN: .nan,
                doublePosInf: .infinity, doubleNegInf: -.infinity,
                int: 4712, string: "Hällo wörld - 002", stringEmpty: "",
                stringNil: nil)
            ]
        
        FileHandling.write(expectedVars[0], to: "XX - 000.json")
        FileHandling.write(expectedVars[1], to: "XX - 001.json")
        FileHandling.write(expectedVars[2], to: "XX - 002.json")
        let x = FileHandling.read(FH.self, from: "XX")
        
        XCTAssertNotNil(x)
        XCTAssertEqual(x!.date.timeIntervalSince1970, expectedVars[2].date.timeIntervalSince1970, accuracy: 0.1)
        XCTAssertEqual(x!.double, expectedVars[2].double, accuracy: 0.001)
        XCTAssertTrue(x!.doubleNaN.isNaN)
        XCTAssertTrue(x!.doublePosInf.isInfinite)
        XCTAssertTrue(x!.doubleNegInf.isInfinite)
        XCTAssertEqual(x!.int, expectedVars[2].int)
        XCTAssertEqual(x!.string, expectedVars[2].string)
        XCTAssertEqual(x!.stringEmpty, expectedVars[2].stringEmpty)
        XCTAssertEqual(x!.stringEmpty, expectedVars[2].stringEmpty)
        XCTAssertEqual(x!.stringNil, expectedVars[2].stringNil)
    }
    
    func testProfileAttribute1() throws {
        // Test 1: Value not in kv-store, not in health, not to be calculated
        let x1 = ProfileService.Attribute<Int>(
            config: ProfileService.Attribute<Int>.Config(
                readFromStore: {nil},
                readFromHealth: {_ in},
                calculate: nil,
                writeToStore: {_,_ in XCTFail()},
                writeToHealth: {_,_ in XCTFail()}))
        x1.onAppear()
        x1.onDisappear()

        // Test 2: Value in kv-store, not in health, not to be calculated. Stays unchanged
        var mustGetHere2: Bool = false
        let expectedDate2: Date = Date(timeIntervalSince1970: 1000)
        let x2 = ProfileService.Attribute<Int>(
            config: ProfileService.Attribute<Int>.Config(
                readFromStore: {(expectedDate2, 4711)},
                readFromHealth: {_ in},
                calculate: nil,
                writeToStore: {_,_ in XCTFail()},
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
        let x3 = ProfileService.Attribute<Int>(
            config: ProfileService.Attribute<Int>.Config(
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
        let x4 = ProfileService.Attribute<Int>(
            config: ProfileService.Attribute<Int>.Config(
                readFromStore: {(Date(timeIntervalSince1970: 2000), 4711)},
                readFromHealth: {_ in},
                calculate: nil,
                writeToStore: {_,_ in XCTFail()},
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
        let x1 = ProfileService.Attribute<Int>(
            config: ProfileService.Attribute<Int>.Config(
                readFromStore: {(Date(timeIntervalSince1970: 2000), 4711)},
                readFromHealth: {$0(Date(timeIntervalSince1970: 1000), 4712)},
                calculate: {4713},
                writeToStore: {_,_ in
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
        let x2 = ProfileService.Attribute<Int>(
            config: ProfileService.Attribute<Int>.Config(
                readFromStore: {(Date(timeIntervalSince1970: 1000), 4711)},
                readFromHealth: {$0(Date(timeIntervalSince1970: 2000), 4712)},
                calculate: {4713},
                writeToStore: {
                    XCTAssertEqual($0, Date(timeIntervalSince1970: 2000))
                    XCTAssertEqual($1, 4712)
                    mustGetHere2 += 1
                },
                writeToHealth: {_,_ in XCTFail()}))
        x2.onAppear()
        x2.onDisappear()
        XCTAssertEqual(mustGetHere2, 1)

        // Test 3: Value not in kv-store, not in health, to be calculated
        let x3 = ProfileService.Attribute<Int>(
            config: ProfileService.Attribute<Int>.Config(
                readFromStore: {nil},
                readFromHealth: {_ in},
                calculate: {4713},
                writeToStore: {_,_ in XCTFail()},
                writeToHealth: {_,_ in XCTFail()}))
        x3.onAppear()
        x3.onDisappear()
    }
}
