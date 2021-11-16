//
//  LogicTests.swift
//  Run!Tests
//
//  Created by Jürgen Boiselle on 15.11.21.
//

import XCTest
@testable import Run_

class LogicTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBmi() throws {
        XCTAssertEqual(bmi(weightKg: 84.5, heightM: 1.84), 25.0, accuracy: 0.1, "BMI")
    }
    
    func testHrMax() throws {
        var birthday = Calendar.current.date(byAdding: .year, value: -10, to: Date())!
        print(birthday)
        XCTAssertEqual(hrMaxBpm(birthday: birthday, gender: .male), 214, "HRmax @ 10")
        
        birthday = Calendar.current.date(byAdding: .year, value: -10, to: Date())!
        birthday = Calendar.current.date(byAdding: .day, value: -1, to: birthday)!
        print(birthday)
        XCTAssertEqual(hrMaxBpm(birthday: birthday, gender: .male), 214, "HRmax before 10")
        
        birthday = Calendar.current.date(byAdding: .day, value: 2, to: birthday)!
        print(birthday)
        XCTAssertEqual(hrMaxBpm(birthday: birthday, gender: .male), 215, "HRmax after 10")
    }
    
    func testHrLimits() throws {
        let hrMax = 178
        let restHr = 42
        
        let limits = hrLimits(hrMaxBpm: hrMax, restingHrBpm: restHr)
        print(limits)
        
        let expected = [
            Intensity.Cold: 42 ..< 130,
            Intensity.Easy: 130 ..< 151,
            Intensity.Long: 130 ..< 151,
            Intensity.Marathon: 151 ..< 164,
            Intensity.Threshold: 162 ..< 175,
            Intensity.Interval: 167 ..< 178
        ]
        
        XCTAssertEqual(limits.count, expected.count, "HR limits")
        expected.forEach { (key: Intensity, value: Range<Int>) in
            XCTAssertEqual(limits[key]?.lowerBound, value.lowerBound, "\(key) lower")
            XCTAssertEqual(limits[key]?.upperBound, value.upperBound, "\(key) upper")
        }
    }
    
    func testVdotDistTimeRoundTrip() throws {
        let distanceM = 10000.0
        let timeSec = TimeInterval(52*60+30) // 52:30
        let vdot = vdot4DistTime(distanceM: distanceM, timeSec: timeSec)

        XCTAssertEqual(vdot4DistTime(distanceM: distanceM, timeSec: timeSec), 37.8, accuracy: 1.0, "vdot")
        XCTAssertEqual(dist4VdotTime(vdot: vdot, timeSec: timeSec), distanceM, "dist")
        print(time4VdotDist(vdot: 30.0, distanceM: 10000))
        XCTAssertLessThanOrEqual(abs(timeSec - time4VdotDist(vdot: vdot, distanceM: distanceM)), 5, "time")
    }
    
    func testVdotPacePercentRoundTrip() throws {
        let percent = 0.8
        let vdot = 30.0
        
        let pace = pace4VdotPercent(vdot: vdot, percent: percent)
        XCTAssertEqual(pace, 414, accuracy: 0.5, "pace")
        XCTAssertEqual(vdot, vdot4PacePercent(paceSecPerKm: TimeInterval(pace), percent: percent), accuracy: 0.1, "vdot - percent - pace")
    }

    func testPlanTraining() throws {
        let paces = planTraining(vdot: 42.0)
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
        
        XCTAssertEqual(vdot4TimeOff(vdotAtStart: vdot, timeOffStart: when, weightAtStart: weight, weightAtEnd: 90.0), 29.5, accuracy: 0.1, "time off")
        
        XCTAssertEqual(vdot4TimeOff(vdotAtStart: vdot, timeOffStart: vacation), 37.1, accuracy: 0.1, "vacation")
    }
    
    func testTrain() throws {
        let hrMax = 176
        let hr = 155
        let vdot = train(hrBpm: hr, hrMaxBpm: hrMax, restingBpm: 40,
                         paceSecPerKm: 3600.0 / 9.2)

        XCTAssertNotNil(vdot, "train")
        print(Double(hr) / Double(hrMax), vdot!)
        XCTAssertEqual(vdot!, 32.5, accuracy: 0.5, "train")
    }
    
    func testPlanSeason() throws {
        let easiestCase = planSeason()
        print(easiestCase)
        
        let breakFrom = Date().advanced(by: 24.0*3600.0*7.0)
        let breakTo = Date().advanced(by: 24.0*3600.0*10.0)
        let withBreak = planSeason(plannedBreaks: [(from: breakFrom, to: breakTo)])
        print(breakFrom, breakTo, withBreak)
    }
    
    func testPlanWeek() throws {
        let plan = planWeek(phase: 3, goal: .longMarathon, sumTime: 3600.0*4.0, days: 4, maxQdays: 2)
        guard let p = plan.plan else {return}
        
        print(p.map {$0.purpose})
    }
    
    func testNextBestWorkout() throws {
        let x = nextBestWorkout(
            phase: 4, goal: .longMarathon, sumTimeWeek: 4.0*3600.0, maxTimeToday: 110*60,
            intensities: [
                .Easy: 10200.0,
                .Threshold: 1200.0
            ],
            nofWorkouts: 3)
        print("T", x)
    }
}
