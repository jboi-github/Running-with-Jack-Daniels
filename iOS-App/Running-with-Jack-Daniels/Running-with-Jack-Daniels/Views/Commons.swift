//
//  Commons.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 27.10.21.
//

import Foundation
import SwiftUI
import RunEnricherKit
import RunReceiversKit
import RunFormulasKit

extension Activity {
    func asImage(highHr: Bool) -> Image {
        switch self {
        case .none:
            return Image(systemName: highHr ? "figure.wave" : "figure.stand")
        case .walking:
            return Image(systemName: "figure.walk")
        case .running:
            return Image(systemName: highHr ? "hare.fill" : "tortoise.fill")
        case .cycling:
            return Image(systemName: "bicycle")
        case .getMoved:
            return Image(systemName: "tram.fill")
        }
    }
}

extension ReceiverControl {
    func asImage(
        onReceiving: @autoclosure () -> Image,
        nonOk: Image = Image(systemName: "nosign")) -> Image
    {
        if self == .received {
            return onReceiving()
        } else {
            return nonOk
        }
    }
}

extension Intensity {
    func asColor() -> Color {
        switch self {
        case .Cold:
            return Color(.systemBlue)
        case .Easy:
            return Color(.systemGreen)
        case .Long:
            return Color(.systemGreen)
        case .Marathon:
            return Color(.systemYellow)
        case .Threshold:
            return Color(.systemOrange)
        case .Interval:
            return Color(.systemRed)
        case .Repetition:
            return .primary
        case .Race:
            return .primary
        }
    }
}
