//
//  StrengthText.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct BatteryStatusView: View {
    let status: Int?
    
    var body: some View {
        Image(systemName: getSystemName())
    }
    
    private func getSystemName() -> String {
        guard let status = status else {return "questionmark"}
        
        if (..<13).contains(status) {
            return "battery.0"
        } else if (13 ..< 38).contains(status) {
            return "battery.25"
        } else if (38 ..< 63).contains(status) {
            return "battery.50"
        } else if (63 ..< 88).contains(status) {
            return "battery.75"
        } else {
            return "battery.100"
        }
    }
}

#if DEBUG
struct BatteryStatusView_Previews: PreviewProvider {
    static var previews: some View {
        BatteryStatusView(status: 50)
    }
}
#endif
