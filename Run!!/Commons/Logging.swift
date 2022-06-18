//
//  Logging.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import Foundation
import os

// MARK: Logging

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.apps4live",
    category: "log")

/**
 Write a log message to standard logging. It adds "*JB" at the beginning of the message + information to easily locate, where the log was written.
 
 To inspect logs later for debugging use the command-line on your Mac:
 - `sudo log collect --device --start '2021-08-01 18:20:00' --output out.logarchive`
 
 Note, that you must be `root` to run log. Use the log-console on the mac. Search for: "subsystem: apps4live" to get the relevant messages.
 */
func log(
    level: OSLogType = .info, _ msg: Any...,
    function: String = #function, file: String = #file,
    line: Int = #line, col: Int = #column)
{
    #if DEBUG
    var localFile: String {URL(fileURLWithPath: file).lastPathComponent}
    var localMsg: String {msg.map {"\($0)"}.joined(separator: ", ")}
    
    // swiftlint: disable line_length
    logger.log(
        level: level,
        "* JB: \(localFile, privacy: .public): \(function, privacy: .public)(\(line, privacy: .public), \(col, privacy: .public)): \(localMsg, privacy: .public)")
    #endif
}

/**
 Handle errors.
 
 - Parameters:
    - error: the optional error to check
 - Returns: true, if check was succesful, false if error occured
 */
@discardableResult func check(
    _ error: Error?,
    function: String = #function, file: String = #file, line: Int = #line, col: Int = #column) -> Bool {
    
    if let error = error {
        log(level: .error, "Error: \(error)", function: function, file: file, line: line, col: col)
        return false
    }
    return true
}

// MARK: Error extensions
extension String: LocalizedError {
    public var errorDescription: String? {self}
}
