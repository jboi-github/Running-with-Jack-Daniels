//
//  ContentView.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import SwiftUI

struct RunAppView: View {
    @Binding var isRunViewActive: Bool
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            RunView()
                .tabItem {
                    Label {
                        Text("Run!").font(.footnote)
                    } icon: {
                        Image(systemName: "hare")
                    }
                }
                .tag(0)
            ImproveView()
                .tabItem {
                    Label {
                        Text("Improve").font(.footnote)
                    } icon: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                    }
                }
                .tag(3)
            ProfileView()
                .tabItem {
                    Label {
                        Text("Profile").font(.footnote)
                    } icon: {
                        Image(systemName: "person")
                    }
                }
                .tag(1)
            PlanView()
                .tabItem {
                    Label {
                        Text("Season").font(.footnote)
                    } icon: {
                        Image(systemName: "calendar")
                    }
                }
                .tag(2)
            ScannerView()
                .tabItem {
                    Label {
                        Text("Bluetooth").font(.footnote)
                    } icon: {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                    }
                }
                .tag(4)
        }
        .onAppear {isRunViewActive = selection == 0}
        .onChange(of: selection) {isRunViewActive = $0 == 0}
    }
}

struct RunAppView_Previews: PreviewProvider {
    static var previews: some View {
        RunAppView(isRunViewActive: .constant(true))
    }
}