//
//  ErrorView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 21.06.21.
//

import SwiftUI

struct ErrorView: View {
    @ObservedObject var hr = BleHeartRateReceiver.sharedInstance
    @ObservedObject var loc = GpsLocationReceiver.sharedInstance
    
    var body: some View {
        HStack {
            Spacer()
            Image(systemName: (hr.localizedError > "" || loc.localizedError > "") ? "bolt" : "checkmark")
            Text("\(hr.localizedError)\(loc.localizedError)")
            if (hr.localizedError > "" || loc.localizedError > "") {
                Button {
                    if hr.localizedError > "" {hr.start()}
                    if loc.localizedError > "" {loc.start()}
                } label: {
                    Image(systemName: "play.fill")
                }
            }
            Spacer()
        }
        .font(.footnote)
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView()
    }
}
