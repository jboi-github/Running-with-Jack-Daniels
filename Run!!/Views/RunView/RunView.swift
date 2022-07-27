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

    @EnvironmentObject private var appStatus: AppStatus
    @EnvironmentObject private var timeseriesSet: TimeSeriesSet
    @EnvironmentObject private var clientSet: ClientsSet
    
    @State private var size: CGSize = .zero

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            HStack {
                ToolbarButton(systemName: "stop.circle", text: "stop") {
                    timeseriesSet.reflect(ResetEvent(date: .now))
                    selection = 1
                }
                ToolbarButton(systemName: "arrow.triangle.capsulepath", text: "reset") {
                    timeseriesSet.reflect(ResetEvent(date: .now))
                }
                Spacer()
                Text("Lock Button") // TODO: Implement
                Spacer()
                RunClientStatusView(
                    stcStatus: clientSet.pedometerDataStatus,
                    hrmStatus: clientSet.heartrateMonitorStatus,
                    gpsStatus: clientSet.locationStatus,
                    intensity: timeseriesSet.status?.intensity,
                    locationsNotEmpty: !timeseriesSet.locationTimeseries.elements.isEmpty,
                    heartratesNotEmpty: !timeseriesSet.heartrateTimeseries.elements.isEmpty)
            }
            ZStack {
                VStack {Spacer(); HStack {Spacer()}}
                TabView(selection: $runSelection) {
                    RunMapCurrentsTotalsTextView(
                        size: size,
                        path: timeseriesSet.pathTimeseries.elements,
                        gpsStatus: clientSet.locationStatus,
                        totals: timeseriesSet.totals,
                        status: timeseriesSet.status,
                        hrmStatus: clientSet.heartrateMonitorStatus,
                        selection: $selection)
                        .tag(1)
                    RunCurrentsTotalsGraphView(
                        size: size,
                        totals: timeseriesSet.totals,
                        status: timeseriesSet.status,
                        hrmStatus: clientSet.heartrateMonitorStatus,
                        selection: $selection)
                        .tag(2)
                    RunCurrentsTotalsTextView(
                        size: size,
                        totals: timeseriesSet.totals,
                        status: timeseriesSet.status,
                        hrmStatus: clientSet.heartrateMonitorStatus,
                        selection: $selection)
                        .tag(3)
                    RunMapCurrentsView(
                        size: size,
                        path: timeseriesSet.pathTimeseries.elements,
                        gpsStatus: clientSet.locationStatus,
                        status: timeseriesSet.status,
                        hrmStatus: clientSet.heartrateMonitorStatus,
                        selection: $selection)
                        .tag(4)
                    RunMapTotalsTextView(
                        size: size,
                        path: timeseriesSet.pathTimeseries.elements,
                        gpsStatus: clientSet.locationStatus,
                        totals: timeseriesSet.totals)
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                // TODO: .refresh {await refresh()}
            }
            .captureSize(in: $size)
        }
        .animation(.default, value: selection)
        .onReceive(timer) {
            timeseriesSet.refreshTotals(upTo: $0)
            clientSet.trigger(asOf: $0)
        }
    }

    private func refresh() {
        let now = Date.now
        clientSet.stopSensors(asOf: now)
        clientSet.startSensors(asOf: now)
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
                .frame(height: size.height * 0.5)

            Divider()

            RunCurrentsView(
                heartrate: status?.heartrate,
                intensity: status?.intensity,
                hrLimits: Profile.hrLimits.value,
                duration: status?.duration,
                distance: status?.distance ?? 0,
                speed: status?.speed,
                vdot: status?.vdot,
                cadence: status?.cadence,
                isActive: status?.motion?.isActive,
                hrmStatus: hrmStatus,
                peripheralName: status?.peripheralName,
                batteryLevel: status?.batteryLevel,
                compact: true,
                selection: $selection)
                .frame(height: size.height * 0.3)

            Divider()

            RunTotalsView(
                size: CGSize(width: size.width, height: size.height * 0.2),
                graphical: false,
                totals: totals)
                .frame(height: size.height * 0.2)

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
                isActive: status?.motion?.isActive,
                hrmStatus: hrmStatus,
                peripheralName: status?.peripheralName,
                batteryLevel: status?.batteryLevel,
                compact: false,
                selection: $selection)
                .frame(height: size.height * 0.6)

            RunTotalsView(size: size, graphical: true, totals: totals)
                .frame(height: size.height * 0.4)
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
                isActive: status?.motion?.isActive,
                hrmStatus: hrmStatus,
                peripheralName: status?.peripheralName,
                batteryLevel: status?.batteryLevel,
                compact: false,
                selection: $selection)
                .frame(height: size.height * 0.6)

            RunTotalsView(size: size, graphical: false, totals: totals)
                .frame(height: size.height * 0.4)
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
                .frame(height: size.height * 0.7)

            RunCurrentsView(
                heartrate: status?.heartrate,
                intensity: status?.intensity,
                hrLimits: Profile.hrLimits.value,
                duration: status?.duration,
                distance: status?.distance ?? 0,
                speed: status?.speed,
                vdot: status?.vdot,
                cadence: status?.cadence,
                isActive: status?.motion?.isActive,
                hrmStatus: hrmStatus,
                peripheralName: status?.peripheralName,
                batteryLevel: status?.batteryLevel,
                compact: true,
                selection: $selection)
                .frame(height: size.height * 0.3)
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
                .frame(height: size.height * 0.7)

            RunTotalsView(size: size, graphical: false, totals: totals)
                .frame(height: size.height * 0.3)
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
