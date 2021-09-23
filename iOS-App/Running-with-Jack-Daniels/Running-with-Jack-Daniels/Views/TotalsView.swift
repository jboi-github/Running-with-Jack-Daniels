//
//  StatsView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 23.06.21.
//

import SwiftUI

//private let infoSegmentsInfo: [WorkoutRecorder.InfoSegment: (image: String, color: Color)] = [
//    WorkoutRecorder.InfoSegment.paused: (image: "pause.rectangle.fill", color: .primary),
//    .running(intensity: .Easy): (image: "rectangle.fill", color: .blue),
//    .running(intensity: .Marathon): (image: "rectangle.fill", color: .green),
//    .running(intensity: .Threshold): (image: "rectangle.fill", color: .yellow),
//    .running(intensity: .Interval): (image: "rectangle.fill", color: .red),
//    .running(intensity: .Repetition): (image: "rectangle.fill", color: .primary)
//]

private let config = [
    (isRunning: true, intensity: Intensity.Easy, color: Color.blue, systemname: "rectangle.fill"),
    (isRunning: true, intensity: Intensity.Marathon, color: Color.green, systemname: "rectangle.fill"),
    (isRunning: true, intensity: Intensity.Threshold, color: Color.yellow, systemname: "rectangle.fill"),
    (isRunning: true, intensity: Intensity.Interval, color: Color.red, systemname: "rectangle.fill"),
    (isRunning: true, intensity: Intensity.Repetition, color: Color.primary, systemname: "rectangle.fill")
]

struct TotalsView: View {
    @ObservedObject var aggs = AggregateManager.sharedInstance
    
    @State private var width0 = CGFloat.zero
    @State private var width1 = CGFloat.zero
    @State private var width2 = CGFloat.zero
    @State private var width3 = CGFloat.zero
    @State private var width4 = CGFloat.zero

    var body: some View {
        VStack {
            ForEach(config.indices) { i in
                if let total = aggs.total[getCategory(i)] {
                    TotalsLineView(
                        total: total, color: config[i].color, systemname: config[i].systemname,
                        width: [$width0, $width1, $width2, $width3, $width4])
                }
            }
            Divider()
            TotalsLineView(
                total: aggs.totalTotal, color: .primary, systemname: "sum",
                width: [$width0, $width1, $width2, $width3, $width4])
        }
    }
    
    private func getCategory(_ i: Int) -> AggregateManager.Total.Categorical {
        AggregateManager.Total.Categorical(isRunning: config[i].isRunning, intensity: config[i].intensity)
    }
}

private struct TotalsLineView: View {
    let total: AggregateManager.Total.Continuous
    let color: Color
    let systemname: String
    let width: [Binding<CGFloat>]
    
    var body: some View {
        HStack {
            Text(Image(systemName: systemname))
                .font(.subheadline)
                .foregroundColor(color)
                .alignedView(width: width[0])
            Spacer()
            total.distanceM.asDistance(.callout)
                .alignedView(width: width[1])
            Spacer()
            total.durationSec.asTime(.callout)
                .alignedView(width: width[2])
            Spacer()
            total.paceSecPerKm.asPace(.callout, withMeasure: false)
                .alignedView(width: width[3])
            Spacer()
            total.vdot.asVdot(.callout)
                .alignedView(width: width[4])
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        TotalsView()
    }
}

