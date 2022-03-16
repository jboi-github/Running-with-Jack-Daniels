//
//  SkinContactedView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 26.02.22.
//

import SwiftUI

struct SkinContactedView: View {
    let skinIsContacted: Bool?
    
    private var imageName: String {
        guard let skinIsContacted = skinIsContacted else {return "questionmark"}

        return skinIsContacted ? "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left.fill" : "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right"
    }
    
    var body: some View {
        Text(Image(systemName: imageName))
    }
}

struct SkinContactedView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SkinContactedView(skinIsContacted: nil)
            SkinContactedView(skinIsContacted: true)
            SkinContactedView(skinIsContacted: false)
        }
    }
}
