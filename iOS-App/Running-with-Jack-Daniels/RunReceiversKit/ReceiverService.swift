//
//  ReceiverService.swift
//  RunReceiversKit
//
//  Created by Jürgen Boiselle on 05.10.21.
//

import Foundation
import Combine
import CoreBluetooth
import CoreLocation
import CoreMotion

/// Provide the receivers as a service
public class ReceiverService {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    public static var sharedInstance = ReceiverService()

    /// Use singleton @sharedInstance
    private init() {
        heartrateValues = bleHeartrateReceiver.valueStream
        heartrateControl = bleHeartrateReceiver.controlStream
        peripheralValues = blePeripheralReceiver.valueStream
        peripheralControl = blePeripheralReceiver.controlStream
        locationValues = gpsReceiver.valueStream
        locationControl = gpsReceiver.controlStream
        motionValues = aclReceiver.valueStream
        motionControl = aclReceiver.controlStream
    }
    
    // MARK: - Published
    public let heartrateValues: AnyPublisher<Heartrate, Never>
    public let heartrateControl: AnyPublisher<ReceiverControl, Never>
    public let peripheralValues: AnyPublisher<CBPeripheral, Never>
    public let peripheralControl: AnyPublisher<ReceiverControl, Never>
    public let locationValues: AnyPublisher<CLLocation, Never>
    public let locationControl: AnyPublisher<ReceiverControl, Never>
    public let motionValues: AnyPublisher<CMMotionActivity, Never>
    public let motionControl: AnyPublisher<ReceiverControl, Never>
    
    public func start() {
        bleHeartrateReceiver.start()
        gpsReceiver.start()
        aclReceiver.start()
    }
    
    public func stop() {
        bleHeartrateReceiver.stop()
        gpsReceiver.stop()
        aclReceiver.stop()
    }
    
    public func startBleScanner() {blePeripheralReceiver.start()}
    public func stopBleScanner() {blePeripheralReceiver.stop()}

    // MARK: - Private
    private let bleHeartrateReceiver = ReceiverPublisher<BleHeartrateReceiver>()
    private let blePeripheralReceiver = ReceiverPublisher<BlePeripheralReceiver>()
    private let gpsReceiver = ReceiverPublisher<GpsReceiver>()
    private let aclReceiver = ReceiverPublisher<AclReceiver>()
}
