//
//  EventsTests.swift
//  Run!Tests
//
//  Created by Jürgen Boiselle on 15.11.21.
//

import XCTest
@testable import Run_
import CoreBluetooth
import CoreLocation
import MapKit
import CoreMotion

class EventsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    static let expectedPeripheralUuid = UUID()

    private class BPHeartrate: BleProducerProtocol {
        static var sharedInstance: BleProducerProtocol = BPHeartrate()
        
        private var config: BleProducer.Config?
        
        func start(config: BleProducer.Config, asOf: Date, transientFailedPeripheralUuid: UUID?) {
            self.config = config
            config.status(BleProducer.Status.started(asOf: asOf))
            
            config.actions[CBUUID(string: "2A38")]?(
                BPHeartrate.sharedInstance,
                EventsTests.expectedPeripheralUuid,
                CBUUID(string: "2A38"),
                CBCharacteristicProperties.read)
            
            config.actions[CBUUID(string: "2A37")]?(
                BPHeartrate.sharedInstance,
                EventsTests.expectedPeripheralUuid,
                CBUUID(string: "2A37"),
                CBCharacteristicProperties.notify)
        }
        
        func stop() {config?.status(BleProducer.Status.stopped)}
        func pause() {config?.status(BleProducer.Status.paused)}
        func resume() {config?.status(BleProducer.Status.resumed)}
        
        func readValue(_ peripheralUuid: UUID, _ characteristicUuid: CBUUID) {
            XCTAssertEqual(peripheralUuid, EventsTests.expectedPeripheralUuid)
            XCTAssertEqual(characteristicUuid, CBUUID(string: "2A38"))
            
            config?.readers[CBUUID(string: "2A38")]?(peripheralUuid, Data([UInt8(2)]), Date())
            
            config?.readers[CBUUID(string: "2A37")]?(peripheralUuid, Data([UInt8(0x00), UInt8(0x30)]), Date())
            
            config?.readers[CBUUID(string: "2A37")]?(peripheralUuid, Data([UInt8(0x06), UInt8(0x2e)]), Date())
            
            config?.readers[CBUUID(string: "2A37")]?(peripheralUuid, Data([UInt8(0x16), UInt8(0x32), UInt8(0xbb), UInt8(0x04)]), Date())
        }
        func writeValue(_ peripheralUuid: UUID, _ characteristicUuid: CBUUID, _ data: Data) {}
        func setNotifyValue(_ peripheralUuid: UUID, _ characteristicUuid: CBUUID, _ notify: Bool) {
            XCTAssertEqual(peripheralUuid, EventsTests.expectedPeripheralUuid)
            XCTAssertEqual(characteristicUuid, CBUUID(string: "2A37"))
            XCTAssertTrue(notify)
        }
    }
    
    func testHeartrateProducer() throws {
        // Values to be collected
        var heartrate = [HeartrateProducer.Heartrate]()
        var peripheralUuid: UUID? = nil
        var bodySensorLocation: HeartrateProducer.BodySensorLocation? = nil
        var status: BleProducer.Status? = nil
        
        // Values to be expected
        
        // Configure and run producer mock up
        let heartrateProducer = HeartrateProducer()
        let config = heartrateProducer.config {
            heartrate.append($0)
        } bodySensorLocation: {
            peripheralUuid = $0
            bodySensorLocation = $1
        } status: {
            status = $0
        }
        
        // Normal workflow
        BPHeartrate.sharedInstance.start(config: config, asOf: Date(), transientFailedPeripheralUuid: nil)
        
        // Check values
        XCTAssertEqual(peripheralUuid, EventsTests.expectedPeripheralUuid)
        if let status = status, case BleProducer.Status.started = status {
            print("status ok")
        } else {
            XCTFail()
        }
        XCTAssertEqual(bodySensorLocation, HeartrateProducer.BodySensorLocation.Wrist)
        XCTAssertEqual(heartrate[0].heartrate, 48)
        XCTAssertNil(heartrate[0].skinIsContacted)
        XCTAssertNil(heartrate[0].rr)
        XCTAssertEqual(heartrate[1].heartrate, 46)
        XCTAssertTrue(heartrate[1].skinIsContacted == true)
        XCTAssertNil(heartrate[1].rr)
        XCTAssertEqual(heartrate[2].heartrate, 50)
        XCTAssertTrue(heartrate[2].skinIsContacted == true)
        XCTAssertEqual(heartrate[2].rr?.count, 1)
        XCTAssertEqual(heartrate[2].rr?[0] ?? .nan, 1.2, accuracy: 0.1)
    }

    private class BPPeripheral: BleProducerProtocol {
        static var sharedInstance: BleProducerProtocol = BPPeripheral()
        
        private var config: BleProducer.Config?
        
        func start(config: BleProducer.Config, asOf: Date, transientFailedPeripheralUuid: UUID?) {
            self.config = config
            
            config.rssi?(expectedPeripheralUuid, NSNumber(1.0))
            config.rssi?(expectedPeripheralUuid, NSNumber(2.0))
            config.rssi?(expectedPeripheralUuid, NSNumber(3.0))
        }
        
        func stop() {config?.status(BleProducer.Status.stopped)}
        func pause() {config?.status(BleProducer.Status.paused)}
        func resume() {config?.status(BleProducer.Status.resumed)}
        
        func readValue(_ peripheralUuid: UUID, _ characteristicUuid: CBUUID) {}
        func writeValue(_ peripheralUuid: UUID, _ characteristicUuid: CBUUID, _ data: Data) {}
        func setNotifyValue(_ peripheralUuid: UUID, _ characteristicUuid: CBUUID, _ notify: Bool) {}
    }
    
    func testPeripheralProducer() throws {
        // Values to be collected
        var rssis = [Double]()
        var rssiUuids = [UUID]()
        
        // Values to be expected
        
        // Configure and run producer mock up
        let peripheralProducer = PeripheralProducer()
        let config = peripheralProducer.config(
            discoveredPeripheral: {print($0)}, // Cannot be tested here
            failedPeripheral: {print($0, $1 as Any)},
            rssi: {
                rssiUuids.append($0)
                rssis.append($1.doubleValue)
            },
            bodySensorLocation: {print($0, $1)}, // Tested in heartrate-test
            status: {print($0)})  // Tested in heartrate-test
        
        // Normal workflow
        BPPeripheral.sharedInstance.start(config: config, asOf: Date(), transientFailedPeripheralUuid: nil)
        
        // Check values
        XCTAssertEqual(rssis, [1.0, 2.0, 3.0])
        XCTAssertEqual(rssiUuids, [EventsTests.expectedPeripheralUuid, EventsTests.expectedPeripheralUuid, EventsTests.expectedPeripheralUuid])
    }
    
    func testIntensityProducer() throws {
        let heartrates = [80, 90, 140, 150, 155, 150, 165, 168, 172, 190, 175, 172, 165, 132, 131]
        let expectedIntensities = [Intensity.Cold, .Easy, .Marathon, .Easy, .Marathon, .Threshold, .Repetition, .Interval, .Threshold, .Easy, .Cold]
        
        var intensities = [Intensity]()
        
        ProfileService.sharedInstance.onAppear()
        ProfileService.sharedInstance.hrMax.onChange(to: 181)
        ProfileService.sharedInstance.hrResting.onChange(to: 40)
        print(hrLimits(hrMaxBpm: ProfileService.sharedInstance.hrMax.value!, restingHrBpm: ProfileService.sharedInstance.hrResting.value!))
        
        let intensityProducer = IntensityProducer()
        intensityProducer.start {
            intensities.append($0.intensity)
        }
        
        heartrates.indices.forEach {
            intensityProducer.heartate(HeartrateProducer.Heartrate(
                timestamp: Date(timeIntervalSince1970: Double(1000 * $0)),
                heartrate: heartrates[$0],
                skinIsContacted: nil,
                energyExpended: nil,
                rr: nil))
        }
        
        XCTAssertEqual(intensities, expectedIntensities)
    }

    func testSpeedProducer() throws {
        var speeds = [SpeedProducer.Speed]()
        let locations = [
            CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: 50,
                    longitude: 10),
                altitude: 0,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: Date(timeIntervalSince1970: 1)),
            CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: 51,
                    longitude: 10),
                altitude: 0,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: Date(timeIntervalSince1970: 2)),
            CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: 52,
                    longitude: 11),
                altitude: 0,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                timestamp: Date(timeIntervalSince1970: 4))
        ]
        let expectedSpeeds = [
            SpeedProducer.Speed(
                timestamp: Date(timeIntervalSince1970: 1),
                speedMperSec: 1000000 / 9,
                speedDegreesPerSec: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 0)),
            SpeedProducer.Speed(
                timestamp: Date(timeIntervalSince1970: 2),
                speedMperSec: 65500,
                speedDegreesPerSec: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        ]
        let speedProducer = SpeedProducer()
        speedProducer.start {speeds.append($0)}
        
        locations.forEach {speedProducer.location($0)}
        
        XCTAssertEqual(speeds.map {$0.timestamp}, expectedSpeeds.map {$0.timestamp})
        expectedSpeeds.indices.forEach {
            XCTAssertEqual(speeds[$0].speedMperSec, expectedSpeeds[$0].speedMperSec, accuracy: 1000.0)
        }
        XCTAssertEqual(
            speeds.map {$0.speedDegreesPerSec.latitudeDelta},
            expectedSpeeds.map {$0.speedDegreesPerSec.latitudeDelta})
        XCTAssertEqual(
            speeds.map {$0.speedDegreesPerSec.longitudeDelta},
            expectedSpeeds.map {$0.speedDegreesPerSec.longitudeDelta})
    }
    
    struct MAAllowed: MotionActivityProtocol {
        static var canUse: Bool = true
        
        let startDate: Date
        let stationary: Bool
        let walking: Bool
        let running: Bool
        let cycling: Bool
        let confidence: CMMotionActivityConfidence
    }
    
    func testIsActiveProducer1() throws {
        var activities = [IsActiveProducer.IsActive]()
        let motions = [
            MAAllowed(
                startDate: Date(timeIntervalSince1970: 1000),
                stationary: true, walking: false, running: false, cycling: false,
                confidence: .medium),
            MAAllowed(
                startDate: Date(timeIntervalSince1970: 2000),
                stationary: false, walking: true, running: false, cycling: false,
                confidence: .medium),
            MAAllowed(
                startDate: Date(timeIntervalSince1970: 4000),
                stationary: false, walking: false, running: true, cycling: false,
                confidence: .medium),
            MAAllowed(
                startDate: Date(timeIntervalSince1970: 5000),
                stationary: false, walking: false, running: false, cycling: true,
                confidence: .medium),
            MAAllowed(
                startDate: Date(timeIntervalSince1970: 6000),
                stationary: false, walking: false, running: false, cycling: false,
                confidence: .medium)
        ]
        let expectedActivities = [
            IsActiveProducer.IsActive(timestamp: Date(timeIntervalSince1970: 1000), isActive: false, type: .pause),
            IsActiveProducer.IsActive(timestamp: Date(timeIntervalSince1970: 2000), isActive: true, type: .walking),
            IsActiveProducer.IsActive(timestamp: Date(timeIntervalSince1970: 4000), isActive: true, type: .running),
            IsActiveProducer.IsActive(timestamp: Date(timeIntervalSince1970: 5000), isActive: true, type: .cycling),
            IsActiveProducer.IsActive(timestamp: Date(timeIntervalSince1970: 6000), isActive: false, type: .pause)
        ]
        
        let isActiveProducer = IsActiveProducer()
        isActiveProducer.start {activities.append($0)}
        
        isActiveProducer.status(.started(asOf: Date()))
        motions.forEach {isActiveProducer.value($0)}
        isActiveProducer.status(.stopped)

        XCTAssertEqual(activities, expectedActivities)
    }

    struct MANotAllowed: MotionActivityProtocol {
        static var canUse: Bool = false
        
        let startDate: Date
        let stationary: Bool
        let walking: Bool
        let running: Bool
        let cycling: Bool
        let confidence: CMMotionActivityConfidence
    }

    func testIsActiveProducer2() throws {
        var activities = [IsActiveProducer.IsActive]()
        let motions = [
            MANotAllowed(
                startDate: Date(timeIntervalSince1970: 1000),
                stationary: true, walking: false, running: false, cycling: false,
                confidence: .medium),
            MANotAllowed(
                startDate: Date(timeIntervalSince1970: 2000),
                stationary: false, walking: true, running: false, cycling: false,
                confidence: .medium),
            MANotAllowed(
                startDate: Date(timeIntervalSince1970: 4000),
                stationary: false, walking: false, running: true, cycling: false,
                confidence: .medium),
            MANotAllowed(
                startDate: Date(timeIntervalSince1970: 5000),
                stationary: false, walking: false, running: false, cycling: true,
                confidence: .medium),
            MANotAllowed(
                startDate: Date(timeIntervalSince1970: 6000),
                stationary: false, walking: false, running: false, cycling: false,
                confidence: .medium)
        ]
        let expectedActivities = [
            IsActiveProducer.IsActive(timestamp: Date(timeIntervalSince1970: 1000), isActive: true, type: .unknown),
            IsActiveProducer.IsActive(timestamp: Date(timeIntervalSince1970: 2000), isActive: true, type: .unknown),
            IsActiveProducer.IsActive(timestamp: Date(timeIntervalSince1970: 4000), isActive: true, type: .unknown),
            IsActiveProducer.IsActive(timestamp: Date(timeIntervalSince1970: 5000), isActive: true, type: .unknown),
            IsActiveProducer.IsActive(timestamp: Date(timeIntervalSince1970: 6000), isActive: true, type: .unknown)
        ]
        
        let isActiveProducer = IsActiveProducer()
        isActiveProducer.start {activities.append($0)}
        
        isActiveProducer.status(.started(asOf: Date()))
        motions.forEach {isActiveProducer.value($0)}
        isActiveProducer.status(.stopped)

        XCTAssertEqual(activities, expectedActivities)
    }
}

extension IsActiveProducer.IsActive: Equatable {
    public static func == (lhs: IsActiveProducer.IsActive, rhs: IsActiveProducer.IsActive) -> Bool {
        [
            lhs.timestamp == rhs.timestamp,
            lhs.isActive == rhs.isActive,
            lhs.type == rhs.type
        ].allSatisfy {$0}
    }
}
