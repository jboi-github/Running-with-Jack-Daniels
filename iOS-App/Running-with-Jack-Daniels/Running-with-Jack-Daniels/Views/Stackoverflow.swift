//
//  Stackoverflow.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 22.07.21.
//

import SwiftUI

private enum I {
    case E, M, T, I
}

private let limits: [I : ClosedRange<Int>] = [
    .E: 65...80,
    .M: 80...90,
    .T: 88...92,
    .I: 98...100
]

struct Stackoverflow: View {
    fileprivate let limits: [I : ClosedRange<Int>]
    @State private var heartrate: CGFloat = 100

    var body: some View {
        VStack {
            Spacer()
            Text("X")
            Spacer()
            Text("\(heartrate, specifier: "%.0f")").font(.caption)
            Slider(value: $heartrate, in: 50...250)
            Spacer()
        }
        .animation(.default)
    }
}

struct Stackoverflow_Previews: PreviewProvider {
    static var previews: some View {
        Stackoverflow(limits: limits)
    }
}
