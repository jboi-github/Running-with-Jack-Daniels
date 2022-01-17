//
//  GpsStatusView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct GpsStatusView: View {
    let status: GpsProducer.Status
    let pathHasLength: Bool // path in service has count > 1
    
    var body: some View {
        Text(Image(systemName: getSystemName()))
    }
    
    private func getSystemName() -> String {
        switch status {
        case .started, .resumed:
            return pathHasLength ? "location.fill" : "location"
        case .stopped:
            return "stop.fill"
        case .paused:
            return "pause"
        case .nonRecoverableError(_, _):
            return "location.slash"
        case .notAuthorized:
            return "hand.raised.slash"
        }
    }
}

#if DEBUG
struct GpsStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                GpsStatusView(status: .stopped, pathHasLength: false)
                GpsStatusView(status: .stopped, pathHasLength: true)
                GpsStatusView(status: .started(asOf: Date()), pathHasLength: false)
                GpsStatusView(status: .started(asOf: Date()), pathHasLength: true)
                GpsStatusView(status: .paused, pathHasLength: false)
                GpsStatusView(status: .paused, pathHasLength: true)
                GpsStatusView(status: .resumed, pathHasLength: false)
                GpsStatusView(status: .resumed, pathHasLength: true)
            }
            HStack {
                GpsStatusView(status: .notAuthorized(asOf: Date()), pathHasLength: false)
                GpsStatusView(status: .notAuthorized(asOf: Date()), pathHasLength: true)
                GpsStatusView(status: .nonRecoverableError(asOf: Date(), error: "X"), pathHasLength: false)
                GpsStatusView(status: .nonRecoverableError(asOf: Date(), error: "X"), pathHasLength: true)
            }
        }
    }
}
#endif
