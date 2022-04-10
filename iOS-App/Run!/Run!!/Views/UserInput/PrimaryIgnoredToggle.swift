//
//  ThreeState.swift
//  Run!
//
//  Created by Jürgen Boiselle on 25.01.22.
//

import SwiftUI

struct PrimaryIgnoredToggle: View {
    @Binding var selection: Int

    var body: some View {
        HStack {
            SegmentView(systemName: "star.fill", color: .accentColor, tag: 0, selection: $selection)
            SegmentView(systemName: "star", color: .accentColor, tag: 1, selection: $selection)
            SegmentView(systemName: "clear", color: Color(UIColor.systemRed), tag: 2, selection: $selection)
        }
        .background(RoundedRectangle(cornerRadius: 8).fill().foregroundColor(Color(UIColor.systemGray5)))
        .font(.callout )
        .animation(.default, value: selection)
    }
}

private struct SegmentView: View {
    let systemName: String
    let color: Color
    let tag: Int
    @Binding var selection: Int
    
    var body: some View {
        Image(systemName: systemName)
            .foregroundColor(color)
            .padding()
            .tag(tag)
            .background(RoundedRectangle(cornerRadius: 8).fill().foregroundColor(selection == tag ? Color(UIColor.systemGray) : Color.clear))
            .onTapGesture {selection = tag}
    }
}

struct ThreeStateToggle_Previews: PreviewProvider {
    static var previews: some View {
        PrimaryIgnoredToggle(selection: .constant(1)).padding()
    }
}
