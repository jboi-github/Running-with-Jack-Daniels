//
//  MotionSymbols.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct PedometerEventView: View {
    let isActive: Bool?
    let intensity: Run.Intensity?

    var body: some View {
        Text(Image(systemName: activityIconName))
    }
    
    private var activityIconName: String {
        guard let isActive = isActive else {return "questionmark"}

        if isActive && intensity == .cold {
            return "tortoise.fill"
        } else if isActive && intensity != .cold {
            return "hare.fill"
        } else if !isActive && intensity == .cold {
            return "figure.stand"
        } else if !isActive && intensity != .cold {
            return "figure.wave"
        }
        return "questionmark"
    }
}

#if DEBUG
struct MotionSymbolsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                PedometerEventView(isActive: true, intensity: .cold)
                PedometerEventView(isActive: false, intensity: .cold)
            }
            HStack {
                PedometerEventView(isActive: true, intensity: .cold)
                PedometerEventView(isActive: true, intensity: .easy)
                PedometerEventView(isActive: true, intensity: .long)
                PedometerEventView(isActive: true, intensity: .marathon)
            }
        }
    }
}
#endif
