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

// DONE: Ensure correct order of control- and value-messages.
// DONE: If ACL not available/not authorized: Send one "Active" after start. Extend CMMotionActivity for this to show "active" if not avail/Auth.
// DONE: If BLE not supported/not authorized: Keep Intensity as Cold and do not send any hr, vdot, etc.
// FIXME: Profile-data from manual input, health app or calculated needs redesign

// TODO: Save workouts to health
// TODO: Create pages for planning the season and workouts

// DONE: Status is jumping after stop and start
// DONE: Many, many status updates. Needs a lot CPU
// DONE: Locations are wiered somehow
// DONE: Time in system-event is -2h. True for ACL. What about GPS?
// FIXME: What happens if some or all services are switched off?

// TODO: Get Battery Level of BLE devices -> In scanner and in currents-toolbar.
// TODO: Get all heartrate BLE infos available
// TODO: ACL, motion to get steps, distance (rough estimation compared to GPS) and pace. If no GPS, use this as alternative but do not show map on UI.
// TODO: Make Map collapsable on UI. Thus save power.
// TODO: Link to system-preferences on Navi-UI
// TODO: Give "Power-Saver"-Button on UI: No location (Pedometer only), no Map.
// TODO: Build segments without Location and HR changes (Changes very often). Keep them seperate for path and healthkit.
// DONE: GPS lets get and process deferred info while in background

// TODO: Add banner commercial
// TODO: Redesign with new async features?

// DONE: Path dissapears after background and does not com back after restart
// DONE: BLE shows heart filled, even when not available
// DONE: HR is 0 instead of invisible if no hr-device available
// DONE: Sum totals is not counting up
// DONE: Controls should not send start when restarting after error.

// TODO: Create integration-Test cases
// DONE: Reduce CPU Usage: (1) locations as ordered array instead of set. (2) Reuse Overlays. (3) Minimize points with RDP-Algo
// FIXME: When HR not available but GPS (speed) it is not shown
// FIXME: Ble crashes App after some time during reset?
// DONE: No distance counting in sum, when paused
// TODO: Can Ble be used to get speed on treadmills?
