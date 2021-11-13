//
//  ContentView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 12.06.21.
//

import SwiftUI
import RunDatabaseKit
import RunReceiversKit
import RunEnricherKit

struct RunView: View {
    var body: some View {
        GeometryReader { proxy in
            VStack {
                MapView()
                    .frame(minHeight: proxy.size.height / 3)

                HrView()
                    .padding()
                    .border(Color.gray)

                TotalsView()
                    .padding()
                    .border(Color.gray)
            }
        }
        .toolbar {
            ToolbarStatusView()
        }
        .onAppear {
            Database.sharedInstance.onAppear()
            ReceiverService.sharedInstance.start()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            Database.sharedInstance.onDisappear()
            ReceiverService.sharedInstance.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

private struct ToolbarStatusView: View {
    @ObservedObject var hrLimits = Database.sharedInstance.hrLimits
    @ObservedObject var currents = CurrentsService.sharedInstance
    
    var body: some View {
        let highHr = currents.heartrateBpm >= (hrLimits.value[.Easy]?.lowerBound ?? Int.max)
        return HStack {
            currents
                .aclControl
                .asImage(onReceiving: currents.activity.asImage(highHr: highHr))
            currents.gpsControl.asImage(
                onReceiving: Image(systemName: "location.fill"),
                nonOk: Image(systemName: "location.slash"))
            HStack(spacing: 0) {
                currents.bleControl.asImage(
                    onReceiving: Image(systemName: "heart.fill"),
                    nonOk: Image(systemName: "heart.slash"))
                currents
                    .batteryLevel
                    .asBatteryLevel
                    .scaleEffect(0.5, anchor: .bottomLeading)
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        RunView()
    }
}
