//
//  MotionSymbols.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct ActivityView: View {
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
                ActivityView(isActive: true, intensity: .Cold)
                ActivityView(isActive: false, intensity: .Cold)
            }
            HStack {
                ActivityView(isActive: true, intensity: .Cold)
                ActivityView(isActive: true, intensity: .Easy)
                ActivityView(isActive: true, intensity: .Long)
                ActivityView(isActive: true, intensity: .Marathon)
            }
        }
    }
}
#endif
