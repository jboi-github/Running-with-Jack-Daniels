//
//  RunStatusView.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 07.04.22.
//

import SwiftUI

struct RunClientStatusView: View {
    let stcStatus: ClientStatus
    let hrmStatus: ClientStatus
    let gpsStatus: ClientStatus
    let intensity: Run.Intensity?
    let locationsNotEmpty: Bool
    let heartratesNotEmpty: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            StcStatusView(status: stcStatus, intensity: intensity)
            BleHrStatusView(status: hrmStatus, graphHasLength: heartratesNotEmpty)
            GpsStatusView(status: gpsStatus, pathHasLength: locationsNotEmpty)
        }
        .font(.callout)
        .onTapGesture {
            guard let url = URL(string: UIApplication.openSettingsURLString) else {return}
            UIApplication.shared.open(url)
        }
    }
}

#if DEBUG
struct RunStatusView_Previews: PreviewProvider {
    static var previews: some View {
        RunClientStatusView(
            stcStatus: .stopped(since: .now),
            hrmStatus: .stopped(since: .now),
            gpsStatus: .stopped(since: .now),
            intensity: .cold,
            locationsNotEmpty: true,
            heartratesNotEmpty: false)
    }
}
#endif
