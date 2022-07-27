//
//  TotalsTests.swift
//  Run!!Tests
//
//  Created by Jürgen Boiselle on 31.03.22.
//

import XCTest
import CoreLocation
import Combine

@testable import Run__

class TotalsTests: XCTestCase {

    var tsSet: TimeSeriesSet! = nil
    var queue: SerialQueue! = nil

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        queue = SerialQueue("X")
        Files.initDirectory()
        tsSet = TimeSeriesSet(queue: queue)
        tsSet.pedometerDataTimeseries.reset()
        tsSet.pedometerEventTimeseries.reset()
        tsSet.motionActivityTimeseries.reset()
        tsSet.locationTimeseries.reset()
        tsSet.distanceTimeseries.reset()
        tsSet.heartrateTimeseries.reset()
        tsSet.intensityTimeseries.reset()
        tsSet.heartrateSecondsTimeseries.reset()
        tsSet.batteryLevelTimeseries.reset()
        tsSet.bodySensorLocationTimeseries.reset()
        tsSet.peripheralTimeseries.reset()
        tsSet.resetTimeseries.reset()
        tsSet.totalsTimeseries.reset()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        tsSet = nil
    }
    var cancellables = Set<AnyCancellable>()
    
    func testSegmentCountEmpty() throws {
        let expectation = XCTestExpectation()
        tsSet.$totals.dropFirst().sink {
            XCTAssertEqual($0, [])
            expectation.fulfill()
        }
        .store(in: &cancellables)

        tsSet.refreshTotals(upTo: makeDt(1000))
        wait(for: [expectation], timeout: 10)
    }

    func testSegmentCountFirst() throws {
        // Prepare to check total
        let expectation = XCTestExpectation()
        tsSet.$totals.dropFirst().sink {
            XCTAssertEqual($0, [
                TimeSeriesSet.Total(
                    endAt: self.makeDt(1000),
                    motionActivity: nil,
                    resetDate: self.makeDt(0),
                    intensity: .easy,
                    duration: 1000, // 0 ..< 1000,
                    numberOfSteps: nil,
                    activeDuration: nil,
                    energyExpended: nil,
                    distance: nil,
                    speed: nil,
                    cadence: nil,
                    avgHeartrate: nil,
                    vdot: nil)
            ])
            expectation.fulfill()
        }
        .store(in: &cancellables)
        
        // Do something
        tsSet.reflect(ResetEvent(date: makeDt(0)))
        
        let intensityEvent = IntensityEvent(date: makeDt(100), intensity: .easy)
        tsSet.intensityTimeseries.insert(intensityEvent)
        tsSet.totalsTimeseries.reflect(intensityEvent: intensityEvent)

        // Check total
        tsSet.refreshTotals(upTo: makeDt(1000))
        wait(for: [expectation], timeout: 10)
    }

    func testSegmentCountTwoDifferent() throws {
        // Prepare to check total
        let expectation = XCTestExpectation()
        tsSet.$totals.dropFirst().sink {
            let expected = [
                TimeSeriesSet.Total(
                    endAt: self.makeDt(1000),
                    motionActivity: nil,
                    resetDate: self.makeDt(0),
                    intensity: .marathon,
                    duration: 800, // 200 ..< 1000,
                    numberOfSteps: nil,
                    activeDuration: nil,
                    energyExpended: nil,
                    distance: nil,
                    speed: nil,
                    cadence: nil,
                    avgHeartrate: nil,
                    vdot: nil),
                TimeSeriesSet.Total(
                    endAt: self.makeDt(200),
                    motionActivity: nil,
                    resetDate: self.makeDt(0),
                    intensity: .easy,
                    duration: 200, // 0 ..< 200,
                    numberOfSteps: nil,
                    activeDuration: nil,
                    energyExpended: nil,
                    distance: nil,
                    speed: nil,
                    cadence: nil,
                    avgHeartrate: nil,
                    vdot: nil)
            ]

            XCTAssertEqual($0.map {$0.date}, expected.map {$0.date})
            XCTAssertEqual($0.map {$0.duration}, expected.map {$0.duration})
            XCTAssertEqual($0, expected)
            expectation.fulfill()
        }
        .store(in: &cancellables)
        
        // Do something
        tsSet.reflect(ResetEvent(date: makeDt(0)))

        let i1 = IntensityEvent(date: makeDt(100), intensity: .easy)
        tsSet.intensityTimeseries.insert(i1)
        tsSet.totalsTimeseries.reflect(intensityEvent: i1)
        
        let i2 = IntensityEvent(date: makeDt(200), intensity: .marathon)
        tsSet.intensityTimeseries.insert(i2)
        tsSet.totalsTimeseries.reflect(intensityEvent: i2)

        // Check total
        tsSet.refreshTotals(upTo: makeDt(1000))
        wait(for: [expectation], timeout: 10)
    }

    func testSegmentCountTwoEqualAndThird() throws {
        // Prepare to check total
        let expectation = XCTestExpectation()
        tsSet.$totals.dropFirst().sink {
            let expected = [
                TimeSeriesSet.Total(
                    endAt: self.makeDt(1000),
                    motionActivity: nil,
                    resetDate: self.makeDt(0),
                    intensity: .marathon,
                    duration: 700, // 300 ..< 1000,
                    numberOfSteps: nil,
                    activeDuration: nil,
                    energyExpended: nil,
                    distance: nil,
                    speed: nil,
                    cadence: nil,
                    avgHeartrate: nil,
                    vdot: nil),
                TimeSeriesSet.Total(
                    endAt: self.makeDt(300),
                    motionActivity: nil,
                    resetDate: self.makeDt(0),
                    intensity: .easy,
                    duration: 300, // 0 ..< 300,
                    numberOfSteps: nil,
                    activeDuration: nil,
                    energyExpended: nil,
                    distance: nil,
                    speed: nil,
                    cadence: nil,
                    avgHeartrate: nil,
                    vdot: nil)
            ]

            XCTAssertEqual($0.map {$0.date}, expected.map {$0.date})
            XCTAssertEqual($0, expected)
            expectation.fulfill()
        }
        .store(in: &cancellables)
        
        // Do something
        tsSet.reflect(ResetEvent(date: makeDt(0)))

        let i1 = IntensityEvent(date: makeDt(100), intensity: .easy)
        tsSet.intensityTimeseries.insert(i1)
        tsSet.totalsTimeseries.reflect(intensityEvent: i1)
        
        let i2 = IntensityEvent(date: makeDt(200), intensity: .easy)
        tsSet.intensityTimeseries.insert(i2)
        tsSet.totalsTimeseries.reflect(intensityEvent: i2)

        let i3 = IntensityEvent(date: makeDt(300), intensity: .marathon)
        tsSet.intensityTimeseries.insert(i3)
        tsSet.totalsTimeseries.reflect(intensityEvent: i3)

        // Check total
        tsSet.refreshTotals(upTo: makeDt(1000))
        wait(for: [expectation], timeout: 10)
    }

    func testCombinedRestings() throws {
        // Prepare to check total
        let expectation = XCTestExpectation()
        tsSet.$totals.dropFirst().sink {
            let expected = [
                TimeSeriesSet.Total(
                    endAt: self.makeDt(1000),
                    motionActivity: nil,
                    resetDate: self.makeDt(0),
                    intensity: .cold,
                    duration: 600, // 300 ..< 400 + 500 ..< 1000,
                    numberOfSteps: nil,
                    activeDuration: nil,
                    energyExpended: nil,
                    distance: nil,
                    speed: nil,
                    cadence: nil,
                    avgHeartrate: nil,
                    vdot: nil),
                TimeSeriesSet.Total(
                    endAt: self.makeDt(500),
                    motionActivity: nil,
                    resetDate: self.makeDt(0),
                    intensity: .threshold,
                    duration: 100, // 400 ..< 500
                    numberOfSteps: nil,
                    activeDuration: nil,
                    energyExpended: nil,
                    distance: nil,
                    speed: nil,
                    cadence: nil,
                    avgHeartrate: nil,
                    vdot: nil),
                TimeSeriesSet.Total(
                    endAt: self.makeDt(300),
                    motionActivity: nil,
                    resetDate: self.makeDt(0),
                    intensity: .marathon,
                    duration: 100, // 200 ..< 300
                    numberOfSteps: nil,
                    activeDuration: nil,
                    energyExpended: nil,
                    distance: nil,
                    speed: nil,
                    cadence: nil,
                    avgHeartrate: nil,
                    vdot: nil),
                TimeSeriesSet.Total(
                    endAt: self.makeDt(200),
                    motionActivity: nil,
                    resetDate: self.makeDt(0),
                    intensity: .easy,
                    duration: 200, // 0 ..< 200
                    numberOfSteps: nil,
                    activeDuration: nil,
                    energyExpended: nil,
                    distance: nil,
                    speed: nil,
                    cadence: nil,
                    avgHeartrate: nil,
                    vdot: nil)
            ]

            XCTAssertEqual($0.map {$0.date}, expected.map {$0.date})
            XCTAssertEqual($0.map {$0.duration}, expected.map {$0.duration})
            XCTAssertEqual($0.map {$0.motionActivity}, expected.map {$0.motionActivity})
            XCTAssertEqual($0, expected)
            expectation.fulfill()
        }
        .store(in: &cancellables)
        
        // Do something
        tsSet.reflect(ResetEvent(date: makeDt(0)))

        let i1 = IntensityEvent(date: makeDt(100), intensity: .easy)
        tsSet.intensityTimeseries.insert(i1)
        tsSet.totalsTimeseries.reflect(intensityEvent: i1)
        
        let i2 = IntensityEvent(date: makeDt(200), intensity: .marathon)
        tsSet.intensityTimeseries.insert(i2)
        tsSet.totalsTimeseries.reflect(intensityEvent: i2)

        let i3 = IntensityEvent(date: makeDt(300), intensity: .cold)
        tsSet.intensityTimeseries.insert(i3)
        tsSet.totalsTimeseries.reflect(intensityEvent: i3)
        
        let i4 = IntensityEvent(date: makeDt(400), intensity: .threshold)
        tsSet.intensityTimeseries.insert(i4)
        tsSet.totalsTimeseries.reflect(intensityEvent: i4)
        
        let i5 = IntensityEvent(date: makeDt(500), intensity: .cold)
        tsSet.intensityTimeseries.insert(i5)
        tsSet.totalsTimeseries.reflect(intensityEvent: i5)

        // Check total
        tsSet.refreshTotals(upTo: makeDt(1000))
        wait(for: [expectation], timeout: 10)
    }
    
    func testCombinedResetted() throws {
        // Prepare to check total
        let expectation = XCTestExpectation()
        tsSet.$totals.dropFirst().sink {
            let expected = [
                TimeSeriesSet.Total(
                    endAt: self.makeDt(1000),
                    motionActivity: nil,
                    resetDate: self.makeDt(150),
                    intensity: .cold,
                    duration: 600, // 300 ..< 400 + 500 ..< 1000,
                    numberOfSteps: nil,
                    activeDuration: nil,
                    energyExpended: nil,
                    distance: nil,
                    speed: nil,
                    cadence: nil,
                    avgHeartrate: nil,
                    vdot: nil),
                TimeSeriesSet.Total(
                    endAt: self.makeDt(500),
                    motionActivity: nil,
                    resetDate: self.makeDt(150),
                    intensity: .threshold,
                    duration: 100, // 400 ..< 500
                    numberOfSteps: nil,
                    activeDuration: nil,
                    energyExpended: nil,
                    distance: nil,
                    speed: nil,
                    cadence: nil,
                    avgHeartrate: nil,
                    vdot: nil),
                TimeSeriesSet.Total(
                    endAt: self.makeDt(300),
                    motionActivity: nil,
                    resetDate: self.makeDt(150),
                    intensity: .marathon,
                    duration: 100, // 200 ..< 300
                    numberOfSteps: nil,
                    activeDuration: nil,
                    energyExpended: nil,
                    distance: nil,
                    speed: nil,
                    cadence: nil,
                    avgHeartrate: nil,
                    vdot: nil),
                TimeSeriesSet.Total(
                    endAt: self.makeDt(200),
                    motionActivity: nil,
                    resetDate: self.makeDt(150),
                    intensity: .easy,
                    duration: 50, // 150 ..< 200
                    numberOfSteps: nil,
                    activeDuration: nil,
                    energyExpended: nil,
                    distance: nil,
                    speed: nil,
                    cadence: nil,
                    avgHeartrate: nil,
                    vdot: nil)
            ]

            XCTAssertEqual($0.map {$0.date}, expected.map {$0.date})
            XCTAssertEqual($0.map {$0.duration}, expected.map {$0.duration})
            XCTAssertEqual($0.map {$0.motionActivity}, expected.map {$0.motionActivity})
            XCTAssertEqual($0, expected)
            expectation.fulfill()
        }
        .store(in: &cancellables)
        
        // Do something
        tsSet.reflect(ResetEvent(date: makeDt(0)))

        let i1 = IntensityEvent(date: makeDt(100), intensity: .easy)
        tsSet.intensityTimeseries.insert(i1)
        tsSet.totalsTimeseries.reflect(intensityEvent: i1)
        
        tsSet.reflect(ResetEvent(date: makeDt(150)))

        let i2 = IntensityEvent(date: makeDt(200), intensity: .marathon)
        tsSet.intensityTimeseries.insert(i2)
        tsSet.totalsTimeseries.reflect(intensityEvent: i2)

        let i3 = IntensityEvent(date: makeDt(300), intensity: .cold)
        tsSet.intensityTimeseries.insert(i3)
        tsSet.totalsTimeseries.reflect(intensityEvent: i3)
        
        let i4 = IntensityEvent(date: makeDt(400), intensity: .threshold)
        tsSet.intensityTimeseries.insert(i4)
        tsSet.totalsTimeseries.reflect(intensityEvent: i4)
        
        let i5 = IntensityEvent(date: makeDt(500), intensity: .cold)
        tsSet.intensityTimeseries.insert(i5)
        tsSet.totalsTimeseries.reflect(intensityEvent: i5)

        // Check total
        tsSet.refreshTotals(upTo: makeDt(1000))
        wait(for: [expectation], timeout: 10)
    }
    
    private func makeDt(_ x: Double) -> Date {
        Date(timeIntervalSinceReferenceDate: x)
    }

    // MARK: Performace Tests. Goal: 1 call/sec < 1% CPU -> 10000 Calls within 100 secs on 100% CPU
    func testPerformanceForeground() throws {
        tsSet.isInBackground = false
        self.measure {performaneRun()}
    }

    func testPerformanceBackground() throws {
        tsSet.isInBackground = true
        self.measure {performaneRun()}
    }

    private func performaneRun() {
        let expectation = XCTestExpectation()
        
        queue.async { [self] in
            for i in (0 ..< 10000) {
                randomWalker()
                tsSet.refreshTotals(upTo: makeDt(Double(1000 + i * 10)))
                if i % 1000 == 0 {
                    log(
                        i,
                        tsSet.totalsTimeseries.elements.count,
                        tsSet.pedometerDataTimeseries.elements.count,
                        tsSet.distanceTimeseries.elements.count,
                        tsSet.heartrateSecondsTimeseries.elements.count)
                }
            }
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 600)
    }
    
    var date: Date = Date(timeIntervalSinceReferenceDate: 1000)
    private func randomWalker() {
        // Sum
        var numberOfSteps: Int = 0
        var pdmDistance: CLLocationDistance = 0
        var activeDuration: TimeInterval = 0
        var gpsDistance: CLLocationDistance = 0
        var heartrateSeconds: Double = 0

        // Choose from values
        let motions: [MotionActivityEvent.Motion] = [.stationary, .walking, .running, .cycling, .other]
        let confidences: [MotionActivityEvent.Confidence] = [.low, .medium, .high]
        date = date.advanced(by: TimeInterval.random(in: 0 ..< 10))
        
        // Choose event type:
        let r = Double.random(in: 0..<1)
        if r < 0.33 {
            numberOfSteps += Int.random(in: 10 ..< 100)
            pdmDistance += CLLocationDistance.random(in: 7 ..< 70)
            activeDuration += TimeInterval.random(in: 0 ..< 10)
            
            let event = PedometerDataEvent(
                date: date,
                numberOfSteps: numberOfSteps,
                distance: pdmDistance,
                activeDuration: activeDuration)
            if let date = tsSet.pedometerDataTimeseries.elements.last?.date {
                tsSet.totalsTimeseries.reflect(dirtyAfter: date)
            }
            tsSet.pedometerDataTimeseries.insert(event)
            date = date.advanced(by: TimeInterval.random(in: 0 ..< 10))
        } else if r < 0.66 {
            gpsDistance += CLLocationDistance.random(in: 20 ..< 50)
            
            let event = DistanceEvent(date: date, distance: gpsDistance)
            if let date = tsSet.distanceTimeseries.elements.last?.date {
                tsSet.totalsTimeseries.reflect(dirtyAfter: date)
            }
            tsSet.distanceTimeseries.insert(event)
            date = date.advanced(by: TimeInterval.random(in: 0 ..< 10))
        } else if r < 0.99 {
            heartrateSeconds += Double.random(in: 1000 ..< 2000)
            
            let event = HeartrateSecondsEvent(
                date: date,
                heartrateSeconds: heartrateSeconds)
            if let date = tsSet.heartrateSecondsTimeseries.elements.last?.date {
                tsSet.totalsTimeseries.reflect(dirtyAfter: date)
            }
            tsSet.heartrateSecondsTimeseries.insert(event)
            date = date.advanced(by: TimeInterval.random(in: 0 ..< 10))
        } else if r < 0.9945 {
            let event = MotionActivityEvent(
                date: date,
                confidence: confidences.randomElement()!,
                motion: motions.randomElement()!)
            tsSet.motionActivityTimeseries.insert(event)
            tsSet.totalsTimeseries.reflect(motionActivityEvent: event)
        } else if r < 0.999 {
            let event = IntensityEvent(date: date, intensity: Run.Intensity.allCases.randomElement()!)
            tsSet.intensityTimeseries.insert(event)
            tsSet.totalsTimeseries.reflect(intensityEvent: event)
        } else {
            let event = ResetEvent(date: date)
            tsSet.reflect(event)
        }
    }
}
