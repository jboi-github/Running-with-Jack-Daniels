//
//  RunTotalsView.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 07.04.22.
//

import SwiftUI
import CoreLocation

private let intensityOrder: [Run.Intensity] = [.cold, .easy, .long, .marathon, .threshold, .interval, .repetition]

extension TimeSeriesSet.Total: ChartDataPoint {
    var classifier: String {(intensity ?? .cold).rawValue.capitalized}
    var x: Double { duration }
    var y: Double { Double(avgHeartrate ?? 0) }

    func makeBody(
        _ canvas: CGRect,
        _ pos: CGPoint,
        _ prevPos: CGPoint,
        _ nearestPos: CGPoint)
    -> some View
    {
        VStack {
            PedometerEventView(isActive: motionActivity?.isActive, intensity: intensity)
            VdotText(vdot: vdot)
        }
        .font(.caption)
        .foregroundColor((intensity ?? .cold).textColor)
        .padding(4)
        .background(Capsule().foregroundColor((intensity ?? .cold).color))
        .offset(x: pos.x, y: pos.y)
    }
}

/**
 Shows totals by motion type except paused.
 Two ways for visualisation within each motion type are possible:
 - table form: Show a line of table for each intensity containing (in this order):
   - duration, distance, speed, vdot, heartrate.
   - Background is a capsule with the intensity-color.
 - graphical form: Show bubbles with intensity color and vdot as numbers on the bubbles.
   - Position the bubbles along duration (x-axes) and distance (y-axes)
 */
struct RunTotalsView: View {
    let size: CGSize
    let graphical: Bool
    let totals: [TimeSeriesSet.Total]

    var body: some View {
        if graphical {
            RunTotalGraphicalView(totals: totals)
        } else if !totals.isEmpty {
            RunTotalTableView(size: size, totals: totals)
        }
    }
}

private struct RunTotalTableView: View {
    let size: CGSize
    let totals: [TimeSeriesSet.Total]

    @State private var widthMotion: CGFloat = 0
    @State private var widthDuration: CGFloat = 0
    @State private var widthDistance: CGFloat = 0
    @State private var widthSpeed: CGFloat = 0
    @State private var widthVdot: CGFloat = 0
    @State private var widthHeartrate: CGFloat = 0
    
    @State private var tableSize = CGSize()
    
    var body: some View {
        VStack {
            // Body lines
            ForEach(totals) { total in
                HStack {
                    MotionActivityView(
                        motion: total.motionActivity,
                        confidence: .high)
                        .alignedView(width: $widthMotion)
                    TimeText(time: total.duration)
                        .alignedView(width: $widthDuration)
                    HeartrateText(heartrate: total.avgHeartrate)
                        .alignedView(width: $widthHeartrate)
                    if total.motionActivity?.isActive ?? true {
                        DistanceText(distance: total.distance)
                            .alignedView(width: $widthDistance)
                        SpeedText(speed: total.speed)
                                .alignedView(width: $widthSpeed)
                        VdotText(vdot: total.vdot)
                            .alignedView(width: $widthVdot)
                    }
                }
                .font(.callout)
                .lineLimit(1)
                .fixedSize()
                .foregroundColor((total.intensity ?? .cold).textColor)
                .padding(4)
                .background(Capsule().foregroundColor((total.intensity ?? .cold).color))
            }
        }
        .fixedSize()
        .captureSize(in: $tableSize)
        .scaleEffect(x: (size.width / tableSize.width).ifNotFinite(1), y: 1, anchor: .center)
    }
}

private struct RunTotalGraphicalView: View {
    let totals: Array<TimeSeriesSet.Total>.Prepared

    init(totals: [TimeSeriesSet.Total]) {
        self.totals = totals.prepared(nx: 10, ny: 5)
    }

    @State private var size: CGSize = .zero

    var body: some View {
        // Chart for bubbles
        RunStandardChart(data: totals, xLabel: "Duration", yLabel: "Heartrate")
    }
}

#if DEBUG
struct RunTotalsView_Previews: PreviewProvider {
    static var previews: some View {
        RunTotalsView(size: CGSize(width: 500, height: 300), graphical: true, totals: [])
        RunTotalsView(size: CGSize(width: 500, height: 300), graphical: false, totals: [
            TimeSeriesSet.Total(
                endAt: .now,
                motionActivity: .stationary,
                resetDate: .now,
                intensity: .cold,
                duration: 100,
                numberOfSteps: nil,
                activeDuration: nil,
                energyExpended: nil,
                distance: 0,
                speed: nil,
                cadence: nil,
                avgHeartrate: 100,
                vdot: nil),
            TimeSeriesSet.Total(
                endAt: .now,
                motionActivity: .walking,
                resetDate: .now,
                intensity: .easy,
                duration: 500,
                numberOfSteps: nil,
                activeDuration: nil,
                energyExpended: nil,
                distance: 1400,
                speed: nil,
                cadence: nil,
                avgHeartrate: 150,
                vdot: nil),
            TimeSeriesSet.Total(
                endAt: .now,
                motionActivity: .running,
                resetDate: .now,
                intensity: .marathon,
                duration: 400,
                numberOfSteps: nil,
                activeDuration: nil,
                energyExpended: nil,
                distance: 1300,
                speed: nil,
                cadence: nil,
                avgHeartrate: 160,
                vdot: nil)
        ])
        RunTotalsView(size: CGSize(width: 500, height: 300), graphical: true, totals: [
            TimeSeriesSet.Total(
                endAt: .now,
                motionActivity: .stationary,
                resetDate: .now,
                intensity: .cold,
                duration: 100,
                numberOfSteps: nil,
                activeDuration: nil,
                energyExpended: nil,
                distance: 0,
                speed: nil,
                cadence: nil,
                avgHeartrate: 100,
                vdot: nil),
            TimeSeriesSet.Total(
                endAt: .now,
                motionActivity: .walking,
                resetDate: .now,
                intensity: .easy,
                duration: 500,
                numberOfSteps: nil,
                activeDuration: nil,
                energyExpended: nil,
                distance: 1400,
                speed: nil,
                cadence: nil,
                avgHeartrate: 150,
                vdot: nil),
            TimeSeriesSet.Total(
                endAt: .now,
                motionActivity: .running,
                resetDate: .now,
                intensity: .marathon,
                duration: 400,
                numberOfSteps: nil,
                activeDuration: nil,
                energyExpended: nil,
                distance: 1300,
                speed: nil,
                cadence: nil,
                avgHeartrate: 160,
                vdot: nil)
        ])
    }
}
#endif
