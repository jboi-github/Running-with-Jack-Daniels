//
//  PeripheralRssiView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 25.01.22.
//

import SwiftUI

struct PeripheralRssiView: View {
    let rssi: Double
    
    var body: some View {
        Text(Image(systemName: rssi.isFinite ? "wifi" : "wifi.slash"))
            .foregroundColor(color())
    }
    
    private func color() -> Color {
        if rssi.isFinite {
            if rssi <= -70 {
                return Color(UIColor.systemRed)
            } else if rssi <= -50 {
                return Color(UIColor.systemYellow)
            } else {
                return Color(UIColor.systemGreen)
            }
        } else {
            return Color.primary
        }
    }
}

struct PeripheralRssiView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PeripheralRssiView(rssi: .nan)
            PeripheralRssiView(rssi: -70)
            PeripheralRssiView(rssi: -50)
            PeripheralRssiView(rssi: 0)
        }
    }
}
