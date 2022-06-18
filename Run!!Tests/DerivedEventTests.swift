//
//  DerivedEventTests.swift
//  Run!!Tests
//
//  Created by Jürgen Boiselle on 16.05.22.
//

import XCTest
@testable import Run__
import CoreMotion
import CoreLocation

class DerivedEventTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: PedometerDataEvent
    func testPedometerDataParserFirst() throws {
        let ts = TimeSeries<PedometerDataEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        let actual = ts.newElements(makeDt(1000), PedometerDataEvent(date: makeDt(2000), numberOfSteps: 100, distance: 10, activeDuration: 100))
        let expected = [PedometerDataEvent(date: makeDt(2000), numberOfSteps: 100, distance: 10, activeDuration: 100)]
        XCTAssertEqual(actual, expected)
    }
    
    func testPedometerDataParserNoGap() throws {
        let ts = TimeSeries<PedometerDataEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        ts.insert(PedometerDataEvent(date: makeDt(1000), numberOfSteps: 50, distance: 5, activeDuration: nil))
        
        let actual = ts.newElements(makeDt(1000), PedometerDataEvent(date: makeDt(2000), numberOfSteps: 100, distance: 10, activeDuration: 100))
        let expected = [
            PedometerDataEvent(date: makeDt(2000), numberOfSteps: 100, distance: 10, activeDuration: 100)
        ]
        XCTAssertEqual(actual, expected)
    }

    func testPedometerDataParserGap() throws {
        let ts = TimeSeries<PedometerDataEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        ts.insert(PedometerDataEvent(date: makeDt(1000), numberOfSteps: 50, distance: 5, activeDuration: nil))
        
        let actual = ts.newElements(makeDt(1500), PedometerDataEvent(date: makeDt(2000), numberOfSteps: 100, distance: 10, activeDuration: 100))
        let expected = [
            PedometerDataEvent(date: makeDt(1500), numberOfSteps: 50, distance: 5, activeDuration: nil),
            PedometerDataEvent(date: makeDt(2000), numberOfSteps: 100, distance: 10, activeDuration: 100)
        ]
        XCTAssertEqual(actual, expected)
    }

    func testPedometerDataParserNegativGap() throws {
        let ts = TimeSeries<PedometerDataEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        ts.insert(PedometerDataEvent(date: makeDt(1000), numberOfSteps: 50, distance: 5, activeDuration: nil))
        
        let actual = ts.newElements(makeDt(500), PedometerDataEvent(date: makeDt(2000), numberOfSteps: 100, distance: 10, activeDuration: 100))
        let expected = [
            PedometerDataEvent(date: makeDt(500), numberOfSteps: 50, distance: 5, activeDuration: nil),
            PedometerDataEvent(date: makeDt(2000), numberOfSteps: 100, distance: 10, activeDuration: 100)
        ]
        XCTAssertEqual(actual, expected)
    }
    
    // MARK: DistanceEvent
    func testDistanceFirstElFirstLoc() throws {
        let ts = TimeSeries<DistanceEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        let actual = ts.parse(
            CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: 10,
                    longitude: 10),
                altitude: 10,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: makeDt(1000)), nil)
        XCTAssertTrue(actual.isEmpty)
    }
    
    func testDistanceFirstElSecondLoc() throws {
        let ts = TimeSeries<DistanceEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        let actual = ts.parse(
            CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: 10,
                    longitude: 10),
                altitude: 10,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: makeDt(1000)),
            CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: 8,
                    longitude: 8),
                altitude: 10,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: makeDt(500)))
        let expected = [DistanceEvent(date: makeDt(1000), distance: 311919.4557442204)] // Google Maps
        XCTAssertEqual(actual, expected)
    }
    
    func testDistanceSecondElFirstLoc() throws {
        let ts = TimeSeries<DistanceEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        ts.insert(DistanceEvent(date: makeDt(1000), distance: 100))
        let actual = ts.parse(
            CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: 10,
                    longitude: 10),
                altitude: 10,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: makeDt(1000)), nil)
        XCTAssertTrue(actual.isEmpty)
    }
    
    func testDistanceSecondElSecondLocNoGap() throws {
        let ts = TimeSeries<DistanceEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        XCTAssertTrue(ts.elements.isEmpty)
        ts.insert(DistanceEvent(date: makeDt(500), distance: 100))
        XCTAssertEqual(ts.elements.last?.vector.date, makeDt(500))
        
        let actual = ts.parse(
            CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: 10,
                    longitude: 10),
                altitude: 10,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: makeDt(1000)),
            CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: 8,
                    longitude: 8),
                altitude: 10,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: makeDt(500)))
        XCTAssertEqual(ts.elements.last?.vector.date, makeDt(500))

        let expected = [DistanceEvent(date: makeDt(1000), distance: 311919.4557442204 + 100)]
        XCTAssertEqual(actual, expected)
    }

    private func makeDt(_ x: Double) -> Date {
        Date(timeIntervalSinceReferenceDate: x)
    }
}
