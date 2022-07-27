//
//  PathPointView.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 25.06.22.
//

import SwiftUI
import CoreLocation
import MapKit

struct MapAnnotationView: View {
    let accuracyRadius: CGFloat
    let speedMinRadius: CGFloat
    let speedMaxRadius: CGFloat
    let courseMinAngle: CGFloat
    let courseMaxAngle: CGFloat
    let color: Color
    let textColor: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.1)]),
                        center: .center,
                        startRadius: accuracyRadius / bitCount(accuracyRadius),
                        endRadius: accuracyRadius))
                .frame(
                    width: 2 * Double(accuracyRadius).ifNotFinite(1),
                    height: 2 * Double(accuracyRadius).ifNotFinite(1),
                    alignment: .center)
            Arc(
                startAngle: .degrees(courseMinAngle),
                endAngle: .degrees(courseMaxAngle))
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [color.opacity(0.5), color.opacity(0.1)]),
                        center: .center,
                        startRadius: speedMinRadius,
                        endRadius: speedMaxRadius))
                .frame(
                    width: 2 * Double(speedMaxRadius).ifNotFinite(1),
                    height: 2 * Double(speedMaxRadius).ifNotFinite(1),
                    alignment: .center)
                .rotationEffect(.degrees(-90))
            Circle()
                .foregroundColor(textColor)
                .frame(
                    width: bitCount(accuracyRadius),
                    height: bitCount(accuracyRadius))
        }
        .drawingGroup()
    }
    
    private func bitCount(_ x: CGFloat) -> CGFloat {
        CGFloat(max(1, UInt.bitWidth - UInt(Double(x).ifNotFinite(0)).leadingZeroBitCount))
    }
}

private struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2, startAngle: startAngle, endAngle: endAngle,
            clockwise: false)
        return path
    }
}

#if DEBUG
struct MapAnnotationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Map(
                coordinateRegion: .constant(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
                        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))))
            VStack {
                MapAnnotationView(
                    accuracyRadius: 20,
                    speedMinRadius: 30,
                    speedMaxRadius: 35,
                    courseMinAngle: 30,
                    courseMaxAngle: 60,
                    color: .red, textColor: .black)
                MapAnnotationView(
                    accuracyRadius: 20,
                    speedMinRadius: 30,
                    speedMaxRadius: 35,
                    courseMinAngle: 130,
                    courseMaxAngle: 190,
                    color: .blue, textColor: .orange)
                MapAnnotationView(
                    accuracyRadius: 120,
                    speedMinRadius: 150,
                    speedMaxRadius: 200,
                    courseMinAngle: 30,
                    courseMaxAngle: 60,
                    color: .yellow, textColor: .blue)
                MapAnnotationView(
                    accuracyRadius: 20,
                    speedMinRadius: 30,
                    speedMaxRadius: 35,
                    courseMinAngle: 230,
                    courseMaxAngle: 260,
                    color: .green, textColor: .red)
            }
        }
    }
}
#endif
