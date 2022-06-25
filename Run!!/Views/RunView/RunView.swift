//
//  RunViiew.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import SwiftUI
import MapKit

struct RunView: View {
    @Binding var selection: Int
    @AppStorage("RunViewSelection") private var runSelection: Int = 0

    @ObservedObject private var timeseriesSet = AppTwin.shared.timeseriesSet
    @State private var size: CGSize = .zero

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            HStack {
                // TODO: Is it possible to get rid of the start button?
                Button {
                    if isWorkingOut {
                        AppTwin.shared.workoutClient.stop(asOf: .now)
                        timeseriesSet.refreshStatus(asOf: .now)
                        selection = 1
                    } else {
                        AppTwin.shared.workoutClient.start(asOf: .now)
                        timeseriesSet.refreshStatus(asOf: .now)
                    }
                } label: {
                    VStack(spacing: 0) {
                        Image(systemName: "\(isWorkingOut ? "stop" : "play").circle").font(.title)
                        Text(isWorkingOut ? "stop" : "start").font(.caption)
                    }
                    .foregroundColor(.accentColor)
                    .padding()
                }
                Spacer()
                Text("Lock Button") // TODO: Implement
                Spacer()
                RunClientStatusView(
                    stcStatus: AppTwin.shared.sensorClients[0].status,
                    hrmStatus: AppTwin.shared.sensorClients[4].status,
                    gpsStatus: AppTwin.shared.sensorClients[3].status,
                    intensity: timeseriesSet.status?.intensity,
                    locationsNotEmpty: !timeseriesSet.locationTimeseries.elements.isEmpty,
                    heartratesNotEmpty: !timeseriesSet.heartrateTimeseries.elements.isEmpty)
            }
            TabView(selection: $runSelection) {
                RunMapCurrentsTotalsTextView(
                    size: size,
                    path: timeseriesSet.pathTimeseries.elements,
                    gpsStatus: AppTwin.shared.sensorClients[3].status,
                    totals: timeseriesSet.totals,
                    status: timeseriesSet.status,
                    hrmStatus: AppTwin.shared.sensorClients[4].status,
                    selection: $selection)
                    .refresh {await refresh()}
                    .tag(1)
                RunCurrentsTotalsGraphView(
                    size: size,
                    totals: timeseriesSet.totals,
                    status: timeseriesSet.status,
                    hrmStatus: AppTwin.shared.sensorClients[4].status,
                    selection: $selection)
                    .refresh {await refresh()}
                    .tag(2)
                RunCurrentsTotalsTextView(
                    size: size,
                    totals: timeseriesSet.totals,
                    status: timeseriesSet.status,
                    hrmStatus: AppTwin.shared.sensorClients[4].status,
                    selection: $selection)
                    .refresh {await refresh()}
                    .tag(3)
                RunMapCurrentsView(
                    size: size,
                    path: timeseriesSet.pathTimeseries.elements,
                    gpsStatus: AppTwin.shared.sensorClients[3].status,
                    status: timeseriesSet.status,
                    hrmStatus: AppTwin.shared.sensorClients[4].status,
                    selection: $selection)
                    .refresh {await refresh()}
                    .tag(4)
                RunMapTotalsTextView(
                    size: size,
                    path: timeseriesSet.pathTimeseries.elements,
                    gpsStatus: AppTwin.shared.sensorClients[3].status,
                    totals: timeseriesSet.totals)
                    .refresh {await refresh()}
                    .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .captureSize(in: $size)
        }
        .animation(.default, value: selection)
        .onReceive(timer) {
            timeseriesSet.refreshTotals(upTo: $0)
            timeseriesSet.refreshStatus(asOf: $0)
        }
    }

    private func refresh() {
        let now = Date.now
        AppTwin.shared.sensorClients.forEach {$0.stop(asOf: now)}
        AppTwin.shared.sensorClients.forEach {$0.start(asOf: now)}
    }
    
    private var isWorkingOut: Bool {
        guard let status = timeseriesSet.status, let isWorkingOut = status.isWorkingOut else {return false}
        return isWorkingOut
    }
}

private struct RunMapCurrentsTotalsTextView: View {
    let size: CGSize
    let path: [PathEvent]
    let gpsStatus: ClientStatus
    let totals: [TimeSeriesSet.Total]
    let status: TimeSeriesSet.WorkoutStatus?
    let hrmStatus: ClientStatus
    @Binding var selection: Int

    var body: some View {
        VStack {
            RunMapView(
                size: size,
                path: path,
                gpsStatus: gpsStatus)
                .frame(height: size.height * 0.9 * 0.5)

            RunCurrentsView(
                heartrate: status?.heartrate,
                intensity: status?.intensity,
                hrLimits: Profile.hrLimits.value,
                duration: status?.duration,
                distance: status?.distance ?? 0,
                speed: status?.speed,
                vdot: status?.vdot,
                cadence: status?.cadence,
                isActive: status?.isActive,
                hrmStatus: hrmStatus,
                peripheralName: status?.peripheralName,
                batteryLevel: status?.batteryLevel,
                selection: $selection)
                .frame(height: size.height * 0.9 * 0.3)

            RunTotalsView(graphical: false, totals: totals)
                .frame(height: size.height * 0.9 * 0.2)
        }
    }
}

private struct RunCurrentsTotalsGraphView: View {
    let size: CGSize
    let totals: [TimeSeriesSet.Total]
    let status: TimeSeriesSet.WorkoutStatus?
    let hrmStatus: ClientStatus
    @Binding var selection: Int

    var body: some View {
        VStack {
            RunCurrentsView(
                heartrate: status?.heartrate,
                intensity: status?.intensity,
                hrLimits: Profile.hrLimits.value,
                duration: status?.duration,
                distance: status?.distance ?? 0,
                speed: status?.speed,
                vdot: status?.vdot,
                cadence: status?.cadence,
                isActive: status?.isActive,
                hrmStatus: hrmStatus,
                peripheralName: status?.peripheralName,
                batteryLevel: status?.batteryLevel,
                selection: $selection)
                .frame(height: size.height * 0.9 * 0.6)

            RunTotalsView(graphical: true, totals: totals)
                .frame(height: size.height * 0.9 * 0.4)
        }
    }
}

private struct RunCurrentsTotalsTextView: View {
    let size: CGSize
    let totals: [TimeSeriesSet.Total]
    let status: TimeSeriesSet.WorkoutStatus?
    let hrmStatus: ClientStatus
    @Binding var selection: Int

    var body: some View {
        VStack {
            RunCurrentsView(
                heartrate: status?.heartrate,
                intensity: status?.intensity,
                hrLimits: Profile.hrLimits.value,
                duration: status?.duration,
                distance: status?.distance ?? 0,
                speed: status?.speed,
                vdot: status?.vdot,
                cadence: status?.cadence,
                isActive: status?.isActive,
                hrmStatus: hrmStatus,
                peripheralName: status?.peripheralName,
                batteryLevel: status?.batteryLevel,
                selection: $selection)
                .frame(height: size.height * 0.9 * 0.6)

            RunTotalsView(graphical: false, totals: totals)
                .frame(height: size.height * 0.9 * 0.4)
        }
    }
}

private struct RunMapCurrentsView: View {
    let size: CGSize
    let path: [PathEvent]
    let gpsStatus: ClientStatus
    let status: TimeSeriesSet.WorkoutStatus?
    let hrmStatus: ClientStatus
    @Binding var selection: Int

    var body: some View {
        VStack {
            RunMapView(
                size: size,
                path: path,
                gpsStatus: gpsStatus)
                .frame(height: size.height * 0.9 * 0.7)

            RunCurrentsView(
                heartrate: status?.heartrate,
                intensity: status?.intensity,
                hrLimits: Profile.hrLimits.value,
                duration: status?.duration,
                distance: status?.distance ?? 0,
                speed: status?.speed,
                vdot: status?.vdot,
                cadence: status?.cadence,
                isActive: status?.isActive,
                hrmStatus: hrmStatus,
                peripheralName: status?.peripheralName,
                batteryLevel: status?.batteryLevel,
                selection: $selection)
                .frame(height: size.height * 0.9 * 0.3)
        }
    }
}

private struct RunMapTotalsTextView: View {
    let size: CGSize
    let path: [PathEvent]
    let gpsStatus: ClientStatus
    let totals: [TimeSeriesSet.Total]

    var body: some View {
        VStack {
            RunMapView(
                size: size,
                path: path,
                gpsStatus: gpsStatus)
                .frame(height: size.height * 0.9 * 0.7)

            RunTotalsView(graphical: false, totals: totals)
                .frame(height: size.height * 0.9 * 0.3)
        }
    }
}

#if DEBUG
struct RunView_Previews: PreviewProvider {
    static var previews: some View {
        RunView(selection: .constant(5))
    }
}
#endif
