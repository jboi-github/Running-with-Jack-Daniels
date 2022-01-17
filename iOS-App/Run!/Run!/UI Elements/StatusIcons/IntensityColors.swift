//
//  IntensityColors.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

extension Intensity {
    var color: Color {
        switch self {
        case .Cold:
            return Color(UIColor.systemBlue)
        case .Easy:
            return Color(UIColor.systemGreen)
        case .Long:
            return Color(UIColor.systemGreen)
        case .Marathon:
            return Color(UIColor.systemYellow)
        case .Threshold:
            return Color(UIColor.systemOrange)
        case .Interval:
            return Color(UIColor.systemRed)
        case .Repetition:
            return Color(UIColor.systemPink)
        case .Race:
            return Color.primary
        }
    }
    
    var textColor: Color {
        switch self {
        case .Cold:
            return Color(UIColor.systemGray6)
        case .Easy:
            return Color.primary
        case .Long:
            return Color.primary
        case .Marathon:
            return Color.primary
        case .Threshold:
            return Color.primary
        case .Interval:
            return Color.primary
        case .Repetition:
            return Color.primary
        case .Race:
            return Color(UIColor.systemGray6)
        }
    }
}
