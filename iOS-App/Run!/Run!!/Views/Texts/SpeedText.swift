//
//  SpeedText.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 01.04.22.
//

import SwiftUI
import CoreLocation

/// Speed (m/s) is either written as pace (s/km) with "mm:ss / km" or "mm:ss" as short format.
struct SpeedText: View {
    let text: String
    
    init(speed: CLLocationSpeed?, short: Bool = false, max: CLLocationSpeed = 100) {
        guard let speed = speed, speed.isFinite && speed > 0 && speed < max else {
            self.text = "--:--\(short ? "" : " /km")"
            return
        }

        let paceSecPerKm: Int = Int(1000.0 / speed)
        let minutes = paceSecPerKm / 60
        let seconds = paceSecPerKm % 60
        self.text = String(format: "%2d:%02d%@", minutes, seconds, short ? "" : " /km")
    }
    
    var body: some View {Text(text)}
}

#if DEBUG
struct SpeedText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Group {
                SpeedText(speed: 10, short: true, max: 100)
                SpeedText(speed: 10, short: false, max: 100)
                SpeedText(speed: .nan, short: true, max: 100)
                SpeedText(speed: .nan, short: false, max: 100)
                SpeedText(speed: 0, short: true, max: 100)
                SpeedText(speed: 0, short: false, max: 100)
            }
            Group {
                SpeedText(speed: 100, short: true, max: 100)
                SpeedText(speed: 100, short: false, max: 100)
                SpeedText(speed: 99, short: true, max: 100)
                SpeedText(speed: 99, short: false, max: 100)
                SpeedText(speed: 110, short: true, max: 100)
                SpeedText(speed: 110, short: false, max: 100)
            }
        }
    }
}
#endif
