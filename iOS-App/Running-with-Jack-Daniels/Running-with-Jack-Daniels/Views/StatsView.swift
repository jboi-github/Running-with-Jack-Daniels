//
//  StatsView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 23.06.21.
//

import SwiftUI

private let infoSegmentsOrder = [
    WorkoutRecorder.InfoSegment.paused,
    .running(intensity: .Easy),
    .running(intensity: .Marathon),
    .running(intensity: .Threshold),
    .running(intensity: .Interval),
    .running(intensity: .Repetition)
]

struct StatsView: View {
    let currentPace: TimeInterval
    let currentTotals: [WorkoutRecorder.InfoSegment: WorkoutRecorder.Info]
    let currentTotal: WorkoutRecorder.Info
    
    var body: some View {
        HStack {
            VStack(alignment: .trailing) {
                ForEach(infoSegmentsOrder.filter {currentTotals.keys.contains($0)}) {
                    Text("\($0.name.capitalized):").font(.subheadline)
                }
                Text("Total:").font(.subheadline)
            }
            Spacer()
            VStack(alignment: .trailing) {
                ForEach(infoSegmentsOrder.filter {currentTotals.keys.contains($0)}) {
                    currentTotals[$0]?.distance.asDistance(.callout)
                }
                currentTotal.distance.asDistance(.callout)
            }
            Spacer()
            VStack(alignment: .trailing) {
                ForEach(infoSegmentsOrder.filter {currentTotals.keys.contains($0)}) {
                    currentTotals[$0]?.duration.asTime(.callout)
                }
                currentTotal.duration.asTime(.callout)
            }
            Spacer()
            VStack(alignment: .trailing) {
                ForEach(infoSegmentsOrder.filter {currentTotals.keys.contains($0)}) {
                    currentTotals[$0]?.avgPaceKmPerSec.asPace(.callout, withMeasure: false)
                }
                currentTotal.avgPaceKmPerSec.asPace(.callout, withMeasure: false)
            }
            Spacer()
            VStack(alignment: .trailing) {
                ForEach(infoSegmentsOrder.filter {currentTotals.keys.contains($0)}) {
                    currentTotals[$0]?.vdot.asVdot(.callout)
                }
            }
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView(
            currentPace: 0.0,
            currentTotals: [WorkoutRecorder.InfoSegment : WorkoutRecorder.Info](),
            currentTotal: WorkoutRecorder.Info.zero)
    }
}
