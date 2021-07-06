//
//  StatsView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 23.06.21.
//

import SwiftUI

struct StatsView: View {
    let startTime: Date
    let currentTime: Date
    
    @ObservedObject var loc = GpsLocationReceiver.sharedInstance
    
    var body: some View {
        HStack {
            Spacer()
            Text("\(formatTI(timeInterval: loc.paceSecPerKm))/km")
                .font(.subheadline.monospacedDigit())
            Spacer()
            Text(formatM(distanceM: Int(loc.distanceM + 0.5)))
                .font(.headline.monospacedDigit())
            Spacer()
            Text(formatTI(timeInterval: startTime.distance(to: currentTime)))
                .font(.subheadline.monospacedDigit())
            Spacer()
        }
    }
    
    private func formatM(distanceM: Int) -> String {
        if distanceM <= 5000 {
            return String(format: "%4dm", locale: Locale.current, distanceM)
        } else {
            return String(format: "%3.1fkm", locale: Locale.current, Double(distanceM) / 1000.0)
        }
    }
    
    private func formatTI(timeInterval: Int) -> String {
        formatTI(timeInterval: TimeInterval(timeInterval))
    }
    
    private func formatTI(timeInterval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        return "\(formatter.string(from: timeInterval) ?? String(timeInterval))"
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView(startTime: Date(), currentTime: Date())
    }
}
