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

extension PedometerDataEvent: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.vector == rhs.vector
    }
}

extension DistanceEvent: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.vector == rhs.vector
    }
}

extension IntensityEvent: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.vector == rhs.vector
    }
}

class DerivedEventTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: PedometerDataEvent
    func testPedometerDataParserFirst() throws {
        let ts = TimeSeries<PedometerDataEvent>()
        ts.reset()
        let actual = ts.newElements(makeDt(1000), PedometerDataEvent(date: makeDt(2000), numberOfSteps: 100, distance: 10, activeDuration: 100))
        let expected = [PedometerDataEvent(date: makeDt(2000), numberOfSteps: 100, distance: 10, activeDuration: 100)]
        XCTAssertEqual(actual, expected)
    }
    
    func testPedometerDataParserNoGap() throws {
        let ts = TimeSeries<PedometerDataEvent>()
        ts.reset()
        ts.insert(PedometerDataEvent(date: makeDt(1000), numberOfSteps: 50, distance: 5, activeDuration: nil))
        
        let actual = ts.newElements(makeDt(1000), PedometerDataEvent(date: makeDt(2000), numberOfSteps: 100, distance: 10, activeDuration: 100))
        let expected = [
            PedometerDataEvent(date: makeDt(2000), numberOfSteps: 100, distance: 10, activeDuration: 100)
        ]
        XCTAssertEqual(actual, expected)
    }

    func testPedometerDataParserGap() throws {
        let ts = TimeSeries<PedometerDataEvent>()
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
        let ts = TimeSeries<PedometerDataEvent>()
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
        let ts = TimeSeries<DistanceEvent>()
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
        let ts = TimeSeries<DistanceEvent>()
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
        let ts = TimeSeries<DistanceEvent>()
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
        let ts = TimeSeries<DistanceEvent>()
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

    // MARK: IntensityEvent
    func testIntensityLimits() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)

        let hrLimits = try XCTUnwrap(Profile.hrLimits.value)
        XCTAssertEqual(Run.Intensity.Cold.getHrBuckets(for: hrLimits), [
            Run.Intensity.Cold: 0 ..< 130,
            .Easy: 130 ..< 160,
            .Marathon: 160 ..< 180,
            .Threshold: 180 ..< 196,
            .Interval: 196 ..< 200,
            .Repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.Easy.getHrBuckets(for: hrLimits), [
            Run.Intensity.Cold: 0 ..< 130,
            .Easy: 130 ..< 160,
            .Marathon: 160 ..< 180,
            .Threshold: 180 ..< 196,
            .Interval: 196 ..< 200,
            .Repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.Long.getHrBuckets(for: hrLimits), [
            Run.Intensity.Cold: 0 ..< 130,
            .Easy: 0 ..< 160,
            .Marathon: 0 ..< 180,
            .Threshold: 0 ..< 196,
            .Interval: 0 ..< 200,
            .Repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.Marathon.getHrBuckets(for: hrLimits), [
            Run.Intensity.Cold: 0 ..< 130,
            .Easy: 0 ..< 160,
            .Marathon: 0 ..< 180,
            .Threshold: 0 ..< 196,
            .Interval: 0 ..< 200,
            .Repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.Threshold.getHrBuckets(for: hrLimits), [
            Run.Intensity.Cold: 0 ..< 130,
            .Easy: 0 ..< 160,
            .Marathon: 0 ..< 176,
            .Threshold: 0 ..< 196,
            .Interval: 0 ..< 200,
            .Repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.Interval.getHrBuckets(for: hrLimits), [
            Run.Intensity.Cold: 0 ..< 130,
            .Easy: 0 ..< 160,
            .Marathon: 0 ..< 176,
            .Threshold: 0 ..< 184,
            .Interval: 0 ..< 200,
            .Repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.Repetition.getHrBuckets(for: hrLimits), [
            Run.Intensity.Cold: 0 ..< 130,
            .Easy: 0 ..< 160,
            .Marathon: 0 ..< 176,
            .Threshold: 0 ..< 184,
            .Interval: 0 ..< 200,
            .Repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.Race.getHrBuckets(for: hrLimits), [
            Run.Intensity.Cold: 0 ..< 130,
            .Easy: 0 ..< 160,
            .Marathon: 0 ..< 176,
            .Threshold: 0 ..< 184,
            .Interval: 0 ..< 200,
            .Repetition: 200 ..< Int.max
        ])
    }
    
    func testIntensityFirstElFirstHr() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        let actual = ts.parse(
            HeartrateEvent(date: makeDt(1000), heartrate: 150, skinIsContacted: nil, energyExpended: nil),
            nil)
        let expected = [IntensityEvent(date: makeDt(1000), intensity: .Easy)]
        XCTAssertEqual(actual, expected)
    }
    
    func testIntensityFirstElSecondHrNoCrossing() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        let actual = ts.parse(
            HeartrateEvent(date: makeDt(1000), heartrate: 150, skinIsContacted: nil, energyExpended: nil),
            HeartrateEvent(date: makeDt(500), heartrate: 140, skinIsContacted: nil, energyExpended: nil))
        let actualU = try XCTUnwrap(actual)
        XCTAssertTrue(actualU.isEmpty)
    }
    
    func testIntensityFirstElSecondHrCrossing() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        let actual = ts.parse(
            HeartrateEvent(date: makeDt(170), heartrate: 170, skinIsContacted: nil, energyExpended: nil),
            HeartrateEvent(date: makeDt(80), heartrate: 80, skinIsContacted: nil, energyExpended: nil))
        let expected = [IntensityEvent(date: makeDt(1000), intensity: .Easy)]
        XCTAssertEqual(actual, expected)
    }

    func testIntensitySecondElFirstHrNoCrossing() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        ts.insert(IntensityEvent(date: makeDt(500), intensity: .Interval))
        let actual = ts.parse(
            HeartrateEvent(date: makeDt(1000), heartrate: 190, skinIsContacted: nil, energyExpended: nil),
            nil)
        let actualU = try XCTUnwrap(actual)
        XCTAssertTrue(actualU.isEmpty)
    }

    func testIntensitySecondElFirstHrCrossing() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        ts.insert(IntensityEvent(date: makeDt(500), intensity: .Interval))
        let actual = ts.parse(
            HeartrateEvent(date: makeDt(1000), heartrate: 180, skinIsContacted: nil, energyExpended: nil),
            nil)
        let actualU = try XCTUnwrap(actual)
        XCTAssertEqual(actualU, [IntensityEvent(date: makeDt(1000), intensity: .Threshold)])
    }

    func testIntensitySecondElSecondHrNoCrossing() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        ts.insert(IntensityEvent(date: makeDt(500), intensity: .Interval))
        let actual = ts.parse(
            HeartrateEvent(date: makeDt(1000), heartrate: 190, skinIsContacted: nil, energyExpended: nil),
            HeartrateEvent(date: makeDt(500), heartrate: 185, skinIsContacted: nil, energyExpended: nil))
        let actualU = try XCTUnwrap(actual)
        XCTAssertTrue(actualU.isEmpty)
    }
    
    func testIntensitySecondElSecondHrCrossing() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
    }

    private func makeDt(_ x: Double) -> Date {
        Date(timeIntervalSinceReferenceDate: x)
    }
}
