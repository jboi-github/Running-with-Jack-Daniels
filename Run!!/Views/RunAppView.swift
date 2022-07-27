//
//  ContentView.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import SwiftUI

struct RunAppView: View {
    let queue: SerialQueue
    @AppStorage("RunAppViewSelection") private var selection: Int = 0
    @EnvironmentObject private var appStatus: AppStatus

    var body: some View {
        Group {
            if selection == 0 {
                RunView(selection: $selection)
                    .background(Color.primary.colorInvert().ignoresSafeArea())
            } else {
                TabView(selection: $selection) { // TODO: Animate change on selection
                    RunView(selection: $selection)
                        .myTabItem(selection, text: "Run!!", systemName: "hare")
                        .tag(0)
                    ImproveView()
                        .myTabItem(selection, text: "Improve", systemName: "chart.line.uptrend.xyaxis")
                        .tag(1)
                    ProfileView()
                        .myTabItem(selection, text: "Profile", systemName: "person")
                        .tag(2)
                    PlanView()
                        .myTabItem(selection, text: "Season", systemName: "calendar")
                        .tag(3)
                    ScannerView(queue: queue)
                        .myTabItem(selection, text: "Bluetooth", systemName: "antenna.radiowaves.left.and.right")
                        .tag(4)
                }
            }
        }
        .colorScheme(.dark)
        .onChange(of: selection) {
            log($0)
            appStatus.isRunViewActive = $0 == 0
        }
        .onAppear {
            log(selection)
            Profile.onAppear()
            appStatus.isRunViewActive = selection == 0
        }
    }
}

private extension View {
    func myTabItem(_ selection: Int, text: String, systemName: String) -> some View {
        if selection == 0 {
            return self
                .anyview
        } else {
            return self
                .tabItem {
                    Label {
                        Text(text).font(.footnote)
                    } icon: {
                        Image(systemName: systemName)
                    }
                }
                .anyview
        }
    }
}

struct RunAppView_Previews: PreviewProvider {
    static var previews: some View {
        RunAppView(queue: SerialQueue("X"))
    }
}
