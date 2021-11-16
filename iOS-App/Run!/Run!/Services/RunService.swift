//
//  RunService.swift
//  Run!
//
//  Created by Jürgen Boiselle on 09.11.21.
//

import Foundation
import CoreBluetooth
import CoreLocation
import CoreMotion

/// One Service for all serives and data to be delivered within the RunView
class RunService {
    static let sharedInstance = RunService()
    
    private init() {}
    
    // MARK: - Interface
    struct Producer {
        let aclProducer: AclProducerProtocol
        let bleProducer: BleProducerProtocol
        let gpsProducer: GpsProducerProtocol
    }

    struct Config: HashedIdentifiable {
        let id = UUID()

        let motion: ((MotionActivityProtocol) -> Void)?
        let aclStatus: ((AclProducer.Status) -> Void)?
        
        let location: ((CLLocation) -> Void)?
        let gpsStatus: ((GpsProducer.Status) -> Void)?
        
        let heartrate: ((HeartrateProducer.Heartrate) -> Void)?
        let bodySensorLocation: ((UUID, HeartrateProducer.BodySensorLocation) -> Void)?
        let bleStatus: ((BleProducer.Status) -> Void)?
        
        let isActive: ((IsActiveProducer.IsActive) -> Void)?
        let speed: ((SpeedProducer.Speed) -> Void)?
        let intensity: ((IntensityProducer.IntensityEvent) -> Void)?
    }
    
    func subscribe(_ config: Config) {configs.insert(config)}
    func unsubscribe(_ config: Config) {configs.remove(config)}

    func start(producer: Producer) {
        self.producer = producer

        // Start acl producer, isActiveProducer
        isActiveProducer.start(isActive: isActive)
        producer.aclProducer.start(value: motion, status: aclStatus)
        
        // Start gps producer, speed-producer
        speedProducer.start(speed: speed)
        producer.gpsProducer.start(value: location, status: gpsStatus)
        
        // Start ble producer, intensity-producer
        intensityProducer.start(intensity: intensity)
        let bleConfig = heartrateProducer.config(
            heartrate: heartrate,
            bodySensorLocation: bodySensorLocation,
            status: bleStatus)
        producer.bleProducer.start(config: bleConfig, transientFailedPeripheralUuid: nil)
    }

    func stop() {
        producer?.aclProducer.stop()
        producer?.bleProducer.stop()
        producer?.gpsProducer.stop()
    }

    func pause() {
        producer?.aclProducer.pause()
        producer?.bleProducer.pause()
        producer?.gpsProducer.pause()
    }

    func resume() {
        producer?.aclProducer.resume()
        producer?.bleProducer.resume()
        producer?.gpsProducer.resume()
    }

    // MARK: Implementation
    
    private var configs = Set<Config>()
    private var producer: Producer?
    
    private let isActiveProducer = IsActiveProducer()
    private let speedProducer = SpeedProducer()
    private let heartrateProducer = HeartrateProducer()
    private let intensityProducer = IntensityProducer()

    private func isActive(_ isActive: IsActiveProducer.IsActive) {
        if configs.isEmpty {log(isActive)}
        configs.forEach {$0.isActive?(isActive)}
    }
    
    private func motion(_ motion: MotionActivityProtocol) {
        if configs.isEmpty {log(motion)}
        configs.forEach {$0.motion?(motion)}
        isActiveProducer.value(motion)
    }
    
    private func aclStatus(_ status: AclProducer.Status) {
        if configs.isEmpty {log(status)}
        configs.forEach {$0.aclStatus?(status)}
        isActiveProducer.status(status)
    }
    
    private func speed(_ speed: SpeedProducer.Speed) {
        if configs.isEmpty {log(speed)}
        configs.forEach {$0.speed?(speed)}
    }
    
    private func location(_ location: CLLocation) {
        if configs.isEmpty {log(location)}
        configs.forEach {$0.location?(location)}
        speedProducer.location(location)
    }
    
    private func gpsStatus(_ status: GpsProducer.Status) {
        if configs.isEmpty {log(status)}
        configs.forEach {$0.gpsStatus?(status)}
    }
    
    private func intensity(_ intensity: IntensityProducer.IntensityEvent) {
        if configs.isEmpty {log(intensity)}
        configs.forEach {$0.intensity?(intensity)}
    }
    
    private func heartrate(_ heartrate: HeartrateProducer.Heartrate) {
        if configs.isEmpty {log(heartrate)}
        configs.forEach {$0.heartrate?(heartrate)}
        intensityProducer.heartate(heartrate)
    }
    
    private func bodySensorLocation(
        _ peripheralUuid: UUID,
        _ bodySensorLocation: HeartrateProducer.BodySensorLocation)
    {
        if configs.isEmpty {log(peripheralUuid, bodySensorLocation)}
        configs.forEach {$0.bodySensorLocation?(peripheralUuid, bodySensorLocation)}
    }
    
    private func bleStatus(_ status: BleProducer.Status) {
        if configs.isEmpty {log(status)}
        configs.forEach {$0.bleStatus?(status)}
    }
}
