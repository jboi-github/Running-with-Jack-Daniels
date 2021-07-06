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
    @State private var userTrackingMode = MapUserTrackingMode.follow
    @ObservedObject var loc = GpsLocationReceiver.sharedInstance
    
    var body: some View {
        VStack {
            ZStack {
                GeometryReader { proxy in
                    Map(coordinateRegion: $coordinateRegion,
                        interactionModes: .all,
                        showsUserLocation: true,
                        userTrackingMode: $userTrackingMode.animation(),
                        annotationItems: Annotation.from(rawPath: loc.rawPath, smoothedPath: loc.smoothedPath))
                    { annotation in
                        
                        MapAnnotation(
                            coordinate: annotation.location.coordinate,
                            anchorPoint: CGPoint(x: 0.5, y: 0.5))
                        {
                            if annotation.type == .raw {
                                let size = annotation.size(proxy.size, region: coordinateRegion)
                                ZStack {
                                    Circle()
                                        .foregroundColor(.blue)
                                        .opacity(0.1)
                                        .frame(width: size.width, height: size.height)
                                        .zIndex(1.0)
                                    Circle()
                                        .foregroundColor(.blue)
                                        .frame(width: 3.0, height: 3.0)
                                        .zIndex(2.0)
                                }
                            } else {
                                Circle()
                                    .foregroundColor(.red)
                                    .frame(width: 3.0, height: 3.0)
                                    .zIndex(3.0)
                            }
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    HStack(alignment: .lastTextBaseline, spacing: 0.0) {
                        Spacer()
                        if userTrackingMode == .none {
                            Button {
                                withAnimation {
                                    userTrackingMode = .follow
                                }
                            } label: {
                                Image(systemName: "mappin.and.ellipse")
                                    .padding()
                                    .background(Circle().fill().foregroundColor(.white).opacity(0.5))
                            }
                        }
                        Image(systemName: getLocation())
                            .padding()
                        Spacer()
                    }
                }
            }
        }
    }
    
    private func getLocation() -> String {
        guard loc.localizedError == "" else {return "location.slash"}
        if loc.receiving {return "location.fill"}
        return "location"
    }
}

private enum SmoothedRaw: Int {
    case raw, smoothed
}

private struct Annotation: Identifiable {
    let location: CLLocation
    let type: SmoothedRaw
    
    var id: Double {(type == .raw ? 1 : -1) * location.id.timeIntervalSince1970}
    
    static func from(rawPath: [CLLocation], smoothedPath: [CLLocation]) -> [Annotation] {
        rawPath.map {Annotation(location: $0, type: .raw)}
        + smoothedPath.map {Annotation(location: $0, type: .smoothed)}
    }
    
    func size(_ size: CGSize, region: MKCoordinateRegion) -> (width: CGFloat, height: CGFloat) {
        let spanAccuracy = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: location.horizontalAccuracy * 2.0,
            longitudinalMeters: location.horizontalAccuracy * 2.0)
            .span
        
        return (
            width: size.width * CGFloat(spanAccuracy.latitudeDelta / region.span.latitudeDelta),
            height: size.height * CGFloat(spanAccuracy.longitudeDelta / region.span.longitudeDelta)
        )
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
