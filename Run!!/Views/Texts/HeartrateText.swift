//
//  HeartrateText.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 01.04.22.
//

import SwiftUI

struct HeartrateText: View {
    let text: String
    
    init(heartrate: Int?) {
        guard let heartrate = heartrate, (0..<250).contains(heartrate) else {
            self.text = "---"
            return
        }

        self.text = String(format: "%3d", heartrate)
    }
    
    var body: some View {
        Text("\(text) bpm").lineLimit(1)
    }
}

#if DEBUG
struct HeartrateText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HeartrateText(heartrate: -1)
            HeartrateText(heartrate: 0)
            HeartrateText(heartrate: 10)
            HeartrateText(heartrate: 200)
            HeartrateText(heartrate: 300)
        }
    }
}
#endif
