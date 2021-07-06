//
//  ContentView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 12.06.21.
//

import SwiftUI
import MapKit

struct MainView: View {
    @State private var currentTime = Date()
    @State private var startTime = Date()

    @ObservedObject var hr = BleHeartRateReceiver.sharedInstance
    @ObservedObject var loc = GpsLocationReceiver.sharedInstance
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            VStack {
                Text("Running with Jack Daniels").font(.headline)
                Text("- Tracking your workout -").font(.subheadline)
            }
            .padding()

            Spacer()
            MapView()
            Spacer()
            
            VStack {
                HStack {
                    Spacer()
                    Text(hr.receiving ? String(format: "%3d", hr.heartrate) : "---")
                        .fontWeight(.bold)
                        .font(.system(size: 500).monospacedDigit())
                        .minimumScaleFactor(0.01)
                        .padding()
                    Image(systemName: getHeart())
                    Spacer()
                }
                HStack {
                    Spacer()
                    if hr.receiving {
                        Text("\(Calendar.current.dateComponents([.second], from: hr.latestTimeStamp, to: currentTime).second!)")
                            .font(.footnote)
                    }
                }
            }
            .padding()
            .border(Color.gray.opacity(0.5), width: 1.0)
            .padding()
            
            Spacer()
            StatsView(startTime: startTime, currentTime: currentTime)
            Spacer()
            HStack {
                Spacer()
                ErrorView()
                Spacer()
                Button {
                    loc.save()
                } label: {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            hr.start()
            loc.start()
            UIApplication.shared.isIdleTimerDisabled = true
            startTime = Date()
        }
        .onDisappear {
            hr.stop()
            loc.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onReceive(timer) {currentTime = $0}
    }
    
    private func getHeart() -> String {
        guard hr.localizedError == "" else {return "heart.slash"}
        if hr.receiving {return "heart.fill"}
        return "heart"
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
