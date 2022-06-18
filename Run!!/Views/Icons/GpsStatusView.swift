//
//  GpsStatusView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct GpsStatusView: View {
    let status: ClientStatus
    let pathHasLength: Bool // path in service has count > 1
    
    var body: some View {
        Text(Image(systemName: getSystemName()))
    }
    
    private func getSystemName() -> String {
        switch status {
        case .started:
            return pathHasLength ? "location.fill" : "location"
        case .stopped:
            return "stop.fill"
        case .notAvailable:
            return "location.slash"
        case .notAllowed:
            return "hand.raised.slash"
        }
    }
}

#if DEBUG
struct GpsStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                GpsStatusView(status: .stopped(since: .now), pathHasLength: false)
                GpsStatusView(status: .stopped(since: .now), pathHasLength: true)
                GpsStatusView(status: .started(since: .now), pathHasLength: false)
                GpsStatusView(status: .started(since: .now), pathHasLength: true)
            }
            HStack {
                GpsStatusView(status: .notAllowed(since: .now), pathHasLength: false)
                GpsStatusView(status: .notAllowed(since: .now), pathHasLength: true)
                GpsStatusView(status: .notAvailable(since: .now), pathHasLength: false)
                GpsStatusView(status: .notAvailable(since: .now), pathHasLength: true)
            }
        }
    }
}
#endif
