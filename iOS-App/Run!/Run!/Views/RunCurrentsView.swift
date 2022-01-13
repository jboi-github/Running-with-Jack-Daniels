//
//  RunCurrentsView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI
import CoreLocation

struct RunCurrentsView: View {
    let hr: Int
    let intensity: Intensity
    let intensities: [Intensity: Range<Int>]
    let duration: TimeInterval
    let distance: CLLocationDistance
    let pace: TimeInterval
    let vdot: Double
    let activityType: IsActiveProducer.ActivityType

    var body: some View {
        ZStack {
            HrLimitsView(hr: hr, intensity: intensity, intensities: intensities)
            VStack {
                HStack {
                    TimeText(time: duration)
                    Spacer()
                    DistanceText(distance: distance)
                }
                Spacer()
                HStack {
                    PaceText(paceSecPerKm: pace, short: false)
                    Spacer()
                    MotionSymbolsView(activityType: activityType, intensity: intensity)
                    VdotText(vdot: vdot)
                }
            }
            .font(.headline)
        }
    }
}

struct RunCurrentsView_Previews: PreviewProvider {
    static var previews: some View {
        RunCurrentsView(
            hr: 100,
            intensity: .Easy,
            intensities: [
                .Cold: 50..<75,
                .Easy: 75..<100,
                .Long: 75..<100,
                .Marathon: 100..<150,
                .Threshold: 150..<175,
                .Interval: 165..<220],
            duration: 3600+550,
            distance: 10400,
            pace: 550,
            vdot: 23.4,
            activityType: .running)
    }
}
