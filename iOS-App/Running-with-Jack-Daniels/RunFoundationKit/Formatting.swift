//
//  Formatting.swift
//  RunFoundationKit
//
//  Created by Jürgen Boiselle on 05.10.21.
//

import Foundation
import SwiftUI
import MapKit

// MARK: Formatting
extension TimeInterval {
    public func asTime(_ font: Font = .body, measureFont: Font = .caption, withMeasure: Bool = true)
    -> some View
    {
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
    
    public func asPace(_ font: Font = .body, measureFont: Font = .caption, withMeasure: Bool = true)
    -> some View
    {
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

    public func asDistance(_ font: Font = .body, measureFont: Font = .caption, withMeasure: Bool = true)
    -> some View
    {
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
    
    public func asVdot(_ font: Font = .body) -> some View {
        guard self.isFinite else {return Text("--.-").font(font).anyview}
        return Text("\(self, specifier: "%2.1f")").font(font).anyview
    }
}

extension MKCoordinateRegion {
    public func expanded(by expansion: Double, minMeter: CLLocationDistance) -> Self {
        let spanExpanded = MKCoordinateSpan(
            latitudeDelta: span.latitudeDelta * expansion,
            longitudeDelta: span.longitudeDelta * expansion)
        let spanMinMeter = MKCoordinateRegion(
            center: center,
            latitudinalMeters: minMeter,
            longitudinalMeters: minMeter)
            .span
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(spanExpanded.latitudeDelta, spanMinMeter.latitudeDelta),
            longitudeDelta: max(spanExpanded.longitudeDelta, spanMinMeter.longitudeDelta))
        
        return Self(center: center, span: span)
    }
}
