//
//  BodysensorLocationView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 27.01.22.
//

import SwiftUI
import HealthKit

struct BodysensorLocationView: View {
    let sensorLocation: BodySensorLocationEvent.SensorLocation?
    
    var imageName: String? {
        switch sensorLocation {
        case .other, .none:
            return nil
        case .chest:
            return "location chest"
        case .wrist:
            return "location wrist"
        case .finger:
            return "location finger"
        case .hand:
            return "location hand"
        case .earLobe:
            return "location ear"
        case .foot:
            return "location foot"
        }
    }
    
    var locationName: String {
        switch sensorLocation {
        case .other, .none:
            return "Other"
        case .chest:
            return "Chest"
        case .wrist:
            return "Wrist"
        case .finger:
            return "Finger"
        case .hand:
            return "Hand"
        case .earLobe:
            return "Earlobe"
        case .foot:
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
            BodysensorLocationView(sensorLocation: .chest)
            BodysensorLocationView(sensorLocation: .wrist)
            BodysensorLocationView(sensorLocation: .finger)
            BodysensorLocationView(sensorLocation: .hand)
            BodysensorLocationView(sensorLocation: .earLobe)
            BodysensorLocationView(sensorLocation: .foot)
            BodysensorLocationView(sensorLocation: .other)
        }
    }
}
