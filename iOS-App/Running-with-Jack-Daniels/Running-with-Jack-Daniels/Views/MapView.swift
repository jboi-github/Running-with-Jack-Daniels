//
//  MapView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 20.06.21.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State private var userInteraction = false
    @ObservedObject var loc = GpsLocationReceiver.sharedInstance
    @ObservedObject var workout = WorkoutRecordingModel.sharedInstance
    
    let colors: [Intensity:Color] = [
        .Easy: .blue,
        .Marathon: .green,
        .Threshold: .yellow,
        .Interval: .red,
        .Repetition: .black
    ]
    
    var body: some View {
        ZStack {
            MapKitView(path: workout.path, userInteraction: userInteraction)
            VStack {
                HStack {
                    Spacer()
                    Text(Image(systemName: getLocation())).font(.caption).padding()
                }
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
    
    private func getLocation() -> String {
        guard loc.localizedError == "" else {return "location.slash"}
        if loc.receiving {return "location.fill"}
        return "location"
    }
    
    private func getColor(intensity: Intensity?) -> Color {
        guard let intensity = intensity else {return .gray}
        return colors[intensity] ?? .gray
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

extension Map {
    func addOverlay(_ overlay: MKOverlay) -> some View {
        MKMapView.appearance().addOverlay(overlay)
        return self
    }
}
