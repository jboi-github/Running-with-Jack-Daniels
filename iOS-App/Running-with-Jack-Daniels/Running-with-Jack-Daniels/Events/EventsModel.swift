//
//  EventsModel.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 27.08.21.
//

import Foundation
import Combine

let serialDispatchQueue = DispatchQueue(
    label: "com.apps4live.Running-with-Jack-Daniels",
    qos: .userInitiated)

let voidEventQueue =
    EventQueue(
        source: PassthroughSubject<VoidEvent, Never>(),
        type: .forward(deferredBy: 0))

private var subscribers = Set<AnyCancellable>()

// MARK: - Events

/// Base protocol of an event, which consists of a timestamp `when`. The derived struct or class is expected to add measures of the event.
protocol Event: Comparable {
    associatedtype Content
    
    /// Time at which the event takes place
    var when: Date {get}
    var content: Content {get}
    
    init(when: Date, content:Content)
    
    /// Create new event by interpolating from `self` until another event at the given point in time
    /// - Parameters:
    ///   - to when: Time at which the new event should take place. This time is between `prev` and `next`
    ///   - until next: next event for interpolation
    func interpolate(at: Date, to: Self) -> Self
    
    /// Create new event by extrapolating from `self` to the given point in time.
    /// Note, that the given time might be before or after the event time.
    /// - Parameters:
    ///   - to when: Time at which the new event should take place. This time might be before or after the given `event
    func extrapolate(at: Date) -> Self
}

extension Event {
    // MARK: Initialization
    static func create(when: Date, content: Content) -> Self {Self(when: when, content: content)}
    
    // MARK: Equatable
    static func == (lhs: Self, rhs: Self) -> Bool {lhs.when == rhs.when}
    static func < (lhs: Self, rhs: Self) -> Bool {lhs.when < rhs.when}
    
    // MARK: Default implementation for forwarding events
    func interpolate(at: Date, to: Self) -> Self {extrapolate(at: at)}
    func extrapolate(at: Date) -> Self {Self(when: at, content: content)}
}

struct VoidEvent: Event {
    typealias Content = Void
    
    let when: Date
    let content: Content

    init() {when = .distantPast}
    
    init(when: Date, content: Content) {
        self.when = when
        self.content = content
    }

    func interpolate(at: Date, to: Self) -> Self {self}
    func extrapolate(at: Date) -> Self {self}
}

enum EventType {
    case forward(deferredBy: TimeInterval)
    case backward
}

private typealias BiTemporalWhen = (impact: Date, event: Date)

// MARK: - Event Queue

class EventQueue<P: Publisher> where P.Output: Event {
    typealias Event = P.Output
    fileprivate typealias Publisher = CurrentValueSubject<BiTemporalWhen, P.Failure>
    
    private let type: EventType
    fileprivate let publisher = Publisher((.distantPast, .distantPast))

    private var events = [Event]()

    init(source: P, type: EventType) {
        self.type = type
        
        source
            .sink { completion in
                serialDispatchQueue.async { [self] in
                    publisher.send(completion: completion)
                }
            } receiveValue: { event in
                serialDispatchQueue.async { [self] in
                    // Insert event, sorted
                    let idx = events.firstIndex(where: {$0.when > event.when}) ?? events.endIndex
                    events.insert(event, at: idx)
                    
                    // return impact
                    switch type {
                    case .forward:
                        publisher.send((event.when, event.when))
                    case .backward:
                        if idx > events.startIndex {
                            publisher.send((events[events.index(before: idx)].when, event.when))
                        } else {
                            publisher.send((event.when, event.when))
                        }
                    }
                }
            }
            .store(in: &subscribers)
    }
    
    func events(after: Date) -> [Event] {events.filter {$0.when > after}}
    
    func commit(before: Date) {
        // Always keep last event
        let last = events.last
        
        // Remove, if committed
        events.removeAll {$0.when < before}
        
        // Play back last. If forward, extrapolate to newest possible position
        if events.isEmpty, let last = last {
            switch type {
            case .forward(let deferredBy):
                events.append(last.extrapolate(at: before.advanced(by: -deferredBy)))
            case .backward:
                events.append(last)
            }
        }
    }
    
    func commitTime(upTo: Date) -> Date {
        switch type {
        case .forward(let deferredBy):
            let deferredWhen = upTo.advanced(by: -deferredBy)
            if let last = events.last, last.when > deferredWhen {
                return last.when
            } else {
                return deferredWhen
            }
        case .backward:
            return events.last?.when ?? upTo
        }
    }

    func findOrCreate(at: Date) -> Event? {
        // Get prev and next
        var prev: Event? = nil
        let next = events.first { event in
            if event.when >= at {
                return true
            } else {
                prev = event
                return false
            }
        }
        
        if let found = next, found.when == at {
            return found
        } else if let prev = prev, let next = next {
            return prev.interpolate(at: at, to: next)
        } else if let event = prev ?? next {
            return event.extrapolate(at: at)
        } else {
            return nil
        }
    }
}

// MARK: - Status

struct Status<C0, C1, C2, C3, C4, C5, C6, C7, C8> {
    let when: Date
    let c0: C0?
    let c1: C1?
    let c2: C2?
    let c3: C3?
    let c4: C4?
    let c5: C5?
    let c6: C6?
    let c7: C7?
    let c8: C8?

    fileprivate init<
        S0: Publisher,
        S1: Publisher,
        S2: Publisher,
        S3: Publisher,
        S4: Publisher,
        S5: Publisher,
        S6: Publisher,
        S7: Publisher,
        S8: Publisher>
    (
        when: Date,
        eq0: EventQueue<S0>,
        eq1: EventQueue<S1>,
        eq2: EventQueue<S2>,
        eq3: EventQueue<S3>,
        eq4: EventQueue<S4>,
        eq5: EventQueue<S5>,
        eq6: EventQueue<S6>,
        eq7: EventQueue<S7>,
        eq8: EventQueue<S8>)
    where S0.Output: Event, S0.Output.Content == C0,
          S1.Output: Event, S1.Output.Content == C1,
          S2.Output: Event, S2.Output.Content == C2,
          S3.Output: Event, S3.Output.Content == C3,
          S4.Output: Event, S4.Output.Content == C4,
          S5.Output: Event, S5.Output.Content == C5,
          S6.Output: Event, S6.Output.Content == C6,
          S7.Output: Event, S7.Output.Content == C7,
          S8.Output: Event, S8.Output.Content == C8
    {
        self.when = when
        c0 = eq0.findOrCreate(at: when)?.content
        c1 = eq1.findOrCreate(at: when)?.content
        c2 = eq2.findOrCreate(at: when)?.content
        c3 = eq3.findOrCreate(at: when)?.content
        c4 = eq4.findOrCreate(at: when)?.content
        c5 = eq5.findOrCreate(at: when)?.content
        c6 = eq6.findOrCreate(at: when)?.content
        c7 = eq7.findOrCreate(at: when)?.content
        c8 = eq8.findOrCreate(at: when)?.content
    }
}

enum StatusType<C0, C1, C2, C3, C4, C5, C6, C7, C8> {
    case rollback(after: Date)
    case commit(before: Date)
    case status(_ status: Status<C0, C1, C2, C3, C4, C5, C6, C7, C8>)
    case publish
}

// MARK: - Status Queue

class StatusQueue<
    E0: Event,
    E1: Event,
    E2: Event,
    E3: Event,
    E4: Event,
    E5: Event,
    E6: Event,
    E7: Event,
    E8: Event,
    Failure: Error>
{
    let publisher = PassthroughSubject<
        StatusType<
            E0.Content,
            E1.Content,
            E2.Content,
            E3.Content,
            E4.Content,
            E5.Content,
            E6.Content,
            E7.Content,
            E8.Content>,
        Failure>()
    private var whens = [BiTemporalWhen]()
    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>
    
    init<
        S0: Publisher,
        S1: Publisher,
        S2: Publisher,
        S3: Publisher,
        S4: Publisher,
        S5: Publisher,
        S6: Publisher,
        S7: Publisher,
        S8: Publisher>
    (
        eq0: EventQueue<S0>,
        eq1: EventQueue<S1>,
        eq2: EventQueue<S2>,
        eq3: EventQueue<S3>,
        eq4: EventQueue<S4>,
        eq5: EventQueue<S5>,
        eq6: EventQueue<S6>,
        eq7: EventQueue<S7>,
        eq8: EventQueue<S8>,
        publishEvery: TimeInterval)
    where S0.Output == E0,
          S1.Output == E1,
          S2.Output == E2,
          S3.Output == E3,
          S4.Output == E4,
          S5.Output == E5,
          S6.Output == E6,
          S7.Output == E7,
          S8.Output == E8,
          S0.Failure == Failure,
          S1.Failure == Failure,
          S2.Failure == Failure,
          S3.Failure == Failure,
          S4.Failure == Failure,
          S5.Failure == Failure,
          S6.Failure == Failure,
          S7.Failure == Failure,
          S8.Failure == Failure
    {
        timer = Timer
            .publish(every: publishEvery, tolerance: 0.5, on: .current, in: .common)
            .autoconnect()
        timer
            .sink { at in
                self.timer(at: at, eq0, eq1, eq2, eq3, eq4, eq5, eq6, eq7, eq8)
            }
            .store(in: &subscribers)
        
        eq0.publisher
            .merge(with: eq1.publisher, eq2.publisher, eq3.publisher, eq4.publisher)
            .merge(with: eq5.publisher, eq6.publisher, eq7.publisher, eq8.publisher)
            .sink { completion in
                self.complete(with: completion)
            } receiveValue: { when in
                self.event(when: when, eq0, eq1, eq2, eq3, eq4, eq5, eq6, eq7, eq8)
            }
            .store(in: &subscribers)
    }
    
    private func timer<
        S0: Publisher,
        S1: Publisher,
        S2: Publisher,
        S3: Publisher,
        S4: Publisher,
        S5: Publisher,
        S6: Publisher,
        S7: Publisher,
        S8: Publisher>
    (
        at: Date,
        _ eq0: EventQueue<S0>,
        _ eq1: EventQueue<S1>,
        _ eq2: EventQueue<S2>,
        _ eq3: EventQueue<S3>,
        _ eq4: EventQueue<S4>,
        _ eq5: EventQueue<S5>,
        _ eq6: EventQueue<S6>,
        _ eq7: EventQueue<S7>,
        _ eq8: EventQueue<S8>)
    where S0.Output == E0,
          S1.Output == E1,
          S2.Output == E2,
          S3.Output == E3,
          S4.Output == E4,
          S5.Output == E5,
          S6.Output == E6,
          S7.Output == E7,
          S8.Output == E8,
          S0.Failure == Failure,
          S1.Failure == Failure,
          S2.Failure == Failure,
          S3.Failure == Failure,
          S4.Failure == Failure,
          S5.Failure == Failure,
          S6.Failure == Failure,
          S7.Failure == Failure,
          S8.Failure == Failure
    {
        guard let lastWhenEvent = whens.last?.event else {return}

        // Invalidate after last when
        publisher.send(.rollback(after: lastWhenEvent))

        // Send status, extrapolated up to now
        publisher.send(
            .status(
                Status(
                    when: at,
                    eq0: eq0, eq1: eq1, eq2: eq2, eq3: eq3, eq4: eq4,
                    eq5: eq5, eq6: eq6, eq7: eq7, eq8: eq8)))

        // Send publish
        publisher.send(.publish)
    }
    
    private func complete(with completion: Subscribers.Completion<Failure>) {
        // whens.removeAll()
        timer.upstream.connect().cancel()
        publisher.send(completion: completion)
    }
    
    private func event<
        S0: Publisher,
        S1: Publisher,
        S2: Publisher,
        S3: Publisher,
        S4: Publisher,
        S5: Publisher,
        S6: Publisher,
        S7: Publisher,
        S8: Publisher>
    (
        when: BiTemporalWhen,
        _ eq0: EventQueue<S0>,
        _ eq1: EventQueue<S1>,
        _ eq2: EventQueue<S2>,
        _ eq3: EventQueue<S3>,
        _ eq4: EventQueue<S4>,
        _ eq5: EventQueue<S5>,
        _ eq6: EventQueue<S6>,
        _ eq7: EventQueue<S7>,
        _ eq8: EventQueue<S8>)
    where S0.Output == E0,
          S1.Output == E1,
          S2.Output == E2,
          S3.Output == E3,
          S4.Output == E4,
          S5.Output == E5,
          S6.Output == E6,
          S7.Output == E7,
          S8.Output == E8,
          S0.Failure == Failure,
          S1.Failure == Failure,
          S2.Failure == Failure,
          S3.Failure == Failure,
          S4.Failure == Failure,
          S5.Failure == Failure,
          S6.Failure == Failure,
          S7.Failure == Failure,
          S8.Failure == Failure
    {
        // Invalidate all future status
        publisher.send(.rollback(after: when.impact))
        
        // Insert new status, sorted
        whens.append(when)
        whens.sort {$0.event <= $1.event}
        
        // Resend all status after impact
        let idx = whens.firstIndex(where: {($0.event > when.impact) || ($0.event >= when.event)}) ?? whens.endIndex
        whens.suffix(from: idx).forEach {
            publisher.send(
                .status(
                    Status(
                        when: $0.event,
                        eq0: eq0, eq1: eq1, eq2: eq2, eq3: eq3, eq4: eq4,
                        eq5: eq5, eq6: eq6, eq7: eq7, eq8: eq8)))
        }

        // Commit defensive earliest event-Q commit-time
        guard let lastWhenEvent = whens.last?.event else {return}
        guard let minCommitTime = [
            eq0.commitTime(upTo: lastWhenEvent),
            eq1.commitTime(upTo: lastWhenEvent),
            eq2.commitTime(upTo: lastWhenEvent),
            eq3.commitTime(upTo: lastWhenEvent),
            eq4.commitTime(upTo: lastWhenEvent),
            eq5.commitTime(upTo: lastWhenEvent),
            eq6.commitTime(upTo: lastWhenEvent),
            eq7.commitTime(upTo: lastWhenEvent),
            eq8.commitTime(upTo: lastWhenEvent)
        ].min() else {return}
        
        eq0.commit(before: minCommitTime)
        eq1.commit(before: minCommitTime)
        eq2.commit(before: minCommitTime)
        eq3.commit(before: minCommitTime)
        eq4.commit(before: minCommitTime)
        eq5.commit(before: minCommitTime)
        eq6.commit(before: minCommitTime)
        eq7.commit(before: minCommitTime)
        eq8.commit(before: minCommitTime)
        whens.removeAll {$0.event < minCommitTime}
        publisher.send(.commit(before: minCommitTime))
    }
}
