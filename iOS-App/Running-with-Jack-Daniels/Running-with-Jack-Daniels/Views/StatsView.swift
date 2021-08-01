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

extension TimeInterval {
    func asTime(_ font: Font = .body, measureFont: Font = .caption, withMeasure: Bool = true) -> some View {
        guard self.isFinite else {return Text("--:--").font(font).anyview}
        
        let hours = Int(self / 3600.0)
        let minutes = Int(self.truncatingRemainder(dividingBy: 3600) / 60.0)
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))
        
        return HStack(spacing: 0) {
            if hours > 0 {Text("\(hours, specifier: "%2d"):")}
            if minutes > 0 {Text("\(minutes, specifier: (self < 3600 ? "%2d" : "%02d")):")}
            Text("\(seconds, specifier: (self < 60 ? "%2d" : "%02d"))")
            
            if withMeasure && self >= 3600 {Text(" h:mm:ss").font(measureFont)}
            else if withMeasure && self >= 60 {Text(" m:ss").font(measureFont)}
            else if withMeasure {Text(" sec").font(measureFont)}
        }
        .font(font)
        .anyview
    }
    
    func asPace(_ font: Font = .body, measureFont: Font = .caption, withMeasure: Bool = true) -> some View {
        return HStack(spacing: 0) {
            asTime(font, measureFont: measureFont, withMeasure: withMeasure)
            Text("\(withMeasure ? "/km" : " /km")").font(measureFont)
        }
    }
}

extension Double {
    func asDistance(_ font: Font = .body, measureFont: Font = .caption, withMeasure: Bool = true) -> some View {
        guard self.isFinite else {return Text("-").font(font).anyview}
        
        if self <= 5000 {
            return HStack(spacing: 0) {
                Text("\(self, specifier: "%4.0f")").font(font)
                if withMeasure {Text(" m").font(measureFont)}
            }
            .anyview
        } else {
            return HStack(spacing: 0) {
                Text("\(self / 1000, specifier: "%3.1f")").font(font)
                if withMeasure {Text(" km").font(measureFont)}
            }
            .anyview
        }
    }
    
    func asVdot(_ font: Font = .body) -> some View {
        guard self.isFinite else {return Text("--.-").font(font).anyview}
        return Text("\(self, specifier: "%2.1f")").font(font).anyview
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
