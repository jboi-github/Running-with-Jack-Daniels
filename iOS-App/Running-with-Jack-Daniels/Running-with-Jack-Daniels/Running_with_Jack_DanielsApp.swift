//
//  Running_with_Jack_DanielsApp.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 12.06.21.
//

import SwiftUI
import OSLog

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
        
        logger.info("didFinishLaunchingWithOptions")
        return true
    }
}

// MARK: Logging

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.apps4live",
    category: "log")

/**
 Write a log message to standard output. It adds "*GF" at the beginning of the message + information to easily locate, where the log was written.
 */
public func log(
    msg: String? = nil,
    function: String = #function, file: String = #file,
    line: Int = #line, col: Int = #column)
{
    #if DEBUG
    var localFile: String {URL(fileURLWithPath: file).lastPathComponent}
    var localMsg: String {
        if let msg = msg {
            return ": \(msg)"
        } else {
            return ""
        }
    }
    
    logger.info("* JB: \(localFile): \(function)(\(line), \(col))\(localMsg)")
    #endif
}

/**
 Handle errors.
 
 - Parameters:
    - error: the optional error to check
 - Returns: true, if check was succesful, false if error occured
 */
func check(
    _ error: Error?,
    function: String = #function, file: String = #file, line: Int = #line, col: Int = #column) -> Bool {
    
    if let error = error {
        log(msg: "Error: \(error)", function: function, file: file, line: line, col: col)
        return false
    }
    return true
}

extension String: LocalizedError {
    public var errorDescription: String? {self}
}
