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

struct StatsView: View {
    let currentPace: TimeInterval
//    let currentTotals: [WorkoutRecorder.InfoSegment: WorkoutRecorder.Info]
//    let currentTotal: WorkoutRecorder.Info
    
    @State private var width0 = CGFloat.zero
    @State private var width1 = CGFloat.zero
    @State private var width2 = CGFloat.zero
    @State private var width3 = CGFloat.zero
    @State private var width4 = CGFloat.zero

    var body: some View {
        VStack {
//            if let info = currentTotals[.paused] {
//                StatsLineView(
//                    info: info, color: .primary, systemname: "pause.rectangle.fill",
//                    width: [$width0, $width1, $width2, $width3, $width4])
//            }
//            if let info = currentTotals[.running(intensity: .Easy)] {
//                StatsLineView(
//                    info: info, color: .blue, systemname: "rectangle.fill",
//                    width: [$width0, $width1, $width2, $width3, $width4])
//            }
//            if let info = currentTotals[.running(intensity: .Marathon)] {
//                StatsLineView(
//                    info: info, color: .green, systemname: "rectangle.fill",
//                    width: [$width0, $width1, $width2, $width3, $width4])
//            }
//            if let info = currentTotals[.running(intensity: .Threshold)] {
//                StatsLineView(
//                    info: info, color: .yellow, systemname: "rectangle.fill",
//                    width: [$width0, $width1, $width2, $width3, $width4])
//            }
//            if let info = currentTotals[.running(intensity: .Interval)] {
//                StatsLineView(
//                    info: info, color: .red, systemname: "rectangle.fill",
//                    width: [$width0, $width1, $width2, $width3, $width4])
//            }
//            if let info = currentTotals[.running(intensity: .Repetition)] {
//                StatsLineView(
//                    info: info, color: .primary, systemname: "rectangle.fill",
//                    width: [$width0, $width1, $width2, $width3, $width4])
//            }
            Divider()
//            StatsLineView(
//                info: currentTotal, color: .primary, systemname: "sum",
//                width: [$width0, $width1, $width2, $width3, $width4])
        }
    }
}

/*
private struct StatsLineView: View {
    let info: WorkoutRecorder.Info
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
            info.distance.asDistance(.callout)
                .alignedView(width: width[1])
            Spacer()
            info.duration.asTime(.callout)
                .alignedView(width: width[2])
            Spacer()
            info.avgPaceKmPerSec.asPace(.callout, withMeasure: false)
                .alignedView(width: width[3])
            Spacer()
            info.vdot.asVdot(.callout)
                .alignedView(width: width[4])
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
*/
