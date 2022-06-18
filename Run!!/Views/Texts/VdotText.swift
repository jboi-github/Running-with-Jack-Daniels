//
//  VdotText.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 01.04.22.
//

import SwiftUI

struct VdotText: View {
    let text: String
    
    init(vdot: Double?) {
        guard let vdot = vdot, vdot.isFinite && vdot >= 0 else {
            self.text = "--.-"
            return
        }
        self.text = String(format: "%3.1f", min(vdot, 99.9))
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
