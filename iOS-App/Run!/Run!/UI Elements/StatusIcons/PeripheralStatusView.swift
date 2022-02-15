//
//  PeripheralConnectionStatus.swift
//  Run!
//
//  Created by Jürgen Boiselle on 25.01.22.
//

import SwiftUI
import CoreBluetooth

struct PeripheralStatusView: View {
    let state: CBPeripheralState?
    
    private let animation = Animation.easeInOut.repeatForever(autoreverses: true)
    @State private var showBoth: Bool = false
    
    var body: some View {
        ZStack {
            Image(systemName: state?.firstImageName ?? "questionmark").opacity(showBoth ? 1 : 0)
            Image(systemName: state?.secondImageName ?? "questionmark").opacity(showBoth ? 0 : 1)
        }
        .onAppear {
            if let state = state, state.firstImageName != state.secondImageName {
                withAnimation(animation) {showBoth = true}
            }
        }
    }
}

private extension CBPeripheralState {
    var firstImageName: String {
        switch self {
        case .disconnected:
            return "rectangle"
        case .connecting:
            return "waveform.path.ecg.rectangle"
        case .connected:
            return "waveform.path.ecg.rectangle.fill"
        case .disconnecting:
            return "waveform.path.ecg.rectangle"
        @unknown default:
            return "nosign"
        }
    }
    
    var secondImageName: String {
        switch self {
        case .disconnected:
            return "rectangle"
        case .connecting:
            return "waveform.path.ecg.rectangle.fill"
        case .connected:
            return "waveform.path.ecg.rectangle.fill"
        case .disconnecting:
            return "rectangle"
        @unknown default:
            return "nosign"
        }
    }
}

struct PeripheralStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PeripheralStatusView(state: .disconnected)
            PeripheralStatusView(state: .connecting)
            PeripheralStatusView(state: .connected)
            PeripheralStatusView(state: .disconnecting)
        }
    }
}
