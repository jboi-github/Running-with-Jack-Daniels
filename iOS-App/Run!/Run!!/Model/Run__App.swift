//
//  Run__App.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import SwiftUI
import BackgroundTasks

@main
struct Run__App: App {
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDalagate
    
    @State private var isRunViewActive: Bool = true
    
    var body: some Scene {
        WindowGroup {
            RunAppView(isRunViewActive: $isRunViewActive)
                .onChange(of: scenePhase) {
                    AppTwin.shared.scenePhaseChanged(at: .now, prev: scenePhase, curr: $0, isRunViewActive)
                }
                .onChange(of: isRunViewActive) {
                    AppTwin.shared.runViewActiveChanged(at: .now, $0)
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool
    {
        let launchedAt = Date.now
        log("Launch with options", launchOptions?.keys ?? [])
        if let bleOption = launchOptions?[.bluetoothCentrals] as? [String] {
            log(bleOption)
            AppTwin.shared.launchedByBle(launchedAt, restoreIds: bleOption)
        }
        if let gpsOption = launchOptions?[.location] {
            log(gpsOption)
            AppTwin.shared.launchedByGps(launchedAt)
        }
        if launchOptions?.isEmpty ?? true {
            log("launched by user")
            AppTwin.shared.launchedByUser(launchedAt)
        }
        return true
    }
}

class AppTwin: ObservableObject {
    static let shared = AppTwin()
    private init() {}
    
    func launchedByBle(_ at: Date, restoreIds: [String]) {
        runAppStatus = .background(since: at)
        if restoreIds.contains(HrmTwin.bleRestoreId) {hrmTwin.start(asOf: at)}
        // TODO: After ble data is processed, save if in background
    }
    
    func launchedByGps(_ at: Date) {
        runAppStatus = .background(since: at)
        gpsTwin.start(asOf: at)
        // TODO: After gps data is processed, save if in background
    }
    
    func launchedByUser(_ at: Date) {
        runAppStatus = .background(since: at)
        // TODO: save when changing into background
    }
    
    func scenePhaseChanged(at: Date, prev: ScenePhase, curr: ScenePhase, _ isRunViewActive: Bool) {
        switch curr {
        case .active:
            runViewActiveChanged(at: at, isRunViewActive)
        case .inactive:
            if prev == .active {runAppStatus = .background(since: at)}
        case .background:
            if prev == .active {runAppStatus = .background(since: at)}
        @unknown default:
            check("ScenePhase unknown!")
        }
    }
    
    func runViewActiveChanged(at: Date, _ isRunViewActive: Bool) {
        if isRunViewActive {
            runAppStatus = .activeRunView(since: at)
        } else {
            runAppStatus = .inactiveRunView(since: at)
        }
    }
    
    private(set) var runAppStatus: RunAppStatus = .terminated {
        didSet {
            log(oldValue, runAppStatus)
            switch (oldValue, runAppStatus) {
            case (.background(_), .activeRunView(let since)):
                aclTwin.start(asOf: since)
                hrmTwin.start(asOf: since)
                gpsTwin.start(asOf: since)
            case (.inactiveRunView(_), .activeRunView(let since)):
                aclTwin.start(asOf: since)
                hrmTwin.start(asOf: since)
                gpsTwin.start(asOf: since)
            case (.activeRunView(_), .inactiveRunView(let since)):
                aclTwin.stop(asOf: since)
                hrmTwin.stop(asOf: since)
                gpsTwin.stop(asOf: since)
            case (.activeRunView(_), .background(let since)):
                if workout.status == .stopped {
                    aclTwin.stop(asOf: since)
                    hrmTwin.stop(asOf: since)
                    gpsTwin.stop(asOf: since)
                } else {
                    // TODO: Send user notification to allow return
                    aclTwin.pause(asOf: since)
                }
            case (_, _):
                break
            }
        }
    }

    let aclTwin = AclTwin()
    let hrmTwin = HrmTwin()
    let gpsTwin = GpsTwin()
    let workout = Workout()
}

enum RunAppStatus  {
    case terminated
    case background(since: Date)
    case activeRunView(since: Date)
    case inactiveRunView(since: Date)
}

/*
 <key>NSBluetoothAlwaysUsageDescription</key>
 <string>Needed to track heartrate during workout. Continues to track while workout is ongoing or Run!! is in foreground.</string>
 <key>NSMotionUsageDescription</key>
 <string>Needed to detect workouts and pauses. If disabled, Run!! is just a complicated stop-watch.</string>
 */
