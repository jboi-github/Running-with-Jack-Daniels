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

class AppTwin {
    static let shared = AppTwin()
    private init() {
        workout = Workout(
            isActiveGetter: {AppTwin.shared.isActives.isActives[$0]},
            distanceGetter: {AppTwin.shared.distances.distances[$0]},
            bodySensorLocationGetter: {AppTwin.shared.hrmTwin.bodySensorLocation})
        totals = Totals(
            motionGetter: {AppTwin.shared.motions.motions[$0]},
            isActiveGetter: {AppTwin.shared.isActives.isActives[$0]},
            heartrateGetter: {AppTwin.shared.heartrates.heartrates[$0]},
            intensityGetter: {AppTwin.shared.intensities.intensities[$0]},
            distanceGetter: {AppTwin.shared.distances.distances[$0]},
            workout: workout)

        isActives = IsActives(workout: workout)
        distances = Distances(workout: workout, totals: totals)
        intensities = Intensities()
        
        motions = Motions(isActives: isActives, workout: workout, totals: totals)
        heartrates = Heartrates(intensities: intensities, workout: workout, totals: totals)
        locations = Locations(distances: distances, workout: workout, totals: totals)
        
        queue = DispatchQueue(label: "run-processing", qos: .userInitiated)
        
        aclTwin = AclTwin(queue: queue, motions: motions)
        hrmTwin = HrmTwin(queue: queue, heartrates: heartrates)
        gpsTwin = GpsTwin(queue: queue, locations: locations)
        
        timer = RunTimer(
            isInBackground: {
                switch AppTwin.shared.runAppStatus {
                case .background:
                    return true
                default:
                    return false
                }
            },
            queue: queue,
            aclTwin: aclTwin,
            motions: motions,
            heartrates: heartrates,
            locations: locations,
            isActives: isActives,
            intensities: intensities,
            distances: distances)
        
        currents = Currents(
            aclTwin: aclTwin,
            hrmTwin: hrmTwin,
            gpsTwin: gpsTwin,
            motions: motions,
            heartrates: heartrates,
            locations: locations,
            isActives: isActives,
            distances: distances,
            intensities: intensities,
            workout: workout)
    }
    
    func launchedByBle(_ at: Date, restoreIds: [String]) {
        runAppStatus = .background(since: at)
        if restoreIds.contains(HrmTwin.bleRestoreId) {hrmTwin.start(asOf: at)}
    }
    
    func launchedByGps(_ at: Date) {
        runAppStatus = .background(since: at)
        gpsTwin.start(asOf: at)
    }
    
    func launchedByUser(_ at: Date) {
        runAppStatus = .background(since: at)
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
            case (.terminated, .background(_)):
                Files.initDirectory()
                Profile.setup()
                
                // Restore collections
                load()
            case (.background(_), .activeRunView(let since)):
                workout.await(asOf: since)
                aclTwin.start(asOf: since)
                hrmTwin.start(asOf: since)
                gpsTwin.start(asOf: since)
                timer.start()
            case (.inactiveRunView(_), .activeRunView(let since)):
                workout.await(asOf: since)
                aclTwin.start(asOf: since)
                hrmTwin.start(asOf: since)
                gpsTwin.start(asOf: since)
                timer.start()
            case (.activeRunView(_), .inactiveRunView(let since)):
                timer.stop()
                aclTwin.stop(asOf: since)
                hrmTwin.stop(asOf: since)
                gpsTwin.stop(asOf: since)
            case (.activeRunView(_), .background(let since)):
                timer.stop()
                if case .stopped = workout.status {
                    aclTwin.stop(asOf: since)
                    hrmTwin.stop(asOf: since)
                    gpsTwin.stop(asOf: since)
                } else {
                    userReturn()
                    aclTwin.pause(asOf: since)
                }
                // Save collections
                save()
            case (.inactiveRunView(_), .background(_)):
                // Save collections
                save()
            case (_, _):
                break
            }
        }
    }

    let queue: DispatchQueue
    
    let isActives: IsActives
    let distances: Distances
    let intensities: Intensities
    
    let motions: Motions
    let heartrates: Heartrates
    let locations: Locations
    
    let aclTwin: AclTwin
    let hrmTwin: HrmTwin
    let gpsTwin: GpsTwin
    
    let timer: RunTimer
    let workout: Workout
    let totals: Totals
    let currents: Currents
    
    private func load() {
        queue.async { [self] in
            workout.load()
            totals.load()

            isActives.load()
            distances.load()
            intensities.load()
            
            motions.load()
            heartrates.load()
            locations.load()
        }
    }
    
    private func save() {
        queue.async { [self] in
            motions.save()
            heartrates.save()
            locations.save()
            
            isActives.save()
            distances.save()
            intensities.save()
            
            workout.save()
            totals.save()
        }
    }
    
    private func userReturn() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            guard check(error), success else {return}
            
            let content = UNMutableNotificationContent()
            content.title = "RUN!!"
            content.subtitle = "return to RUN!!"
            content.sound = UNNotificationSound.default

            // show this notification five seconds from now
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)

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
