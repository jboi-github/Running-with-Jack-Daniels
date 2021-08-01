//
//  NavigationView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 07.07.21.
//

import SwiftUI

struct NaviView: View {
    @State var runViewActive: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            List {
                Spacer()
                NavigationLink(destination: PlanView()) {
                    Label("Plan", systemImage: "calendar")
                }
                NavigationLink(destination: RunView(), isActive: $runViewActive) {
                    Label("Run", systemImage: "hare")
                }
                NavigationLink(destination: RunView()) {
                    Label("Improve", systemImage: "speedometer")
                }
                Spacer()
            }
            .navigationTitle("Run with Jack Daniels")
            .navigationBarTitleDisplayMode(.inline)
        }
        .colorScheme(runViewActive ? .dark : colorScheme)
        .animation(.default)
    }
}

struct NavigationView_Previews: PreviewProvider {
    static var previews: some View {
        NaviView()
    }
}

extension View {
    var anyview: AnyView {AnyView(self)}
}
