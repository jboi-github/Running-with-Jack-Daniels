//
//  MotionActivityView.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 23.05.22.
//

import SwiftUI

struct MotionActivityView: View {
    let motionActivity: MotionActivityEvent
    
    var body: some View {
        Text(Image(systemName: systemName)).foregroundColor(color)
    }
    
    var systemName: String {
        switch motionActivity.motion {
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
        }
    }
    
    var color: Color {
        switch motionActivity.confidence {
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
                MotionActivityView(motionActivity: MotionActivityEvent(date: .now, confidence: .low, motion: .stationary))
                MotionActivityView(motionActivity: MotionActivityEvent(date: .now, confidence: .low, motion: .walking))
                MotionActivityView(motionActivity: MotionActivityEvent(date: .now, confidence: .low, motion: .running))
                MotionActivityView(motionActivity: MotionActivityEvent(date: .now, confidence: .low, motion: .cycling))
                MotionActivityView(motionActivity: MotionActivityEvent(date: .now, confidence: .low, motion: .other))
            }

            HStack {
                MotionActivityView(motionActivity: MotionActivityEvent(date: .now, confidence: .medium, motion: .stationary))
                MotionActivityView(motionActivity: MotionActivityEvent(date: .now, confidence: .medium, motion: .walking))
                MotionActivityView(motionActivity: MotionActivityEvent(date: .now, confidence: .medium, motion: .running))
                MotionActivityView(motionActivity: MotionActivityEvent(date: .now, confidence: .medium, motion: .cycling))
                MotionActivityView(motionActivity: MotionActivityEvent(date: .now, confidence: .medium, motion: .other))
            }

            HStack {
                MotionActivityView(motionActivity: MotionActivityEvent(date: .now, confidence: .high, motion: .stationary))
                MotionActivityView(motionActivity: MotionActivityEvent(date: .now, confidence: .high, motion: .walking))
                MotionActivityView(motionActivity: MotionActivityEvent(date: .now, confidence: .high, motion: .running))
                MotionActivityView(motionActivity: MotionActivityEvent(date: .now, confidence: .high, motion: .cycling))
                MotionActivityView(motionActivity: MotionActivityEvent(date: .now, confidence: .high, motion: .other))
            }
        }
    }
}
#endif
