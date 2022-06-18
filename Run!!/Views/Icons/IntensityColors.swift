//
//  IntensityColors.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

extension Run.Intensity {
    var color: Color {
        switch self {
        case .cold:
            return Color(UIColor.systemBlue)
        case .easy:
            return Color(UIColor.systemGreen)
        case .long:
            return Color(UIColor.systemGreen)
        case .marathon:
            return Color(UIColor.systemYellow)
        case .threshold:
            return Color(UIColor.systemOrange)
        case .interval:
            return Color(UIColor.systemRed)
        case .repetition:
            return Color(UIColor.systemPink)
        case .race:
            return Color.primary
        }
    }
    
    var textColor: Color {
        switch self {
        case .cold:
            return Color.primary
        case .easy:
            return Color(UIColor.systemGray6)
        case .long:
            return Color(UIColor.systemGray6)
        case .marathon:
            return Color(UIColor.systemGray6)
        case .threshold:
            return Color(UIColor.systemGray6)
        case .interval:
            return Color(UIColor.systemGray6)
        case .repetition:
            return Color(UIColor.systemGray6)
        case .race:
            return Color.primary
        }
    }
}
