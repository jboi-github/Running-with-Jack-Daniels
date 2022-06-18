//
//  StatsView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 23.06.21.
//

import SwiftUI
import RunFormulasKit
import RunEnricherKit

struct TotalsView: View {
    @State private var width0 = CGFloat.zero
    @State private var width1 = CGFloat.zero
    @State private var width2 = CGFloat.zero
    @State private var width3 = CGFloat.zero
    @State private var width4 = CGFloat.zero
    @State private var width5 = CGFloat.zero
    
    @State private var totals:
        (sum: TotalsService.Total, totals: [DataLine]) =
        (sum: TotalsService.Total.zero, totals: [DataLine]())
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            ForEach(totals.totals) { line in
                FullLineView(
                    activity: line.activity,
                    intensity: line.intensity,
                    total: line.total,
                    width: [$width0, $width1, $width2, $width3, $width4, $width5])
            }
            Divider()
            ContentLineView(total: totals.sum, width: [$width0, $width1, $width2, $width3, $width4, $width5])
        }
        .onReceive(timer) {
            let t = TotalsService.sharedInstance.current(at: $0)
            self.totals = (t.sum, t.totals.map {
                DataLine(activity: $0.0, intensity: $0.1, total: $0.2)
            })
        }
    }
}

private struct FullLineView: View {
    let activity: Activity
    let intensity: Intensity
    let total: TotalsService.Total
    let width: [Binding<CGFloat>]
    
    var body: some View {
        HStack {
            Text(activity.asImage(highHr: true))
                .font(.subheadline)
                .alignedView(width: width[0])
            Spacer()
            ContentLineView(total: total, width: width)
        }
        .border(intensity.asColor())
    }
}

private struct ContentLineView: View {
    let total: TotalsService.Total
    let width: [Binding<CGFloat>]

    var body: some View {
        HStack {
            total.distance.asDistance(.callout)
                .alignedView(width: width[1])
            Spacer()
            total.duration.asTime(.callout)
                .alignedView(width: width[2])
            Spacer()
            total.paceSecPerKm.asPace(.callout, withMeasure: false)
                .alignedView(width: width[3])
            Spacer()
            Text("\(total.heartrateBpm, specifier: "%3d")")
                .font(.callout)
                .alignedView(width: width[4])
            Spacer()
            total.vdot.asVdot(.callout)
                .alignedView(width: width[5])
        }
    }
}

private struct DataLine: Identifiable {
    let id = UUID()
    
    let activity: Activity
    let intensity: Intensity
    let total: TotalsService.Total
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        TotalsView()
    }
}

