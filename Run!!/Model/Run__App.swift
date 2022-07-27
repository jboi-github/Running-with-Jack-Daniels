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
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var appStatus = AppStatus()
    @StateObject private var timeseriesSet = TimeSeriesSet(queue: queue)
    @StateObject private var clientsSet = ClientsSet(queue: queue)

    var body: some Scene {
        WindowGroup {
            RunAppView(queue: queue)
                .onAppear {
                    clientsSet.connect(timeseriesSet: timeseriesSet)
                    appStatus.delegate = AppStatusDelegate(timeseriesSet, clientsSet)
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .inactive {
                        appStatus.isAppOnForeground = true
                    } else if newPhase == .active {
                        appStatus.isAppOnForeground = true
                    } else if newPhase == .background {
                        appStatus.isAppOnForeground = false
                    }
                }
                .environmentObject(appStatus)
                .environmentObject(timeseriesSet)
                .environmentObject(clientsSet)
        }
    }
}

protocol RunAppStatusDelegate: AnyObject {
    /// App is in background or terminated. User opens it and it moves straight into RunView.
    func enterForegroundIntoRunView(asOf: Date)
    
    /// App is in background or terminated. User opens it and it moves into any other View like "improve" or "profile".
    func enterForegroundIntoOtherView(asOf: Date)
    
    /// App is started, in foreground and in RunView. User moves away from RunView into any other view.
    func leaveRunViewWhileInForeground(asOf: Date)
    
    /// App is started, in foreground and in any other view but RunView. User moves into from RunView from any other view.
    func enterRunViewWhileInForeground(asOf: Date)
    
    /// App is started, in foreground and in RunView. User closes app or moves it into ackground while RunView is open.
    func leaveForegroundWhileInRunView(asOf: Date)
    
    /// App is started, in foreground and in any other view but RunView. User closes app or moves it into ackground.
    func leaveForegroundWhileInOtherView(asOf: Date)
}

class AppStatus: ObservableObject {
    init() {
        Files.initDirectory()
    }
    
    var delegate: AppStatusDelegate?
    
    var isRunViewActive: Bool = false {
        didSet {
            if oldValue == isRunViewActive {return}
            let asOf = Date.now

            if isRunViewActive {
                if isAppOnForeground {
                    delegate?.enterRunViewWhileInForeground(asOf: asOf)
                }
            } else {
                if isAppOnForeground {
                    delegate?.leaveRunViewWhileInForeground(asOf: asOf)
                }
            }
        }
    }
    
    var isAppOnForeground: Bool = false {
        didSet {
            if oldValue == isAppOnForeground {return}
            let asOf = Date.now

            if isAppOnForeground {
                if isRunViewActive {
                    delegate?.enterForegroundIntoRunView(asOf: asOf)
                } else {
                    delegate?.enterForegroundIntoOtherView(asOf: asOf)
                }
            } else {
                if isRunViewActive {
                    delegate?.leaveForegroundWhileInRunView(asOf: asOf)
                } else {
                    delegate?.leaveForegroundWhileInOtherView(asOf: asOf)
                }
            }
        }
    }
}

class AppStatusDelegate: RunAppStatusDelegate {
    init(_ timeseriesSet: TimeSeriesSet, _ clientSet: ClientsSet) {
        self.timeseriesSet = timeseriesSet
        self.clientSet = clientSet
        log()
    }
    
    func enterForegroundIntoRunView(asOf: Date) {
        log()
        timeseriesSet.isInBackground = false
        clientSet.startSensors(asOf: asOf)
    }
    
    func enterForegroundIntoOtherView(asOf: Date) {
        log()
        timeseriesSet.isInBackground = false
        clientSet.stopSensors(asOf: asOf)
    }
    
    func leaveRunViewWhileInForeground(asOf: Date) {
        log()
        clientSet.stopSensors(asOf: asOf)
    }
    
    func enterRunViewWhileInForeground(asOf: Date) {
        log()
        clientSet.startSensors(asOf: asOf)
    }
    
    func leaveForegroundWhileInRunView(asOf: Date) {
        log()
        timeseriesSet.isInBackground = true
        AppStatusDelegate.userReturn()
    }
    
    func leaveForegroundWhileInOtherView(asOf: Date) {
        log()
        timeseriesSet.isInBackground = true
    }
    
    private let timeseriesSet: TimeSeriesSet
    private let clientSet: ClientsSet

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

// Very global variables
private let queue = SerialQueue("run-processing")
let workoutTimeout: TimeInterval = 6 * 3600
