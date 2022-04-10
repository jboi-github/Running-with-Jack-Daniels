//
//  RunTotalsView.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 07.04.22.
//

import SwiftUI
import CoreLocation

private let motionTypeOrder: [MotionType] = [.walking, .running, .cycling, .unknown, .invalid]
private let intensityOrder: [Run.Intensity] = [.Cold, .Easy, .Long, .Marathon, .Threshold, .Interval, .Repetition]

extension Totals.KeyValue: ChartDataPoint {
    var classifier: String {(key.intensity ?? .Cold).rawValue.capitalized}
    var x: Double {value.sumDuration ?? 0}
    var y: Double {Double(value.avgHeartrate ?? 0)}
    
    func makeBody(
        _ canvas: CGRect,
        _ pos: CGPoint,
        _ prevPos: CGPoint,
        _ nearestPos: CGPoint)
    -> some View
    {
        VStack {
            MotionSymbolsView(
                motionType: key.motionType,
                intensity: key.intensity)

            VdotText(vdot: value.vdot)
        }
        .font(.caption)
        .foregroundColor((key.intensity ?? .Cold).textColor)
        .padding(4)
        .background(Capsule().foregroundColor((key.intensity ?? .Cold).color))
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
    let totals: [Totals.KeyValue]
    
    var body: some View {
        graphical ?
            RunTotalGraphicalView(totals: totals).anyview
            :
        VStack(spacing: 0) {
                ForEach(motionTypeOrder) {type in
                    let totals = totals.filter {$0.key.motionType == type}
                    if !totals.isEmpty {
                        RunTotalTableView(motionType: type, totals: totals)
                    }
                }
            }
            .anyview
    }
}

private struct RunTotalTableView: View {
    let motionType: MotionType
    let totals: [Totals.KeyValue]
    
    @State private var widthMotionSymbol: CGFloat = 0
    @State private var widthDuration: CGFloat = 0
    @State private var widthDistance: CGFloat = 0
    @State private var widthSpeed: CGFloat = 0
    @State private var widthVdot: CGFloat = 0
    @State private var widthHeartrate: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Body lines
            ForEach(intensityOrder) { intensity in
                if let total = totals.first(where: {$0.key.intensity == intensity}) {
                    ZStack {
                        Capsule().foregroundColor((total.key.intensity ?? .Cold).color)
                        HStack {
                            MotionSymbolsView(motionType: motionType, intensity: intensity).alignedView(width: $widthMotionSymbol)
                            TimeText(time: total.value.sumDuration).alignedView(width: $widthDuration)
                            DistanceText(distance: total.value.sumDistance).alignedView(width: $widthDistance)
                            HeartrateText(heartrate: total.value.avgHeartrate).alignedView(width: $widthHeartrate)
                            SpeedText(speed: total.value.avgSpeed).alignedView(width: $widthSpeed)
                            VdotText(vdot: total.value.vdot).alignedView(width: $widthVdot)
                        }
                        .font(.callout)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundColor((total.key.intensity ?? .Cold).textColor)
                        .padding(4)
                    }
                }
            }
        }
    }
}

private struct RunTotalGraphicalView: View {
    let totals: Array<Totals.KeyValue>.Prepared

    init(totals: [Totals.KeyValue]) {
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
            Totals.KeyValue(
                key: Totals.Key(isActive: false, motionType: .pause, intensity: .Cold),
                value: Totals.Value(sumHeartrate: 100 * 100, sumDuration: 100, sumDistance: 0)),
            Totals.KeyValue(
                key: Totals.Key(isActive: true, motionType: .running, intensity: .Easy),
                value: Totals.Value(sumHeartrate: 150 * 500, sumDuration: 500, sumDistance: 1400)),
            Totals.KeyValue(
                key: Totals.Key(isActive: true, motionType: .running, intensity: .Marathon),
                value: Totals.Value(sumHeartrate: 160 * 400, sumDuration: 400, sumDistance: 1300))
        ])
        RunTotalsView(graphical: true, totals: [
            Totals.KeyValue(
                key: Totals.Key(isActive: false, motionType: .pause, intensity: .Cold),
                value: Totals.Value(sumHeartrate: 100 * 100, sumDuration: 100, sumDistance: 0)),
            Totals.KeyValue(
                key: Totals.Key(isActive: true, motionType: .running, intensity: .Easy),
                value: Totals.Value(sumHeartrate: 150 * 500, sumDuration: 500, sumDistance: 1400)),
            Totals.KeyValue(
                key: Totals.Key(isActive: true, motionType: .running, intensity: .Marathon),
                value: Totals.Value(sumHeartrate: 160 * 1200, sumDuration: 1200, sumDistance: 1400))
        ])
    }
}
#endif
