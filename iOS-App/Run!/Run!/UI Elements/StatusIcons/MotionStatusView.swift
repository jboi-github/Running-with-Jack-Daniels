//
//  MotionStatusView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct MotionStatusView: View {
    let status: AclProducer.Status
    let intensity: Intensity

    var body: some View {
        Text(Image(systemName: getSystemName()))
    }
    
    private func getSystemName() -> String {
        switch status {
        case .started(_), .resumed:
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
        case .nonRecoverableError(_, _):
            return "xmark"
        case .notAuthorized(_):
            return "hand.raised.slash"
        }
    }
}

#if DEBUG
struct MotionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                MotionStatusView(status: .stopped, intensity: .Cold)
                MotionStatusView(status: .stopped, intensity: .Easy)
                MotionStatusView(status: .started(asOf: Date()), intensity: .Cold)
                MotionStatusView(status: .started(asOf: Date()), intensity: .Easy)
                MotionStatusView(status: .paused, intensity: .Cold)
                MotionStatusView(status: .paused, intensity: .Easy)
                MotionStatusView(status: .resumed, intensity: .Cold)
                MotionStatusView(status: .resumed, intensity: .Easy)
            }
            HStack {
                MotionStatusView(status: .notAuthorized(asOf: Date()), intensity: .Cold)
                MotionStatusView(status: .notAuthorized(asOf: Date()), intensity: .Easy)
                MotionStatusView(status: .nonRecoverableError(asOf: Date(), error: "X"), intensity: .Cold)
                MotionStatusView(status: .nonRecoverableError(asOf: Date(), error: "X"), intensity: .Easy)
            }
        }
    }
}
#endif
