//
//  RunTotalsView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI
import CoreLocation

private let activityTypeOrder: [IsActiveProducer.ActivityType] = [.walking, .running, .cycling, .unknown]
private let intensityeOrder: [Intensity] = [
    .Cold, .Easy, .Long, .Marathon, .Threshold, .Interval, .Repetition
]

extension IsActiveProducer.ActivityType: Identifiable {
    var id: Self.RawValue {self.rawValue}
}

extension TotalsService.Total: ChartDataPoint {
    var classifier: String {intensity.rawValue.capitalized}
    var x: Double {durationSec}
    var y: Double {Double(heartrateBpm)}
    
    func makeBody(
        _ canvas: CGRect,
        _ pos: CGPoint,
        _ prevPos: CGPoint,
        _ nearestPos: CGPoint)
    -> some View
    {
        VStack {
            MotionSymbolsView(
                activityType: activityType,
                intensity: intensity)

            VdotText(vdot: vdot)
        }
        .font(.caption)
        .foregroundColor(intensity.textColor)
        .padding(4)
        .background(Capsule().foregroundColor(intensity.color))
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
    let totals: [TotalsService.Total]
    
    var body: some View {
        ForEach(activityTypeOrder) {type in
            let totals = totals.filter {$0.activityType == type}
            if !totals.isEmpty {
                if graphical {
                    RunTotalGraphicalView(motionType: type, totals: totals)
                } else {
                    RunTotalTableView(motionType: type, totals: totals)
                }
            }
        }
    }
}

private struct RunTotalTableView: View {
    let motionType: IsActiveProducer.ActivityType
    let totals: [TotalsService.Total]
    
    @State private var widthDuration: CGFloat = 0
    @State private var widthDistance: CGFloat = 0
    @State private var widthSpeed: CGFloat = 0
    @State private var widthVdot: CGFloat = 0
    @State private var widthHeartrate: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Motion Type in upper heading corner
            HStack {
                MotionSymbolsView(activityType: motionType, intensity: .Cold)
                    .font(.caption)
                Spacer()
            }
            
            // Headline
            HStack {
                Text("Time").alignedView(width: $widthDuration)
                Text("Distance").alignedView(width: $widthDistance)
                Text("HR").alignedView(width: $widthHeartrate)
                Text("Pace").alignedView(width: $widthSpeed)
                Text("vdot").alignedView(width: $widthVdot)
            }
            .font(.subheadline)
            .lineLimit(1)

            // Body lines
            ForEach(intensityeOrder.indices) {idx in
                if let total = totals.first(where: {$0.intensity == intensityeOrder[idx]}) {
                    ZStack {
                        Capsule().foregroundColor(total.intensity.color)
                        HStack {
                            TimeText(time: total.durationSec).alignedView(width: $widthDuration)
                            DistanceText(distance: total.distanceM).alignedView(width: $widthDistance)
                            HrText(heartrate: total.heartrateBpm).alignedView(width: $widthHeartrate)
                            PaceText(paceSecPerKm: total.paceSecPerKm).alignedView(width: $widthSpeed)
                            VdotText(vdot: total.vdot).alignedView(width: $widthVdot)
                        }
                        .font(.body)
                        .lineLimit(1)
                        .foregroundColor(total.intensity.textColor)
                        .padding(4)
                    }
                }
            }
        }
        .minimumScaleFactor(0.5)
    }
}

private struct RunTotalGraphicalView: View {
    let motionType: IsActiveProducer.ActivityType
    let totals: Array<TotalsService.Total>.Prepared
    
    let totalDuration: TimeInterval
    let totalDistance: CLLocationDistance

    init(motionType: IsActiveProducer.ActivityType, totals: [TotalsService.Total]) {
        self.motionType = motionType
        self.totals = totals.prepared(nx: 10, ny: 5)
        self.totalDuration = totals.map {$0.durationSec}.reduce(0.0, +)
        self.totalDistance = totals.map {$0.distanceM}.reduce(0.0, +)
    }
    
    @State private var size: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Motion Type in upper trailing corner
            VStack {
                HStack {
                    Spacer()
                    MotionSymbolsView(activityType: motionType, intensity: .Cold)
                        .font(.caption)
                }
                Spacer()
            }
            
            // Chart for bubbles
            RunStandardChart(data: totals, xLabel: "Duration", yLabel: "Heartrate")
        }
    }
}

#if DEBUG
struct RunTotalsView_Previews: PreviewProvider {
    static var previews: some View {
        RunTotalsView(graphical: false, totals: [
            TotalsService.Total(
                activityType: .pause,
                intensity: .Cold,
                durationSec: 100,
                distanceM: 0,
                heartrateBpm: 100,
                paceSecPerKm: .nan,
                vdot: .nan),
            TotalsService.Total(
                activityType: .running,
                intensity: .Easy,
                durationSec: 500,
                distanceM: 1400,
                heartrateBpm: 150,
                paceSecPerKm: 500 / 1.4,
                vdot: 24),
            TotalsService.Total(
                activityType: .running,
                intensity: .Marathon,
                durationSec: 400,
                distanceM: 1300,
                heartrateBpm: 160,
                paceSecPerKm: 400 / 1.4,
                vdot: 34)
        ])
        RunTotalsView(graphical: true, totals: [
            TotalsService.Total(
                activityType: .pause,
                intensity: .Cold,
                durationSec: 100,
                distanceM: 0,
                heartrateBpm: 100,
                paceSecPerKm: .nan,
                vdot: .nan),
            TotalsService.Total(
                activityType: .running,
                intensity: .Easy,
                durationSec: 500,
                distanceM: 1400,
                heartrateBpm: 150,
                paceSecPerKm: 500 / 1.4,
                vdot: 24),
            TotalsService.Total(
                activityType: .running,
                intensity: .Marathon,
                durationSec: 400,
                distanceM: 1400,
                heartrateBpm: 160,
                paceSecPerKm: 400 / 1.4,
                vdot: 34)
        ])
    }
}
#endif