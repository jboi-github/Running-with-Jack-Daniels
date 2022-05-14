//
//  PathOverlay.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI
import MapKit

struct MapView: View {
    let path: [LocationX]
    let intensityGetter: (Date) -> Run.Intensity?
    @Binding var region: MKCoordinateRegion
    @Binding var userTrackingMode: MapUserTrackingMode

    var body: some View {
        Map(
            coordinateRegion: $region,
            interactionModes: .all,
            showsUserLocation: true,
            userTrackingMode: $userTrackingMode,
            annotationItems: path)
        {
            MapAnnotation(
                coordinate: CLLocationCoordinate2D(
                    latitude: $0.latitude,
                    longitude: $0.longitude))
            {
                // TODO: Colored by intensity, make use of speed, course, accuracies.
                Circle()
                    .foregroundColor(Color(UIColor.systemRed))
                    .frame(width: 10, height: 10)
            }
        }
    }
}

#if DEBUG
struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(path: [], intensityGetter: {print($0); return nil}, region: .constant(MKCoordinateRegion()), userTrackingMode: .constant(.follow))
    }
}
#endif
