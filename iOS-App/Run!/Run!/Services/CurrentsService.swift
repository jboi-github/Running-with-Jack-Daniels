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
                aclStatus: { status in
                    DispatchQueue.main.async {
                        self.aclStatus = status
                        if case .started = status {self.reset()}
                    }
                },
                location: nil,
                gpsStatus: { status in
                    DispatchQueue.main.async {
                        self.gpsStatus = status
                        if case .started = status {self.reset()}
                    }
                },
                heartrate: { heartrate in
                    DispatchQueue.main.async {
                        self.heartrate = heartrate
                    }
                },
                bodySensorLocation: nil,
                bleStatus: { status in
                    DispatchQueue.main.async {
                        self.bleStatus = status
                        if case .started = status {self.reset()}
                    }
                },
                isActive: { isActive in
                    DispatchQueue.main.async {
                        self.isActive = isActive
                    }
                },
                speed: { speed in
                    DispatchQueue.main.async {
                        self.speed = speed
                    }
                },
                intensity: { intensity in
                    DispatchQueue.main.async {
                        self.intensity = intensity
                    }
                }))
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
