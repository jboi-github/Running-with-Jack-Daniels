//
//  ContentView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 12.06.21.
//

import SwiftUI
import MapKit

struct RunView: View {
    @ObservedObject var hr = BleHeartRateReceiver.sharedInstance
    @ObservedObject var loc = GpsLocationReceiver.sharedInstance
    @ObservedObject var limits = Database.sharedInstance.hrLimits

    var body: some View {
        GeometryReader { proxy in
            VStack {
                MapView()
                    .frame(minHeight: proxy.size.height / 3)
                HrView(limits: limits.value, heartrate: hr.heartrate)
                    .border(Color.gray)
                    .padding()
                    .frame(maxHeight: proxy.size.height / 4)
                StatsView()
                    .padding()
                ErrorView(hr: hr, loc: loc)
            }
        }
        .onAppear {
            Database.sharedInstance.onAppear()
            hr.start()
            loc.start()
            WorkoutRecordingModel.sharedInstance.onAppear()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            WorkoutRecordingModel.sharedInstance.onDisappear()
            loc.stop()
            hr.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    private func getHeart() -> String {
        guard hr.localizedError == "" else {return "heart.slash"}
        if hr.receiving {return "heart.fill"}
        return "heart"
    }
}

private struct ErrorView: View {
    @ObservedObject var hr: BleHeartRateReceiver
    @ObservedObject var loc: GpsLocationReceiver
    
    var body: some View {
        HStack {
            Spacer()
            Image(systemName: (hr.localizedError > "" || loc.localizedError > "") ? "bolt" : "checkmark")
            Text("\(hr.localizedError)\(loc.localizedError)")
            if (hr.localizedError > "" || loc.localizedError > "") {
                Button {
                    if hr.localizedError > "" {hr.start()}
                    if loc.localizedError > "" {loc.reset()}
                } label: {
                    Image(systemName: "play.fill")
                }
            }
        }
        .padding()
        .font(.footnote)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        RunView()
    }
}
