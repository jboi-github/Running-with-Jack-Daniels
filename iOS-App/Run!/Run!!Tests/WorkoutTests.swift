//
//  WorkoutTests.swift
//  Run!!Tests
//
//  Created by Jürgen Boiselle on 30.03.22.
//

import XCTest
@testable import Run__

class WorkoutTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStatusStopped() throws {
        let workout = Workout(isActiveGetter: {log($0); return nil}, distanceGetter: {log($0); return nil}, bodySensorLocationGetter: {.Other})
        XCTAssertEqual(workout.status, WorkoutStatus.stopped(since: .distantPast))
        
        workout.start(asOf: Date(seconds: 10))
        XCTAssertEqual(workout.status, WorkoutStatus.stopped(since: .distantPast))
        
        workout.pause(asOf: Date(seconds: 20))
        XCTAssertEqual(workout.status, WorkoutStatus.stopped(since: .distantPast))
        
        workout.stop(asOf: Date(seconds: 30))
        XCTAssertEqual(workout.status, WorkoutStatus.stopped(since: .distantPast))
        
        workout.await(asOf: Date(seconds: 40))
        XCTAssertEqual(workout.status, WorkoutStatus.waiting(since: Date(seconds: 40)))
    }
    
    func testStatusWaiting() throws {
        let workout = Workout(isActiveGetter: {log($0); return nil}, distanceGetter: {log($0); return nil}, bodySensorLocationGetter: {.Other})
        XCTAssertEqual(workout.status, WorkoutStatus.stopped(since: .distantPast))
        
        workout.await(asOf: Date(seconds: 40))
        XCTAssertEqual(workout.status, WorkoutStatus.waiting(since: Date(seconds: 40)))
        
        workout.pause(asOf: Date(seconds: 20))
        XCTAssertEqual(workout.status, WorkoutStatus.waiting(since: Date(seconds: 40)))
        
        workout.stop(asOf: Date(seconds: 30))
        XCTAssertEqual(workout.status, WorkoutStatus.waiting(since: Date(seconds: 40)))
        
        workout.start(asOf: Date(seconds: 10))
        XCTAssertEqual(workout.status, WorkoutStatus.started(since: Date(seconds: 40)))
    }
    
    func testStatusStarted() throws {
        let workout = Workout(isActiveGetter: {log($0); return nil}, distanceGetter: {log($0); return nil}, bodySensorLocationGetter: {.Other})
        XCTAssertEqual(workout.status, WorkoutStatus.stopped(since: .distantPast))
        
        workout.await(asOf: Date(seconds: 40))
        XCTAssertEqual(workout.status, WorkoutStatus.waiting(since: Date(seconds: 40)))
        
        workout.start(asOf: Date(seconds: 10))
        XCTAssertEqual(workout.status, WorkoutStatus.started(since: Date(seconds: 40)))
        
        workout.pause(asOf: Date(seconds: 20))
        XCTAssertEqual(workout.status, WorkoutStatus.paused(since: Date(seconds: 20)))
        
        workout.stop(asOf: Date(seconds: 30))
        XCTAssertEqual(workout.status, WorkoutStatus.stopped(since: Date(seconds: 40)))
    }
    
    func testStatusPaused() throws {
        let workout = Workout(isActiveGetter: {log($0); return nil}, distanceGetter: {log($0); return nil}, bodySensorLocationGetter: {.Other})
        XCTAssertEqual(workout.status, WorkoutStatus.stopped(since: .distantPast))
        
        workout.await(asOf: Date(seconds: 10))
        XCTAssertEqual(workout.status, WorkoutStatus.waiting(since: Date(seconds: 10)))
        
        workout.start(asOf: Date(seconds: 20))
        XCTAssertEqual(workout.status, WorkoutStatus.started(since: Date(seconds: 20)))
        
        workout.pause(asOf: Date(seconds: 30))
        XCTAssertEqual(workout.status, WorkoutStatus.paused(since: Date(seconds: 30)))
        
        workout.start(asOf: Date(seconds: 40))
        XCTAssertEqual(workout.status, WorkoutStatus.started(since: Date(seconds: 40)))
        XCTAssertEqual(workout.startTime,  Date(seconds: 20))
        
        workout.pause(asOf: Date(seconds: 45))
        XCTAssertEqual(workout.status, WorkoutStatus.paused(since: Date(seconds: 45)))
        
        workout.start(asOf: Date(seconds: 50))
        XCTAssertEqual(workout.status, WorkoutStatus.started(since: Date(seconds: 50)))
        XCTAssertEqual(workout.startTime,  Date(seconds: 20))

        workout.stop(asOf: Date(seconds: 60))
        XCTAssertEqual(workout.status, WorkoutStatus.stopped(since: Date(seconds: 60)))
        XCTAssertEqual(workout.endTime,  Date(seconds: 60))
        
        XCTAssertEqual(workout.pauses, [Date(seconds: 30), Date(seconds: 45)])
        XCTAssertEqual(workout.resumes, [Date(seconds: 40), Date(seconds: 50)])
    }
    
    func testMotionType() throws {
        let workout = Workout(
            isActiveGetter: {IsActive(asOf: $0, isActive: true)},
            distanceGetter: {log($0); return nil},
            bodySensorLocationGetter: {.Other})
        workout.await(asOf: Date(seconds: 10))
        workout.start(asOf: Date(seconds: 20))

        workout.changed(motions: [
            Motion(asOf: Date(seconds: 21), motion: MotionType.pause),
            Motion(asOf: Date(seconds: 22), motion: MotionType.running),
            Motion(asOf: Date(seconds: 23), motion: MotionType.walking),
            Motion(asOf: Date(seconds: 24), motion: MotionType.running)
        ], [
            Motion(asOf: Date(seconds: 24), motion: MotionType.unknown)
        ])
        workout.stop(asOf: Date(seconds: 60))
        
        XCTAssertEqual(
            [
                workout.motionTypes[MotionType.unknown],
                workout.motionTypes[MotionType.walking],
                workout.motionTypes[MotionType.running],
                workout.motionTypes[MotionType.cycling],
                workout.motionTypes[MotionType.pause],
                workout.motionTypes[MotionType.invalid]
            ], [-1, 1, 2, nil, 1, nil]
        )
    }
    
    func testDistanceBothExist() throws {
        let distances = [
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 0), speed: 100),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 1.5), speed: 1),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 2.1), speed: 2),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 3), speed: 3)
        ]
        let isActives = [
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 1.6), isActive: true),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 2), isActive: false),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 3), isActive: true)
        ]
        
        let workout = Workout(
            isActiveGetter: {isActives[$0]},
            distanceGetter: {distances[$0]},
            bodySensorLocationGetter: {.Other})
        workout.await(asOf: Date(seconds: 0))
        workout.start(asOf: Date(seconds: 0))

        workout.changed(distances: [distances[1], distances[2], distances[3]], [Distance(asOf: Date(timeIntervalSinceReferenceDate: 3), speed: 0.5)])
        XCTAssertEqual(workout.distance, 3.5)

        workout.stop(asOf: Date(seconds: 60))
    }
    
    func testDistanceDistanceFirst() throws {
        var distances = [
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 0), speed: 100),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 1.5), speed: 1)
        ]
        let isActives = [
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 1.6), isActive: true),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 2), isActive: false),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 3), isActive: true)
        ]
        
        let workout = Workout(
            isActiveGetter: {isActives[$0]},
            distanceGetter: {distances[$0]},
            bodySensorLocationGetter: {.Other})
        workout.await(asOf: Date(seconds: 0))
        workout.start(asOf: Date(seconds: 0))

        workout.changed(isActives: isActives, [])
        XCTAssertEqual(workout.distance, 1.0)

        distances += [
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 2.1), speed: 2),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 3), speed: 3)
        ]
        workout.changed(distances: [distances[2], distances[3]], [])
        XCTAssertEqual(workout.distance, 4.0)

        workout.stop(asOf: Date(seconds: 60))
    }
    
    func testDistanceIsActiveFirst() throws {
        let distances = [
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 0), speed: 100),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 1.5), speed: 1),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 2.1), speed: 2),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 3), speed: 3)
        ]
        var isActives = [
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 1.6), isActive: true)
        ]
        
        let workout = Workout(
            isActiveGetter: {isActives[$0]},
            distanceGetter: {distances[$0]},
            bodySensorLocationGetter: {.Other})
        workout.await(asOf: Date(seconds: 0))
        workout.start(asOf: Date(seconds: 0))

        workout.changed(distances: [distances[1], distances[2], distances[3]], [])
        XCTAssertEqual(workout.distance, 1.0)

        isActives += [
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 2), isActive: false),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 3), isActive: true)
        ]
        workout.changed(isActives: [isActives[1], isActives[2]], [])
        XCTAssertEqual(workout.distance, 4.0)

        workout.stop(asOf: Date(seconds: 60))
    }
    
    func testSaveLoad() throws {
        // TODO: Implement
        let distances = [
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 0), speed: 100),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 1.5), speed: 1),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 2.1), speed: 2),
            Distance(asOf: Date(timeIntervalSinceReferenceDate: 3), speed: 3)
        ]
        let isActives = [
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 1.6), isActive: true),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 2), isActive: false),
            IsActive(asOf: Date(timeIntervalSinceReferenceDate: 3), isActive: true)
        ]
        
        let workout = Workout(
            isActiveGetter: {isActives[$0]},
            distanceGetter: {distances[$0]},
            bodySensorLocationGetter: {.Other})
        workout.await(asOf: Date(seconds: 0))
        workout.start(asOf: Date(seconds: 0))
        workout.changed(distances: [distances[1], distances[2], distances[3]], [Distance(asOf: Date(timeIntervalSinceReferenceDate: 3), speed: 0.5)])

        workout.save()
        let workout2 = Workout(
            isActiveGetter: {isActives[$0]},
            distanceGetter: {distances[$0]},
            bodySensorLocationGetter: {.Other})
        workout.stop(asOf: Date(seconds: 60))

        workout2.load()
        XCTAssertEqual(workout.status, WorkoutStatus.stopped(since: Date(seconds: 60)))
        XCTAssertEqual(workout2.status, WorkoutStatus.started(since: Date(seconds: 0)))
        XCTAssertEqual(workout.distance, workout2.distance)
        
        workout2.stop(asOf: Date(seconds: 60))
    }
}
