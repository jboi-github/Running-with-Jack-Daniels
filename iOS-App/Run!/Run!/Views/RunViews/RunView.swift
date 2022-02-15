//
//  RunView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI
import CoreLocation

struct RunView: View {
    @Binding var isLocked: Bool

    @State private var size: CGSize = .zero
    @State private var currentDate = Date()
    @State private var unlockedSince = Date.distantFuture
    
    @Environment(\.scenePhase) private var scenePhase
    
    // get changes on active state
    @ObservedObject var currents = CurrentsService.sharedInstance

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView {
            RunMapCurrentsTotalsTextView(size: size, upTo: currentDate)
            RunCurrentsTotalsGraphView(size: size, upTo: currentDate)
            RunCurrentsTotalsTextView(size: size, upTo: currentDate)
            RunMapCurrentsView(size: size, upTo: currentDate)
            RunMapTotalsTextView(size: size, upTo: currentDate)
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
            if !isLocked {unlockedSince = min(unlockedSince, currentDate)}
            if unlockedSince.distance(to: currentDate) >= 3 && currents.isActive.isActive {
                unlockedSince = .distantFuture
                isLocked = true
            }
        }
    }
}

private func totals(upTo: Date)
-> (totals: [TotalsService.Total], duration: TimeInterval, distance: CLLocationDistance)
{
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

private func peripheralName(_ peripheralUuid: UUID) -> String {
    BleProducer.sharedInstance.peripherals[peripheralUuid]?.name ?? "-"
}

private struct RunCurrentsTotalsGraphView: View {
    let size: CGSize
    let upTo: Date
    
    var body: some View {
        let t = totals(upTo: upTo)
        return List {
            Section {
                RunCurrentsView(
                    hr: CurrentsService.sharedInstance.heartrate.heartrate,
                    intensity: CurrentsService.sharedInstance.intensity.intensity,
                    intensities: ProfileService.sharedInstance.hrLimits.value,
                    duration: t.duration,
                    distance: t.distance,
                    pace: 1000.0 / CurrentsService.sharedInstance.speed.speedMperSec,
                    vdot: vdot(
                        t.distance,
                        CurrentsService.sharedInstance.heartrate.heartrate,
                        1000.0 / CurrentsService.sharedInstance.speed.speedMperSec,
                        ProfileService.sharedInstance.hrLimits.value),
                    activityType: CurrentsService.sharedInstance.isActive.type,
                    status: CurrentsService.sharedInstance.bleStatus,
                    peripheralName: peripheralName(CurrentsService.sharedInstance.heartrate.peripheralUuid),
                    batteryStatus: 50) // TODO: !
            }
            .frame(height: size.height * 0.9 * 0.6)
            Section {
                RunTotalsView(graphical: true, totals: t.totals)
            }
            .frame(height: size.height * 0.9 * 0.4)
        }
        .listStyle(PlainListStyle())
    }
}

private struct RunCurrentsTotalsTextView: View {
    let size: CGSize
    let upTo: Date

    var body: some View {
        let t = totals(upTo: upTo)
        return List {
            Section {
                RunCurrentsView(
                    hr: CurrentsService.sharedInstance.heartrate.heartrate,
                    intensity: CurrentsService.sharedInstance.intensity.intensity,
                    intensities: ProfileService.sharedInstance.hrLimits.value,
                    duration: t.duration,
                    distance: t.distance,
                    pace: 1000.0 / CurrentsService.sharedInstance.speed.speedMperSec,
                    vdot: vdot(
                        t.distance,
                        CurrentsService.sharedInstance.heartrate.heartrate,
                        1000.0 / CurrentsService.sharedInstance.speed.speedMperSec,
                        ProfileService.sharedInstance.hrLimits.value),
                    activityType: CurrentsService.sharedInstance.isActive.type,
                    status: CurrentsService.sharedInstance.bleStatus,
                    peripheralName: peripheralName(CurrentsService.sharedInstance.heartrate.peripheralUuid),
                    batteryStatus: 50) // TODO: !
            }
            .frame(height: size.height * 0.9 * 0.6)
            Section {
                RunTotalsView(graphical: false, totals: t.totals)
            }
            .frame(height: size.height * 0.9 * 0.4)
        }
        .listStyle(PlainListStyle())
    }
}

private struct RunMapCurrentsTotalsTextView: View {
    let size: CGSize
    let upTo: Date

    var body: some View {
        let t = totals(upTo: upTo)
        return List {
            Section {
                RunMapView(path: PathService.sharedInstance.path, status: CurrentsService.sharedInstance.gpsStatus)
            }
            .frame(height: size.height * 0.9 * 0.5)
            Section {
                RunCurrentsView(
                    hr: CurrentsService.sharedInstance.heartrate.heartrate,
                    intensity: CurrentsService.sharedInstance.intensity.intensity,
                    intensities: ProfileService.sharedInstance.hrLimits.value,
                    duration: t.duration,
                    distance: t.distance,
                    pace: 1000.0 / CurrentsService.sharedInstance.speed.speedMperSec,
                    vdot: vdot(
                        t.distance,
                        CurrentsService.sharedInstance.heartrate.heartrate,
                        1000.0 / CurrentsService.sharedInstance.speed.speedMperSec,
                        ProfileService.sharedInstance.hrLimits.value),
                    activityType: CurrentsService.sharedInstance.isActive.type,
                    status: CurrentsService.sharedInstance.bleStatus,
                    peripheralName: peripheralName(CurrentsService.sharedInstance.heartrate.peripheralUuid),
                    batteryStatus: 50) // TODO: !
            }
            .frame(height: size.height * 0.9 * 0.3)
            Section {
                RunTotalsView(graphical: false, totals: t.totals)
            }
            .frame(height: size.height * 0.9 * 0.2)
        }
        .listStyle(PlainListStyle())
    }
}

private struct RunMapCurrentsView: View {
    let size: CGSize
    let upTo: Date

    var body: some View {
        let t = totals(upTo: upTo)
        return List {
            Section {
                RunMapView(path: PathService.sharedInstance.path, status: CurrentsService.sharedInstance.gpsStatus)
            }
            .frame(height: size.height * 0.9 * 0.7)
            Section {
                RunCurrentsView(
                    hr: CurrentsService.sharedInstance.heartrate.heartrate,
                    intensity: CurrentsService.sharedInstance.intensity.intensity,
                    intensities: ProfileService.sharedInstance.hrLimits.value,
                    duration: t.duration,
                    distance: t.distance,
                    pace: 1000.0 / CurrentsService.sharedInstance.speed.speedMperSec,
                    vdot: vdot(
                        t.distance,
                        CurrentsService.sharedInstance.heartrate.heartrate,
                        1000.0 / CurrentsService.sharedInstance.speed.speedMperSec,
                        ProfileService.sharedInstance.hrLimits.value),
                    activityType: CurrentsService.sharedInstance.isActive.type,
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
    let upTo: Date

    var body: some View {
        let t = totals(upTo: upTo)
        return List {
            Text("\(size.height)")
            Section {
                RunMapView(path: PathService.sharedInstance.path, status: CurrentsService.sharedInstance.gpsStatus)
            }
            .frame(height: size.height * 0.9 * 0.7)
            Section {
                RunTotalsView(graphical: false, totals: t.totals)
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
