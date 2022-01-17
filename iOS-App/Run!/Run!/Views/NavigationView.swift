//
//  NavigationView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 21.11.21.
//

import SwiftUI

struct NavigationView: View {
    var body: some View {
        #if DEBUG
        GalleryView()
        #endif
    }
}

#if DEBUG
struct NavigationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView()
    }
}
#endif
