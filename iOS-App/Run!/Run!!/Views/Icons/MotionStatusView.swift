//
//  MotionStatusView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct MotionStatusView: View {
    let status: AclStatus
    let intensity: Run.Intensity?

    var body: some View {
        Text(Image(systemName: getSystemName()))
    }
    
    private func getSystemName() -> String {
        switch status {
        case .started:
            switch intensity {
            case .Cold:
                return "tortoise.fill"
            default:
                return "hare.fill"
            }
        case .stopped:
            return "stop.fill"
        case .paused:
            return "pause"
        case .notAvailable:
            return "xmark"
        case .notAllowed:
            return "hand.raised.slash"
        }
    }
}

#if DEBUG
struct MotionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                MotionStatusView(status: .stopped(since: .now), intensity: .Cold)
                MotionStatusView(status: .stopped(since: .now), intensity: .Easy)
                MotionStatusView(status: .started(since: .now), intensity: .Cold)
                MotionStatusView(status: .started(since: .now), intensity: .Easy)
                MotionStatusView(status: .paused(since: .now), intensity: .Cold)
                MotionStatusView(status: .paused(since: .now), intensity: .Easy)
            }
            HStack {
                MotionStatusView(status: .notAllowed(since: .now), intensity: .Cold)
                MotionStatusView(status: .notAllowed(since: .now), intensity: .Easy)
                MotionStatusView(status: .notAvailable(since: .now), intensity: .Cold)
                MotionStatusView(status: .notAvailable(since: .now), intensity: .Easy)
            }
        }
    }
}
#endif
