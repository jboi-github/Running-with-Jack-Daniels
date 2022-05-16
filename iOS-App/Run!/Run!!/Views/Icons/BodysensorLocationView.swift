//
//  BodysensorLocationView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 27.01.22.
//

import SwiftUI
import HealthKit

struct BodysensorLocationView: View {
    let sensorLocation: BodySensorLocationX?
    
    var imageName: String? {
        switch sensorLocation {
        case .Other, .none:
            return nil
        case .Chest:
            return "location chest"
        case .Wrist:
            return "location wrist"
        case .Finger:
            return "location finger"
        case .Hand:
            return "location hand"
        case .EarLobe:
            return "location ear"
        case .Foot:
            return "location foot"
        }
    }
    
    var locationName: String {
        switch sensorLocation {
        case .Other, .none:
            return "Other"
        case .Chest:
            return "Chest"
        case .Wrist:
            return "Wrist"
        case .Finger:
            return "Finger"
        case .Hand:
            return "Hand"
        case .EarLobe:
            return "Earlobe"
        case .Foot:
            return "Foot"
        }
    }

    var body: some View {
        VStack {
            ZStack {
                Image(systemName: "figure.walk").resizable()
                if let imageName = imageName {Image(imageName).resizable()}
            }
            .scaledToFit()
            Text("\(locationName)")
                .lineLimit(1)
                .font(.caption)
                .minimumScaleFactor(0.01)
        }
    }
}

struct BodysensorLocationView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            BodysensorLocationView(sensorLocation: .Chest)
            BodysensorLocationView(sensorLocation: .Wrist)
            BodysensorLocationView(sensorLocation: .Finger)
            BodysensorLocationView(sensorLocation: .Hand)
            BodysensorLocationView(sensorLocation: .EarLobe)
            BodysensorLocationView(sensorLocation: .Foot)
            BodysensorLocationView(sensorLocation: .Other)
        }
    }
}
