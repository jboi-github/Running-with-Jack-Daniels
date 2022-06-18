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
    let path: [LocationsService.PathPoint]
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
    func addPath(_ path: [LocationsService.PathPoint], autoRegion: Bool) {
        if !overlays.isEmpty {removeOverlays(overlays)}
        
        // Split path into segments by intensity and activity
        var prev: LocationsService.PathPoint? = nil
        path.split { pp in
            defer {prev = pp}
            
            if let prev = prev {
                return pp.activityIntensity != prev.activityIntensity
            } else {
                return false
            }
        }
        .compactMap {
            // Omit non-activity locations
            guard let first = $0.first, first.activityIntensity.activity.isActive else {return nil}
            
            return (
                path: $0.map {$0.location.coordinate},
                color: first.activityIntensity.intensity.asColor(),
                lineWidth: $0.reduce(0.0, {$0 + $1.location.horizontalAccuracy}) / Double($0.count) )
        }
        .forEach { (path: [CLLocationCoordinate2D], color: Color, lineWidth: Double) in
            // Each path as a colored line
            addOverlay(
                ColoredPolylineOverlay(
                    coordinates: path,
                    color: UIColor(color).withAlphaComponent(0.25),
                    lineWidth: lineWidth))
            addOverlay(ColoredPolylineOverlay(coordinates: path, color: .systemRed, lineWidth: 3))
        }
        if let last = path.last {
            addOverlay(
                MKCircle(
                    center: last.location.coordinate,
                    radius: last.location.horizontalAccuracy))
        }
        
        if autoRegion {
            let boundingMapRect = overlays.reduce(MKMapRect.null) {$0.union($1.boundingMapRect)}
            let region = MKCoordinateRegion(boundingMapRect).expanded(by: 1.1, minMeter: 500)
            if !overlays.isEmpty {setRegion(regionThatFits(region), animated: true)}
        }
    }
}

class ColoredPolylineOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D {polyline.coordinate}
    var boundingMapRect: MKMapRect {polyline.boundingMapRect}
    
    let color: UIColor
    let lineWidth: CGFloat
    let polyline: MKPolyline
    
    init(coordinates: [CLLocationCoordinate2D], color: UIColor, lineWidth: CGFloat) {
        self.polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        self.color = color
        self.lineWidth = lineWidth
    }
}

class MapViewDelegate: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? ColoredPolylineOverlay {
            let renderer = MKPolylineRenderer(overlay: overlay.polyline)
            renderer.lineWidth = overlay.lineWidth
            renderer.lineJoin = .bevel
            renderer.lineCap = .butt
            renderer.strokeColor = overlay.color
            return renderer
        } else if let overlay = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: overlay)
            renderer.fillColor = .systemBlue.withAlphaComponent(0.5)
            return renderer
        } else {
            return MKOverlayRenderer()
        }
    }
}

struct MapKitView_Previews: PreviewProvider {
    static var previews: some View {
        MapKitView(path: [LocationsService.PathPoint](), userInteraction: false)
    }
}
