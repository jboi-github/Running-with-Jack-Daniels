//
//  BleHrStatusView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct BleHrStatusView: View {
    let status: BleProducer.Status
    let graphHasLength: Bool // graph in service is not empty
    
    var body: some View {
        Text(Image(systemName: getSystemName()))
    }
    
    private func getSystemName() -> String {
        switch status {
        case .started, .resumed:
            return graphHasLength ? "heart.fill" : "heart"
        case .stopped:
            return "stop.fill"
        case .paused:
            return "pause"
        case .nonRecoverableError(_, _):
            return "heart.slash"
        case .notAuthorized:
            return "hand.raised.slash"
        case .error(_, _):
            return "heart.slash.fill"
        }
    }
}

struct BleHrStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                BleHrStatusView(status: .stopped, graphHasLength: false)
                BleHrStatusView(status: .stopped, graphHasLength: true)
                BleHrStatusView(status: .started(asOf: Date()), graphHasLength: false)
                BleHrStatusView(status: .started(asOf: Date()), graphHasLength: true)
                BleHrStatusView(status: .paused, graphHasLength: false)
                BleHrStatusView(status: .paused, graphHasLength: true)
                BleHrStatusView(status: .resumed, graphHasLength: false)
                BleHrStatusView(status: .resumed, graphHasLength: true)
            }
            HStack {
                BleHrStatusView(status: .notAuthorized(asOf: Date()), graphHasLength: false)
                BleHrStatusView(status: .notAuthorized(asOf: Date()), graphHasLength: true)
                BleHrStatusView(status: .nonRecoverableError(asOf: Date(), error: "X"), graphHasLength: false)
                BleHrStatusView(status: .nonRecoverableError(asOf: Date(), error: "X"), graphHasLength: true)
                BleHrStatusView(status: .error(UUID(), "Y"), graphHasLength: false)
                BleHrStatusView(status: .error(UUID(), "Y"), graphHasLength: true)
            }
        }
    }
}
