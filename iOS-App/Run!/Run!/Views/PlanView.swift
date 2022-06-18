//
//  PlanView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct PlanView: View {
    @State private var selectedTab = "Profile"
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selectedTab) {
            PlanProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag("Profile")

            PlanSeasonView()
                .tabItem {
                    Label("Season", systemImage: "calendar")
                }
                .tag("Season")
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Plan")
        .animation(.default, value: selectedTab)
        .onAppear {
            log("appeared")
            ProfileService.sharedInstance.onAppear()
        }
        .onDisappear {
            log("disappeared")
            ProfileService.sharedInstance.onDisappear()
        }
        .onChange(of: scenePhase) {
            switch $0 {
            case .active:
                log("resume")
                ProfileService.sharedInstance.onAppear()
            case .inactive:
                log("pause")
                ProfileService.sharedInstance.onDisappear()
            default:
                log("no action necessary")
            }
        }
    }
}

#if DEBUG
struct PlanView_Previews: PreviewProvider {
    static var previews: some View {
        PlanView()
    }
}
#endif
