//
//  SourceView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 20.11.21.
//

import SwiftUI

struct SourceView<V>: View {
    let systemName: String
    let color: Color
    
    init(source: ProfileService.Attribute<V>.Source) {
        switch source {
        case .store, .manually:
            systemName = "hand.point.up.left"
            color = Color(UIColor.systemBlue)
        case .health:
            systemName = "heart.fill"
            color = Color(UIColor.systemRed)
        case .calculated:
            systemName = "function"
            color = .primary
        }
    }
    
    var body: some View {
        Text(Image(systemName: systemName))
            .foregroundColor(color)
            .animation(.default, value: systemName)
    }
}

#if DEBUG
struct SourceView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            SourceView<Int>(source: .manually)
            SourceView<Int>(source: .store)
            SourceView<Int>(source: .health)
            SourceView<Int>(source: .calculated)
        }
    }
}
#endif
