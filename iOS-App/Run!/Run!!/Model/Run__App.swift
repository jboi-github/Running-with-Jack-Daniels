//
//  Run__App.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import SwiftUI
import UserNotifications

@main
struct Run__App: App {
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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

class AppTwin {
    static let shared = AppTwin()
    private init() {
        Files.initDirectory()
        queue = DispatchQueue(label: "run-processing", qos: .userInitiated)

        pedometerDataClient = Client(delegate: PedometerDataClient(queue: queue))
        pedometerEventClient = Client(delegate: PedometerEventClient(queue: queue))
        motionActivityClient = Client(delegate: MotionActivityClient(queue: queue))
        locationClient = Client(delegate: LocationClient(queue: queue))
        heartrateMonitorClient = Client(delegate: HeartrateMonitorClient(queue: queue))
        workoutClient = Client(delegate: WorkoutClient(queue: queue))
    }
    
    func launchedByBle(_ at: Date, restoreIds: [String]) {
        runAppStatus = .background(since: at)
    }
    
    func launchedByGps(_ at: Date) {
        runAppStatus = .background(since: at)
    }
    
    func launchedByUser(_ at: Date) {
        runAppStatus = .background(since: at)
    }
    
    func scenePhaseChanged(at: Date, prev: ScenePhase, curr: ScenePhase, _ isRunViewActive: Bool) {
        switch curr {
        case .active:
            runViewActiveChanged(at: at, isRunViewActive)
        case .inactive:
            if prev == .active {
                runAppStatus = .background(since: at)
            }
        case .background:
            if prev == .active {
                runAppStatus = .background(since: at)
            }
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
            let asOf = Date.now
            log(asOf, oldValue, runAppStatus)

            if case .activeRunView = runAppStatus {
                pedometerDataClient.start(asOf: asOf)
                pedometerEventClient.start(asOf: asOf)
                motionActivityClient.start(asOf: asOf)
                locationClient.start(asOf: asOf)
                heartrateMonitorClient.start(asOf: asOf)
            }
            if case .activeRunView = oldValue, case .stopped = workoutClient.status {
                pedometerDataClient.stop(asOf: asOf)
                pedometerEventClient.stop(asOf: asOf)
                motionActivityClient.stop(asOf: asOf)
                locationClient.stop(asOf: asOf)
                heartrateMonitorClient.stop(asOf: asOf)
            }
            if case .background = runAppStatus, case .started = workoutClient.status {
                AppTwin.userReturn()
            }
        }
    }

    let queue: DispatchQueue
        
    let pedometerDataClient: Client<PedometerDataClient>
    let pedometerEventClient: Client<PedometerEventClient>
    let motionActivityClient: Client<MotionActivityClient>
    let locationClient: Client<LocationClient>
    let heartrateMonitorClient: Client<HeartrateMonitorClient>
    let workoutClient: Client<WorkoutClient>
    
    private static func userReturn() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            guard check(error), success else {return}
            
            let content = UNMutableNotificationContent()
            content.title = "RUN!! Workout in progress"
            content.subtitle = "return to RUN!! whenever needed."
            content.sound = UNNotificationSound.default

            // show this notification one seconds from now
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

            // choose a random identifier
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            // add our notification request
            UNUserNotificationCenter.current().add(request)
        }
    }
}

enum RunAppStatus  {
    case terminated
    case background(since: Date)
    case activeRunView(since: Date)
    case inactiveRunView(since: Date)
}

let workoutTimeout: TimeInterval = 12*3600
let signalTimeout: TimeInterval = 600
