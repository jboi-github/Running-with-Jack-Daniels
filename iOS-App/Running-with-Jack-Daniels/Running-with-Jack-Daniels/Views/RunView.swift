//
//  ContentView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 12.06.21.
//

import SwiftUI

struct RunView: View {
    /*
    @ObservedObject var hr = BleHeartrateReceiver.sharedInstance
    @ObservedObject var loc = GpsLocationReceiver.sharedInstance
    @ObservedObject var acc = AclMotionReceiver.sharedInstance
 */
    @ObservedObject var hrLimits = Database.sharedInstance.hrLimits

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            VStack {
//                MapView(path: workout.path)
//                    .frame(minHeight: proxy.size.height / 3)

//                HrView(
//                    heartrate: hr.heartrate?.heartrate,
//                    currentPace: 0.0,
//                    hrLimits: hrLimits.value)
//                    .padding()
//                    .border(Color.gray)

//                StatsView(
//                    currentPace: 0.0,
//                    currentTotals: currentTotals,
//                    currentTotal: currentTotal)
//                    .padding()
//                    .border(Color.gray)

//                ErrorMessageView(
//                    hrError: hr.localizedError,
//                    locError: loc.localizedError,
//                    hrReset: hr.start,
//                    locReset: loc.reset)
                
//                HStack {
//                    Button {
//                        hr.heartrate = BleHeartrateReceiver.Heartrate(heartrate: 150, when: Date())
//                        acc.isRunning = AclMotionReceiver.IsRunning(isRunning: true, when: Date())
//                    } label: {
//                        Text("150")
//                    }
//                    Button {
//                        acc.isRunning = AclMotionReceiver.IsRunning(isRunning: true, when: Date())
//                        hr.heartrate = BleHeartrateReceiver.Heartrate(heartrate: 180, when: Date())
//                    } label: {
//                        Text("180")
//                    }
//                    Button {
//                        hr.heartrate = BleHeartrateReceiver.Heartrate(heartrate: 190, when: Date())
//                        acc.isRunning = AclMotionReceiver.IsRunning(isRunning: true, when: Date())
//                    } label: {
//                        Text("190")
//                    }
//                    Button {
//                        hr.heartrate = BleHeartrateReceiver.Heartrate(heartrate: 203, when: Date())
//                        acc.isRunning = AclMotionReceiver.IsRunning(isRunning: true, when: Date())
//                    } label: {
//                        Text("203")
//                    }
//                }
            }
        }
//        .toolbar {
//            ToolbarStatusView(
//                hrError: hr.localizedError,
//                locError: loc.localizedError,
//                hrReceiving: hr.receiving,
//                locReceiving: loc.receiving,
//                accReceiving: acc.receiving,
//                hrLimitsEasy: hrLimits.value[.Easy],
//                heartrate: hr.heartrate?.heartrate)
//        }
        .onAppear {
            Database.sharedInstance.onAppear()
//            WorkoutRecorder.sharedInstance.start()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            Database.sharedInstance.onDisappear()
//            WorkoutRecorder.sharedInstance.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onReceive(timer) {_ in 
//            let current = workout.current($0)
//            
//            currentPace = current.paceSecPerKm
//            currentTotals = current.totals
//            currentTotal = current.total
        }
    }
}

private struct ErrorMessageView: View {
    let hrError: String
    let locError: String
    let hrReset: () -> Void
    let locReset: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            Image(systemName: (hrError > "" || locError > "") ? "bolt" : "checkmark")
            Text("\(hrError)\(locError)")
            if (hrError > "" || locError > "") {
                Button {
                    if hrError > "" {hrReset()}
                    if locError > "" {locReset()}
                } label: {
                    Image(systemName: "play.fill")
                }
            }
        }
        .padding()
        .font(.footnote)
    }
}

private struct ToolbarStatusView: View {
    let hrError: String
    let locError: String
    let hrReceiving: Bool
    let locReceiving: Bool
    let accReceiving: AclMotionReceiver.Status
    let hrLimitsEasy: ClosedRange<Int>?
    let heartrate: Int?

    var body: some View {
        HStack {
            Image(systemName: getMotion())
            Image(systemName: getLocation())
            Image(systemName: getHeart())
        }
        .font(.caption)
    }
    
    private func getLocation() -> String {
        guard locError == "" else {return "location.slash"}
        if locReceiving {return "location.fill"}
        return "location"
    }
    
    private func getHeart() -> String {
        guard hrError == "" else {return "heart.slash"}
        if hrReceiving {return "heart.fill"}
        return "heart"
    }
    
    private func getMotion() -> String {
        switch accReceiving {
        case .off:
            return "nosign"
            
        case .stationary:
            if let heartrate = heartrate,
               let hrLimitsEasy = hrLimitsEasy,
               heartrate >= hrLimitsEasy.lowerBound
            {
                return "figure.wave"
            } else {
                return "figure.stand"
            }
            
        case .walking:
            return "figure.walk"
            
        case .running:
            if let heartrate = heartrate,
               let hrLimitsEasy = hrLimitsEasy,
               heartrate < hrLimitsEasy.lowerBound
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
