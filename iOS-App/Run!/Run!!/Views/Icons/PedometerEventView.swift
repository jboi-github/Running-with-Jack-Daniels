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

        if isActive && intensity == .Cold {
            return "tortoise.fill"
        } else if isActive && intensity != .Cold {
            return "hare.fill"
        } else if !isActive && intensity == .Cold {
            return "figure.stand"
        } else if !isActive && intensity != .Cold {
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
                PedometerEventView(isActive: true, intensity: .Cold)
                PedometerEventView(isActive: false, intensity: .Cold)
            }
            HStack {
                PedometerEventView(isActive: true, intensity: .Cold)
                PedometerEventView(isActive: true, intensity: .Easy)
                PedometerEventView(isActive: true, intensity: .Long)
                PedometerEventView(isActive: true, intensity: .Marathon)
            }
        }
    }
}
#endif
