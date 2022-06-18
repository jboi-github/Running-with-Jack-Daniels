//
//  MotionActivityView.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 23.05.22.
//

import SwiftUI

struct MotionActivityView: View {
    let motion: MotionActivityEvent.Motion?
    let confidence: MotionActivityEvent.Confidence?

    var body: some View {
        Text(Image(systemName: systemName)).foregroundColor(color)
    }
    
    var systemName: String {
        switch motion {
        case .stationary:
            return "figure.stand"
        case .walking:
            return "figure.walk"
        case .running:
            return "hare.fill"
        case .cycling:
            return "bicycle"
        case .other:
            return "tram.fill"
        case .none:
            return "questionmark"
        }
    }
    
    var color: Color {
        switch confidence {
        case .none:
            return .red
        case .low:
            return .yellow
        case .medium:
            return .green
        case .high:
            return .blue
        }
    }
}

#if DEBUG
struct MotionActivityView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                MotionActivityView(motion: .stationary, confidence: .low)
                MotionActivityView(motion: .walking, confidence: .low)
                MotionActivityView(motion: .running, confidence: .low)
                MotionActivityView(motion: .cycling, confidence: .low)
                MotionActivityView(motion: .other, confidence: .low)
            }

            HStack {
                MotionActivityView(motion: .stationary, confidence: .medium)
                MotionActivityView(motion: .walking, confidence: .medium)
                MotionActivityView(motion: .running, confidence: .medium)
                MotionActivityView(motion: .cycling, confidence: .medium)
                MotionActivityView(motion: .other, confidence: .medium)
            }

            HStack {
                MotionActivityView(motion: .stationary, confidence: .high)
                MotionActivityView(motion: .walking, confidence: .high)
                MotionActivityView(motion: .running, confidence: .high)
                MotionActivityView(motion: .cycling, confidence: .high)
                MotionActivityView(motion: .other, confidence: .high)
            }
        }
    }
}
#endif
