//
//  Running_with_Jack_DanielsApp.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 12.06.21.
//

import SwiftUI
import os
import MapKit

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

// MARK: Logging

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.apps4live",
    category: "log")

/**
 Write a log message to standard logging. It adds "*JB" at the beginning of the message + information to easily locate, where the log was written.
 
 To inspect logs later for debugging use the command-line on your Mac:
 - `sudo log collect --device --start '2021-08-01 18:20:00' --output out.logarchive`
 
 Note, that you must be `root` to run log. Use the log-console on the mac. Search for: "subsystem: apps4live" to get the relevant messages.
 */
public func log(
    level: OSLogType = .info, _ msg: Any...,
    function: String = #function, file: String = #file,
    line: Int = #line, col: Int = #column)
{
    #if DEBUG
    var localFile: String {URL(fileURLWithPath: file).lastPathComponent}
    var localMsg: String {msg.map {"\($0)"}.joined(separator: ", ")}
    
    logger.log(level: level, "* JB: \(localFile, privacy: .public): \(function, privacy: .public)(\(line, privacy: .public), \(col, privacy: .public)): \(localMsg, privacy: .public)")
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
        log(level: .error, "Error: \(error)", function: function, file: file, line: line, col: col)
        return false
    }
    return true
}

// MARK: Common extensions

extension String: LocalizedError {
    public var errorDescription: String? {self}
}

extension MKCoordinateRegion {
    var area: Double {span.latitudeDelta * span.longitudeDelta}
}

extension View {
    var anyview: AnyView {AnyView(self)}
}

extension TimeInterval {
    func asTime(_ font: Font = .body, measureFont: Font = .caption, withMeasure: Bool = true) -> some View {
        guard self.isFinite else {return Text("--:--").font(font).anyview}
        
        let hours = Int(self / 3600.0)
        let minutes = Int(self.truncatingRemainder(dividingBy: 3600) / 60.0)
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))
        
        return HStack(spacing: 0) {
            if hours > 0 {Text("\(hours, specifier: "%2d"):")}
            if minutes > 0 {Text("\(minutes, specifier: (self < 3600 ? "%2d" : "%02d")):")}
            Text("\(seconds, specifier: (self < 60 ? "%2d" : "%02d"))")
            
            if withMeasure && self >= 3600 {Text(" h:mm:ss").font(measureFont)}
            else if withMeasure && self >= 60 {Text(" m:ss").font(measureFont)}
            else if withMeasure {Text(" sec").font(measureFont)}
        }
        .font(font)
        .anyview
    }
    
    func asPace(_ font: Font = .body, measureFont: Font = .caption, withMeasure: Bool = true) -> some View {
        return HStack(spacing: 0) {
            asTime(font, measureFont: measureFont, withMeasure: withMeasure)
            Text("\(withMeasure ? "/km" : " /km")").font(measureFont)
        }
    }
}

extension Double {
    public func format(_ format: String, ifNan: String = "NaN") -> String {
        String(format: self.isFinite ? format : ifNan, self)
    }

    func asDistance(_ font: Font = .body, measureFont: Font = .caption, withMeasure: Bool = true) -> some View {
        guard self.isFinite else {return Text("-").font(font).anyview}
        
        if self <= 5000 {
            return HStack(spacing: 0) {
                Text("\(self, specifier: "%4.0f")").font(font)
                if withMeasure {Text(" m").font(measureFont)}
            }
            .anyview
        } else {
            return HStack(spacing: 0) {
                Text("\(self / 1000, specifier: "%3.1f")").font(font)
                if withMeasure {Text(" km").font(measureFont)}
            }
            .anyview
        }
    }
    
    func asVdot(_ font: Font = .body) -> some View {
        guard self.isFinite else {return Text("--.-").font(font).anyview}
        return Text("\(self, specifier: "%2.1f")").font(font).anyview
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension MKCoordinateSpan: Equatable {
    public static func == (lhs: MKCoordinateSpan, rhs: MKCoordinateSpan) -> Bool {
        lhs.latitudeDelta == rhs.latitudeDelta && lhs.longitudeDelta == rhs.longitudeDelta
    }
    
    func expanded(by expansion: CLLocationDegrees) -> Self {
        MKCoordinateSpan(latitudeDelta: latitudeDelta * expansion, longitudeDelta: longitudeDelta * expansion)
    }
}

extension MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        lhs.center == rhs.center && lhs.span == rhs.span
    }
    
    func expanded(by expansion: CLLocationDegrees, minMeter: CLLocationDistance = 0) -> Self {
        let minSpan = MKCoordinateRegion(center: center, latitudinalMeters: minMeter, longitudinalMeters: minMeter).span
        let expandedSpan = span.expanded(by: expansion)
        
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: max(minSpan.latitudeDelta, expandedSpan.latitudeDelta),
                longitudeDelta: max(minSpan.longitudeDelta, expandedSpan.longitudeDelta)))
    }
}
