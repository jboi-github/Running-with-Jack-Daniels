//
//  ToolbarButton.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 02.07.22.
//

import SwiftUI

struct ToolbarButton: View {
    let systemName: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text(Image(systemName: systemName)).font(.title)
                Text("\(text)").font(.footnote)
            }
            .foregroundColor(.accentColor)
            .padding(.horizontal)
        }
        .buttonStyle(BorderlessButtonStyle()) // Buttons in List-Rows are triggered all at once.
    }
}

#if DEBUG
struct ToolbarButton_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarButton(systemName: "play", text: "Play, ey!") {log("playing")}
    }
}
#endif
