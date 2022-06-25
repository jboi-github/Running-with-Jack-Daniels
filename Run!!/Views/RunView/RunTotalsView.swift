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
    var y: Double { avgHeartrate ?? 0 }

    func makeBody(
        _ canvas: CGRect,
        _ pos: CGPoint,
        _ prevPos: CGPoint,
        _ nearestPos: CGPoint)
    -> some View
    {
        VStack {
            PedometerEventView(isActive: isActive, intensity: intensity)
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
    let graphical: Bool
    let totals: [TimeSeriesSet.Total]

    var body: some View {
        if graphical {
            RunTotalGraphicalView(totals: totals)
        } else if !totals.isEmpty {
            RunTotalTableView(totals: totals)
        }
    }
}

// FIXME: Should show motion indication at beginning of line
private struct RunTotalTableView: View {
    let totals: [TimeSeriesSet.Total]

    @State private var widthMotion: CGFloat = 0
    @State private var widthDuration: CGFloat = 0
    @State private var widthDistance: CGFloat = 0
    @State private var widthSpeed: CGFloat = 0
    @State private var widthVdot: CGFloat = 0
    @State private var widthHeartrate: CGFloat = 0

    var body: some View {
        List {
            // Body lines
            ForEach(totals) { total in
                ZStack {
                    Capsule().foregroundColor((total.intensity ?? .cold).color)
                    HStack {
                        MotionActivityView(
                            motion: total.motionActivity,
                            confidence: .high)
                            .alignedView(width: $widthMotion)
                        TimeText(time: total.duration)
                            .alignedView(width: $widthDuration)
                        DistanceText(distance: total.distance)
                            .alignedView(width: $widthDistance)
                        HeartrateText(heartrate: Int((total.avgHeartrate ?? 0) + 0.5))
                            .alignedView(width: $widthHeartrate)
                        SpeedText(speed: total.avgSpeed)
                            .alignedView(width: $widthSpeed)
                        VdotText(vdot: total.vdot)
                            .alignedView(width: $widthVdot)
                    }
                    .font(.callout)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor((total.intensity ?? .cold).textColor)
                    .padding(4)
                }
            }
        }
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
        RunTotalsView(graphical: true, totals: [])
        RunTotalsView(graphical: false, totals: [
            TimeSeriesSet.Total(
                asOf: .now,
                motionActivity: .stationary,
                workoutDate: .now,
                isWorkingOut: true,
                intensity: .cold,
                duration: 100,
                gpsDistance: 0,
                heartrateSeconds: 100 * 100),
            TimeSeriesSet.Total(
                asOf: .now,
                motionActivity: .walking,
                workoutDate: .now,
                isWorkingOut: true,
                intensity: .easy,
                duration: 500,
                gpsDistance: 1400,
                heartrateSeconds: 150 * 500),
            TimeSeriesSet.Total(
                asOf: .now,
                motionActivity: .running,
                workoutDate: .now,
                isWorkingOut: true,
                intensity: .marathon,
                duration: 400,
                gpsDistance: 1300,
                heartrateSeconds: 160 * 400)
        ])
        RunTotalsView(graphical: true, totals: [
            TimeSeriesSet.Total(
                asOf: .now,
                motionActivity: .stationary,
                workoutDate: .now,
                isWorkingOut: true,
                intensity: .cold,
                duration: 100,
                gpsDistance: 0,
                heartrateSeconds: 100 * 100),
            TimeSeriesSet.Total(
                asOf: .now,
                motionActivity: .walking,
                workoutDate: .now,
                isWorkingOut: true,
                intensity: .easy,
                duration: 500,
                gpsDistance: 1400,
                heartrateSeconds: 150 * 500),
            TimeSeriesSet.Total(
                asOf: .now,
                motionActivity: .running,
                workoutDate: .now,
                isWorkingOut: true,
                intensity: .marathon,
                duration: 400,
                gpsDistance: 1300,
                heartrateSeconds: 160 * 400)
        ])
    }
}
#endif
