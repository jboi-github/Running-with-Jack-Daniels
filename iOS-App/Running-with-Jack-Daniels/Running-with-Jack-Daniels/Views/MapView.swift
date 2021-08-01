//
//  MapView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 20.06.21.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State private var coordinateRegion = MKCoordinateRegion()
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
            GeometryReader { proxy in
                Map(coordinateRegion: $coordinateRegion,
                    interactionModes: userInteraction ?  .all : MapInteractionModes(),
                    showsUserLocation: false,
                    userTrackingMode: .none,
                    annotationItems: workout.path)
                { pathItem in
                    
                    MapAnnotation(
                        coordinate: pathItem.coordinate,
                        anchorPoint: CGPoint(x: 0.5, y: 0.5))
                    {
                        let size = size(proxy.size, region: coordinateRegion, location: pathItem)
                        ZStack {
                            Circle()
                                .foregroundColor(getColor(intensity: pathItem.intensity))
                                .opacity(0.1)
                                .frame(width: size.width, height: size.height)
                                .zIndex(1.0)
                            Circle()
                                .foregroundColor(getColor(intensity: pathItem.intensity))
                                .frame(width: 3.0, height: 3.0)
                                .zIndex(2.0)
                        }
                    }
                }
                .onChange(of: loc.region) { _ in
                    guard !userInteraction else {return}
                    
                    withAnimation {setCoordinateRegion(loc.region)}
                }
                .onChange(of: userInteraction) { _ in
                    if !userInteraction {withAnimation {setCoordinateRegion(loc.region)}}
                }
            }
            
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
    
    private func size(_ size: CGSize, region: MKCoordinateRegion, location: WorkoutRecordingModel.PathItem)
    -> (width: CGFloat, height: CGFloat)
    {
        guard region.span.latitudeDelta > 0 && region.span.longitudeDelta > 0 else {return (0, 0)}
        
        let spanAccuracy = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: location.accuracyM * 2.0,
            longitudinalMeters: location.accuracyM * 2.0)
            .span
        
        let width = size.width * CGFloat(spanAccuracy.latitudeDelta / region.span.latitudeDelta)
        let height = size.height * CGFloat(spanAccuracy.longitudeDelta / region.span.longitudeDelta)
        return (width, height)
    }
    
    private func setCoordinateRegion(_ region: MKCoordinateRegion) {
        coordinateRegion = MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: max(0.0045, region.span.latitudeDelta * 1.1),
                longitudeDelta: max(0.0045, region.span.longitudeDelta * 1.1)))
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

extension MKCoordinateRegion {
    var area: Double {span.latitudeDelta * span.longitudeDelta}
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
