//
//  RunView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI
import CoreLocation

private typealias Totals = (totals: [TotalsService.Total], duration: TimeInterval, distance: CLLocationDistance)

struct RunView: View {
    @Binding var isLocked: Bool

    @State private var size: CGSize = .zero
    @State private var currentDate = Date()
    @State private var unlockedSince = Date.distantFuture
    @State private var totals: Totals = (totals: [], duration: .nan, distance: .nan)
    @State private var vdot: Double = .nan
    @State private var path: [PathService.PathElement] = []
    
    @Environment(\.scenePhase) private var scenePhase

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView {
            RunMapCurrentsTotalsTextView(size: size, path: path, totals: totals, vdot: vdot)
            RunCurrentsTotalsGraphView(size: size, totals: totals, vdot: vdot)
            RunCurrentsTotalsTextView(size: size, totals: totals, vdot: vdot)
            RunMapCurrentsView(size: size, path: path, totals: totals, vdot: vdot)
            RunMapTotalsTextView(size: size, path: path, totals: totals)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .toolbar {
            RunStatusView(
                aclStatus: CurrentsService.sharedInstance.aclStatus,
                bleStatus: CurrentsService.sharedInstance.bleStatus,
                gpsStatus: CurrentsService.sharedInstance.gpsStatus,
                intensity: CurrentsService.sharedInstance.intensity.intensity,
                gpsPath: PathService.sharedInstance.path,
                hrGraph: HrGraphService.sharedInstance.graph)
        }
        .navigationBarTitleDisplayMode(.inline)
        .captureSize(in: $size)
        .onAppear {
            log("start RunService", currentDate)
            RunService.sharedInstance.start(
                producer: RunService.Producer(
                    aclProducer: AclProducer.sharedInstance,
                    bleProducer: BleProducer.sharedInstance,
                    gpsProducer: GpsProducer.sharedInstance),
                asOf: currentDate)
        }
        .onDisappear {
            log("stop RunService", currentDate)
            RunService.sharedInstance.stop(asOf: currentDate)
            isLocked = false
        }
        .onChange(of: scenePhase) {
            switch $0 {
            case .active:
                log("resume RunService", currentDate)
                RunService.sharedInstance.resume(asOf: currentDate)
            case .inactive:
                log("pause RunService", currentDate)
                RunService.sharedInstance.pause(asOf: currentDate)
            default:
                log("no action necessary")
            }
        }
        .onReceive(timer) {
            currentDate = $0
            
            totals = totals(upTo: currentDate)
            vdot = vdot(
                totals.distance,
                CurrentsService.sharedInstance.heartrate.heartrate,
                1000.0 / CurrentsService.sharedInstance.speed.speedMperSec,
                ProfileService.sharedInstance.hrLimits.value)
            path = PathService.sharedInstance.path
            
            if !isLocked {unlockedSince = min(unlockedSince, currentDate)}
            if unlockedSince.distance(to: currentDate) >= 10 && CurrentsService.sharedInstance.isActive.isActive {
                unlockedSince = .distantFuture
                isLocked = true
            }
        }
    }
    
    private func totals(upTo: Date) -> Totals {
        let totals = TotalsService.sharedInstance.totals(upTo: upTo).values.array()
        let distance = totals
            .filter {$0.activityType != .pause}
            .map {$0.distanceM}
            .reduce(0.0, +)
        let duration = totals
            .filter {$0.activityType != .pause}
            .map {$0.durationSec}
            .reduce(0.0, +)
        return (totals, duration, distance)
    }

    private func vdot(
        _ distance: CLLocationDistance,
        _ heartrate: Int,
        _ pace: TimeInterval,
        _ intensities: [Intensity: Range<Int>]?) -> Double
    {
        guard distance > 0 else {return .nan}
        guard heartrate > 0 else {return .nan}
        
        if let intensities = intensities {
            return train(
                hrBpm: heartrate,
                paceSecPerKm: pace,
                limits: intensities) ?? .nan
        } else {
            return .nan
        }
    }
}

private func peripheralName(_ peripheralUuid: UUID) -> String {
    BleProducer.sharedInstance.peripherals[peripheralUuid]?.name ?? "-"
}

private struct RunCurrentsTotalsGraphView: View {
    let size: CGSize
    let totals: Totals
    let vdot: Double
    
    var body: some View {
        List {
            Section {
                RunCurrentsView(
                    hr: CurrentsService.sharedInstance.heartrate.heartrate,
                    intensity: CurrentsService.sharedInstance.intensity.intensity,
                    intensities: ProfileService.sharedInstance.hrLimits.value,
                    duration: totals.duration,
                    distance: totals.distance,
                    pace: 1000.0 / CurrentsService.sharedInstance.speed.speedMperSec,
                    vdot: vdot,
                    activityType: CurrentsService.sharedInstance.isActive.type,
                    isActive: CurrentsService.sharedInstance.isActive.isActive,
                    status: CurrentsService.sharedInstance.bleStatus,
                    peripheralName: peripheralName(CurrentsService.sharedInstance.heartrate.peripheralUuid),
                    batteryStatus: 50) // TODO: !
            }
            .frame(height: size.height * 0.9 * 0.6)
            Section {
                RunTotalsView(graphical: true, totals: totals.totals)
            }
            .frame(height: size.height * 0.9 * 0.4)
        }
        .listStyle(PlainListStyle())
    }
}

private struct RunCurrentsTotalsTextView: View {
    let size: CGSize
    let totals: Totals
    let vdot: Double

    var body: some View {
        List {
            Section {
                RunCurrentsView(
                    hr: CurrentsService.sharedInstance.heartrate.heartrate,
                    intensity: CurrentsService.sharedInstance.intensity.intensity,
                    intensities: ProfileService.sharedInstance.hrLimits.value,
                    duration: totals.duration,
                    distance: totals.distance,
                    pace: 1000.0 / CurrentsService.sharedInstance.speed.speedMperSec,
                    vdot: vdot,
                    activityType: CurrentsService.sharedInstance.isActive.type,
                    isActive: CurrentsService.sharedInstance.isActive.isActive,
                    status: CurrentsService.sharedInstance.bleStatus,
                    peripheralName: peripheralName(CurrentsService.sharedInstance.heartrate.peripheralUuid),
                    batteryStatus: 50) // TODO: !
            }
            .frame(height: size.height * 0.9 * 0.6)
            Section {
                RunTotalsView(graphical: false, totals: totals.totals)
            }
            .frame(height: size.height * 0.9 * 0.4)
        }
        .listStyle(PlainListStyle())
    }
}

private struct RunMapCurrentsTotalsTextView: View {
    let size: CGSize
    let path: [PathService.PathElement]
    let totals: Totals
    let vdot: Double

    var body: some View {
        List {
            Section {
                RunMapView(path: path, status: CurrentsService.sharedInstance.gpsStatus)
            }
            .frame(height: size.height * 0.9 * 0.5)
            Section {
                RunCurrentsView(
                    hr: CurrentsService.sharedInstance.heartrate.heartrate,
                    intensity: CurrentsService.sharedInstance.intensity.intensity,
                    intensities: ProfileService.sharedInstance.hrLimits.value,
                    duration: totals.duration,
                    distance: totals.distance,
                    pace: 1000.0 / CurrentsService.sharedInstance.speed.speedMperSec,
                    vdot: vdot,
                    activityType: CurrentsService.sharedInstance.isActive.type,
                    isActive: CurrentsService.sharedInstance.isActive.isActive,
                    status: CurrentsService.sharedInstance.bleStatus,
                    peripheralName: peripheralName(CurrentsService.sharedInstance.heartrate.peripheralUuid),
                    batteryStatus: 50) // TODO: !
            }
            .frame(height: size.height * 0.9 * 0.3)
            Section {
                RunTotalsView(graphical: false, totals: totals.totals)
            }
            .frame(height: size.height * 0.9 * 0.2)
        }
        .listStyle(PlainListStyle())
    }
}

private struct RunMapCurrentsView: View {
    let size: CGSize
    let path: [PathService.PathElement]
    let totals: Totals
    let vdot: Double

    var body: some View {
        List {
            Section {
                RunMapView(path: path, status: CurrentsService.sharedInstance.gpsStatus)
            }
            .frame(height: size.height * 0.9 * 0.7)
            Section {
                RunCurrentsView(
                    hr: CurrentsService.sharedInstance.heartrate.heartrate,
                    intensity: CurrentsService.sharedInstance.intensity.intensity,
                    intensities: ProfileService.sharedInstance.hrLimits.value,
                    duration: totals.duration,
                    distance: totals.distance,
                    pace: 1000.0 / CurrentsService.sharedInstance.speed.speedMperSec,
                    vdot: vdot,
                    activityType: CurrentsService.sharedInstance.isActive.type,
                    isActive: CurrentsService.sharedInstance.isActive.isActive,
                    status: CurrentsService.sharedInstance.bleStatus,
                    peripheralName: peripheralName(CurrentsService.sharedInstance.heartrate.peripheralUuid),
                    batteryStatus: 50) // TODO: !
            }
            .frame(height: size.height * 0.9 * 0.3)
        }
        .listStyle(PlainListStyle())
    }
}

private struct RunMapTotalsTextView: View {
    let size: CGSize
    let path: [PathService.PathElement]
    let totals: Totals

    var body: some View {
        List {
            Section {
                RunMapView(path: path, status: CurrentsService.sharedInstance.gpsStatus)
            }
            .frame(height: size.height * 0.9 * 0.7)
            Section {
                RunTotalsView(graphical: false, totals: totals.totals)
            }
            .frame(height: size.height * 0.9 * 0.3)
        }
        .listStyle(PlainListStyle())
    }
}

#if DEBUG
struct RunView_Previews: PreviewProvider {
    static var previews: some View {
        RunView(isLocked: .constant(true))
    }
}
#endif
