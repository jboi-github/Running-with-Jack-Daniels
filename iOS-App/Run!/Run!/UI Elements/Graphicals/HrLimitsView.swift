//
//  HrLimitsView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

private let intensityOrder = [Intensity.Cold, .Easy, .Long, .Marathon, .Threshold, .Interval]
private let intensityUpper = [true, true, false, true, false, true]
private let lineWidth: CGFloat = 10

struct HrLimitsView: View {
    let hr: Int
    let intensity: Intensity
    let intensities: [Intensity: Range<Int>]
    let min: Int
    let max: Int
    
    init(hr: Int, intensity: Intensity, intensities: [Intensity: Range<Int>]) {
        self.hr = hr
        self.intensity = intensity
        self.intensities = intensities
        min = intensities.values.map {$0.lowerBound}.min() ?? 0
        max = intensities.values.map {$0.upperBound}.max() ?? 100
    }
    
    var body: some View {
        ZStack {
            Group {
                // Background
                Circle()
                    .trim(from: norm(min), to: norm(max))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.primary)
                Circle()
                    .inset(by: lineWidth)
                    .trim(from: norm(min), to: norm(max))
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.primary)
                
                // Intensities
                ForEach(intensityOrder.indices) {
                    Circle()
                        .inset(by: intensityUpper[$0] ? 0 : lineWidth)
                        .trim(
                            from: norm(intensities[intensityOrder[$0]]?.lowerBound ?? min),
                            to: norm(intensities[intensityOrder[$0]]?.upperBound ?? max))
                        .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                        .foregroundColor(intensityOrder[$0].color)
                }
                
                // Needle
                GaugeNeedle()
                    .rotation(Angle(degrees: norm(Swift.max(min - 5, Swift.min(max + 5, hr))) * 360))
            }
            .rotationEffect(Angle(degrees: 135))

            // Value
            HrText(heartrate: hr)
                .animation(nil)
                .font(.largeTitle)
                .foregroundColor(intensity.color)
                .padding()
                .background(
                    Capsule()
                        .foregroundColor(Color(UIColor.systemBackground))
                        .blur(radius: 8))
        }
        .padding()
    }
    
    private func norm(_ value: Int) -> CGFloat {
        (min ..< max).transform(value, to: 0.0 ..< 0.75)
    }
}

private struct GaugeNeedle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLines([
            CGPoint(x: rect.midX, y: rect.midY + lineWidth / 2),
            CGPoint(x: rect.midX + min(rect.width, rect.height) / 2, y: rect.midY + 1),
            CGPoint(x: rect.midX + min(rect.width, rect.height) / 2, y: rect.midY - 1),
            CGPoint(x: rect.midX, y: rect.midY - lineWidth / 2),
            CGPoint(x: rect.midX, y: rect.midY)
        ])
        return path
    }
}

struct HrLimitsView_Previews: PreviewProvider {
    static var previews: some View {
        HrLimitsView(
            hr: 100,
            intensity: .Easy,
            intensities: [
                .Cold: 50..<75,
                .Easy: 75..<100,
                .Long: 75..<100,
                .Marathon: 100..<150,
                .Threshold: 150..<175,
                .Interval: 165..<220])
    }
}
