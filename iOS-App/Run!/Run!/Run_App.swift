//
//  Run_App.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

@main
struct Run_App: App {
    var body: some Scene {
        WindowGroup {
            NavigationView()
                .onAppear {ProfileService.sharedInstance.onAppear()}
                .colorScheme(.dark)
                .animation(.default)
        }
    }
}
