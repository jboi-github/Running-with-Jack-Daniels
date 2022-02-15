//
//  MotionSymbols.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct MotionSymbolsView: View {
    let activityType: IsActiveProducer.ActivityType
    let intensity: Intensity

    var body: some View {
        Text(Image(systemName: motionSymbolName))
    }
    
    private var motionSymbolName: String {
        switch activityType {
        case .pause:
            switch intensity {
            case .Cold, .Easy, .Long:
                return "figure.stand"
            default:
                return "figure.wave"
            }
        case .walking:
            return "figure.walk"
        case .running:
            return "hare"
        case .cycling:
            return "bicycle"
        case .unknown:
            return "tram.fill"
        }
    }
}

extension IsActiveProducer.ActivityType {
    var uiColor: UIColor {
        switch self {
        case .pause:
            return .systemBlue
        case .walking:
            return .systemGreen
        case .running:
            return .systemRed
        case .cycling:
            return .systemYellow
        case .unknown:
            return .systemGray6
        }
    }
}

#if DEBUG
struct MotionSymbolsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                MotionSymbolsView(activityType: .walking, intensity: .Cold)
                MotionSymbolsView(activityType: .running, intensity: .Cold)
                MotionSymbolsView(activityType: .cycling, intensity: .Cold)
                MotionSymbolsView(activityType: .unknown, intensity: .Cold)
            }
            HStack {
                MotionSymbolsView(activityType: .pause, intensity: .Cold)
                MotionSymbolsView(activityType: .pause, intensity: .Easy)
                MotionSymbolsView(activityType: .pause, intensity: .Long)
                MotionSymbolsView(activityType: .pause, intensity: .Marathon)
            }
        }
    }
}
#endif
