//
//  DistanceText.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI
import CoreLocation

struct DistanceText: View {
    let text: String
    
    init(distance: CLLocationDistance) {
        if !distance.isFinite {
            self.text = "---- m"
        } else if distance < 0 {
            self.text = "---- m"
        } else if distance > 1000000 {
            self.text = "!!! km"
        } else if distance > 5000 {
            self.text = String(format: "%3.1f km", distance / 1000)
        } else {
            self.text = String(format: "%4.0f m", distance)
        }
    }
    
    var body: some View {Text(text)}
}

#if DEBUG
struct DistanceText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            DistanceText(distance: .nan)
            DistanceText(distance: -100)
            DistanceText(distance: 0)
            DistanceText(distance: 10)
            DistanceText(distance: 1000)
            DistanceText(distance: 5000)
            DistanceText(distance: 5001)
            DistanceText(distance: 7600)
            DistanceText(distance: 42193)
            DistanceText(distance: 1050050)
        }
    }
}
#endif
