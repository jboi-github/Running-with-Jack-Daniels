//
//  TimeText.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct TimeText: View {
    let text: String
    
    init(time: TimeInterval, short: Bool = true, max: TimeInterval = 10 * 3600) {
        if !time.isFinite {
            self.text = "-:--"
        } else if time < 0 {
            self.text = "-:--"
        } else if time > max {
            self.text = "!:!!"
        } else if time < 60 {
            self.text = String(format: "%3.1f s%@", time, short ? "" : "ec")
        } else if time < 3600 {
            let time: Int = Int(time)
            let minutes = time / 60
            let seconds = time % 60
            self.text = String(format: "%2d:%02d %@", minutes, seconds, short ? "m" : "m:ss")
        } else if short {
            let time: Int = Int(time)
            let minutes = (time % 3600) / 60
            let hours = time / 3600
            self.text = String(format: "%2d:%02d h", hours, minutes)
        } else {
            let time: Int = Int(time)
            let seconds = time % 60
            let minutes = (time % 3600) / 60
            let hours = time / 3600
            self.text = String(format: "%2d:%02d:%02d h:mm:ss", hours, minutes, seconds)
        }
    }
    
    var body: some View {Text(text)}
}

struct TimeText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Group {
                TimeText(time: .nan, short: true)
                TimeText(time: .nan, short: false)
                TimeText(time: -100, short: true)
                TimeText(time: -100, short: false)
                TimeText(time: 0, short: true)
                TimeText(time: 0, short: false)
                TimeText(time: 10.456, short: true)
                TimeText(time: 10.456, short: false)
                TimeText(time: 100, short: true)
                TimeText(time: 100, short: false)
            }
            Group {
                TimeText(time: 3599, short: true)
                TimeText(time: 3599, short: false)
                TimeText(time: 3600, short: true)
                TimeText(time: 3600, short: false)
                TimeText(time: 35990, short: true)
                TimeText(time: 35990, short: false)
                TimeText(time: 36000, short: true)
                TimeText(time: 36000, short: false)
            }
        }
    }
}
