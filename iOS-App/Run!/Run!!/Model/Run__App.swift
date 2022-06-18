//
//  Run__App.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import SwiftUI
import UserNotifications
import Combine

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

class AppTwin: ObservableObject {
    static let shared = AppTwin()
    private init() {
        Files.initDirectory()
        queue = DispatchQueue(label: "run-processing", qos: .userInitiated)

        // Timeseries
        timeseriesSet = TimeSeriesSet()

        // Clients
        sensorClients = [
            Client(
                delegate: PedometerDataClient(
                    queue: queue,
                    pedometerDataTimeseries: timeseriesSet.pedometerDataTimeseries)),
            Client(
                delegate: PedometerEventClient(
                    queue: queue,
                    pedometerEventTimeseries: timeseriesSet.pedometerEventTimeseries)),
            Client(
                delegate: MotionActivityClient(
                    queue: queue,
                    motionActivityTimeseries: timeseriesSet.motionActivityTimeseries)),
            Client(
                delegate: LocationClient(
                    queue: queue,
                    locationTimeseries: timeseriesSet.locationTimeseries,
                    distanceTimeseries: timeseriesSet.distanceTimeseries)),
            Client(
                delegate: HeartrateMonitorClient(
                    queue: queue,
                    heartrateTimeseries: timeseriesSet.heartrateTimeseries,
                    intensityTimeseries: timeseriesSet.intensityTimeseries,
                    batteryLevelTimeseries: timeseriesSet.batteryLevelTimeseries,
                    bodySensorLocationTimeseries: timeseriesSet.bodySensorLocationTimeseries,
                    peripheralTimeseries: timeseriesSet.peripheralTimeseries))
        ]
        workoutClient = Client(
            delegate: WorkoutClient(
                queue: queue,
                workoutTimeseries: timeseriesSet.workoutTimeseries,
                archive: timeseriesSet.archive))
        timerClient = Client(delegate: TimerClient(sensorClients + [workoutClient]))

        $runAppStatus
            .sink { [self] runAppStatus in
                let oldValue = self.runAppStatus
                let asOf = Date.now
                log(asOf, oldValue, runAppStatus)

                if case .activeRunView = runAppStatus {
                    log("User did move to RunView")
                    Profile.onAppear()
                    sensorClients.forEach {$0.start(asOf: asOf)}
                    timerClient.start(asOf: asOf)
                }
                if case .activeRunView = oldValue {
                    log("User left RunView")
                    timerClient.stop(asOf: asOf)
                }
                if case .activeRunView = oldValue, case .stopped = workoutClient.status {
                    log("User left RunView without working out")
                    sensorClients.forEach {$0.stop(asOf: asOf)}
                }
                if case .background = runAppStatus, case .started = workoutClient.status {
                    log("User left RunView while still in Workout")
                    AppTwin.userReturn()
                }
                if case .background = runAppStatus {
                    log("App moved to background")
                    timeseriesSet.isInBackground = true
                } else {
                    log("User moved to foreground")
                    timeseriesSet.isInBackground = false
                }
            }
            .store(in: &subscribers)
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
    
    @Published private(set) var runAppStatus: RunAppStatus = .terminated
    
    let queue: DispatchQueue
    
    // Clients
    let sensorClients: [Client]
    let workoutClient: Client
    let timerClient: Client
    
    // Timeseries
    let timeseriesSet: TimeSeriesSet

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
    
    private var subscribers = Set<AnyCancellable>()
}

enum RunAppStatus  {
    case terminated
    case background(since: Date)
    case activeRunView(since: Date)
    case inactiveRunView(since: Date)
}

let workoutTimeout: TimeInterval = 12*3600
let signalTimeout: TimeInterval = 600
