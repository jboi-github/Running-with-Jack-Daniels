//
//  CurrentsService.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import Foundation

class CurrentsService: ObservableObject {
    static let sharedInstance = CurrentsService()
    
    private init() {
        RunService.sharedInstance.subscribe(
            RunService.Config(
                motion: nil,
                aclStatus: {
                    self.aclStatus = $0
                    if case .started = $0 {self.reset()}
                },
                location: nil,
                gpsStatus: {
                    self.gpsStatus = $0
                    if case .started = $0 {self.reset()}
                },
                heartrate: {self.heartrate = $0},
                bodySensorLocation: nil,
                bleStatus: {
                    self.bleStatus = $0
                    if case .started = $0 {self.reset()}
                },
                isActive: {self.isActive = $0},
                speed: {self.speed = $0},
                intensity: {self.intensity = $0}))
    }
    
    // MARK: - Interface
    @Published private(set) var aclStatus: AclProducer.Status = .stopped
    @Published private(set) var bleStatus: BleProducer.Status = .stopped
    @Published private(set) var gpsStatus: GpsProducer.Status = .stopped
    @Published private(set) var speed: SpeedProducer.Speed = .zero
    @Published private(set) var heartrate: HeartrateProducer.Heartrate = .zero
    @Published private(set) var isActive: IsActiveProducer.IsActive = .zero
    @Published private(set) var intensity: IntensityProducer.IntensityEvent = .zero
    
    // MARK: - Implementation
    private func reset() {
        speed = .zero
        heartrate = .zero
        isActive = .zero
        intensity = .zero
    }
}
