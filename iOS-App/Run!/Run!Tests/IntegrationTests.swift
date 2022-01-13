//
//  IntegrationTests.swift
//  Run!Tests
//
//  Created by Jürgen Boiselle on 21.11.21.
//

import XCTest
@testable import Run_
import CoreMotion
import CoreBluetooth
import CoreLocation

// DONE: (Today) Minimize collect and compare functions to work/notwork switches
// DONE: (This week) Manually create expected values via Excel. Drop collect functions
// DONE: (Today) Add tests for only one producer is working
// DONE: (Today) Merge path service test here
// DONE: (Next week) Attributes with dependencies
// DONE: In Acl-only data, missing about 100 seconds of initial .unknown in totals
// DONE: Keep hr limits dynamic
// DONE: Some vdots are nan even with all other values given
// TODO: (Next week) Add performance tests
// TODO: (Next week) Create UI Tests from Gallery. Try TDD approach.
// TODO: (Next week) Add more UI-Elements and views

class IntegrationTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        print(" --- SET UP --- ")
        print(PathService.sharedInstance.path.count)
        print(HrGraphService.sharedInstance.graph.count)
        print(CurrentsService.sharedInstance.isActive.isActive)
        print(TotalsService.sharedInstance.totals.count)
        print(ProfileService.sharedInstance.birthday.value ?? .distantPast)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        print(" --- TEAR DOWN --- ")
    }
    
    /**
     Create some integration tests for:
     - Normal operations: GPS, BLE and ACL are allowed and working (1 case)
     - One case were each is dis-allowed, but the rest is allowed (3 cases)
     - One case were each is not working, but the rest is allowed (3 cases)
     - One case were one is allowed, but the rest is not (3 cases)
     - One case were one is working, but the rest is not (3 cases)
     - Minimal operations: Non is allowed (1 case)
     - Minimal operations: Non is working (1 case)
     
     All cases get the same data:
     - Locations taken from a downloaded track
     - Timstamps to be added
     - Heartrates every second
     - Active/inActive events, changing from pause to walk, run, cycle, pause, run, pause.
     */
    
    struct MA: MotionActivityProtocol {
        static var canUse: Bool = true
        
        init(
            startDate: Date,
            stationary: Bool,
            walking: Bool,
            running: Bool,
            cycling: Bool,
            confidence: CMMotionActivityConfidence)
        {
            self.startDate = startDate
            self.stationary = stationary
            self.walking = walking
            self.running = running
            self.cycling = cycling
            self.confidence = confidence
        }
        
        init(startDate: Date, ma: MA) {
            self.startDate = startDate
            self.stationary = ma.stationary
            self.walking = ma.walking
            self.running = ma.running
            self.cycling = ma.cycling
            self.confidence = ma.confidence
        }
        
        let startDate: Date
        let stationary: Bool
        let walking: Bool
        let running: Bool
        let cycling: Bool
        let confidence: CMMotionActivityConfidence
    }

    let motions = [
        MA( startDate: Date(),
            stationary: true,
            walking: false,
            running: false,
            cycling: false,
            confidence: .high),
        MA( startDate: Date(),
            stationary: false,
            walking: true,
            running: false,
            cycling: false,
            confidence: .high),
        MA( startDate: Date(),
            stationary: false,
            walking: false,
            running: true,
            cycling: false,
            confidence: .high),
        MA( startDate: Date(),
            stationary: false,
            walking: false,
            running: false,
            cycling: true,
            confidence: .high)
    ]
    
    // Locations are injected every 30 seconds
    // HR changes every second by 2. Starting at lower limit, up to upper limit and then -2 back.
    // Activities are created round robin every 5 minutes changing. Starting with paused. They come in a second delayed

    // MARK: - Simulate
    
    class BP: BleProducerProtocol {
        static let sharedInstance: BleProducerProtocol = BP()
        static var working: Bool = true

        private var config: BleProducer.Config?
        private let uuid = UUID()
        
        fileprivate func inject(heartrate: Int, at: Date) {
            guard BP.working else {return}
            config?.readers[CBUUID(string: "2A37")]?(uuid, Data([UInt8(0x00), UInt8(heartrate)]), at)
        }

        func start(config: BleProducer.Config, asOf: Date, transientFailedPeripheralUuid: UUID?) {
            self.config = config
            config.status(BP.working ? .started(asOf: asOf) : .notAuthorized(asOf: asOf))
        }

        func stop() {config?.status(.stopped)}
        func pause() {config?.status(.paused)}
        func resume() {config?.status(.resumed)}

        func readValue(_ peripheralUuid: UUID, _ characteristicUuid: CBUUID) {}
        func writeValue(_ peripheralUuid: UUID, _ characteristicUuid: CBUUID, _ data: Data) {}
        func setNotifyValue(_ peripheralUuid: UUID, _ characteristicUuid: CBUUID, _ notify: Bool) {}
    }
    
    class AP: AclProducerProtocol {
        static let sharedInstance: AclProducerProtocol = AP()
        static var working: Bool = true

        private var value: ((MotionActivityProtocol) -> Void)?
        private var status: ((AclProducer.Status) -> Void)?

        fileprivate func inject(_ motion: MotionActivityProtocol) {
            if AP.working {value?(motion)}
        }
        
        func start(
            value: @escaping (MotionActivityProtocol) -> Void,
            status: @escaping (AclProducer.Status) -> Void,
            asOf: Date)
        {
            self.value = value
            self.status = status
            status(AP.working ? .started(asOf: asOf) : .notAuthorized(asOf: asOf))
        }
        
        func stop() {status?(.stopped)}
        func pause() {status?(.paused)}
        func resume() {status?(.resumed)}
    }
    
    class GP: GpsProducerProtocol {
        static let sharedInstance: GpsProducerProtocol = GP()
        static var working: Bool = true

        private var value: ((CLLocation) -> Void)?
        private var status: ((GpsProducer.Status) -> Void)?
        
        fileprivate func inject(_ location: CLLocation) {if GP.working {value?(location)}}
        
        func start(
            value: @escaping (CLLocation) -> Void,
            status: @escaping (GpsProducer.Status) -> Void,
            asOf: Date)
        {
            self.value = value
            self.status = status
            status(GP.working ? .started(asOf: asOf) : .notAuthorized(asOf: asOf))
        }
        
        func stop() {status?(.stopped)}
        func pause() {status?(.paused)}
        func resume() {status?(.resumed)}
    }
    
    private func loop(
        aclProducer: AclProducerProtocol,
        bleProducer: BleProducerProtocol,
        gpsProducer: GpsProducerProtocol,
        work: (TimeInterval) throws -> Void) rethrows
    {
        // Start the engine
        ProfileService.sharedInstance.onAppear()
        ProfileService.sharedInstance.hrMax.onChange(to: 181)
        ProfileService.sharedInstance.hrResting.onChange(to: 40)
    
        try work(Date.distantPast.timeIntervalSince1970)

        RunService.sharedInstance.start(
            producer: RunService.Producer(
                aclProducer: aclProducer,
                bleProducer: bleProducer,
                gpsProducer: gpsProducer),
                asOf: Date(timeIntervalSince1970: 0))
        try work(0)

        // loop through actions
        for action in actions {
            switch action {
            case .location(let seconds, let latitude, let longitude):
                let location = CLLocation(
                    coordinate: CLLocationCoordinate2D(
                        latitude: latitude,
                        longitude: longitude),
                    altitude: 0,
                    horizontalAccuracy: 0,
                    verticalAccuracy: 0,
                    timestamp: Date(timeIntervalSince1970: seconds))
                (GP.sharedInstance as! GP).inject(location)
                try work(seconds)
            case .heartrate(let seconds, let heartrate):
                (BP.sharedInstance as! BP)
                    .inject(heartrate: heartrate, at: Date(timeIntervalSince1970: seconds))
                try work(seconds)
            case .motion(let seconds, let idx):
                (AP.sharedInstance as! AP).inject(
                    MA( startDate: Date(timeIntervalSince1970: seconds), ma: motions[idx]))
                try work(seconds)
            }
        }
        
        // The end
        RunService.sharedInstance.stop()
        try work(Date.distantFuture.timeIntervalSince1970)
    }
    
    // MARK: - Test Cases
    
    func testHrGraphService() throws {
        // Collects hr as a graph, the totals of avg-hr per intensity, up to date and can read/write on disk
        // Data is collected from RunService, ble-producer and derived intensity-producer
        MA.canUse = true
        AP.working = true
        BP.working = true
        GP.working = true
        ProfileService.sharedInstance.onAppear()
        ProfileService.sharedInstance.hrMax.onChange(to: 181)
        ProfileService.sharedInstance.hrResting.onChange(to: 40)
        ProfileService.sharedInstance.hrLimits.onAppear()
        print(try XCTUnwrap(ProfileService.sharedInstance.hrLimits.value))

        // Must access elements to ensure, they're created
        print(HrGraphService.sharedInstance.graph.isEmpty)
        print(HrGraphService.sharedInstance.hrSecs.isEmpty)

        RunService.sharedInstance.start(
            producer: RunService.Producer(
                aclProducer: AP.sharedInstance,
                bleProducer: BP.sharedInstance,
                gpsProducer: GP.sharedInstance),
            asOf: Date(timeIntervalSince1970: 0))
        
        XCTAssertEqual(HrGraphService.sharedInstance.graph.count, 1)
        XCTAssertTrue(HrGraphService.sharedInstance.hrSecs.isEmpty)

        (BP.sharedInstance as! BP).inject(heartrate: 48, at: Date(timeIntervalSince1970: 60))
        (BP.sharedInstance as! BP).inject(heartrate: 64, at: Date(timeIntervalSince1970: 120))
        (BP.sharedInstance as! BP).inject(heartrate: 160, at: Date(timeIntervalSince1970: 180))
        (BP.sharedInstance as! BP).inject(heartrate: 240, at: Date(timeIntervalSince1970: 240))
        (BP.sharedInstance as! BP).inject(heartrate: 240, at: Date(timeIntervalSince1970: 300))

        print(HrGraphService.sharedInstance.graph)
        XCTAssertEqual(
            HrGraphService.sharedInstance.graph.compactMap {$0.heartrate},
            [48, 64, 64, 160, 240, 240])
        XCTAssertEqual(
            HrGraphService.sharedInstance.graph.compactMap {$0.intensity},
            [.Cold, .Cold, .Cold, .Marathon, .Marathon, .Repetition, .Repetition])
        
        XCTAssertEqual(HrGraphService.sharedInstance.hrSecs.count, 3)
        XCTAssertNotNil(HrGraphService.sharedInstance.hrSecs[.Cold])
        XCTAssertNotNil(HrGraphService.sharedInstance.hrSecs[.Marathon])
        XCTAssertNotNil(HrGraphService.sharedInstance.hrSecs[.Repetition])
        
        // Up to date
        var x1 = HrGraphService.sharedInstance.hrSecs(upTo: Date(timeIntervalSince1970: 1000))
        x1[.Repetition] = HrGraphService.HrTotal(
            duration: (x1[.Repetition]?.duration ?? 0) + 10,
            sumHeartrate: (x1[.Repetition]?.sumHeartrate ?? 0) + 2400)
        let x2 = HrGraphService.sharedInstance.hrSecs(upTo: Date(timeIntervalSince1970: 1010))
        XCTAssertEqual(x1.count, x2.count)
        XCTAssertEqual(x1.map {$0.value.sumHeartrate}.sorted(), x2.map {$0.value.sumHeartrate}.sorted())
        XCTAssertEqual(x1.map {$0.value.duration}.sorted(), x2.map {$0.value.duration}.sorted())
        
        // Does read/write work?
        RunService.sharedInstance.pause() // save
        
        let x3 = HrGraphService.sharedInstance.graph
        (BP.sharedInstance as! BP).inject(heartrate: 0x30, at: Date(timeIntervalSince1970: 2000))
        XCTAssertNotEqual(x3.count, HrGraphService.sharedInstance.graph.count) // changed
        
        RunService.sharedInstance.resume() // restore
        XCTAssertEqual(
            HrGraphService.sharedInstance.graph.compactMap {$0.heartrate},
            [48, 64, 64, 160, 240, 240])
        XCTAssertEqual(
            HrGraphService.sharedInstance.graph.compactMap {$0.intensity},
            [.Cold, .Cold, .Cold, .Marathon, .Marathon, .Repetition, .Repetition])
    }
    
    func testPathService() throws {
        // Is expected to produce a path, where each element contains all locations, an avg-location and a flag to indicate activity
        // Ranges must be without gaps or overlaps from -inf to +inf. Some elements empty/without locations
        MA.canUse = true
        AP.working = true
        BP.working = true
        GP.working = true

        // Must access elements to ensure, they're created
        print(PathService.sharedInstance.path.isEmpty)
        
        RunService.sharedInstance.start(
            producer: RunService.Producer(
                aclProducer: AP.sharedInstance,
                bleProducer: BP.sharedInstance,
                gpsProducer: GP.sharedInstance),
            asOf: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(PathService.sharedInstance.path.first?.range, Date(timeIntervalSince1970: 0) ..< .distantFuture)

        // Collect results
        (GP.sharedInstance as! GP).inject(CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 1,
                longitude: 1),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date(timeIntervalSince1970: 500)))
        (GP.sharedInstance as! GP).inject(CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 2,
                longitude: 2),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date(timeIntervalSince1970: 1500)))
        (GP.sharedInstance as! GP).inject(CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 3,
                longitude: 3),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date(timeIntervalSince1970: 1700)))
        (GP.sharedInstance as! GP).inject(CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 4,
                longitude: 4),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date(timeIntervalSince1970: 2000)))
        (GP.sharedInstance as! GP).inject(CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 5,
                longitude: 5),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date(timeIntervalSince1970: 2500)))
        XCTAssertEqual(PathService.sharedInstance.path.map {$0.range}, [
            Date(timeIntervalSince1970: 0) ..< .distantFuture
        ])
        XCTAssertEqual(
            PathService.sharedInstance.path.compactMap {$0.isActive?.isActive},
            [false])
        XCTAssertEqual(
            PathService.sharedInstance.path.map {$0.locations.count},
            [5])

        (AP.sharedInstance as! AP).inject(MA(
            startDate: Date(timeIntervalSince1970: 1000),
            stationary: false, walking: false, running: true, cycling: false,
            confidence: .high))
        (AP.sharedInstance as! AP).inject(MA(
            startDate: Date(timeIntervalSince1970: 2000),
            stationary: true, walking: false, running: false, cycling: false,
            confidence: .high))
        XCTAssertEqual(PathService.sharedInstance.path.map {$0.range}, [
            Date(timeIntervalSince1970: 0) ..< Date(timeIntervalSince1970: 1000),
            Date(timeIntervalSince1970: 1000) ..< Date(timeIntervalSince1970: 2000),
            Date(timeIntervalSince1970: 2000) ..< .distantFuture
        ])
        XCTAssertEqual(
            PathService.sharedInstance.path.compactMap {$0.isActive?.isActive},
            [false, true, false])
        XCTAssertEqual(
            PathService.sharedInstance.path.map {$0.locations.count},
            [1,2,2])

        (AP.sharedInstance as! AP).inject(MA(
            startDate: Date(timeIntervalSince1970: 2200),
            stationary: false, walking: false, running: true, cycling: false,
            confidence: .high))
        (AP.sharedInstance as! AP).inject(MA(
            startDate: Date(timeIntervalSince1970: 2700),
            stationary: true, walking: false, running: false, cycling: false,
            confidence: .high))
        XCTAssertEqual(PathService.sharedInstance.path.map {$0.range}, [
            Date(timeIntervalSince1970: 0) ..< Date(timeIntervalSince1970: 1000),
            Date(timeIntervalSince1970: 1000) ..< Date(timeIntervalSince1970: 2000),
            Date(timeIntervalSince1970: 2000) ..< Date(timeIntervalSince1970: 2200),
            Date(timeIntervalSince1970: 2200) ..< Date(timeIntervalSince1970: 2700),
            Date(timeIntervalSince1970: 2700) ..< .distantFuture
        ])
        XCTAssertEqual(
            PathService.sharedInstance.path.compactMap {$0.isActive?.isActive},
            [false, true, false, true, false])
        XCTAssertEqual(
            PathService.sharedInstance.path.map {$0.locations.count},
            [1,2,1,1,0])
        
        let p1 = PathService.sharedInstance.path[1]
        XCTAssertEqual(p1.avgLocation?.coordinate.latitude, 2.5)
        XCTAssertEqual(p1.avgLocation?.coordinate.longitude, 2.5)
        
        // Does read/write work?
        RunService.sharedInstance.pause()
        let x3 = PathService.sharedInstance.path
        (GP.sharedInstance as! GP).inject(CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 5,
                longitude: 5),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date(timeIntervalSince1970: 3000)))
        (GP.sharedInstance as! GP).inject(CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 5,
                longitude: 5),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date(timeIntervalSince1970: 3500)))
        XCTAssertNotEqual(
            x3.map {$0.locations.count},
            PathService.sharedInstance.path.map {$0.locations.count})
        RunService.sharedInstance.resume()
        XCTAssertEqual(
            PathService.sharedInstance.path.compactMap {$0.isActive?.isActive},
            [false, true, false, true, false])
        XCTAssertEqual(
            x3.map {$0.locations.count},
            PathService.sharedInstance.path.map {$0.locations.count})
    }
    
    private func collector(
        _ apWorking: Bool, _ bpWorking: Bool, _ gpWorking: Bool,
        expectedSeconds: [TimeInterval], expectedHeartrates: [Int],
        expectedIntensities: [Intensity], expectedIsActives: [Bool],
        expectedTypes: [IsActiveProducer.ActivityType],
        expectedSpeeds: [TimeInterval], expectedAclStatus: [AclProducer.Status],
        expectedBleStatus: [BleProducer.Status], expectedGpsStatus: [GpsProducer.Status],
        expectedTotals: [TotalsService.Total]) throws
    {
        MA.canUse = apWorking
        AP.working = apWorking
        BP.working = bpWorking
        GP.working = gpWorking

        var collectedSeconds = [TimeInterval]()
        var collectedHeartrates = [Int]()
        var collectedIntensities = [Intensity]()
        var collectedIsActives = [Bool]()
        var collectedTypes = [IsActiveProducer.ActivityType]()
        var collectedSpeeds = [TimeInterval]()
        var collectedAclStatus = [AclProducer.Status]()
        var collectedBleStatus = [BleProducer.Status]()
        var collectedGpsStatus = [GpsProducer.Status]()

        loop(
            aclProducer: AP.sharedInstance,
            bleProducer: BP.sharedInstance,
            gpsProducer: GP.sharedInstance)
        {
            if $0 == Date.distantPast.timeIntervalSince1970 {return}
            
            collectedSeconds.append($0)
            collectedHeartrates.append(CurrentsService.sharedInstance.heartrate.heartrate)
            collectedIntensities.append(CurrentsService.sharedInstance.intensity.intensity)
            collectedIsActives.append(CurrentsService.sharedInstance.isActive.isActive)
            collectedTypes.append(CurrentsService.sharedInstance.isActive.type)
            collectedSpeeds.append(CurrentsService.sharedInstance.speed.speedMperSec)
            collectedAclStatus.append(CurrentsService.sharedInstance.aclStatus)
            collectedBleStatus.append(CurrentsService.sharedInstance.bleStatus)
            collectedGpsStatus.append(CurrentsService.sharedInstance.gpsStatus)
        }
        
        XCTAssertEqual(collectedSeconds, expectedSeconds)
        XCTAssertEqual(collectedHeartrates, expectedHeartrates)
        XCTAssertEqual(collectedIntensities, expectedIntensities)
        XCTAssertEqual(collectedIsActives, expectedIsActives)
        XCTAssertEqual(collectedTypes, expectedTypes)
        XCTAssertEqual(collectedSpeeds.map {$0.isNaN}, expectedSpeeds.map {$0.isNaN})
        XCTAssertEqual(collectedAclStatus, expectedAclStatus)
        XCTAssertEqual(collectedBleStatus, expectedBleStatus)
        XCTAssertEqual(collectedGpsStatus, expectedGpsStatus)
        
        let collectedTotals = TotalsService
                .sharedInstance
                .totals(upTo: Date(timeIntervalSince1970: 4000))
                .values
                .sorted(by: {
                    ($0.durationSec < $1.durationSec) || (
                        $0.durationSec == $1.durationSec && $0.distanceM < $1.distanceM
                    ) || (
                        $0.durationSec == $1.durationSec &&
                        $0.distanceM == $1.distanceM &&
                        $0.heartrateBpm < $1.heartrateBpm
                    )
                })
        
        XCTAssertEqual(collectedTotals.count, expectedTotals.count)
        expectedTotals.indices.forEach {
            if collectedTotals[$0] != expectedTotals[$0] {print($0)}
            XCTAssertEqual(collectedTotals[$0], expectedTotals[$0])
        }
    }
    
    func testAllWorks() throws {
        try collector(
            true, true, true,
            expectedSeconds: expectedSeconds,
            expectedHeartrates: expectedHeartrates,
            expectedIntensities: expectedIntensities,
            expectedIsActives: expectedIsActives,
            expectedTypes: expectedTypes,
            expectedSpeeds: expectedSpeeds,
            expectedAclStatus: expectedAclStatus,
            expectedBleStatus: expectedBleStatus,
            expectedGpsStatus: expectedGpsStatus,
            expectedTotals: expectedTotals)
    }
    
    func testNoAcl() throws {
        try collector(
            false, true, true,
            expectedSeconds: expectedSeconds,
            expectedHeartrates: expectedHeartrates,
            expectedIntensities: expectedIntensities,
            expectedIsActives: expectedNoIsActives,
            expectedTypes: expectedNoTypes,
            expectedSpeeds: expectedSpeeds,
            expectedAclStatus: expectedNoAclStatus,
            expectedBleStatus: expectedBleStatus,
            expectedGpsStatus: expectedGpsStatus,
            expectedTotals: expectedTotalsNoAcl)
    }
    
    func testNoBle() throws {
        try collector(
            true, false, true,
            expectedSeconds: expectedSeconds,
            expectedHeartrates: expectedNoHeartrates,
            expectedIntensities: expectedNoIntensities,
            expectedIsActives: expectedIsActives,
            expectedTypes: expectedTypes,
            expectedSpeeds: expectedSpeeds,
            expectedAclStatus: expectedAclStatus,
            expectedBleStatus: expectedNoBleStatus,
            expectedGpsStatus: expectedGpsStatus,
            expectedTotals: expectedTotalsNoBle)
    }
    
    func testNoGps() throws {
        try collector(
            true, true, false,
            expectedSeconds: expectedSeconds,
            expectedHeartrates: expectedHeartrates,
            expectedIntensities: expectedIntensities,
            expectedIsActives: expectedIsActives,
            expectedTypes: expectedTypes,
            expectedSpeeds: expectedNoSpeeds,
            expectedAclStatus: expectedAclStatus,
            expectedBleStatus: expectedBleStatus,
            expectedGpsStatus: expectedNoGpsStatus,
            expectedTotals: expectedTotalsNoGps)
    }
    
    func testOnlyAcl() throws {
        try collector(
            true, false, false,
            expectedSeconds: expectedSeconds,
            expectedHeartrates: expectedNoHeartrates,
            expectedIntensities: expectedNoIntensities,
            expectedIsActives: expectedIsActives,
            expectedTypes: expectedTypes,
            expectedSpeeds: expectedNoSpeeds,
            expectedAclStatus: expectedAclStatus,
            expectedBleStatus: expectedNoBleStatus,
            expectedGpsStatus: expectedNoGpsStatus,
            expectedTotals: expectedTotalsOnlyAcl)
    }
    
    func testOnlyBle() throws {
        try collector(
            false, true, false,
            expectedSeconds: expectedSeconds,
            expectedHeartrates: expectedHeartrates,
            expectedIntensities: expectedIntensities,
            expectedIsActives: expectedNoIsActives,
            expectedTypes: expectedNoTypes,
            expectedSpeeds: expectedNoSpeeds,
            expectedAclStatus: expectedNoAclStatus,
            expectedBleStatus: expectedBleStatus,
            expectedGpsStatus: expectedNoGpsStatus,
            expectedTotals: expectedTotalsOnlyBle)
    }
    
    func testOnlyGps() throws {
        try collector(
            false, false, true,
            expectedSeconds: expectedSeconds,
            expectedHeartrates: expectedNoHeartrates,
            expectedIntensities: expectedNoIntensities,
            expectedIsActives: expectedNoIsActives,
            expectedTypes: expectedNoTypes,
            expectedSpeeds: expectedSpeeds,
            expectedAclStatus: expectedNoAclStatus,
            expectedBleStatus: expectedNoBleStatus,
            expectedGpsStatus: expectedGpsStatus,
            expectedTotals: expectedTotalsOnlyGps)
    }
    
    func testNonWorks() throws {
        try collector(
            false, false, false,
            expectedSeconds: expectedSeconds,
            expectedHeartrates: expectedNoHeartrates,
            expectedIntensities: expectedNoIntensities,
            expectedIsActives: expectedNoIsActives,
            expectedTypes: expectedNoTypes,
            expectedSpeeds: expectedNoSpeeds,
            expectedAclStatus: expectedNoAclStatus,
            expectedBleStatus: expectedNoBleStatus,
            expectedGpsStatus: expectedNoGpsStatus,
            expectedTotals: expectedTotalsNonWorks)
    }
}

extension AclProducer.Status: Equatable {
    public static func == (lhs: AclProducer.Status, rhs: AclProducer.Status) -> Bool {
        switch (lhs, rhs) {
        case (.started, .started):
            return true
        case (.stopped, .stopped):
            return true
        case (.paused, .paused):
            return true
        case (.resumed, .resumed):
            return true
        case (.nonRecoverableError, .nonRecoverableError):
            return true
        case (.notAuthorized, .notAuthorized):
            return true
        default:
            return false
        }
    }
}

extension BleProducer.Status: Equatable {
    public static func == (lhs: BleProducer.Status, rhs: BleProducer.Status) -> Bool {
        switch (lhs, rhs) {
        case (.started, .started):
            return true
        case (.stopped, .stopped):
            return true
        case (.paused, .paused):
            return true
        case (.resumed, .resumed):
            return true
        case (.nonRecoverableError, .nonRecoverableError):
            return true
        case (.notAuthorized, .notAuthorized):
            return true
        default:
            return false
        }
    }
}

extension GpsProducer.Status: Equatable {
    public static func == (lhs: GpsProducer.Status, rhs: GpsProducer.Status) -> Bool {
        switch (lhs, rhs) {
        case (.started, .started):
            return true
        case (.stopped, .stopped):
            return true
        case (.paused, .paused):
            return true
        case (.resumed, .resumed):
            return true
        case (.nonRecoverableError, .nonRecoverableError):
            return true
        case (.notAuthorized, .notAuthorized):
            return true
        default:
            return false
        }
    }
}

extension TotalsService.Total: Equatable {
    public static func == (lhs: TotalsService.Total, rhs: TotalsService.Total) -> Bool {
        if abs(lhs.durationSec - rhs.durationSec) > 0.1 {return false}
        if abs(lhs.distanceM - rhs.distanceM) > 0.1 {return false}
        if abs(lhs.vdot - rhs.vdot) > 0.1 {return false}
        if abs(lhs.heartrateBpm - rhs.heartrateBpm) > 1 {return false}
        if abs(lhs.paceSecPerKm - rhs.paceSecPerKm) > 0.1 {return false}
        if lhs.intensity != rhs.intensity {return false}
        if lhs.activityType != rhs.activityType {return false}
        return true
    }
}
