//
//  RunStatusView.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 07.04.22.
//

import SwiftUI

struct RunStatusView: View {
    let aclStatus: AclStatus
    let hrmStatus: BleStatus
    let gpsStatus: GpsStatus
    let intensity: Run.Intensity?
    let locationsNotEmpty: Bool
    let heartratesNotEmpty: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            MotionStatusView(status: aclStatus, intensity: intensity)
            BleHrStatusView(status: hrmStatus, graphHasLength: heartratesNotEmpty)
            GpsStatusView(status: gpsStatus, pathHasLength: locationsNotEmpty)
        }
        .font(.caption)
        .scaleEffect(0.75)
        .onTapGesture {
            guard let url = URL(string: UIApplication.openSettingsURLString) else {return}
            UIApplication.shared.open(url)
        }
    }
}

#if DEBUG
struct RunStatusView_Previews: PreviewProvider {
    static var previews: some View {
        RunStatusView(
            aclStatus: .stopped(since: .now),
            hrmStatus: .stopped(since: .now),
            gpsStatus: .stopped(since: .now),
            intensity: .Cold,
            locationsNotEmpty: true,
            heartratesNotEmpty: false)
    }
}
#endif
