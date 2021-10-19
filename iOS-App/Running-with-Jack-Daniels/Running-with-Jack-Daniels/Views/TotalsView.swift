//
//  StatsView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 23.06.21.
//

import SwiftUI
import RunFormulasKit
import RunEnricherKit

private let config = [
    (isActive: true, intensity: Intensity.Easy, color: Color.blue, systemname: "rectangle.fill"),
    (isActive: true, intensity: Intensity.Marathon, color: Color.green, systemname: "rectangle.fill"),
    (isActive: true, intensity: Intensity.Threshold, color: Color.yellow, systemname: "rectangle.fill"),
    (isActive: true, intensity: Intensity.Interval, color: Color.red, systemname: "rectangle.fill"),
    (isActive: true, intensity: Intensity.Repetition, color: Color.primary, systemname: "rectangle.fill")
]

struct TotalsView: View {
    @ObservedObject var totals = TotalsService.sharedInstance
    
    @State private var width0 = CGFloat.zero
    @State private var width1 = CGFloat.zero
    @State private var width2 = CGFloat.zero
    @State private var width3 = CGFloat.zero
    @State private var width4 = CGFloat.zero

    var body: some View {
        VStack {
            ForEach(config.indices) { i in
                if let total = totals.totals[getCategory(i)] {
                    TotalsLineView(
                        total: total, color: config[i].color, systemname: config[i].systemname,
                        width: [$width0, $width1, $width2, $width3, $width4])
                }
            }
            Divider()
            TotalsLineView(
                total: totals.sumTotals, color: .primary, systemname: "sum",
                width: [$width0, $width1, $width2, $width3, $width4])
        }
    }
    
    private func getCategory(_ i: Int) -> TotalsService.ActiveIntensity {
        TotalsService.ActiveIntensity(isActive: config[i].isActive, intensity: config[i].intensity)
    }
}

private struct TotalsLineView: View {
    let total: TotalsService.Total
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
            total.distance.asDistance(.callout)
                .alignedView(width: width[1])
            Spacer()
            total.duration.asTime(.callout)
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

