//
//  ContentView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 12.06.21.
//

import SwiftUI

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
            AggregateManager.sharedInstance.start()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            Database.sharedInstance.onDisappear()
            AggregateManager.sharedInstance.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

private struct ToolbarStatusView: View {
    @ObservedObject var hrLimits = Database.sharedInstance.hrLimits
    @ObservedObject var aggs = AggregateManager.sharedInstance
    
    var body: some View {
        HStack {
            Image(systemName: getMotion())
            Image(systemName: getLocation())
            Image(systemName: getHeart())
        }
        .font(.caption)
    }
    
    private func getLocation() -> String {aggs.current.gpsReceiving ? "location.fill" : "location.slash"}
    private func getHeart() -> String {aggs.current.bleReceiving ? "heart.fill" : "heart.slash"}

    private func getMotion() -> String {
        switch aggs.current.aclReceiving {
        case .off:
            return "nosign"
            
        case .stationary:
            if let hrLimitsEasy = hrLimits.value[.Easy],
               aggs.current.heartrateBpm >= hrLimitsEasy.lowerBound
            {
                return "figure.wave"
            } else {
                return "figure.stand"
            }
            
        case .walking:
            return "figure.walk"
            
        case .running:
            if let hrLimitsEasy = hrLimits.value[.Easy],
               aggs.current.heartrateBpm < hrLimitsEasy.lowerBound
            {
                return "tortoise.fill"
            } else {
                return "hare.fill"
            }
            
        case .cycling:
            return "bicycle"
            
        case .automotion:
            return "tram.fill"
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        RunView()
    }
}
