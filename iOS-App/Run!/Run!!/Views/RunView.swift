//
//  RunViiew.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import SwiftUI

struct RunView: View {
    @ObservedObject private var workout = AppTwin.shared.workout
    @ObservedObject private var hrmTwin = AppTwin.shared.hrmTwin
    
    var body: some View {
        VStack {
            Text("RunView")
            Button {
                AppTwin.shared.aclTwin.stop(asOf: .now)
            } label: {
                Text("End Workout")
            }
            .disabled(workout.status == .stopped)
            Text("Last HR: \(hrmTwin.lastReceived.ISO8601Format())")
                .padding()
        }
    }
}

struct RunView_Previews: PreviewProvider {
    static var previews: some View {
        RunView()
    }
}
