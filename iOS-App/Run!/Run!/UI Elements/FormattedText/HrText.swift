//
//  HrText.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct HrText: View {
    let text: String
    
    init(heartrate: Int) {
        if heartrate < 0 {
            self.text = "---"
        } else if heartrate > 250 {
            self.text = "!!!"
        } else {
            self.text = String(format: "%3d", heartrate)
        }
    }
    
    var body: some View {Text(text)}
}

struct HrText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HrText(heartrate: -1)
            HrText(heartrate: 0)
            HrText(heartrate: 10)
            HrText(heartrate: 200)
            HrText(heartrate: 300)
        }
    }
}
