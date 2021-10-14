//
//  Running_with_Jack_DanielsApp.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 12.06.21.
//

import SwiftUI
import RunFoundationKit

@main
struct Running_with_Jack_DanielsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            NaviView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        log()
        return true
    }
}

// FIXME: Status is jumping after stop and start
// FIXME: Many, many status updates. Needs a lot CPU
// FIXME: Locations are wiered somehow
// FIXME: What happens if some or all services are switched off?
// FIXME: Profile-data fom manual input, health app or calculated needs redesign
// TODO: Create pages for planning the season and workouts
// TODO: Save workouts to health
// TODO: Redesign with new async features?
// FIXME: Time in system-event is -2h. True for ACL. What about GPS?

