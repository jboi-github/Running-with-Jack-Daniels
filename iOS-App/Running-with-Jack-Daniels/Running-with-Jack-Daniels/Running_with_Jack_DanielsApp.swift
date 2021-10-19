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

// FIXME: Ensure correct order of control- and value-messages.
// FIXME: If ACL not available/not authorized: Send one "Active" after start. Extend CMMotionActivity for this to show "active" if not avail/Auth.
// FIXME: If BLE not supported/not authorized: Keep Intensity as Easy and do not send any hr, vdot, etc.
// FIXME: Profile-data from manual input, health app or calculated needs redesign

// TODO: Save workouts to health
// TODO: Create pages for planning the season and workouts

// FIXME: Status is jumping after stop and start
// FIXME: Many, many status updates. Needs a lot CPU
// FIXME: Locations are wiered somehow
// FIXME: Time in system-event is -2h. True for ACL. What about GPS?
// FIXME: What happens if some or all services are switched off?

// TODO: Get Battery Level of BLE devices -> In scanner and in currents-toolbar.
// TODO: Get all heartrate BLE infos available
// TODO: ACL, motion to get steps, distance (rough estimation compared to GPS) and pace. If no GPS use this as alternative but do not show map on UI.
// TODO: GPS lets get and process deferred info while in background

// TODO: Add banner commercial
// TODO: Redesign with new async features?

// FIXME: Path dissapears after background and does not com back after restart
// DONE: BLE shows heart filled, even when not available
// DONE: HR is 0 instead of invisible if no hr-device available
// FIXME: Sum totals is not counting up
// FIXME: Controls should not send start when restarting after error.
