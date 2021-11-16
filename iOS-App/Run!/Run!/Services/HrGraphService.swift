//
//  HrGraphService.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import Foundation

class HrGraphService: ObservableObject {
    static let sharedInstance = HrGraphService()
    
    private init() {
        RunService.sharedInstance.subscribe(
            RunService.Config(
                motion: nil,
                aclStatus: nil,
                location: nil,
                gpsStatus: nil,
                heartrate: heartrate,
                bodySensorLocation: nil,
                bleStatus: bleStatus,
                isActive: nil,
                speed: nil,
                intensity: intensity))
    }
    
    // MARK: - Interface
    struct Heartrate: Rangable, Codable {
        let range: Range<Date>
        let heartrate: Int?
        let intensity: Intensity?
    }
    
    struct HrTotal {
        var duration: TimeInterval
        var sumHeartrate: Double
        
        var avgHeartrate: Int {duration > 0 ? Int(sumHeartrate / duration + 0.5) : -1}
        
        fileprivate mutating func add(range: Range<Date>, hr: Int) {
            duration += range.distance
            sumHeartrate += Double(hr) * range.distance
        }
        
        fileprivate mutating func sub(range: Range<Date>, hr: Int) {
            duration -= range.distance
            sumHeartrate -= Double(hr) * range.distance
        }
        
        static var zero: HrTotal {HrTotal(duration: 0, sumHeartrate: 0)}
    }
    
    /// `graph` elements are ordered by there arrival. Usually, this is also timestamp order.
    @Published private(set) var graph = [Heartrate]()
    @Published private(set) var hrSecs = [Intensity: HrTotal]()
    
    func hrSecs(upTo: Date) -> [Intensity: HrTotal] {
        guard let last = graph.last, last.range.upperBound == .distantFuture else {return hrSecs}
        guard let hr = last.heartrate, let intensity = last.intensity else {return hrSecs}

        var hrSecs = hrSecs
        hrSecs[intensity, default: .zero]
            .add(range: last.range.clamped(to: .distantPast ..< upTo), hr: hr)
        return hrSecs
    }
    
    // MARK: - Implementation
    private struct MergeDelegate: RangableMergeDelegate {
        typealias R = Heartrate
        
        func reduce(_ rangable: Heartrate, to: Range<Date>) -> Heartrate {
            Heartrate(range: to, heartrate: rangable.heartrate, intensity: rangable.intensity)
        }
        
        func resolve(_ r1: Heartrate, _ r2: Heartrate, to: Range<Date>) -> Heartrate {
            Heartrate(
                range: to,
                heartrate: r2.heartrate ?? r1.heartrate,
                intensity: r2.intensity ?? r1.intensity)
        }
        
        func drop(_ rangable: Heartrate) {
            guard rangable.range.upperBound < .distantFuture else {return}
            guard let hr = rangable.heartrate, let intensity = rangable.intensity else {return}
            HrGraphService
                .sharedInstance
                .hrSecs[intensity, default: .zero].sub(range: rangable.range, hr: hr)
        }
        
        func add(_ rangable: Heartrate) {
            guard rangable.range.upperBound < .distantFuture else {return}
            guard let hr = rangable.heartrate, let intensity = rangable.intensity else {return}
            HrGraphService
                .sharedInstance
                .hrSecs[intensity, default: .zero].add(range: rangable.range, hr: hr)
        }
    }
    
    private var fileName = ""
    
    private func heartrate(_ heartrate: HeartrateProducer.Heartrate) {
        graph.merge(
            Heartrate(
                range: heartrate.timestamp ..< .distantFuture,
                heartrate: heartrate.heartrate,
                intensity: nil),
            delegate: MergeDelegate())
    }
    
    private func intensity(_ intensityEvent: IntensityProducer.IntensityEvent) {
        graph.merge(
            Heartrate(
                range: intensityEvent.timestamp ..< .distantFuture,
                heartrate: nil,
                intensity: intensityEvent.intensity),
            delegate: MergeDelegate())
    }
    
    private func bleStatus(_ status: BleProducer.Status) {
        let now = Date()
        
        switch status {
        case .started:
            graph.removeAll(keepingCapacity: true)
            hrSecs.removeAll()
            fileName = "heartrate-\(now).json"
        case .stopped:
            if let last = graph.last, last.range.upperBound == .distantFuture {
                graph[graph.lastIndex!] = MergeDelegate()
                    .reduce(last, to: last.range.clamped(to: .distantPast ..< now))
            }
            FileHandling.write(graph, to: fileName)
        case .resumed:
            graph = FileHandling.read([Heartrate].self, from: "heartrate-") ?? []
        default:
            FileHandling.write(graph, to: fileName)
        }
    }
}
