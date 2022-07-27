//
//  ClientSet.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 05.07.22.
//

import Foundation
import Combine

class ClientsSet: ObservableObject {
    
    // MARK: Initialisation
    init(queue: SerialQueue) {
        self.queue = queue
    }
    
    func connect(timeseriesSet: TimeSeriesSet) {
        if isConnected {return}
        isConnected = true // Call only once per instance
        
        // Create clients
        sensorClients = [
            Client(
                delegate: PedometerDataClient(
                    queue: queue,
                    timeseriesSet: timeseriesSet,
                    pedometerDataTimeseries: timeseriesSet.pedometerDataTimeseries)),
            Client(
                delegate: PedometerEventClient(
                    queue: queue,
                    timeseriesSet: timeseriesSet,
                    pedometerEventTimeseries: timeseriesSet.pedometerEventTimeseries)),
            Client(
                delegate: MotionActivityClient(
                    queue: queue,
                    timeseriesSet: timeseriesSet,
                    motionActivityTimeseries: timeseriesSet.motionActivityTimeseries)),
            Client(
                delegate: LocationClient(
                    queue: queue,
                    timeseriesSet: timeseriesSet,
                    locationTimeseries: timeseriesSet.locationTimeseries)),
            Client(
                delegate: HeartrateMonitorClient(
                    queue: queue,
                    timeseriesSet: timeseriesSet,
                    heartrateTimeseries: timeseriesSet.heartrateTimeseries,
                    batteryLevelTimeseries: timeseriesSet.batteryLevelTimeseries,
                    bodySensorLocationTimeseries: timeseriesSet.bodySensorLocationTimeseries,
                    peripheralTimeseries: timeseriesSet.peripheralTimeseries))
        ]
        
        // Connect status
        setSink(idx: 0) { self.pedometerDataStatus = $0 }
        setSink(idx: 1) { self.pedometerEventStatus = $0 }
        setSink(idx: 2) { self.motionActivityStatus = $0 }
        setSink(idx: 3) { self.locationStatus = $0 }
        setSink(idx: 4) { self.heartrateMonitorStatus = $0 }
    }
    
    // MARK: Interface
    @Published private(set) var pedometerDataStatus: ClientStatus = .stopped(since: .distantPast)
    @Published private(set) var pedometerEventStatus: ClientStatus = .stopped(since: .distantPast)
    @Published private(set) var motionActivityStatus: ClientStatus = .stopped(since: .distantPast)
    @Published private(set) var locationStatus: ClientStatus = .stopped(since: .distantPast)
    @Published private(set) var heartrateMonitorStatus: ClientStatus = .stopped(since: .distantPast)
    
    func startSensors(asOf: Date) {
        sensorClients.forEach { $0.start(asOf: asOf) }
    }
    
    func stopSensors(asOf: Date) {
        sensorClients.forEach { $0.stop(asOf: asOf) }
    }

    func refreshSensors(asOf: Date) {
        stopSensors(asOf: asOf)
        startSensors(asOf: asOf)
    }
    
    func trigger(asOf: Date) {
        sensorClients.forEach { $0.trigger(asOf: asOf) }
    }

    // MARK: Implementation
    private unowned let queue: SerialQueue
    private var isConnected: Bool = false
    private var sensorClients = [Client]()
    private var cancellables = Set<AnyCancellable>()
    
    private func setSink(idx: Int, sink: @escaping (ClientStatus) -> Void) {
        sensorClients[idx]
            .$status
            .sink { status in DispatchQueue.main.async { sink(status) } }
            .store(in: &cancellables)
    }
}
