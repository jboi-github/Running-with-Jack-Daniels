//
//  MapView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 20.06.21.
//

import SwiftUI
import MapKit
import RunEnricherKit

struct MapView: View {
    @ObservedObject var locations = LocationsService.sharedInstance
    @State private var userInteraction = false
    
    var body: some View {
        ZStack {
            MapKitView(path: locations.path, userInteraction: userInteraction)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Toggle(isOn: $userInteraction, label: {EmptyView()})
                        .labelsHidden()
                        .toggleStyle(UserInteractionStyle())
                    Spacer()
                }
            }
        }
    }
}

private struct UserInteractionStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 0.0) {
            getImage("mappin.and.ellipse", isOn: !configuration.isOn)
            getImage("hand.point.up.left", isOn: configuration.isOn)
        }
        .clipShape(Capsule())
        .scaleEffect(0.75)
        .onTapGesture {configuration.isOn.toggle()}
    }
    
    private func getImage(_ systemName: String, isOn: Bool) -> some View {
        Text(Image(systemName: systemName))
            .font(.body)
            .foregroundColor(.accentColor)
            .padding()
            .background(Color.primary.opacity(isOn ? 0.75 : 0.5))
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
