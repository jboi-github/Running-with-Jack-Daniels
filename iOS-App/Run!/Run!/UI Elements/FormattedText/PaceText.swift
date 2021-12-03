//
//  PaceText.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

/// Pace is either written as "mm:ss / km" or "mm:ss" as short format.
struct PaceText: View {
    let text: String
    
    init(paceSecPerKm: TimeInterval, short: Bool = false, max: TimeInterval = 3600) {
        guard paceSecPerKm.isFinite && paceSecPerKm < max else {
            self.text = "--:--\(short ? "" : "/km")"
            return
        }

        let paceSecPerKm: Int = Int(paceSecPerKm)
        let minutes = paceSecPerKm / 60
        let seconds = paceSecPerKm % 60
        self.text = String(format: "%2d:%02d%@", minutes, seconds, short ? "" : "/km")
    }
    
    var body: some View {Text(text)}
}

struct PaceText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Group {
                PaceText(paceSecPerKm: 100, short: true, max: 3600)
                PaceText(paceSecPerKm: 100, short: false, max: 3600)
                PaceText(paceSecPerKm: .nan, short: true, max: 3600)
                PaceText(paceSecPerKm: .nan, short: false, max: 3600)
                PaceText(paceSecPerKm: 0, short: true, max: 3600)
                PaceText(paceSecPerKm: 0, short: false, max: 3600)
            }
            Group {
                PaceText(paceSecPerKm: 3600, short: true, max: 3600)
                PaceText(paceSecPerKm: 3600, short: false, max: 3600)
                PaceText(paceSecPerKm: 3599, short: true, max: 3600)
                PaceText(paceSecPerKm: 3599, short: false, max: 3600)
                PaceText(paceSecPerKm: 3700, short: true, max: 3600)
                PaceText(paceSecPerKm: 3700, short: false, max: 3600)
            }
        }
    }
}
