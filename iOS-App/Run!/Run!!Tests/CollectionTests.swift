//
//  Run__Tests.swift
//  Run!!Tests
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import XCTest
import CoreLocation
@testable import Run__

class CollectionsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testNgramMapNltCount() throws {
        let array = [1,2,3,4,5,6,7,8,9]
        let result = array.ngram(3)
        
        XCTAssertEqual(result, [[1,2,3], [2,3,4], [3,4,5], [4,5,6], [5,6,7], [6,7,8], [7,8,9]])
    }
    
    func testNgramMapNeqCount() throws {
        let array = [1,2,3,4,5,6,7,8,9]
        let result = array.ngram(array.count)
        
        XCTAssertEqual(result, [[1,2,3,4,5,6,7,8,9]])
    }
    
    func testNgramMapNgtCount() throws {
        let array = [1,2,3,4,5,6,7,8,9]
        let result = array.ngram(array.count + 1)
        
        XCTAssertEqual(result, [])
    }
    
    func testNgramMapEmpty() throws {
        let array = [Int]()
        let result = array.ngram(2)
        
        XCTAssertEqual(result, [])
    }
    
    func testNgramMapN0() throws {
        let array = [1,2,3,4,5,6,7,8,9]
        let result = array.ngram(0)
        
        XCTAssertEqual(result, [])
    }
    
    func testNgramMapN1() throws {
        let array = [1,2,3,4,5,6,7,8,9]
        let result = array.ngram(1)
        
        XCTAssertEqual(result, [[1],[2],[3],[4],[5],[6],[7],[8],[9]])
    }

//
//    // TODO: Testcases
//    // AclTwin (reflected in motions + isActives)
//    // - not allowed
//    // - not available
//    // - return from pause -> bulk motions: 0, 1, more
//    // - start
//    // - receive motion
//    // - stop
//    
//    // HrmTwin (reflected in heartrates + intensities)
//    // - not allowed
//    // - not available
//    // - start
//    // - receive heartrate
//    // - stop
//    
//    // GpsTwin (reflected in locations + distances)
//    // - not allowed
//    // - not available
//    // - start
//    // - receive location: First, next
//    // - stop
//    
//    // RunTimer (reflected in all collections)
//    // - start
//    // - stop and restart
//    // - time elapses
//    
//    // User
//    // - starts App
//    // - sends app to background
//    // - brings app to foreground
//
//    func testMotions() throws {
//        let workout = Workout(isActiveGetter: {_ in nil}, distanceGetter: {_ in nil}, bodySensorLocationGetter: {.Chest})
//        let totals = Totals(motionGetter: {_ in nil}, isActiveGetter: {_ in nil}, heartrateGetter: {_ in nil}, intensityGetter: {_ in nil}, distanceGetter: {_ in nil}, workout: workout)
//        let isActives = IsActives(workout: workout)
//        let motions = Motions(isActives: isActives, workout: workout, totals: totals)
//        
//        // Let it run before first acl motion
//        motions.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10000.5))
//        XCTAssertTrue(motions.motions.isEmpty)
//        XCTAssertNil(motions.latestOriginal)
//        XCTAssertTrue(isActives.isActives.isEmpty)
//        XCTAssertEqual(workout.status, .stopped(since: .distantPast))
//        workout.await(asOf: .distantPast)
//
//        // Add some originals
//        motions.appendOriginal(motion: Motion(asOf: Date(timeIntervalSinceReferenceDate: 10010.5), motion: .unknown))
//        motions.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10012.5))
//        motions.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10015.5))
//        motions.appendOriginal(motion: Motion(asOf: Date(timeIntervalSinceReferenceDate: 10014.3), motion: .walking))
//        motions.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10016.5))
//        motions.appendOriginal(motion: Motion(asOf: Date(timeIntervalSinceReferenceDate: 10020.2), motion: .running))
//        XCTAssertEqual(
//            motions.motions,
//            [
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10010.5), motion: .unknown),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10011), motion: .unknown),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10012), motion: .unknown),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10013), motion: .unknown),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10014.3), motion: .walking),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10015), motion: .walking),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10016), motion: .walking),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10017), motion: .walking),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10018), motion: .walking),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10019), motion: .walking),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10020.2), motion: .running)
//            ])
//        XCTAssertEqual(
//            isActives.isActives,
//            [
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10010.5), isActive: false),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10011), isActive: false),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10012), isActive: false),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10013), isActive: false),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10014.3), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10015), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10016), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10017), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10018), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10019), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10020.2), isActive: true)
//            ])
//        XCTAssertEqual(workout.status, .started(since: Date(timeIntervalSinceReferenceDate: 10014.3)))
//        
//        // Do maintenance
//        motions.maintain(truncateAt: Date(timeIntervalSinceReferenceDate: 10016.5))
//        XCTAssertEqual(
//            motions.motions,
//            [
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10017), motion: .walking),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10018), motion: .walking),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10019), motion: .walking),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10020.2), motion: .running)
//            ])
//        XCTAssertEqual(
//            isActives.isActives,
//            [
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10017), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10018), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10019), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10020.2), isActive: true)
//            ])
//        XCTAssertEqual(workout.status, .started(since: Date(timeIntervalSinceReferenceDate: 10014.3)))
//
//        // save + load
//        motions.save()
//        isActives.save()
//        
//        let workout2 = Workout(isActiveGetter: {_ in nil}, distanceGetter: {_ in nil}, bodySensorLocationGetter: {.Chest})
//        let totals2 = Totals(motionGetter: {_ in nil}, isActiveGetter: {_ in nil}, heartrateGetter: {_ in nil}, intensityGetter: {_ in nil}, distanceGetter: {_ in nil}, workout: workout)
//        let isActives2 = IsActives(workout: workout2)
//        let motions2 = Motions(isActives: isActives2, workout: workout2, totals: totals2)
//        motions2.load(asOf: Date(timeIntervalSinceReferenceDate: 0))
//        isActives2.load(asOf: Date(timeIntervalSinceReferenceDate: 0))
//        
//        XCTAssertEqual(
//            motions.motions,
//            [
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10017), motion: .walking),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10018), motion: .walking),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10019), motion: .walking),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10020.2), motion: .running)
//            ])
//        XCTAssertEqual(
//            isActives.isActives,
//            [
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10017), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10018), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10019), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10020.2), isActive: true)
//            ])
//        XCTAssertEqual(workout.status, .started(since: Date(timeIntervalSinceReferenceDate: 10014.3)))
//        
//        XCTAssertEqual(
//            motions2.motions.map {Int($0.asOf.timeIntervalSinceReferenceDate * 10)},
//            motions.motions.map {Int($0.asOf.timeIntervalSinceReferenceDate * 10)})
//        XCTAssertEqual(
//            motions2.motions.map {$0.motion},
//            motions.motions.map {$0.motion})
//        XCTAssertEqual(
//            isActives2.isActives.map {Int($0.asOf.timeIntervalSinceReferenceDate * 10)},
//            isActives.isActives.map {Int($0.asOf.timeIntervalSinceReferenceDate * 10)})
//        XCTAssertEqual(
//            isActives2.isActives.map {$0.isActive},
//            isActives.isActives.map {$0.isActive})
//        XCTAssertEqual(workout2.status, .stopped(since: .distantPast))
//    }
//
//    func testHeartrates() throws {
//        let workout = Workout(isActiveGetter: {_ in nil}, distanceGetter: {_ in nil}, bodySensorLocationGetter: {.Chest})
//        let totals = Totals(motionGetter: {_ in nil}, isActiveGetter: {_ in nil}, heartrateGetter: {_ in nil}, intensityGetter: {_ in nil}, distanceGetter: {_ in nil}, workout: workout)
//        let intensities = Intensities()
//        let heartrates = Heartrates(intensities: intensities, workout: workout, totals: totals)
//        Profile.hrLimits.onAppear()
//        Profile.hrLimits.onChange(to: [.Cold : 0 ..< 110, .Easy: 110 ..< 120, .Marathon: 120 ..< 150])
//
//        // Let it run before first hrm heartrate
//        heartrates.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10000.5))
//        XCTAssertTrue(heartrates.heartrates.isEmpty)
//        XCTAssertNil(heartrates.latestOriginal)
//        XCTAssertEqual(intensities.intensities, [Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10000.5), intensity: .Cold)])
//
//        // Add some originals
//        heartrates.appendOriginal(heartrate: Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10010.5), heartrate: 100))
//        heartrates.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10012.5))
//        heartrates.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10015.5))
//        heartrates.appendOriginal(heartrate: Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10014.3), heartrate: 120))
//        heartrates.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10016.5))
//        heartrates.appendOriginal(heartrate: Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10020.2), heartrate: 150))
//        heartrates.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10022.5))
//        XCTAssertEqual(
//            heartrates.heartrates, [
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10010.5), heartrate: 100),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10011), heartrate: 103),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10012), heartrate: 108),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10013), heartrate: 113),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10014.3), heartrate: 120),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10015), heartrate: 124),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10016), heartrate: 129),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10017), heartrate: 134),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10018), heartrate: 139),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10019), heartrate: 144),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10020.2), heartrate: 150),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10021), heartrate: 150),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10022), heartrate: 150)
//            ])
//        
//        print(intensities.intensities.map {($0.asOf.timeIntervalSinceReferenceDate, $0.intensity)})
//        XCTAssertEqual(
//            intensities.intensities, [
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10000.5), intensity: .Cold),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10010.5), intensity: .Cold),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10011), intensity: .Cold),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10012), intensity: .Cold),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10013), intensity: .Easy),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10014.3), intensity: .Marathon),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10015), intensity: .Marathon),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10016), intensity: .Marathon),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10017), intensity: .Marathon),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10018), intensity: .Marathon),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10019), intensity: .Marathon),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10020.2), intensity: .Repetition),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10021), intensity: .Repetition),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10022), intensity: .Repetition)
//            ])
//        
//        // Do maintenance
//        heartrates.maintain(truncateAt: Date(timeIntervalSinceReferenceDate: 10016.5))
//
//        XCTAssertEqual(
//            heartrates.heartrates, [
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10017), heartrate: 134),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10018), heartrate: 139),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10019), heartrate: 144),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10020.2), heartrate: 150),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10021), heartrate: 150),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10022), heartrate: 150)
//            ])
//        
//        XCTAssertEqual(
//            intensities.intensities, [
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10017), intensity: .Marathon),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10018), intensity: .Marathon),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10019), intensity: .Marathon),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10020.2), intensity: .Repetition),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10021), intensity: .Repetition),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10022), intensity: .Repetition)
//            ])
//
//        // save + load
//        heartrates.save()
//        intensities.save()
//        
//        let intensities2 = Intensities()
//        let heartrates2 = Heartrates(intensities: intensities2, workout: workout, totals: totals)
//        heartrates2.load(asOf: Date(timeIntervalSinceReferenceDate: 0))
//        intensities2.load(asOf: Date(timeIntervalSinceReferenceDate: 0))
//
//        XCTAssertEqual(
//            heartrates.heartrates, [
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10017), heartrate: 134),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10018), heartrate: 139),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10019), heartrate: 144),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10020.2), heartrate: 150),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10021), heartrate: 150),
//                Heartrate(asOf: Date(timeIntervalSinceReferenceDate: 10022), heartrate: 150)
//            ])
//        
//        XCTAssertEqual(
//            intensities.intensities, [
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10017), intensity: .Marathon),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10018), intensity: .Marathon),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10019), intensity: .Marathon),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10020.2), intensity: .Repetition),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10021), intensity: .Repetition),
//                Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10022), intensity: .Repetition)
//            ])
//
//        XCTAssertEqual(
//            heartrates2.heartrates.map {Int($0.timestamp.timeIntervalSinceReferenceDate * 10)},
//            heartrates.heartrates.map {Int($0.timestamp.timeIntervalSinceReferenceDate * 10)})
//        XCTAssertEqual(
//            heartrates2.heartrates.map {$0.heartrate},
//            heartrates.heartrates.map {$0.heartrate})
//        XCTAssertEqual(
//            intensities2.intensities.map {Int($0.asOf.timeIntervalSinceReferenceDate * 10)},
//            intensities.intensities.map {Int($0.asOf.timeIntervalSinceReferenceDate * 10)})
//        XCTAssertEqual(
//            intensities2.intensities.map {$0.intensity},
//            intensities.intensities.map {$0.intensity})
//    }
//
//    func testLocations() throws {
//        func l(_ asOf: Date) -> CLLocation {
//            CLLocation(
//                coordinate: CLLocationCoordinate2D(
//                    latitude: CLLocationDegrees(Int(asOf.timeIntervalSince1970) % 360),
//                    longitude: CLLocationDegrees(Int(asOf.timeIntervalSinceReferenceDate) % 360)),
//                altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: asOf)
//        }
//        
//        let workout = Workout(isActiveGetter: {_ in nil}, distanceGetter: {_ in nil}, bodySensorLocationGetter: {.Chest})
//        let totals = Totals(motionGetter: {_ in nil}, isActiveGetter: {_ in nil}, heartrateGetter: {_ in nil}, intensityGetter: {_ in nil}, distanceGetter: {_ in nil}, workout: workout)
//        let distances = Distances(workout: workout, totals: totals)
//        let locations = Locations(distances: distances, workout: workout, totals: totals)
//
//        // Let it run before first hrm heartrate
//        distances.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10000.5))
//        XCTAssertTrue(locations.locations.isEmpty)
//        XCTAssertNil(locations.latestOriginal)
//        XCTAssertTrue(distances.distances.isEmpty)
//
//        // Add some originals
//        locations.appendOriginal(location: Location(l(Date(timeIntervalSinceReferenceDate: 10010.5))))
//        distances.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10012.5))
//        distances.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10015.5))
//        locations.appendOriginal(location: Location(l(Date(timeIntervalSinceReferenceDate: 10014.3))))
//        distances.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10016.5))
//        locations.appendOriginal(location: Location(l(Date(timeIntervalSinceReferenceDate: 10020.5))))
//        distances.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10022.5))
//        XCTAssertEqual(locations.locations.map {$0.timestamp.timeIntervalSinceReferenceDate}, [10010.5, 10014.3, 10020.5])
//        XCTAssertEqual(
//            distances.distances.map {$0.asOf.timeIntervalSinceReferenceDate},
//            [10010.5, 10011,10012,10013,10014.3,10015,10016,10017,10018,10019,10020.5,10021,10022])
//
//        // Do maintenance
//        locations.maintain(truncateAt: Date(timeIntervalSinceReferenceDate: 10016.5))
//        XCTAssertEqual(locations.locations.map {$0.timestamp.timeIntervalSinceReferenceDate}, [10020.5])
//        XCTAssertEqual(
//            distances.distances.map {$0.asOf.timeIntervalSinceReferenceDate},
//            [10017,10018,10019,10020.5,10021,10022])
//
//        // save + load
//        locations.save()
//        distances.save()
//        
//        let distances2 = Distances(workout: workout, totals: totals)
//        let locations2 = Locations(distances: distances2, workout: workout, totals: totals)
//        locations2.load(asOf: Date(timeIntervalSinceReferenceDate: 0))
//        distances2.load(asOf: Date(timeIntervalSinceReferenceDate: 0))
//
//        XCTAssertEqual(locations.locations.map {$0.timestamp.timeIntervalSinceReferenceDate}, [10020.5])
//        XCTAssertEqual(
//            distances.distances.map {$0.asOf.timeIntervalSinceReferenceDate},
//            [10017,10018,10019,10020.5,10021,10022])
//
//        XCTAssertEqual(locations2.locations, locations.locations)
//        XCTAssertEqual(distances2.distances, distances.distances)
//    }
//    
//    func testAclNotA() throws {
//        let workout = Workout(isActiveGetter: {_ in nil}, distanceGetter: {_ in nil}, bodySensorLocationGetter: {.Chest})
//        let totals = Totals(motionGetter: {_ in nil}, isActiveGetter: {_ in nil}, heartrateGetter: {_ in nil}, intensityGetter: {_ in nil}, distanceGetter: {_ in nil}, workout: workout)
//        let isActives = IsActives(workout: workout)
//        let motions = Motions(isActives: isActives, workout: workout, totals: totals)
//        
//        // Let it run before first acl motion
//        motions.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10000.5))
//        XCTAssertTrue(motions.motions.isEmpty)
//        XCTAssertNil(motions.latestOriginal)
//        XCTAssertTrue(isActives.isActives.isEmpty)
//        XCTAssertEqual(workout.status, .stopped(since: .distantPast))
//        workout.await(asOf: .distantPast)
//
//        // ACL notcies about ist inablitiy to deliver
//        motions.appendOriginal(motion: Motion(asOf: Date(timeIntervalSinceReferenceDate: 10010.5), motion: .invalid))
//        motions.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10012.5))
//
//        XCTAssertEqual(
//            motions.motions,
//            [
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10010.5), motion: .invalid),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10011), motion: .invalid),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10012), motion: .invalid)
//            ])
//        XCTAssertEqual(
//            isActives.isActives,
//            [
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10010.5), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10011), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10012), isActive: true)
//            ])
//        XCTAssertEqual(workout.status, .started(since: Date(timeIntervalSinceReferenceDate: 10010.5)))
//        
//        // User ends workout
//        workout.stop(asOf: Date(timeIntervalSinceReferenceDate: 10015))
//        XCTAssertEqual(workout.status, .stopped(since: Date(timeIntervalSinceReferenceDate: 10015)))
//        workout.await(asOf: Date(timeIntervalSinceReferenceDate: 10016))
//        
//        // Clock ticks
//        motions.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10017.5))
//        XCTAssertEqual(
//            motions.motions,
//            [
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10010.5), motion: .invalid),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10011), motion: .invalid),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10012), motion: .invalid),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10013), motion: .invalid),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10014), motion: .invalid),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10015), motion: .invalid),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10016), motion: .invalid),
//                Motion(asOf: Date(timeIntervalSinceReferenceDate: 10017), motion: .invalid)
//            ])
//        XCTAssertEqual(
//            isActives.isActives,
//            [
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10010.5), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10011), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10012), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10013), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10014), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10015), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10016), isActive: true),
//                IsActive(asOf: Date(timeIntervalSinceReferenceDate: 10017), isActive: true)
//            ])
//        XCTAssertEqual(workout.status, .started(since: Date(timeIntervalSinceReferenceDate: 10016)))
//    }
//
//    func testGpsNotA() throws {
//        let workout = Workout(isActiveGetter: {_ in nil}, distanceGetter: {_ in nil}, bodySensorLocationGetter: {.Chest})
//        let totals = Totals(motionGetter: {_ in nil}, isActiveGetter: {_ in nil}, heartrateGetter: {_ in nil}, intensityGetter: {_ in nil}, distanceGetter: {_ in nil}, workout: workout)
//        let distances = Distances(workout: workout, totals: totals)
//        let locations = Locations(distances: distances, workout: workout, totals: totals)
//        
//        // Let it run before first gps location
//        distances.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10000.5))
//        XCTAssertTrue(locations.locations.isEmpty)
//        XCTAssertNil(locations.latestOriginal)
//        XCTAssertTrue(distances.distances.isEmpty)
//
//        // GPS does not notcie about its inablity to deliver, but time ticks
//        distances.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10012.5))
//        XCTAssertTrue(locations.locations.isEmpty)
//        XCTAssertTrue(distances.distances.isEmpty)
//    }
//
//    func testHrmNotA() throws {
//        let workout = Workout(isActiveGetter: {_ in nil}, distanceGetter: {_ in nil}, bodySensorLocationGetter: {.Chest})
//        let totals = Totals(motionGetter: {_ in nil}, isActiveGetter: {_ in nil}, heartrateGetter: {_ in nil}, intensityGetter: {_ in nil}, distanceGetter: {_ in nil}, workout: workout)
//        let intensities = Intensities()
//        let heartrates = Heartrates(intensities: intensities, workout: workout, totals: totals)
//        
//        // Let it run before first hrm heartrate
//        heartrates.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10000.5))
//        XCTAssertTrue(heartrates.heartrates.isEmpty)
//        XCTAssertNil(heartrates.latestOriginal)
//        XCTAssertEqual(intensities.intensities, [Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10000.5), intensity: .Cold)])
//
//        // HRM does not notice about its inablity to deliver, but time ticks
//        heartrates.trigger(asOf: Date(timeIntervalSinceReferenceDate: 10002.5))
//        XCTAssertTrue(heartrates.heartrates.isEmpty)
//        XCTAssertNil(heartrates.latestOriginal)
//        XCTAssertEqual(intensities.intensities, [
//            Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10000.5), intensity: .Cold),
//            Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10001), intensity: .Cold),
//            Intensity(asOf: Date(timeIntervalSinceReferenceDate: 10002), intensity: .Cold)
//        ])
//    }
//    
//    private func waitForMain() {
//        let expectation = XCTestExpectation()
//        
//        DispatchQueue.main.async {
//            expectation.fulfill()
//        }
//        
//        wait(for: [expectation], timeout: 10)
//    }
}

