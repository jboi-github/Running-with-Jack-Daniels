//
//  IntensityEventTests.swift
//  Run!!Tests
//
//  Created by Jürgen Boiselle on 16.06.22.
//

import XCTest
@testable import Run__

class IntensityEventTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: IntensityEvent
    func testIntensityLimits() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)

        let hrLimits = try XCTUnwrap(Profile.hrLimits.value)
        XCTAssertEqual(Run.Intensity.cold.getHrBuckets(for: hrLimits), [
            Run.Intensity.cold: 0 ..< 130,
            .easy: 130 ..< 160,
            .marathon: 160 ..< 180,
            .threshold: 180 ..< 196,
            .interval: 196 ..< 200,
            .repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.easy.getHrBuckets(for: hrLimits), [
            Run.Intensity.cold: 0 ..< 130,
            .easy: 130 ..< 160,
            .marathon: 160 ..< 180,
            .threshold: 180 ..< 196,
            .interval: 196 ..< 200,
            .repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.long.getHrBuckets(for: hrLimits), [
            Run.Intensity.cold: 0 ..< 130,
            .easy: 130 ..< 160,
            .marathon: 160 ..< 180,
            .threshold: 180 ..< 196,
            .interval: 196 ..< 200,
            .repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.marathon.getHrBuckets(for: hrLimits), [
            Run.Intensity.cold: 0 ..< 130,
            .easy: 130 ..< 160,
            .marathon: 160 ..< 180,
            .threshold: 180 ..< 196,
            .interval: 196 ..< 200,
            .repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.threshold.getHrBuckets(for: hrLimits), [
            Run.Intensity.cold: 0 ..< 130,
            .easy: 130 ..< 160,
            .marathon: 160 ..< 176,
            .threshold: 176 ..< 196,
            .interval: 196 ..< 200,
            .repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.interval.getHrBuckets(for: hrLimits), [
            Run.Intensity.cold: 0 ..< 130,
            .easy: 130 ..< 160,
            .marathon: 160 ..< 176,
            .threshold: 176 ..< 184,
            .interval: 184 ..< 200,
            .repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.repetition.getHrBuckets(for: hrLimits), [
            Run.Intensity.cold: 0 ..< 130,
            .easy: 130 ..< 160,
            .marathon: 160 ..< 176,
            .threshold: 176 ..< 184,
            .interval: 184 ..< 200,
            .repetition: 200 ..< Int.max
        ])
        XCTAssertEqual(Run.Intensity.race.getHrBuckets(for: hrLimits), [
            Run.Intensity.cold: 0 ..< 130,
            .easy: 130 ..< 160,
            .marathon: 160 ..< 176,
            .threshold: 176 ..< 184,
            .interval: 184 ..< 200,
            .repetition: 200 ..< Int.max
        ])
    }
    
    func testIntensityFirstElFirstHr() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(1000), heartrate: 180, skinIsContacted: nil, energyExpended: nil),
                nil))
        XCTAssertEqual(actual, [IntensityEvent(date: makeDt(1000), intensity: .threshold)])
    }
    
    // Not a real case
    func testIntensityFirstElSecondHrNoCrossingAsc() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(2000), heartrate: 190, skinIsContacted: nil, energyExpended: nil),
                HeartrateEvent(date: makeDt(1000), heartrate: 180, skinIsContacted: nil, energyExpended: nil)))
        XCTAssertEqual(actual, [IntensityEvent(date: makeDt(1000), intensity: .threshold)])
    }
    
    // Not a real case
    func testIntensityFirstElSecondHrNoCrossingDesc() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(2000), heartrate: 180, skinIsContacted: nil, energyExpended: nil),
                HeartrateEvent(date: makeDt(1000), heartrate: 190, skinIsContacted: nil, energyExpended: nil)))
        XCTAssertEqual(actual, [IntensityEvent(date: makeDt(1000), intensity: .threshold)])
    }

    // Not a real case
    func testIntensityFirstElSecondHrCrossingAsc() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(190), heartrate: 190, skinIsContacted: nil, energyExpended: nil),
                HeartrateEvent(date: makeDt(150), heartrate: 150, skinIsContacted: nil, energyExpended: nil)))
        XCTAssertEqual(actual, [
            IntensityEvent(date: makeDt(150), intensity: .easy),
            IntensityEvent(date: makeDt(160), intensity: .marathon),
            IntensityEvent(date: makeDt(180), intensity: .threshold)
        ])
    }

    // Not a real case
    func testIntensityFirstElSecondHrCrossingDesc() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(190), heartrate: 150, skinIsContacted: nil, energyExpended: nil),
                HeartrateEvent(date: makeDt(150), heartrate: 190, skinIsContacted: nil, energyExpended: nil)))
        XCTAssertEqual(actual, [
            IntensityEvent(date: makeDt(150), intensity: .threshold),
            IntensityEvent(date: makeDt(160), intensity: .marathon),
            IntensityEvent(date: makeDt(180), intensity: .easy)
        ])
    }

    // Not a real case
    func testIntensitySecondElFirstHrNoCrossing() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        ts.insert(IntensityEvent(date: makeDt(1000), intensity: .threshold))
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(2000), heartrate: 180, skinIsContacted: nil, energyExpended: nil),
                nil))
        XCTAssertEqual(actual, [IntensityEvent(date: makeDt(2000), intensity: .threshold)])
    }

    // Not a real case
    func testIntensitySecondElFirstHrCrossing() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        ts.insert(IntensityEvent(date: makeDt(0), intensity: .threshold))
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(170), heartrate: 170, skinIsContacted: nil, energyExpended: nil),
                nil))
        XCTAssertEqual(actual, [IntensityEvent(date: makeDt(170), intensity: .marathon)])
    }

    func testIntensitySecondElSecondHrNoCrossingAsc() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        ts.insert(IntensityEvent(date: makeDt(190), intensity: .threshold))
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(195), heartrate: 195, skinIsContacted: nil, energyExpended: nil),
                HeartrateEvent(date: makeDt(190), heartrate: 190, skinIsContacted: nil, energyExpended: nil)))
        XCTAssertEqual(actual, [])
    }

    func testIntensitySecondElSecondHrNoCrossingDesc() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        ts.insert(IntensityEvent(date: makeDt(190), intensity: .threshold))
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(195), heartrate: 176, skinIsContacted: nil, energyExpended: nil),
                HeartrateEvent(date: makeDt(190), heartrate: 190, skinIsContacted: nil, energyExpended: nil)))
        XCTAssertEqual(actual, [])
    }

    func testIntensitySecondElSecondHrCrossingAsc() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        ts.insert(IntensityEvent(date: makeDt(190), intensity: .threshold))
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(205), heartrate: 205, skinIsContacted: nil, energyExpended: nil),
                HeartrateEvent(date: makeDt(190), heartrate: 190, skinIsContacted: nil, energyExpended: nil)))
        XCTAssertEqual(actual, [
            IntensityEvent(date: makeDt(196), intensity: .interval),
            IntensityEvent(date: makeDt(200), intensity: .repetition)
        ])
    }
    
    func testIntensitySecondElSecondHrCrossingDesc() throws {
        Profile.onAppear()
        Profile.hrMax.onChange(to: 200)
        
        let ts = TimeSeries<IntensityEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        ts.insert(IntensityEvent(date: makeDt(0), intensity: .threshold))
        let actual = try XCTUnwrap(
            ts.parse(
                HeartrateEvent(date: makeDt(30), heartrate: 160, skinIsContacted: nil, energyExpended: nil),
                HeartrateEvent(date: makeDt(0), heartrate: 190, skinIsContacted: nil, energyExpended: nil)))
        XCTAssertEqual(actual, [
            IntensityEvent(date: makeDt(14), intensity: .marathon)
        ])
    }
    
    // MARK: HeartrateSecondsEvent
    func testHeartrateSecondsFirstElFirstHr() throws {
        let ts = TimeSeries<HeartrateSecondsEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        let actual = ts.parse(
            HeartrateEvent(
                date: makeDt(1000),
                heartrate: 100,
                skinIsContacted: nil,
                energyExpended: nil), nil)
        XCTAssertNil(actual)
    }
    
    func testHeartrateSecondsFirstElSecondHr() throws {
        let ts = TimeSeries<HeartrateSecondsEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        let actual = ts.parse(
            HeartrateEvent(
                date: makeDt(1500),
                heartrate: 150,
                skinIsContacted: nil,
                energyExpended: nil),
            HeartrateEvent(
                date: makeDt(1000),
                heartrate: 100,
                skinIsContacted: nil,
                energyExpended: nil))
        let expected = HeartrateSecondsEvent(date: makeDt(1500), heartrateSeconds: 125 * 500)
        XCTAssertEqual(actual, expected)
    }
    
    func testHeartrateSecondsSecondElFirstHr() throws {
        let ts = TimeSeries<HeartrateSecondsEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        ts.insert(HeartrateSecondsEvent(date: makeDt(500), heartrateSeconds: 125 * 500))
        let actual = ts.parse(
            HeartrateEvent(
                date: makeDt(1000),
                heartrate: 100,
                skinIsContacted: nil,
                energyExpended: nil), nil)
        XCTAssertNil(actual)
    }
    
    func testHeartrateSecondsSecondElSecondHr() throws {
        let ts = TimeSeries<HeartrateSecondsEvent, None>(queue: DispatchQueue.global())
        ts.reset()
        XCTAssertTrue(ts.elements.isEmpty)
        ts.insert(HeartrateSecondsEvent(date: makeDt(500), heartrateSeconds: 100))
        XCTAssertEqual(ts.elements.last?.vector.date, makeDt(500))
        
        let actual = ts.parse(
            HeartrateEvent(
                date: makeDt(1000),
                heartrate: 150,
                skinIsContacted: nil,
                energyExpended: nil),
            HeartrateEvent(
                date: makeDt(500),
                heartrate: 100,
                skinIsContacted: nil,
                energyExpended: nil))
        XCTAssertEqual(ts.elements.last?.vector.date, makeDt(500))

        let expected = HeartrateSecondsEvent(
            date: makeDt(1000),
            heartrateSeconds: 125 * 500 + 100)
        XCTAssertEqual(actual, expected)
    }

    private func makeDt(_ x: Double) -> Date {
        Date(timeIntervalSinceReferenceDate: x)
    }
}
