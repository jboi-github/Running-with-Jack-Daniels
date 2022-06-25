//
//  PathOverlay.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI
import MapKit

struct MapView: View {
    let size: CGSize
    let path: [PathEvent]
    @Binding var region: MKCoordinateRegion
    @Binding var userTrackingMode: MapUserTrackingMode

    var body: some View {
        Map(
            coordinateRegion: $region,
            interactionModes: .all,
            showsUserLocation: true,
            userTrackingMode: $userTrackingMode,
            annotationItems: path)
        {  pathEvent in
            MapAnnotation(coordinate: pathEvent.midPoint) {
                MapAnnotationView(
                    accuracyRadius: pathEvent.accuracyRadius * factor,
                    speedMinRadius: pathEvent.speedMinRadius * factor,
                    speedMaxRadius: pathEvent.speedMaxRadius * factor,
                    courseMinAngle: pathEvent.courseMinAngle,
                    courseMaxAngle: pathEvent.courseMaxAngle,
                    color: (pathEvent.intensity ?? .cold).color,
                    textColor: (pathEvent.intensity ?? .cold).textColor)
            }
        }
    }
    
    var factor: CGFloat {size.width / region.span.latitudeDelta}
}

#if DEBUG
struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(
            size: CGSize(),
            path: [],
            region: .constant(MKCoordinateRegion()),
            userTrackingMode: .constant(.follow))
    }
}
#endif
