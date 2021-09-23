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
                        .font(.headline)
                }
                NavigationLink(destination: RunView(), isActive: $runViewActive) {
                    Label("Run", systemImage: "hare")
                        .font(.headline)
                }
                NavigationLink(destination: RunView()) {
                    Label("Improve", systemImage: "speedometer")
                        .font(.headline)
                }
                Spacer()
                NavigationLink(destination: BleScannerViewWrapper()) {
                    Label("Bluetooth Scanner", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.footnote)
                }
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
