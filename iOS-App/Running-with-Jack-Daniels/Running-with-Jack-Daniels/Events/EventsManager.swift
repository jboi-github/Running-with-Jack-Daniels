//
//  EventsManager.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 14.09.21.
//

import Foundation
import CoreLocation
import MapKit
import Combine

/**
 Manage native and artificial events and bring them into a status stream.
 Collect locations-path, segments and totals or the current workout.
 
 The `EventManager`is based on the `EventModel` of events and states.
 */
public class EventsManager {
    // MARK: - Initialization
    
    /// Access shared instance of this singleton
    static var sharedInstance = EventsManager()

    /// Use singleton @sharedInstance
    init() {}
    
    // MARK: - Published
    
    public func start(at: Date = Date()) {
        log()
        startAll(at: at)
        connectAll(at: at)
    }
    
    public func stop(at: Date = Date()) {
        log()
        stopAll(at: at)
    }
    
    public func reset(at: Date = Date()) {
        log()
        stopAll(at: at)
        startAll(at: at)
        connectAll(at: at)
    }
    
    // MARK: Connect aggregates
    
    typealias LocationContent = (location: CodableLocation, original: Bool)
    typealias AppStatusType =
        StatusType<Int, Bool, LocationContent, Bool, Bool, AclMotionReceiver.Status, Bool, Intensity, Int>
    typealias AppStatus =
        Status<Int, Bool, LocationContent, Bool, Bool, AclMotionReceiver.Status, Bool, Intensity, Int>

    /// Connect to Status-Queue and get updates about new status, rollbacks and completions.
    /// A connect or re-connect is necessary after each start or reset of this service. You can set multiple `sink` calls.
    /// All of them are called in parallel and valid until the service is stopped or reset.
    private(set) var statusPublisher: Publishers.Share<PassthroughSubject<AppStatusType, Error>>!
    
    // MARK: - Private
    private func startAll(at: Date) {
        isStarted = PassthroughSubject<ArtificialIsStartedEvent, Error>()
        
        BleHeartrateReceiver.sharedInstance.start()
        GpsLocationReceiver.sharedInstance.start()
        AclMotionReceiver.sharedInstance.start()
        IntensityReceiver.sharedInstance.start()
        SegmentIdReceiver.sharedInstance.start()

        isStarted.send(ArtificialIsStartedEvent(when: at, content: true))
    }
    
    private func stopAll(at: Date) {
        isStarted.send(ArtificialIsStartedEvent(when: at, content: false))
        isStarted.send(completion: .finished)

        BleHeartrateReceiver.sharedInstance.stop()
        GpsLocationReceiver.sharedInstance.stop()
        AclMotionReceiver.sharedInstance.stop()
        IntensityReceiver.sharedInstance.stop()
        SegmentIdReceiver.sharedInstance.stop()
        
        subscribers.removeAll()
    }

    // MARK: Events
    
    private struct HeartrateEvent: Event {
        typealias Content = Int
        
        let when: Date
        let content: Content
        
        init(when: Date, content: Content) {
            self.when = when
            self.content = content
        }
    }
    
    private struct HeartrateStatusEvent: Event {
        typealias Content = Bool
        
        let when: Date
        let content: Content
        
        init(when: Date, content: Content) {
            self.when = when
            self.content = content
        }
    }
    
    private struct LocationEvent: Event {
        typealias Content = LocationContent
        
        var when: Date {content.location.timestamp}
        let content: Content
        
        init(when: Date = .distantPast, content: Content) {
            self.content = content
        }

        func interpolate(at: Date, to: Self) -> Self {
            let p =
                (when.timeIntervalSince1970 - self.when.timeIntervalSince1970) /
                (to.when.timeIntervalSince1970 - self.when.timeIntervalSince1970)
            
            return Self(
                content: (
                    location: content.location.moveScaled(by: p, to: to.content.location),
                    original: false))
        }
        
        /// Use current speed and bearing to get new location
        func extrapolate(at: Date) -> Self {
            let timeInterval = when.timeIntervalSince1970 - content.location.timestamp.timeIntervalSince1970
            let span = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: content.location.latitude,
                    longitude: content.location.longitude),
                latitudinalMeters: content.location.speed * timeInterval * cos(content.location.course.asRadians),
                longitudinalMeters: content.location.speed * timeInterval * sin(content.location.course.asRadians))
                .span
            
            return Self(
                content: (
                    location: CodableLocation(
                        latitude: content.location.latitude + span.latitudeDelta,
                        longitude: content.location.longitude + span.longitudeDelta,
                        altitude: content.location.altitude,
                        horizontalAccuracy: content.location.horizontalAccuracy,
                        verticalAccuracy: content.location.verticalAccuracy,
                        course: content.location.course,
                        courseAccuracy: content.location.courseAccuracy,
                        speed: content.location.speed,
                        speedAccuracy: content.location.speedAccuracy,
                        timestamp: when),
                    original: false))
        }
    }
    
    private struct LocationStatusEvent: Event {
        typealias Content = Bool
        
        let when: Date
        let content: Content
        
        init(when: Date, content: Content) {
            self.when = when
            self.content = content
        }
    }
    
    private struct ActivityEvent: Event {
        typealias Content = Bool
        
        let when: Date
        let content: Content
        
        init(when: Date, content: Content) {
            self.when = when
            self.content = content
        }
    }
    
    private struct ActivityStatusEvent: Event {
        typealias Content = AclMotionReceiver.Status
        
        let when: Date
        let content: Content
        
        init(when: Date, content: Content) {
            self.when = when
            self.content = content
        }
    }
    
    private struct ArtificialIsStartedEvent: Event {
        typealias Content = Bool
        
        let when: Date
        let content: Content
        
        init(when: Date, content: Content) {
            self.when = when
            self.content = content
        }
    }
    
    private struct ArtificialIntensityEvent: Event {
        typealias Content = Intensity
        
        let when: Date
        let content: Content
        
        init(when: Date, content: Content) {
            self.when = when
            self.content = content
        }
    }
    
    private struct ArtificialSegmentEvent: Event {
        typealias Content = Int
        
        let when: Date
        let content: Content
        
        init(when: Date, content: Content) {
            self.when = when
            self.content = content
        }
    }
    
    /// Store for sink
    private var subscribers = Set<AnyCancellable>()
    
    // MARK: Sources for artificial events
    private var isStarted: PassthroughSubject<ArtificialIsStartedEvent, Error>!
    
    // MARK: Event-Queues
    private var heartrateQ: EventQueue<AnyPublisher<HeartrateEvent, Error>>!
    private var heartrateStatusQ: EventQueue<AnyPublisher<HeartrateStatusEvent, Error>>!
    private var locationQ: EventQueue<AnyPublisher<LocationEvent, Error>>!
    private var locationStatusQ: EventQueue<AnyPublisher<LocationStatusEvent, Error>>!
    private var activityQ: EventQueue<AnyPublisher<ActivityEvent, Error>>!
    private var acitivityStatusQ: EventQueue<AnyPublisher<ActivityStatusEvent, Error>>!
    private var isStartedQ: EventQueue<AnyPublisher<ArtificialIsStartedEvent, Error>>!
    private var intensityQ: EventQueue<AnyPublisher<ArtificialIntensityEvent, Error>>!
    private var segmentIdQ: EventQueue<AnyPublisher<ArtificialSegmentEvent, Error>>!
    
    // MARK: Status-Queue
    
    private func connectAll(at: Date) {
        heartrateQ = EventQueue(
            source: BleHeartrateReceiver
                .sharedInstance
                .heartrate
                .map {HeartrateEvent(when: $0.when, content: $0.heartrate)}
                .eraseToAnyPublisher(),
            type: .backward)
        
        heartrateStatusQ = EventQueue(
            source: BleHeartrateReceiver
                .sharedInstance
                .receiving
                .map {HeartrateStatusEvent(when: at, content: $0)}
                .eraseToAnyPublisher(),
            type: .forward(deferredBy: 1))
        
        locationQ = EventQueue(
            source: GpsLocationReceiver
                .sharedInstance
                .location
                .map {LocationEvent(content: (location: CodableLocation.fromLocation($0), original: true))}
                .eraseToAnyPublisher(),
            type: .backward)
        
        locationStatusQ = EventQueue(
            source: GpsLocationReceiver
                .sharedInstance
                .receiving
                .map {LocationStatusEvent(when: at, content: $0)}
                .eraseToAnyPublisher(),
            type: .forward(deferredBy: 1))

        activityQ = EventQueue(
            source: AclMotionReceiver
                .sharedInstance
                .isRunning
                .map {ActivityEvent(when: $0.when, content: $0.isRunning)}
                .eraseToAnyPublisher(),
            type: .forward(deferredBy: 60))
        
        acitivityStatusQ = EventQueue(
            source: AclMotionReceiver
                .sharedInstance
                .receiving
                .map {ActivityStatusEvent(when: at, content: $0)}
                .eraseToAnyPublisher(),
            type: .forward(deferredBy: 1))

        intensityQ = EventQueue(
            source: IntensityReceiver
                .sharedInstance
                .intensityChange
                .map {ArtificialIntensityEvent(when: $0.when, content: $0.intensity)}
                .eraseToAnyPublisher(),
            type: .forward(deferredBy: 35)) // Half time to previous heartrate + some processing time

        segmentIdQ = EventQueue(
            source: SegmentIdReceiver
                .sharedInstance
                .segmentIdChange
                .map {ArtificialSegmentEvent(when: $0.when, content: $0.segment)}
                .eraseToAnyPublisher(),
            type: .forward(deferredBy: 40)) // Intensity + som eprocessing time

        isStartedQ = EventQueue(source: isStarted.eraseToAnyPublisher(), type: .forward(deferredBy: 1))

        statusPublisher = StatusQueue(
            eq0: heartrateQ,
            eq1: heartrateStatusQ,
            eq2: locationQ,
            eq3: locationStatusQ,
            eq4: activityQ,
            eq5: acitivityStatusQ,
            eq6: isStartedQ,
            eq7: intensityQ,
            eq8: segmentIdQ,
            publishEvery: 1)
            .publisher
            .share()
        
        // Connect for artificial events
        statusPublisher
            .sink { completion in
                var error: Error? {
                    switch completion {
                    case .finished:
                        return nil
                    case.failure(let error):
                        return error
                    }
                }
                if !check(error) {self.stop()}
            } receiveValue: {
                self.artificialsSink($0)
            }
            .store(in: &subscribers)
    }
    
    // MARK: Sink for artificial events
    private func artificialsSink(_ statusType: AppStatusType)
    {
        switch statusType {
        case .status(let status):
            if let hrBpm = status.T.hrBpm {
                IntensityReceiver.sharedInstance.heartrate(hrBpm, at: status.when)
            }
            if let intensity = status.T.intensity,
               let isStarted = status.T.isStarted,
               let isRunning = status.T.isRunning
            {
                SegmentIdReceiver.sharedInstance.segment(
                    isStarted: isStarted,
                    isRunning: isRunning,
                    intensity: intensity,
                    at: status.when)
            }
        default:
            break
        }
    }
}

/// Rename status attributes into readble text
extension Status
where
    C0 == Int,
    C1 == Bool,
    C2 == EventsManager.LocationContent,
    C3 == Bool,
    C4 == Bool,
    C5 == AclMotionReceiver.Status,
    C6 == Bool,
    C7 == Intensity,
    C8 == Int
{
    typealias AppStatusAttributes = (
        hrBpm: Int?,
        bleReceiving: Bool?,
        location: CodableLocation?,
        locationOriginl: Bool?,
        gpsReceiving: Bool?,
        isRunning: Bool?,
        aclReceiving: AclMotionReceiver.Status?,
        isStarted: Bool?,
        intensity: Intensity?,
        segmentId: Int?)
    
    var T: AppStatusAttributes {(c0, c1, c2?.0, c2?.1, c3, c4, c5, c6, c7, c8)}
}
