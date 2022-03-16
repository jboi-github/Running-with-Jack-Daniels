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
    let intensities: [Intensity: Range<Int>]?
    let duration: TimeInterval
    let distance: CLLocationDistance
    let pace: TimeInterval
    let vdot: Double
    let activityType: IsActiveProducer.ActivityType
    let isActive: Bool
    let status: BleProducer.Status
    let peripheralName: String
    let batteryStatus: Int
    
    @State private var secondariesHeight: CGFloat = .zero

    var body: some View {
        ZStack {
            if let intensities = intensities, status.isRunning {
                HrLimitsView(hr: hr, intensity: intensity, intensities: intensities)
            } else if !status.isRunning {
                NavigationLink(destination: ScannerView()) {
                    Label("Bluetooth Scanner", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.subheadline)
                        .padding()
                }
                .padding()
            } else {
                NavigationLink(destination: PlanView()) {
                    Label("Plan", systemImage: "calendar")
                        .font(.subheadline)
                        .padding()
                }
                .padding()
            }
            VStack {
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    MotionSymbolsView(activityType: activityType, intensity: intensity)
                        .font(.subheadline)
                        .foregroundColor(Color(uiColor: isActive ? .systemRed : .systemBlue))
                    TimeText(time: duration)
                    Spacer()
                    DistanceText(distance: distance)
                }
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    PaceText(paceSecPerKm: pace, short: false)
                    Spacer()
                    HStack {
                        Text("\(peripheralName)")
                            .lineLimit(1)
                        BatteryStatusView(status: 50)
                    }
                    .font(.caption)
                    Spacer()
                    VdotText(vdot: vdot)
                }
            }
            .font(.headline)
        }
    }
}

#if DEBUG
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
            activityType: .running, isActive: true,
            status: .started(asOf: Date()),
            peripheralName: "HR-Name",
            batteryStatus: 50)
        
        RunCurrentsView(
            hr: 100,
            intensity: .Easy,
            intensities: nil,
            duration: 3600+550,
            distance: 10400,
            pace: 550,
            vdot: 23.4,
            activityType: .running, isActive: false,
            status: .started(asOf: Date()),
            peripheralName: "HR-Name",
            batteryStatus: 50)
    }
}
#endif
