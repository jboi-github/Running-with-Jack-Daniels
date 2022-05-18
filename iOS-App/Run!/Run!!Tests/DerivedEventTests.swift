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
            .Easy: 130 ..< 160,
            .Marathon: 160 ..< 180,
            .Threshold: 180 ..< 196,
            .Interval: 196 ..< 200,
            .Repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.Marathon.getHrBuckets(for: hrLimits), [
            Run.Intensity.Cold: 0 ..< 130,
            .Easy: 130 ..< 160,
            .Marathon: 160 ..< 180,
            .Threshold: 180 ..< 196,
            .Interval: 196 ..< 200,
            .Repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.Threshold.getHrBuckets(for: hrLimits), [
            Run.Intensity.Cold: 0 ..< 130,
            .Easy: 130 ..< 160,
            .Marathon: 160 ..< 176,
            .Threshold: 176 ..< 196,
            .Interval: 196 ..< 200,
            .Repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.Interval.getHrBuckets(for: hrLimits), [
            Run.Intensity.Cold: 0 ..< 130,
            .Easy: 130 ..< 160,
            .Marathon: 160 ..< 176,
            .Threshold: 176 ..< 184,
            .Interval: 184 ..< 200,
            .Repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.Repetition.getHrBuckets(for: hrLimits), [
            Run.Intensity.Cold: 0 ..< 130,
            .Easy: 130 ..< 160,
            .Marathon: 160 ..< 176,
            .Threshold: 176 ..< 184,
            .Interval: 184 ..< 200,
            .Repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.Race.getHrBuckets(for: hrLimits), [
            Run.Intensity.Cold: 0 ..< 130,
            .Easy: 130 ..< 160,
            .Marathon: 160 ..< 176,
            .Threshold: 176 ..< 184,
            .Interval: 184 ..< 200,
            .Repetition: 200 ..< Int.max
        ])
    }
    
    func testIntensityFirstElFirstHr() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(1000), heartrate: 180, skinIsContacted: nil, energyExpended: nil),
                nil))
        XCTAssertEqual(actual, [IntensityEvent(date: makeDt(1000), intensity: .Threshold)])
    }
    
    // Not a real case
    func testIntensityFirstElSecondHrNoCrossingAsc() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(2000), heartrate: 190, skinIsContacted: nil, energyExpended: nil),
                HeartrateEvent(date: makeDt(1000), heartrate: 180, skinIsContacted: nil, energyExpended: nil)))
        XCTAssertEqual(actual, [IntensityEvent(date: makeDt(1000), intensity: .Threshold)])
    }
    
    // Not a real case
    func testIntensityFirstElSecondHrNoCrossingDesc() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(2000), heartrate: 180, skinIsContacted: nil, energyExpended: nil),
                HeartrateEvent(date: makeDt(1000), heartrate: 190, skinIsContacted: nil, energyExpended: nil)))
        XCTAssertEqual(actual, [IntensityEvent(date: makeDt(1000), intensity: .Threshold)])
    }

    // Not a real case
    func testIntensityFirstElSecondHrCrossingAsc() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(190), heartrate: 190, skinIsContacted: nil, energyExpended: nil),
                HeartrateEvent(date: makeDt(150), heartrate: 150, skinIsContacted: nil, energyExpended: nil)))
        XCTAssertEqual(actual, [
            IntensityEvent(date: makeDt(150), intensity: .Easy),
            IntensityEvent(date: makeDt(160), intensity: .Marathon),
            IntensityEvent(date: makeDt(180), intensity: .Threshold)
        ])
    }

    // Not a real case
    func testIntensityFirstElSecondHrCrossingDesc() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(190), heartrate: 150, skinIsContacted: nil, energyExpended: nil),
                HeartrateEvent(date: makeDt(150), heartrate: 190, skinIsContacted: nil, energyExpended: nil)))
        XCTAssertEqual(actual, [
            IntensityEvent(date: makeDt(150), intensity: .Threshold),
            IntensityEvent(date: makeDt(160), intensity: .Marathon),
            IntensityEvent(date: makeDt(180), intensity: .Easy)
        ])
    }

    // Not a real case
    func testIntensitySecondElFirstHrNoCrossing() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        ts.insert(IntensityEvent(date: makeDt(1000), intensity: .Threshold))
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(2000), heartrate: 180, skinIsContacted: nil, energyExpended: nil),
                nil))
        XCTAssertEqual(actual, [IntensityEvent(date: makeDt(2000), intensity: .Threshold)])
    }

    // Not a real case
    func testIntensitySecondElFirstHrCrossing() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        ts.insert(IntensityEvent(date: makeDt(0), intensity: .Threshold))
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(170), heartrate: 170, skinIsContacted: nil, energyExpended: nil),
                nil))
        XCTAssertEqual(actual, [IntensityEvent(date: makeDt(170), intensity: .Marathon)])
    }

    func testIntensitySecondElSecondHrNoCrossingAsc() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        ts.insert(IntensityEvent(date: makeDt(190), intensity: .Threshold))
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(195), heartrate: 195, skinIsContacted: nil, energyExpended: nil),
                HeartrateEvent(date: makeDt(190), heartrate: 190, skinIsContacted: nil, energyExpended: nil)))
        XCTAssertEqual(actual, [])
    }

    func testIntensitySecondElSecondHrNoCrossingDesc() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        ts.insert(IntensityEvent(date: makeDt(190), intensity: .Threshold))
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(195), heartrate: 176, skinIsContacted: nil, energyExpended: nil),
                HeartrateEvent(date: makeDt(190), heartrate: 190, skinIsContacted: nil, energyExpended: nil)))
        XCTAssertEqual(actual, [])
    }

    func testIntensitySecondElSecondHrCrossingAsc() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        ts.insert(IntensityEvent(date: makeDt(190), intensity: .Threshold))
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(205), heartrate: 205, skinIsContacted: nil, energyExpended: nil),
                HeartrateEvent(date: makeDt(190), heartrate: 190, skinIsContacted: nil, energyExpended: nil)))
        XCTAssertEqual(actual, [
            IntensityEvent(date: makeDt(196), intensity: .Interval),
            IntensityEvent(date: makeDt(200), intensity: .Repetition)
        ])
    }
    
    func testIntensitySecondElSecondHrCrossingDesc() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent>()
        ts.reset()
        ts.insert(IntensityEvent(date: makeDt(0), intensity: .Threshold))
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(30), heartrate: 160, skinIsContacted: nil, energyExpended: nil),
                HeartrateEvent(date: makeDt(0), heartrate: 190, skinIsContacted: nil, energyExpended: nil)))
        XCTAssertEqual(actual, [
            IntensityEvent(date: makeDt(14), intensity: .Marathon)
        ])
    }

    private func makeDt(_ x: Double) -> Date {
        Date(timeIntervalSinceReferenceDate: x)
    }
}
