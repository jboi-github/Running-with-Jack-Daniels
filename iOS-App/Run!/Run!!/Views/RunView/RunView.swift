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
    
    @ObservedObject private var currents = AppTwin.shared.currents
    @ObservedObject private var workout = AppTwin.shared.workout
    @State private var size: CGSize = .zero

    var body: some View {
        VStack {
            HStack {
                if workout.status.canStop {
                    Button {
                        AppTwin.shared.workout.stop(asOf: .now)
                        selection = 1
                    } label: {
                        VStack(spacing: 0) {
                            Image(systemName: "stop.circle").font(.title)
                            Text("stop").font(.caption)
                        }
                        .foregroundColor(.accentColor)
                        .padding()
                    }
                }
                Spacer()
                Text("Lock Button") // TODO: Implement
                Spacer()
                RunStatusView(
                    aclStatus: currents.aclStatus,
                    hrmStatus: currents.hrmStatus,
                    gpsStatus: currents.gpsStatus,
                    intensity: currents.intensity,
                    locationsNotEmpty: !workout.locations.isEmpty,
                    heartratesNotEmpty: !workout.heartrates.isEmpty)
            }
            TabView {
                PdmGridView()
                    .refresh {refresh()}
                RunMapCurrentsTotalsTextView(size: size, selection: $selection)
                    .refresh {refresh()}
                RunCurrentsTotalsGraphView(size: size, selection: $selection)
                    .refresh {refresh()}
                RunCurrentsTotalsTextView(size: size, selection: $selection)
                    .refresh {refresh()}
                RunMapCurrentsView(size: size, selection: $selection)
                    .refresh {refresh()}
                RunMapTotalsTextView(size: size)
                    .refresh {refresh()}
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .captureSize(in: $size)
        }
        .animation(.default, value: workout.status)
        .animation(.default, value: selection)
    }
    
    private func refresh() {
        AppTwin.shared.hrmTwin.stop(asOf: .now)
        AppTwin.shared.hrmTwin.start(asOf: .now)
        
        AppTwin.shared.gpsTwin.stop(asOf: .now)
        AppTwin.shared.gpsTwin.start(asOf: .now)
    }
}

private struct RunMapCurrentsTotalsTextView: View {
    let size: CGSize
    @Binding var selection: Int
    @ObservedObject private var currents = AppTwin.shared.currents
    @ObservedObject private var workout = AppTwin.shared.workout

    var body: some View {
        VStack {
            RunMapView(
                path: workout.locations,
                intensityGetter: {AppTwin.shared.intensities.intensities[$0]?.intensity},
                gpsStatus: currents.gpsStatus)
                .frame(height: size.height * 0.9 * 0.5)

            RunCurrentsView(
                heartrate: currents.heartrate,
                intensity: currents.intensity,
                hrLimits: Profile.hrLimits.value,
                duration: currents.duration,
                distance: currents.distance,
                speed: currents.speed,
                vdot: currents.vdot,
                motionType: currents.motionType,
                isActive: currents.isActive,
                hrmStatus: currents.hrmStatus,
                peripheralName: currents.peripheralName,
                batteryLevel: currents.batteryLevel,
                selection: $selection)
                .frame(height: size.height * 0.9 * 0.3)

            RunTotalsView(graphical: false, totals: AppTwin.shared.workout.totals)
                .frame(height: size.height * 0.9 * 0.2)
        }
    }
}

private struct RunCurrentsTotalsGraphView: View {
    let size: CGSize
    @Binding var selection: Int
    @ObservedObject private var currents = AppTwin.shared.currents

    var body: some View {
        VStack {
            RunCurrentsView(
                heartrate: currents.heartrate,
                intensity: currents.intensity,
                hrLimits: Profile.hrLimits.value,
                duration: currents.duration,
                distance: currents.distance,
                speed: currents.speed,
                vdot: currents.vdot,
                motionType: currents.motionType,
                isActive: currents.isActive,
                hrmStatus: currents.hrmStatus,
                peripheralName: currents.peripheralName,
                batteryLevel: currents.batteryLevel,
                selection: $selection)
                .frame(height: size.height * 0.9 * 0.6)

            RunTotalsView(graphical: true, totals: AppTwin.shared.workout.totals)
                .frame(height: size.height * 0.9 * 0.4)
        }
    }
}

private struct RunCurrentsTotalsTextView: View {
    let size: CGSize
    @Binding var selection: Int
    @ObservedObject private var currents = AppTwin.shared.currents

    var body: some View {
        VStack {
            RunCurrentsView(
                heartrate: currents.heartrate,
                intensity: currents.intensity,
                hrLimits: Profile.hrLimits.value,
                duration: currents.duration,
                distance: currents.distance,
                speed: currents.speed,
                vdot: currents.vdot,
                motionType: currents.motionType,
                isActive: currents.isActive,
                hrmStatus: currents.hrmStatus,
                peripheralName: currents.peripheralName,
                batteryLevel: currents.batteryLevel,
                selection: $selection)
                .frame(height: size.height * 0.9 * 0.6)

            RunTotalsView(graphical: false, totals: AppTwin.shared.workout.totals)
                .frame(height: size.height * 0.9 * 0.4)
        }
    }
}

private struct RunMapCurrentsView: View {
    let size: CGSize
    @Binding var selection: Int
    @ObservedObject private var currents = AppTwin.shared.currents
    @ObservedObject private var workout = AppTwin.shared.workout

    var body: some View {
        VStack {
            RunMapView(
                path: workout.locations,
                intensityGetter: {AppTwin.shared.intensities.intensities[$0]?.intensity},
                gpsStatus: AppTwin.shared.currents.gpsStatus)
                .frame(height: size.height * 0.9 * 0.7)

            RunCurrentsView(
                heartrate: currents.heartrate,
                intensity: currents.intensity,
                hrLimits: Profile.hrLimits.value,
                duration: currents.duration,
                distance: currents.distance,
                speed: currents.speed,
                vdot: currents.vdot,
                motionType: currents.motionType,
                isActive: currents.isActive,
                hrmStatus: currents.hrmStatus,
                peripheralName: currents.peripheralName,
                batteryLevel: currents.batteryLevel,
                selection: $selection)
                .frame(height: size.height * 0.9 * 0.3)
        }
    }
}

private struct RunMapTotalsTextView: View {
    let size: CGSize
    @ObservedObject private var workout = AppTwin.shared.workout

    var body: some View {
        VStack {
            RunMapView(
                path: workout.locations,
                intensityGetter: {AppTwin.shared.intensities.intensities[$0]?.intensity},
                gpsStatus: AppTwin.shared.currents.gpsStatus)
                .frame(height: size.height * 0.9 * 0.7)

            RunTotalsView(graphical: false, totals: AppTwin.shared.workout.totals)
                .frame(height: size.height * 0.9 * 0.3)
        }
    }
}

private struct PdmGridView: View {
    @ObservedObject private var steps = AppTwin.shared.steps
    private static let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 9)
    
    var body: some View {
        LazyVGrid(columns: PdmGridView.columns) {
            ForEach(steps.stepsUI) {
                TimeText(time: $0.asOf.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 24*3600), short: true, max: 24*3600)
                //Text("\($0.id.uuidString)")
                Text("\($0.isOriginal ? "T" : "F")")
                Text("\($0.numberOfSteps)")
                DistanceText(distance: $0.distance)
                SpeedText(speed: $0.averageActiveSpeed)
                SpeedText(speed: $0.currentSpeed)
                Text("\($0.currentCadence ?? .nan)")
                DistanceText(distance: $0.metersAscended)
                DistanceText(distance: $0.metersDescended)
            }
        }
        .font(.caption)
        .lineLimit(1)
    }
}

struct RunView_Previews: PreviewProvider {
    static var previews: some View {
        RunView(selection: .constant(5))
    }
}
