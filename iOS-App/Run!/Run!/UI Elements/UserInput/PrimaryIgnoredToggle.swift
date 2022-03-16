//
//  ThreeState.swift
//  Run!
//
//  Created by Jürgen Boiselle on 25.01.22.
//

import SwiftUI

struct PrimaryIgnoredToggle: View {
    @Binding var selection: Int
    
    private let options = [
        Image(systemName: "star.fill"),
        Image(systemName: "rectangle"),
        Image(systemName: "clear")
    ]

    var body: some View {
        VStack {
            Picker(selection: $selection, label: EmptyView()) {
                ForEach(options.indices) {options[$0].tag($0)}
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .animation(.default, value: selection)
    }
}

struct ThreeStateToggle_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryIgnoredToggle(selection: .constant(1)).padding()
    }
}
