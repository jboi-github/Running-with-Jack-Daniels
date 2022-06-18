//
//  RunCurrentsView.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 07.04.22.
//

import SwiftUI
import CoreLocation

struct RunCurrentsView: View {
    let heartrate: Int?
    let intensity: Run.Intensity?
    let hrLimits: [Run.Intensity: Range<Int>]?
    let duration: TimeInterval
    let distance: CLLocationDistance
    let speed: CLLocationSpeed?
    let vdot: Double?
    let cadence: Double?
    let isActive: Bool?
    let hrmStatus: ClientStatus
    let peripheralName: String?
    let batteryLevel: Int?
    
    @Binding var selection: Int

    var body: some View {
        ZStack {
            if let hrLimits = hrLimits, case .started = hrmStatus {
                HrLimitsView(heartrate: heartrate, intensity: intensity, hrLimits: hrLimits)
            } else if case .started = hrmStatus {
                Button {
                    withAnimation {
                        selection = 3
                    }
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Season Plan")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .padding()
                }
                .padding()
                .buttonStyle(BorderlessButtonStyle()) // Buttons in List-Rows are triggered all at once.
            } else {
                Button {
                    withAnimation {
                        selection = 4
                    }
                } label: {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        Text("Bluetooth Scanner")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .padding()
                }
                .padding()
                .buttonStyle(BorderlessButtonStyle()) // Buttons in List-Rows are triggered all at once.
            }
            VStack {
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    PedometerEventView(isActive: isActive, intensity: intensity)
                        .font(.subheadline)
                        .foregroundColor(Color(uiColor: (isActive ?? false) ? .systemRed : .systemBlue))
                    TimeText(time: duration)
                    Spacer()
                    DistanceText(distance: distance)
                }
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    SpeedText(speed: speed, short: false)
                    Spacer()
                    HStack {
                        Text("\(peripheralName ?? "-")")
                            .lineLimit(1)
                        BatteryStatusView(status: batteryLevel)
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
            heartrate: 100,
            intensity: .Easy,
            hrLimits: [
                .Cold: 50..<75,
                .Easy: 75..<100,
                .Long: 75..<100,
                .Marathon: 100..<150,
                .Threshold: 150..<175,
                .Interval: 165..<220],
            duration: 3600+550,
            distance: 10400,
            speed: 5.1,
            vdot: 23.4,
            cadence: 10, isActive: true,
            hrmStatus: .started(since: Date()),
            peripheralName: "HR-Name",
            batteryLevel: 50, selection: .constant(0))
        
        RunCurrentsView(
            heartrate: 100,
            intensity: .Easy,
            hrLimits: nil,
            duration: 3600+550,
            distance: 10400,
            speed: 3.5,
            vdot: 23.4,
            cadence: 130, isActive: false,
            hrmStatus: .started(since: Date()),
            peripheralName: "HR-Name",
            batteryLevel: 50, selection: .constant(0))
    }
}
#endif
