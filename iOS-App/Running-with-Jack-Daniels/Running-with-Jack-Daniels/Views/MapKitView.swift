//
//  MapKitView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 04.08.21.
//

import SwiftUI
import MapKit

/// MapView utiliziing the older but (still) better customizable MKMapView
struct MapKitView: UIViewRepresentable {
    let path: [CLLocation]
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
    func addPath(_ path: [CLLocation], autoRegion: Bool) {
        if !overlays.isEmpty {removeOverlays(overlays)}
        
        // The path
        let route = MKPolyline(coordinates: path.map {$0.coordinate}, count: path.count)
        addOverlay(route)

        // Circles with accuracy
        addOverlays(path.map {MKCircle(center: $0.coordinate, radius: $0.horizontalAccuracy)})
        
        if autoRegion {
            let region = regionThatFits(
                MKCoordinateRegion(route.boundingMapRect)
                    .expanded(by: 1.1, minMeter: 500))
            if region.area > 0 {setRegion(region, animated: true)}
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
        MapKitView(path: [CLLocation](), userInteraction: false)
    }
}
