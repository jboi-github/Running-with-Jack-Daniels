//
//  FormulaTests.swift
//  Run!!Tests
//
//  Created by Jürgen Boiselle on 31.03.22.
//

import XCTest
@testable import Run__

class FormulaTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBmi() throws {
        XCTAssertEqual(Run.bmi(weightKg: 84.5, heightM: 1.84), 25.0, accuracy: 0.1, "BMI")
    }
    
    func testHrMax() throws {
        var birthday = Calendar.current.date(byAdding: .year, value: -10, to: Date())!
        print(birthday)
        XCTAssertEqual(Run.hrMaxBpm(birthday: birthday, gender: .male), 214, "HRmax @ 10")
        
        birthday = Calendar.current.date(byAdding: .year, value: -10, to: Date())!
        birthday = Calendar.current.date(byAdding: .day, value: -1, to: birthday)!
        print(birthday)
        XCTAssertEqual(Run.hrMaxBpm(birthday: birthday, gender: .male), 214, "HRmax before 10")
        
        birthday = Calendar.current.date(byAdding: .day, value: 2, to: birthday)!
        print(birthday)
        XCTAssertEqual(Run.hrMaxBpm(birthday: birthday, gender: .male), 215, "HRmax after 10")
    }
    
    func testHrLimits() throws {
        let hrMax = 178
        let restHr = 42
        
        let limits = Run.hrLimits(hrMaxBpm: hrMax, restingHrBpm: restHr)
        print(limits)
        
        let expected = [
            Run.Intensity.Cold: 0 ..< 130,
            Run.Intensity.Easy: 130 ..< 151,
            Run.Intensity.Long: 130 ..< 151,
            Run.Intensity.Marathon: 151 ..< 164,
            Run.Intensity.Threshold: 162 ..< 175,
            Run.Intensity.Interval: 167 ..< 178
        ]
        
        XCTAssertEqual(limits.count, expected.count, "HR limits")
        expected.forEach { (key: Run.Intensity, value: Range<Int>) in
            XCTAssertEqual(limits[key]?.lowerBound, value.lowerBound, "\(key) lower")
            XCTAssertEqual(limits[key]?.upperBound, value.upperBound, "\(key) upper")
        }
    }
    
    func testVdotDistTimeRoundTrip() throws {
        let distanceM = 10000.0
        let timeSec = TimeInterval(52*60+30) // 52:30
        let vdot = Run.vdot4DistTime(distanceM: distanceM, timeSec: timeSec)

        XCTAssertEqual(Run.vdot4DistTime(distanceM: distanceM, timeSec: timeSec), 37.8, accuracy: 1.0, "vdot")
        XCTAssertEqual(Run.dist4VdotTime(vdot: vdot, timeSec: timeSec), distanceM, "dist")
        print(Run.time4VdotDist(vdot: 30.0, distanceM: 10000))
        XCTAssertLessThanOrEqual(abs(timeSec - Run.time4VdotDist(vdot: vdot, distanceM: distanceM)), 5, "time")
    }
    
    func testVdotPacePercentRoundTrip() throws {
        let percent = 0.8
        let vdot = 30.0
        
        let pace = Run.pace4VdotPercent(vdot: vdot, percent: percent)
        XCTAssertEqual(pace, 414, accuracy: 0.5, "pace")
        XCTAssertEqual(vdot, Run.vdot4PacePercent(paceSecPerKm: TimeInterval(pace), percent: percent), accuracy: 0.1, "vdot - percent - pace")
    }

    func testPlanTraining() throws {
        let paces = Run.planTraining(vdot: 42.0)
        paces.forEach { key, value in
            switch key {
            case .Easy:
                XCTAssertEqual(value.lower, 404, accuracy: 0.5, "Easy - lower")
                XCTAssertEqual(value.upper, 334, accuracy: 0.5, "Easy - upper")
            case .Long:
                XCTAssertEqual(value.lower, 404, accuracy: 0.5, "Long - lower")
                XCTAssertEqual(value.upper, 334, accuracy: 0.5, "Long - upper")
            case .Threshold:
                XCTAssertEqual(value.lower, 308, accuracy: 0.5, "Threshold - lower")
                XCTAssertEqual(value.upper, 294, accuracy: 0.5, "Threshold - upper")
            case .Interval:
                XCTAssertEqual(value.lower, 276, accuracy: 0.5, "Interval - lower")
                XCTAssertEqual(value.upper, 265, accuracy: 0.5, "Interval - upper")
            case .Repetition:
                XCTAssertEqual(value.lower, 255, accuracy: 0.5, "Interval - lower")
                XCTAssertEqual(value.upper, 229, accuracy: 0.5, "Interval - upper")
            default:
                XCTFail("Unpaceable intensity detected")
            }
        }
    }
    
    func testVdot4TimeOff() throws {
        let vdot = 39.0
        let weight = 85.0
        let when = Calendar.current.date(byAdding: .year, value: -7, to: Date())!
        let vacation = Calendar.current.date(byAdding: .day, value: -21, to: Date())!
        
        XCTAssertEqual(Run.vdot4TimeOff(vdotAtStart: vdot, timeOffStart: when, weightAtStart: weight, weightAtEnd: 90.0), 29.5, accuracy: 0.1, "time off")
        
        XCTAssertEqual(Run.vdot4TimeOff(vdotAtStart: vdot, timeOffStart: vacation), 37.1, accuracy: 0.1, "vacation")
    }
    
    func testTrain() throws {
        let limits: [Run.Intensity: Range<Int>] = [.Cold: 0..<100, .Easy: 100..<150, .Threshold: 150..<170]
        
        XCTAssertEqual(
            try XCTUnwrap(Run.train(hrBpm: 169, paceSecPerKm: 5*60+06, limits: limits)),
            40, accuracy: 0.5)
        XCTAssertNil(Run.train(hrBpm: 180, paceSecPerKm: 5*60+06, limits: limits))
        XCTAssertEqual(
            try XCTUnwrap(Run.train(hrBpm: 165, paceSecPerKm: 7*60, limits: limits)),
            27, accuracy: 0.5)
        XCTAssertEqual(
            try XCTUnwrap(Run.train(hrBpm: 150, paceSecPerKm: 5*60+06, limits: limits)),
            42, accuracy: 0.5)
    }
    
    func testPlanSeason() throws {
        let easiestCase = Plan.planSeason()
        print(easiestCase)
        
        let breakFrom = Date().advanced(by: 24.0*3600.0*7.0)
        let breakTo = Date().advanced(by: 24.0*3600.0*10.0)
        let withBreak = Plan.planSeason(plannedBreaks: [(from: breakFrom, to: breakTo)])
        print(breakFrom, breakTo, withBreak)
    }
    
    func testPlanWeek() throws {
        let plan = Plan.planWeek(phase: 3, goal: .longMarathon, sumTime: 3600.0*4.0, days: 4, maxQdays: 2)
        guard let p = plan.plan else {return}
        
        print(p.map {$0.purpose})
    }
    
    func testNextBestWorkout() throws {
        let x = Plan.nextBestWorkout(
            phase: 4, goal: .longMarathon, sumTimeWeek: 4.0*3600.0, maxTimeToday: 110*60,
            intensities: [
                .Easy: 10200.0,
                .Threshold: 1200.0
            ],
            nofWorkouts: 3)
        print("T", x)
    }
}
