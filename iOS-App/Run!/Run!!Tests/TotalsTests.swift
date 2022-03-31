//
//  TotalsTests.swift
//  Run!!Tests
//
//  Created by Jürgen Boiselle on 31.03.22.
//

import XCTest
@testable import Run__

class TotalsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testChangedMotions() throws {
        let workout = Workout(
            isActiveGetter: {IsActive(asOf: $0, isActive: true)},
            distanceGetter: {Distance(asOf: $0, speed: 1.5)},
            bodySensorLocationGetter: {.Other})
        let totals = Totals(
            motionGetter: {Motion(asOf: $0, motion: .running)},
            isActiveGetter: {IsActive(asOf: $0, isActive: true)},
            heartrateGetter: {Heartrate(asOf: $0, heartrate: 100)},
            intensityGetter: {Intensity(asOf: $0, intensity: .Easy)},
            distanceGetter: {Distance(asOf: $0, speed: 1)},
            workout: workout)
        
        workout.await(asOf: Date(timeIntervalSinceReferenceDate: 10))
        workout.start(asOf: Date(timeIntervalSinceReferenceDate: 20))
        
        workout.changed(motions: [
            Motion(asOf: Date(timeIntervalSinceReferenceDate: 21), motion: .running),
            Motion(asOf: Date(timeIntervalSinceReferenceDate: 22), motion: .running),
            Motion(asOf: Date(timeIntervalSinceReferenceDate: 23), motion: .running)
        ], [])
        workout.changed(isActives: [
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 21), isActive: true),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 22), isActive: true),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 23), isActive: true)
        ], [])
        XCTAssertEqual(workout.startTime, Date(timeIntervalSinceReferenceDate: 20))
        XCTAssertEqual(workout.endTime, Date(timeIntervalSinceReferenceDate: 23))
        
        totals.changed(motions: [
            Motion(asOf: Date(timeIntervalSinceReferenceDate: 21), motion: .running),
            Motion(asOf: Date(timeIntervalSinceReferenceDate: 22), motion: .running),
            Motion(asOf: Date(timeIntervalSinceReferenceDate: 23), motion: .running)
        ], [], [
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 21), isActive: true),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 22), isActive: true),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 23), isActive: true)
        ], [])
        
        XCTAssertEqual(totals.totals.count, 1)
        print(totals.totals)
        XCTAssertEqual(
            totals.totals[Totals.Key(isActive: true, motionType: .running, intensity: .Easy)],
            Totals.Value(sumHeartrate: 300, sumDuration: 3, sumDistance: 3))

        workout.stop(asOf: Date(timeIntervalSinceReferenceDate: 120))
    }

    func testChangedRemovedMotions() throws {
        let workout = Workout(
            isActiveGetter: {IsActive(asOf: $0, isActive: true)},
            distanceGetter: {Distance(asOf: $0, speed: 1.5)},
            bodySensorLocationGetter: {.Other})
        let totals = Totals(
            motionGetter: {Motion(asOf: $0, motion: .running)},
            isActiveGetter: {IsActive(asOf: $0, isActive: true)},
            heartrateGetter: {Heartrate(asOf: $0, heartrate: 100)},
            intensityGetter: {Intensity(asOf: $0, intensity: .Easy)},
            distanceGetter: {Distance(asOf: $0, speed: 1)},
            workout: workout)
        
        workout.await(asOf: Date(timeIntervalSinceReferenceDate: 10))
        workout.start(asOf: Date(timeIntervalSinceReferenceDate: 20))
        
        workout.changed(motions: [
            Motion(asOf: Date(timeIntervalSinceReferenceDate: 21), motion: .running),
            Motion(asOf: Date(timeIntervalSinceReferenceDate: 22), motion: .running),
            Motion(asOf: Date(timeIntervalSinceReferenceDate: 23), motion: .running)
        ], [
            Motion(asOf: Date(timeIntervalSinceReferenceDate: 21), motion: .walking),
            Motion(asOf: Date(timeIntervalSinceReferenceDate: 22), motion: .walking)
        ])
        workout.changed(isActives: [
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 21), isActive: true),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 22), isActive: true),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 23), isActive: true)
        ], [
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 21), isActive: false),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 22), isActive: false)
        ])
        totals.changed(motions: [
            Motion(asOf: Date(timeIntervalSinceReferenceDate: 21), motion: .running),
            Motion(asOf: Date(timeIntervalSinceReferenceDate: 22), motion: .running),
            Motion(asOf: Date(timeIntervalSinceReferenceDate: 23), motion: .running)
        ], [
            Motion(asOf: Date(timeIntervalSinceReferenceDate: 21), motion: .walking),
            Motion(asOf: Date(timeIntervalSinceReferenceDate: 22), motion: .walking)
        ], [
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 21), isActive: true),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 22), isActive: true),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 23), isActive: true)
        ], [
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 21), isActive: false),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 22), isActive: false)
        ])
        
        XCTAssertEqual(totals.totals.count, 2)
        XCTAssertEqual(
            totals.totals[Totals.Key(isActive: true, motionType: .running, intensity: .Easy)],
            Totals.Value(sumHeartrate: 300, sumDuration: 3, sumDistance: 3))
        XCTAssertEqual(
            totals.totals[Totals.Key(isActive: false, motionType: .walking, intensity: .Easy)],
            Totals.Value(sumHeartrate: -200, sumDuration: -2, sumDistance: -2))

        workout.stop(asOf: Date(timeIntervalSinceReferenceDate: 120))
    }

    func testChangedHeartrates() throws {
        let workout = Workout(
            isActiveGetter: {IsActive(asOf: $0, isActive: true)},
            distanceGetter: {Distance(asOf: $0, speed: 1.5)},
            bodySensorLocationGetter: {.Other})
        let totals = Totals(
            motionGetter: {Motion(asOf: $0, motion: .running)},
            isActiveGetter: {IsActive(asOf: $0, isActive: true)},
            heartrateGetter: {Heartrate(asOf: $0, heartrate: 100)},
            intensityGetter: {Intensity(asOf: $0, intensity: .Easy)},
            distanceGetter: {Distance(asOf: $0, speed: 1)},
            workout: workout)
        
        workout.await(asOf: Date(timeIntervalSinceReferenceDate: 10))
        workout.start(asOf: Date(timeIntervalSinceReferenceDate: 20))
        
        workout.append(Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 23), heartrate: 90))
        totals.changed(intensities: [
            Intensity(asOf: Date(timeIntervalSinceReferenceDate: 21), intensity: .Easy),
            Intensity(asOf: Date(timeIntervalSinceReferenceDate: 22), intensity: .Easy),
            Intensity(asOf: Date(timeIntervalSinceReferenceDate: 23), intensity: .Easy)
        ], [
            Intensity(asOf: Date(timeIntervalSinceReferenceDate: 21), intensity: .Cold),
            Intensity(asOf: Date(timeIntervalSinceReferenceDate: 22), intensity: .Cold)
        ], [
            Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 21), heartrate: 100),
            Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 22), heartrate: 100),
            Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 23), heartrate: 100)
        ], [
            Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 21), heartrate: 10),
            Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 22), heartrate: 10)
        ])
        
        XCTAssertEqual(totals.totals.count, 2)
        XCTAssertEqual(
            totals.totals[Totals.Key(isActive: true, motionType: .running, intensity: .Easy)],
            Totals.Value(sumHeartrate: 300, sumDuration: 3, sumDistance: 3))
        XCTAssertEqual(
            totals.totals[Totals.Key(isActive: true, motionType: .running, intensity: .Cold)],
            Totals.Value(sumHeartrate: -20, sumDuration: -2, sumDistance: -2))

        workout.stop(asOf: Date(timeIntervalSinceReferenceDate: 120))
    }

    func testChangedDistances() throws {
        let workout = Workout(
            isActiveGetter: {IsActive(asOf: $0, isActive: true)},
            distanceGetter: {Distance(asOf: $0, speed: 1.5)},
            bodySensorLocationGetter: {.Other})
        let totals = Totals(
            motionGetter: {Motion(asOf: $0, motion: .running)},
            isActiveGetter: {IsActive(asOf: $0, isActive: true)},
            heartrateGetter: {Heartrate(asOf: $0, heartrate: 100)},
            intensityGetter: {Intensity(asOf: $0, intensity: .Easy)},
            distanceGetter: {Distance(asOf: $0, speed: 2)},
            workout: workout)
        
        workout.await(asOf: Date(timeIntervalSinceReferenceDate: 10))
        workout.start(asOf: Date(timeIntervalSinceReferenceDate: 20))
        
        workout.changed(distances: [
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 21), speed: 2),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 22), speed: 2),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 23), speed: 2)
        ], [
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 21), speed: 1),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 22), speed: 1),
        ])
        totals.changed(distances: [
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 21), speed: 2),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 22), speed: 2),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 23), speed: 2)
        ], [
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 21), speed: 1),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 22), speed: 1),
        ])
        
        XCTAssertEqual(totals.totals.count, 1)
        XCTAssertEqual(
            totals.totals[Totals.Key(isActive: true, motionType: .running, intensity: .Easy)],
            Totals.Value(sumHeartrate: 100, sumDuration: 1, sumDistance: 4))

        workout.stop(asOf: Date(timeIntervalSinceReferenceDate: 120))
    }

    func testSaveLoad() throws {
        let workout = Workout(
            isActiveGetter: {IsActive(asOf: $0, isActive: true)},
            distanceGetter: {Distance(asOf: $0, speed: 1.5)},
            bodySensorLocationGetter: {.Other})
        let totals = Totals(
            motionGetter: {Motion(asOf: $0, motion: .running)},
            isActiveGetter: {IsActive(asOf: $0, isActive: true)},
            heartrateGetter: {Heartrate(asOf: $0, heartrate: 100)},
            intensityGetter: {Intensity(asOf: $0, intensity: .Easy)},
            distanceGetter: {Distance(asOf: $0, speed: 2)},
            workout: workout)
        
        workout.await(asOf: Date(timeIntervalSinceReferenceDate: 10))
        workout.start(asOf: Date(timeIntervalSinceReferenceDate: 20))
        
        workout.changed(distances: [
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 21), speed: 2),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 22), speed: 2),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 23), speed: 2)
        ], [
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 21), speed: 1),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 22), speed: 1),
        ])
        totals.changed(distances: [
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 21), speed: 2),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 22), speed: 2),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 23), speed: 2)
        ], [
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 21), speed: 1),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 22), speed: 1),
        ])
        
        workout.stop(asOf: Date(timeIntervalSinceReferenceDate: 120))
        
        let totals2 = Totals(
            motionGetter: {Motion(asOf: $0, motion: .running)},
            isActiveGetter: {IsActive(asOf: $0, isActive: true)},
            heartrateGetter: {Heartrate(asOf: $0, heartrate: 100)},
            intensityGetter: {Intensity(asOf: $0, intensity: .Easy)},
            distanceGetter: {Distance(asOf: $0, speed: 2)},
            workout: workout)

        totals.save()
        totals2.load()
        
        XCTAssertEqual(totals.totals, totals2.totals)

        totals2.changed(distances: [
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 21), speed: 2),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 22), speed: 2),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 23), speed: 2)
        ], [
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 21), speed: 1),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 22), speed: 1),
        ])
        XCTAssertNotEqual(totals.totals, totals2.totals)
    }
}
