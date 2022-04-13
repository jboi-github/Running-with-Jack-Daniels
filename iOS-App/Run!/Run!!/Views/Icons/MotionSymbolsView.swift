//
//  MotionSymbols.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct MotionSymbolsView: View {
    let motionType: MotionType?
    let intensity: Run.Intensity?

    var body: some View {
        Text(Image(systemName: motionSymbolName))
    }
    
    private var motionSymbolName: String {
        switch motionType {
        case .pause:
            switch intensity {
            case .Cold, .Easy, .Long, .none:
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
        case .invalid:
            return "questionmark"
        case .none:
            return "questionmark"
        }
    }
}

extension MotionType {
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
            return .label
        case .invalid:
            return .label
        }
    }
}

#if DEBUG
struct MotionSymbolsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                MotionSymbolsView(motionType: .walking, intensity: .Cold)
                MotionSymbolsView(motionType: .running, intensity: .Cold)
                MotionSymbolsView(motionType: .cycling, intensity: .Cold)
                MotionSymbolsView(motionType: .unknown, intensity: .Cold)
            }
            HStack {
                MotionSymbolsView(motionType: .pause, intensity: .Cold)
                MotionSymbolsView(motionType: .pause, intensity: .Easy)
                MotionSymbolsView(motionType: .pause, intensity: .Long)
                MotionSymbolsView(motionType: .pause, intensity: .Marathon)
            }
        }
    }
}
#endif
