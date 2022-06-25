//
//  BleHrStatusView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct BleHrStatusView: View {
    let status: ClientStatus
    let graphHasLength: Bool // graph in service is not empty
    
    var body: some View {
        Text(Image(systemName: getSystemName()))
    }
    
    private func getSystemName() -> String {
        switch status {
        case .started:
            return "antenna.radiowaves.left.and.right\(graphHasLength ? ".circle.fill":"")"
        case .stopped:
            return "stop.fill"
        case .notAvailable:
            return "antenna.radiowaves.left.and.right.slash"
        case .notAllowed:
            return "hand.raised.slash"
        }
    }
}

#if DEBUG
struct BleHrStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                BleHrStatusView(status: .stopped(since: .now), graphHasLength: false)
                BleHrStatusView(status: .stopped(since: .now), graphHasLength: true)
                BleHrStatusView(status: .started(since: .now), graphHasLength: false)
                BleHrStatusView(status: .started(since: .now), graphHasLength: true)
            }
            HStack {
                BleHrStatusView(status: .notAllowed(since: .now), graphHasLength: false)
                BleHrStatusView(status: .notAllowed(since: .now), graphHasLength: true)
                BleHrStatusView(status: .notAvailable(since: .now), graphHasLength: false)
                BleHrStatusView(status: .notAvailable(since: .now), graphHasLength: true)
            }
        }
    }
}
#endif
