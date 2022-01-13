//
//  RunStatusView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 22.12.21.
//

import SwiftUI

/**
 Present icons for current status. When tapped, open system config for app.
 User can then change authorization.
 */
struct RunStatusView: View {
    let aclStatus: AclProducer.Status
    let bleStatus: BleProducer.Status
    let gpsStatus: GpsProducer.Status
    let intensity: Intensity
    let gpsPath: [PathService.PathElement]
    let hrGraph: [HrGraphService.Heartrate]

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            MotionStatusView(status: aclStatus, intensity: intensity)
            BleHrStatusView(status: bleStatus, graphHasLength: !hrGraph.isEmpty)
            GpsStatusView(status: gpsStatus, pathHasLength: !gpsPath.isEmpty)
            BatteryStatusView(status: 50)
        }
        .font(.caption)
        .onTapGesture {
            guard let url = URL(string: UIApplication.openSettingsURLString) else {return}
            UIApplication.shared.open(url)
        }
    }
}

struct RunStatusView_Previews: PreviewProvider {
    static var previews: some View {
        RunStatusView(
            aclStatus: .stopped,
            bleStatus: .stopped,
            gpsStatus: .stopped,
            intensity: .Cold,
            gpsPath: [],
            hrGraph: [])
    }
}
