//
//  MapKitView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 04.08.21.
//

import SwiftUI
import MapKit
import RunEnricherKit

/// MapView utiliziing the older but (still) better customizable MKMapView
struct MapKitView: UIViewRepresentable {
    let path: Set<LocationsService.PathPoint>
    let userInteraction: Bool
    let mapViewDelegate = MapViewDelegate()

    func makeUIView(context: Context) -> MKMapView {
        MKMapView(frame: .zero)
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        view.delegate = mapViewDelegate
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = userInteraction
        view.isZoomEnabled = userInteraction
        view.isPitchEnabled = userInteraction
        view.isScrollEnabled = userInteraction
        view.isRotateEnabled = userInteraction
        view.isMultipleTouchEnabled = userInteraction
        view.addPath(path, autoRegion: !userInteraction)
    }
}

private extension MKMapView {
    func addPath(_ path: Set<LocationsService.PathPoint>, autoRegion: Bool) {
        if !overlays.isEmpty {removeOverlays(overlays)}
        
        // Circles with accuracy
        addOverlays(
            path.map {
                MKCircle(center: $0.location.coordinate, radius: $0.location.horizontalAccuracy)
            })
        
        if autoRegion {
            let boundingMapRect = overlays.reduce(MKMapRect.null) {$0.union($1.boundingMapRect)}
            let region = MKCoordinateRegion(boundingMapRect).expanded(by: 1.1, minMeter: 500)
            if !path.isEmpty {setRegion(regionThatFits(region), animated: true)}
        }
    }
}

class MapViewDelegate: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.lineWidth = 3
            renderer.lineJoin = .bevel
            renderer.lineCap = .butt
            renderer.strokeColor = UIColor.systemRed
            return renderer
        } else if let overlay = overlay as? MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.25)
            return renderer
        } else {
            return MKOverlayRenderer()
        }
    }
}

struct MapKitView_Previews: PreviewProvider {
    static var previews: some View {
        MapKitView(path: Set<LocationsService.PathPoint>(), userInteraction: false)
    }
}
