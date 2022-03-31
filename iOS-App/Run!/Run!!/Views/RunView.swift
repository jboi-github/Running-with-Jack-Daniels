//
//  RunViiew.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import SwiftUI

struct RunView: View {
    @ObservedObject private var timer = AppTwin.shared.timer

    var body: some View {
        List {
            VStack {
                Text("RunView").font(.title).padding()
                Text("\(timer.date.formatted(date: .omitted, time: .standard))").font(.caption)
                HStack {
                    Button {
                        AppTwin.shared.workout.stop(asOf: .now)
                    } label: {
                        Image(systemName: "stop").font(.callout)
                    }
                    .disabled(!AppTwin.shared.workout.status.canStop)
                    .padding()
                    Button {
                        AppTwin.shared.workout.await(asOf: .now)
                    } label: {
                        Image(systemName: "pause").font(.callout)
                    }
                    .disabled(!AppTwin.shared.workout.status.isStopped)
                    .padding()
                }
            }
            .padding()
            HStack {
                VStack {
                    Text("start: \(AppTwin.shared.workout.startTime.formatted(date: .omitted, time: .standard))")
                    Text("now/end: \(AppTwin.shared.workout.endTime.formatted(date: .omitted, time: .standard))")
                }
                Spacer()
                VStack {
                    Text("duration: \(AppTwin.shared.workout.duration, specifier: "%.0f")")
                    Text("distance: \(AppTwin.shared.workout.distance, specifier: "%.1f")")
                }
            }.font(.caption)
            DetailsView(asOf: timer.date).padding()
        }
        .refreshable {
            AppTwin.shared.hrmTwin.stop(asOf: .now)
            AppTwin.shared.hrmTwin.start(asOf: .now)
            
            AppTwin.shared.gpsTwin.stop(asOf: .now)
            AppTwin.shared.gpsTwin.start(asOf: .now)
        }
    }
}

private struct DetailsView: View {
    let asOf: Date
    
    var body: some View {
        HStack {
            VStack {
                Text("\(AppTwin.shared.locations.locations.count)")
                ForEach(AppTwin.shared.locations.locations.suffix(10).reversed()) {
                    Text("\($0.speed, specifier: "%2.1f")").lineLimit(1)
                }
            }
            VStack {
                Text("\(AppTwin.shared.distances.distances.count)")
                ForEach(AppTwin.shared.distances.distances.suffix(10).reversed()) {
                    Text("\($0.speed, specifier: "%2.1f")").lineLimit(1)
                }
            }
            VStack {
                Text("\(AppTwin.shared.heartrates.heartrates.count)")
                ForEach(AppTwin.shared.heartrates.heartrates.suffix(10).reversed()) {
                    Text("\($0.heartrate, specifier: "%3d")").lineLimit(1)
                }
            }
            VStack {
                Text("\(AppTwin.shared.intensities.intensities.count)")
                ForEach(AppTwin.shared.intensities.intensities.suffix(10).reversed()) {
                    Text("\($0.intensity.rawValue)").lineLimit(1)
                }
            }
            VStack {
                Text("\(AppTwin.shared.motions.motions.count)")
                ForEach(AppTwin.shared.motions.motions.suffix(10).reversed()) {
                    Text("\($0.motion.rawValue)").lineLimit(1)
                }
            }
            VStack {
                Text("\(AppTwin.shared.isActives.isActives.count)")
                ForEach(AppTwin.shared.isActives.isActives.suffix(10).reversed()) {
                    Text("\($0.isActive ? "Yes" : "No")").lineLimit(1)
                }
            }
        }
        .font(.caption)
    }
}

struct RunView_Previews: PreviewProvider {
    static var previews: some View {
        RunView()
    }
}
