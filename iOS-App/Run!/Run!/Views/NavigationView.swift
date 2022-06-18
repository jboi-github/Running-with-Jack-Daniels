//
//  NavigationView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 21.11.21.
//

import SwiftUI

struct NavigationView: View {
    @State private var runViewActive: Bool = false

    var body: some View {
        LockScreenView(withLocker: runViewActive) { isLocked in
            SwiftUI.NavigationView {
                List {
                    Section {
                        NavigationLink(destination: PlanView()) {
                            Label("Plan", systemImage: "calendar")
                                .font(.headline)
                                .padding()
                        }
                        NavigationLink(destination: RunView(isLocked: isLocked), isActive: $runViewActive) {
                            Label("Run", systemImage: "hare")
                                .font(.headline)
                                .padding()
                        }
                        NavigationLink(destination: AdjustView()) {
                            Label("Improve", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.headline)
                                .padding()
                        }
                    }
                    Section {
                        NavigationLink(destination: ScannerView()) {
                            Label("Bluetooth Scanner", systemImage: "antenna.radiowaves.left.and.right")
                                .font(.footnote)
                                .padding(.horizontal)
                        }
                    }
                    #if DEBUG
                    Section {
                        NavigationLink(destination: GalleryView()) {
                            Label("Gallery", systemImage: "photo.on.rectangle.angled")
                                .font(.footnote)
                                .padding(.horizontal)
                        }
                    }
                    #endif
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Run!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
    }
}

#if DEBUG
struct NavigationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView()
    }
}
#endif
