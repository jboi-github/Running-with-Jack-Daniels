//
//  StatsView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 23.06.21.
//

import SwiftUI

private let intensities = [Intensity.Easy, .Marathon, .Threshold, .Interval, .Repetition]

struct StatsView: View {
    @ObservedObject var workout = WorkoutRecordingModel.sharedInstance
    
    var body: some View {
        HStack {
            VStack(alignment: .trailing) {
                ForEach(intensities.filter {workout.intensities.keys.contains($0)}) {
                    Text("\($0.id.capitalized):").font(.subheadline)
                }
                Text("Totals:").font(.subheadline)
            }
            Spacer()
            VStack(alignment: .trailing) {
                ForEach(intensities.filter {workout.intensities.keys.contains($0)}) {
                    workout.intensities[$0]?.distance.asDistance(.callout)
                }
                workout.totals.distance.asDistance(.callout)
            }
            Spacer()
            VStack(alignment: .trailing) {
                ForEach(intensities.filter {workout.intensities.keys.contains($0)}) {
                    workout.intensities[$0]?.time.asTime(.callout)
                }
                workout.totals.time.asTime(.callout)
            }
            Spacer()
            VStack(alignment: .trailing) {
                ForEach(intensities.filter {workout.intensities.keys.contains($0)}) { intensity in
                    workout.intensities[intensity]?.avgPace.asPace(.callout, withMeasure: false)
                }
                workout.totals.avgPace.asPace(.callout, withMeasure: false)
            }
            Spacer()
            VStack(alignment: .trailing) {
                ForEach(intensities.filter {workout.intensities.keys.contains($0)}) {
                    workout.intensities[$0]?.avgVdot?.asVdot(.callout)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
                workout.vdot.asVdot(.caption)
            }
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
