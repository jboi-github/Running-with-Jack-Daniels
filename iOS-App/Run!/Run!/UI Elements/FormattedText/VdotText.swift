//
//  VdotText.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct VdotText: View {
    let text: String
    
    init(vdot: Double) {
        if !vdot.isFinite {
            self.text = "--.-"
        } else if vdot < 0 {
            self.text = "--.-"
        } else if vdot > 100 {
            self.text = "99.9"
        } else {
            self.text = String(format: "%3.1f", vdot)
        }
    }
    
    var body: some View {Text(text)}
}

#if DEBUG
struct VdotText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            VdotText(vdot: .nan)
            VdotText(vdot: 0)
            VdotText(vdot: -1)
            VdotText(vdot: 12.3)
            VdotText(vdot: 2.3)
            VdotText(vdot: 2.0)
            VdotText(vdot: 12342.1)
        }
    }
}
#endif
