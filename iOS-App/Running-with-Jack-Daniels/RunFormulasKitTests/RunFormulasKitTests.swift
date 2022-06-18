//
//  RunFormulasKitTests.swift
//  RunFormulasKitTests
//
//  Created by Jürgen Boiselle on 05.10.21.
//

import XCTest
@testable import RunFormulasKit

class RunFormulasKitTests: XCTestCase {

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
        self.measure {
            // Put the code you want to measure the time of here.
        }
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
            Intensity.Easy: (lower: 130, upper: 149),
            Intensity.Long: (lower: 130, upper: 149),
            Intensity.Threshold: (lower: 162, upper: 167),
            Intensity.Interval: (lower: 175, upper: 178)
        ]
        
        XCTAssertEqual(limits.count, expected.count, "HR limits")
        expected.forEach { (key: Intensity, value: (lower: Int, upper: Int)) in
            XCTAssertEqual(limits[key]?.lowerBound, value.lower, "\(key) lower")
            XCTAssertEqual(limits[key]?.upperBound, value.upper, "\(key) upper")
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
    
    func testVdotPacePercentRountTrip() throws {
        let percent = 0.8
        let vdot = 30.0
        
        let pace = pace4VdotPercent(vdot: vdot, percent: percent)
        XCTAssertEqual(pace, 413, "pace")
        XCTAssertEqual(vdot, vdot4PacePercent(paceSecPerKm: TimeInterval(pace), percent: percent), accuracy: 0.1, "vdot - percent - pace")
    }

    func testPlanTraining() throws {
        let paces = planTraining(vdot: 42.0)
        paces.forEach { key, value in
            switch key {
            case .Easy:
                XCTAssertEqual(value.lower, 403, "Easy - lower")
                XCTAssertEqual(value.upper, 337, "Easy - upper")
            case .Long:
                XCTAssertEqual(value.lower, 403, "Long - lower")
                XCTAssertEqual(value.upper, 337, "Long - upper")
            case .Threshold:
                XCTAssertEqual(value.lower, 307, "Threshold - lower")
                XCTAssertEqual(value.upper, 293, "Threshold - upper")
            case .Interval:
                XCTAssertEqual(value.lower, 276, "Interval - lower")
                XCTAssertEqual(value.upper, 264, "Interval - upper")
            case .Repetition:
                XCTAssertEqual(value.lower, 254, "Interval - lower")
                XCTAssertEqual(value.upper, 228, "Interval - upper")
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
