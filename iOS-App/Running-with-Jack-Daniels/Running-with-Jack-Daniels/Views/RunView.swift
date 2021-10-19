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
        HStack {
            Image(systemName: getMotion())
            Image(systemName: getLocation())
            Image(systemName: getHeart())
        }
        .font(.caption)
    }
    
    private func getLocation() -> String {
        currents.gpsControl == .received ? "location.fill" : "location.slash"
    }
    private func getHeart() -> String {
        currents.bleControl == .received ? "heart.fill" : "heart.slash"
    }

    private func getMotion() -> String {
        guard currents.aclControl == .received else {return "nosign"}
        
        if currents.activity.stationary {
            if let hrLimitsEasy = hrLimits.value[.Easy],
               currents.heartrateBpm >= hrLimitsEasy.lowerBound
            {
                return "figure.wave"
            } else {
                return "figure.stand"
            }
        } else if currents.activity.walking {
            return "figure.walk"
        } else if currents.activity.running {
            if let hrLimitsEasy = hrLimits.value[.Easy],
               currents.heartrateBpm < hrLimitsEasy.lowerBound
            {
                return "tortoise.fill"
            } else {
                return "hare.fill"
            }
        } else if currents.activity.cycling {
            return "bicycle"
        } else if currents.activity.automotive {
            return "tram.fill"
        } else {
            return "nosign"
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        RunView()
    }
}
