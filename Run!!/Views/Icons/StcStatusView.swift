//
//  MotionStatusView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct StcStatusView: View {
    let status: ClientStatus
    let intensity: Run.Intensity?

    var body: some View {
        Text(Image(systemName: getSystemName()))
    }
    
    private func getSystemName() -> String {
        switch status {
        case .started:
            switch intensity {
            case .cold:
                return "tortoise.fill"
            default:
                return "hare.fill"
            }
        case .stopped:
            return "stop.fill"
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
                StcStatusView(status: .stopped(since: .now), intensity: .cold)
                StcStatusView(status: .stopped(since: .now), intensity: .easy)
                StcStatusView(status: .started(since: .now), intensity: .cold)
                StcStatusView(status: .started(since: .now), intensity: .easy)
            }
            HStack {
                StcStatusView(status: .notAllowed(since: .now), intensity: .cold)
                StcStatusView(status: .notAllowed(since: .now), intensity: .easy)
                StcStatusView(status: .notAvailable(since: .now), intensity: .cold)
                StcStatusView(status: .notAvailable(since: .now), intensity: .easy)
            }
        }
    }
}
#endif
