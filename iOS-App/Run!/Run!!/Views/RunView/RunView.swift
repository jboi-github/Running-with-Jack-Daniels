//
//  RunViiew.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import SwiftUI
import MapKit

//struct RunView: View {
//    @Binding var selection: Int
//    @AppStorage("RunViewSelection") private var runSelection: Int = 0
//
//    @ObservedObject private var currents = AppTwin.shared.currents
//    @ObservedObject private var workout = AppTwin.shared.workout
//    @State private var size: CGSize = .zero
//
//    var body: some View {
//        VStack {
//            HStack {
//                if workout.status.canStop {
//                    Button {
//                        AppTwin.shared.workout.stop(asOf: .now)
//                        selection = 1
//                    } label: {
//                        VStack(spacing: 0) {
//                            Image(systemName: "stop.circle").font(.title)
//                            Text("stop").font(.caption)
//                        }
//                        .foregroundColor(.accentColor)
//                        .padding()
//                    }
//                }
//                Spacer()
//                Text("Lock Button") // TODO: Implement
//                Spacer()
//                RunStatusView(
//                    stcStatus: currents.stcStatus,
//                    hrmStatus: currents.hrmStatus,
//                    gpsStatus: currents.gpsStatus,
//                    intensity: currents.intensity,
//                    locationsNotEmpty: !workout.locations.isEmpty,
//                    heartratesNotEmpty: !workout.heartrates.isEmpty)
//            }
//            TabView(selection: $runSelection) {
//                PdmGridView()
//                    .refresh {await refresh()}
//                    .tag(0)
//                RunMapCurrentsTotalsTextView(size: size, selection: $selection)
//                    .refresh {await refresh()}
//                    .tag(1)
//                RunCurrentsTotalsGraphView(size: size, selection: $selection)
//                    .refresh {await refresh()}
//                    .tag(2)
//                RunCurrentsTotalsTextView(size: size, selection: $selection)
//                    .refresh {await refresh()}
//                    .tag(3)
//                RunMapCurrentsView(size: size, selection: $selection)
//                    .refresh {await refresh()}
//                    .tag(4)
//                RunMapTotalsTextView(size: size)
//                    .refresh {await refresh()}
//                    .tag(5)
//            }
//            .tabViewStyle(.page(indexDisplayMode: .automatic))
//            .captureSize(in: $size)
//        }
//        .animation(.default, value: workout.status)
//        .animation(.default, value: selection)
//    }
//
//    private func refresh() {
////        AppTwin.shared.hrmTwin.stop(asOf: .now)
////        AppTwin.shared.hrmTwin.start(asOf: .now)
////
////        AppTwin.shared.gpsTwin.stop(asOf: .now)
////        AppTwin.shared.gpsTwin.start(asOf: .now)
//    }
//}
//
//private struct RunMapCurrentsTotalsTextView: View {
//    let size: CGSize
//    @Binding var selection: Int
//    @ObservedObject private var currents = AppTwin.shared.currents
//    @ObservedObject private var workout = AppTwin.shared.workout
//
//    var body: some View {
//        VStack {
//            RunMapView(
//                path: workout.locations,
//                intensityGetter: {AppTwin.shared.intensities.intensities[$0]?.intensity},
//                gpsStatus: currents.gpsStatus)
//                .frame(height: size.height * 0.9 * 0.5)
//
//            RunCurrentsView(
//                heartrate: currents.heartrate,
//                intensity: currents.intensity,
//                hrLimits: Profile.hrLimits.value,
//                duration: currents.duration,
//                distance: currents.distance,
//                speed: currents.speed,
//                vdot: currents.vdot,
//                cadence: currents.cadence,
//                isActive: currents.isActive,
//                hrmStatus: currents.hrmStatus,
//                peripheralName: currents.peripheralName,
//                batteryLevel: currents.batteryLevel,
//                selection: $selection)
//                .frame(height: size.height * 0.9 * 0.3)
//
//            RunTotalsView(graphical: false, totals: AppTwin.shared.workout.totals)
//                .frame(height: size.height * 0.9 * 0.2)
//        }
//    }
//}
//
//private struct RunCurrentsTotalsGraphView: View {
//    let size: CGSize
//    @Binding var selection: Int
//    @ObservedObject private var currents = AppTwin.shared.currents
//
//    var body: some View {
//        VStack {
//            RunCurrentsView(
//                heartrate: currents.heartrate,
//                intensity: currents.intensity,
//                hrLimits: Profile.hrLimits.value,
//                duration: currents.duration,
//                distance: currents.distance,
//                speed: currents.speed,
//                vdot: currents.vdot,
//                cadence: currents.cadence,
//                isActive: currents.isActive,
//                hrmStatus: currents.hrmStatus,
//                peripheralName: currents.peripheralName,
//                batteryLevel: currents.batteryLevel,
//                selection: $selection)
//                .frame(height: size.height * 0.9 * 0.6)
//
//            RunTotalsView(graphical: true, totals: AppTwin.shared.workout.totals)
//                .frame(height: size.height * 0.9 * 0.4)
//        }
//    }
//}
//
//private struct RunCurrentsTotalsTextView: View {
//    let size: CGSize
//    @Binding var selection: Int
//    @ObservedObject private var currents = AppTwin.shared.currents
//
//    var body: some View {
//        VStack {
//            RunCurrentsView(
//                heartrate: currents.heartrate,
//                intensity: currents.intensity,
//                hrLimits: Profile.hrLimits.value,
//                duration: currents.duration,
//                distance: currents.distance,
//                speed: currents.speed,
//                vdot: currents.vdot,
//                cadence: currents.cadence,
//                isActive: currents.isActive,
//                hrmStatus: currents.hrmStatus,
//                peripheralName: currents.peripheralName,
//                batteryLevel: currents.batteryLevel,
//                selection: $selection)
//                .frame(height: size.height * 0.9 * 0.6)
//
//            RunTotalsView(graphical: false, totals: AppTwin.shared.workout.totals)
//                .frame(height: size.height * 0.9 * 0.4)
//        }
//    }
//}
//
//private struct RunMapCurrentsView: View {
//    let size: CGSize
//    @Binding var selection: Int
//    @ObservedObject private var currents = AppTwin.shared.currents
//    @ObservedObject private var workout = AppTwin.shared.workout
//
//    var body: some View {
//        VStack {
//            RunMapView(
//                path: workout.locations,
//                intensityGetter: {AppTwin.shared.intensities.intensities[$0]?.intensity},
//                gpsStatus: AppTwin.shared.currents.gpsStatus)
//                .frame(height: size.height * 0.9 * 0.7)
//
//            RunCurrentsView(
//                heartrate: currents.heartrate,
//                intensity: currents.intensity,
//                hrLimits: Profile.hrLimits.value,
//                duration: currents.duration,
//                distance: currents.distance,
//                speed: currents.speed,
//                vdot: currents.vdot,
//                cadence: currents.cadence,
//                isActive: currents.isActive,
//                hrmStatus: currents.hrmStatus,
//                peripheralName: currents.peripheralName,
//                batteryLevel: currents.batteryLevel,
//                selection: $selection)
//                .frame(height: size.height * 0.9 * 0.3)
//        }
//    }
//}
//
//private struct RunMapTotalsTextView: View {
//    let size: CGSize
//    @ObservedObject private var workout = AppTwin.shared.workout
//
//    var body: some View {
//        VStack {
//            RunMapView(
//                path: workout.locations,
//                intensityGetter: {AppTwin.shared.intensities.intensities[$0]?.intensity},
//                gpsStatus: AppTwin.shared.currents.gpsStatus)
//                .frame(height: size.height * 0.9 * 0.7)
//
//            RunTotalsView(graphical: false, totals: AppTwin.shared.workout.totals)
//                .frame(height: size.height * 0.9 * 0.3)
//        }
//    }
//}

struct RunView: View {
    @Binding var selection: Int
    
    @ObservedObject private var workoutClient = AppTwin.shared.workoutClient
    @ObservedObject private var locationClient = AppTwin.shared.locationClient
    @ObservedObject private var pedometerDataClient = AppTwin.shared.pedometerDataClient
    @ObservedObject private var pedometerEventClient = AppTwin.shared.pedometerEventClient
    @ObservedObject private var motionActivityClient = AppTwin.shared.motionActivityClient
    
    var body: some View {
        VStack {
            Group {
                HStack {
                    Text("Locations:")
                    Spacer()
                    Text("\(locationClient.counter)")
                    Text(Image(systemName: locationClient.status.systemName))
                }
                HStack {
                    Text("Pedometer Data:")
                    Spacer()
                    Text("\(pedometerDataClient.counter)")
                    Text(Image(systemName: pedometerDataClient.status.systemName))
                }
                HStack {
                    Text("Pedometer Events:")
                    Spacer()
                    Text("\(pedometerEventClient.counter)")
                    Text(Image(systemName: pedometerEventClient.status.systemName))
                }
                HStack {
                    Text("Motion Activities:")
                    Spacer()
                    Text("\(motionActivityClient.counter)")
                    Text(Image(systemName: motionActivityClient.status.systemName))
                }
            }
            .font(.headline)
            Spacer()
            Button {
                if workoutIsStarted {
                    workoutClient.stop(asOf: .now)
                } else {
                    workoutClient.start(asOf: .now)
                }
            } label: {
                Text(Image(systemName: workoutIsStarted ? "stop.fill" : "play.fill"))
            }
            .font(.largeTitle)
            Spacer()
        }
    }
    
    private var workoutIsStarted: Bool {
        if case .started = workoutClient.status {
            return true
        } else {
            return false
        }
    }
}

extension ClientStatus {
    var systemName: String {
        switch self {
        case .stopped:
            return "figure.stand"
        case .started:
            return "checkmark"
        case .notAllowed:
            return "hand.raised.slash.fill"
        case .notAvailable:
            return "nosign"
        }
    }
}

struct RunView_Previews: PreviewProvider {
    static var previews: some View {
        RunView(selection: .constant(5))
    }
}
