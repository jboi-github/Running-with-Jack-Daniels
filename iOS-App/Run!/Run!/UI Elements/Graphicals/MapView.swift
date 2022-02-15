//
//  PathOverlay.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI
import MapKit

/// MapView utiliziing the older but (still) better customizable MKMapView
struct MapView: UIViewRepresentable {
    let path: [PathService.PathElement]
    let isAutoRegion: Bool

    private let mapViewDelegate = MapViewDelegate()

    func makeUIView(context: Context) -> MKMapView {
        MKMapView(frame: .zero)
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        view.delegate = mapViewDelegate
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = !isAutoRegion
        view.isZoomEnabled = !isAutoRegion
        view.isPitchEnabled = !isAutoRegion
        view.isScrollEnabled = !isAutoRegion
        view.isRotateEnabled = !isAutoRegion
        view.isMultipleTouchEnabled = !isAutoRegion
        view.addPath(path, isAutoRegion)
    }
}

private extension MKMapView {
    func addPath(_ path: [PathService.PathElement], _ isAutoRegion: Bool) {
        // TODO: Path Elements are too often re-created, dropped as overlay and re-inserted.
        if !overlays.isEmpty {removeOverlays(overlays)}
        
        path
            .forEach {
                guard let isActive = $0.isActive else {return}
                
                if isActive.isActive {
                    let path = $0.locations.map({$0.coordinate})
                    guard !path.isEmpty else {return}
                    
                    // Each path as a colored line
                    addOverlay(
                        ColoredPolylineOverlay(
                            coordinates: path,
                            color: isActive.type.uiColor.withAlphaComponent(0.25),
                            lineWidth: 3))
                    addOverlay(ColoredPolylineOverlay(coordinates: path, color: .systemRed, lineWidth: 3))
                } else if let avgLocation = $0.avgLocation {
                    addOverlay(
                        ColoredCircleOverlay(
                            center: avgLocation.coordinate,
                            radius: max(avgLocation.horizontalAccuracy, 3),
                            color: isActive.type.uiColor.withAlphaComponent(1.0 / avgLocation.horizontalAccuracy)))
                }
            }

        if isAutoRegion && !overlays.isEmpty {
            let boundingMapRect = overlays.reduce(MKMapRect.null) {$0.union($1.boundingMapRect)}
            let region = MKCoordinateRegion(boundingMapRect).expanded(by: 1.1, minMeter: 500)
            setRegion(regionThatFits(region), animated: true)
        }

        // Current position
        if let last = path.last, let location = last.locations.last {
            addOverlay(
                ColoredCircleOverlay(
                    center: location.coordinate,
                    radius: max(location.horizontalAccuracy, 6),
                    color:  last.isActive?.type.uiColor ?? .systemBlue))
        }
    }
}

private class ColoredPolylineOverlay: NSObject, MKOverlay {
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

private class ColoredCircleOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D {circle.coordinate}
    var boundingMapRect: MKMapRect {circle.boundingMapRect}
    
    let color: UIColor
    let circle: MKCircle
    
    init(center: CLLocationCoordinate2D, radius: CLLocationDistance, color: UIColor) {
        self.circle = MKCircle(center: center, radius: radius)
        self.color = color
    }
}

private class MapViewDelegate: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? ColoredPolylineOverlay {
            let renderer = MKPolylineRenderer(overlay: overlay.polyline)
            renderer.lineWidth = overlay.lineWidth
            renderer.lineJoin = .bevel
            renderer.lineCap = .butt
            renderer.strokeColor = overlay.color
            return renderer
        } else if let overlay = overlay as? ColoredCircleOverlay {
            let renderer = MKCircleRenderer(circle: overlay.circle)
            renderer.fillColor = overlay.color
            return renderer
        } else {
            return MKOverlayRenderer()
        }
    }
}

extension MKCoordinateRegion {
    public func expanded(by expansion: Double, minMeter: CLLocationDistance) -> Self {
        let spanExpanded = MKCoordinateSpan(
            latitudeDelta: span.latitudeDelta * expansion,
            longitudeDelta: span.longitudeDelta * expansion)
        let spanMinMeter = MKCoordinateRegion(
            center: center,
            latitudinalMeters: minMeter,
            longitudinalMeters: -minMeter)
            .span
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(spanExpanded.latitudeDelta, spanMinMeter.latitudeDelta),
            longitudeDelta: max(spanExpanded.longitudeDelta, spanMinMeter.longitudeDelta))
        
        return Self(center: center, span: span)
    }
}

#if DEBUG
struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(path: [], isAutoRegion: true)
    }
}
#endif
