//
//  HrLimitsView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

private let intensityOrder = [Run.Intensity.Cold, .Easy, .Long, .Marathon, .Threshold, .Interval]
private let intensityUpper = [true, true, false, true, false, true]
private let lineWidth: CGFloat = 10

struct HrLimitsView: View {
    let heartrate: Int?
    let intensity: Run.Intensity?
    let hrLimits: [Run.Intensity: Range<Int>]?
    let min: Int
    let easyLower: Int
    let max: Int
    
    @State private var angle: Angle = .zero
    
    init(heartrate: Int?, intensity: Run.Intensity?, hrLimits: [Run.Intensity: Range<Int>]) {
        self.heartrate = heartrate
        self.intensity = intensity
        self.hrLimits = hrLimits
        min = hrLimits[.Cold]?.lowerBound ?? 0
        easyLower = hrLimits[.Easy]?.lowerBound ?? 0
        max = hrLimits.values.map {$0.upperBound}.max() ?? 0
    }
    
    var body: some View {
        if let hrLimits = hrLimits {
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
                                from: norm(hrLimits[intensityOrder[$0]]?.lowerBound ?? min),
                                to: norm(hrLimits[intensityOrder[$0]]?.upperBound ?? max))
                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                            .foregroundColor(intensityOrder[$0].color)
                    }
                    
                    // Needle
                    if heartrate != nil {
                        GaugeNeedle()
                            .rotation(angle)
                    }
                }
                .rotationEffect(Angle(degrees: 135))

                // Value
                if let heartrate = heartrate, let intensity = intensity {
                    HeartrateText(heartrate: heartrate)
                        .font(.largeTitle)
                        .lineLimit(2)
                        .foregroundColor(intensity.color)
                        .padding()
                        .background(
                            Capsule()
                                .foregroundColor(Color(UIColor.systemBackground))
                                .blur(radius: 8))
                }
            }
            .padding()
            .onChange(of: heartrate ?? -1) { heartrate in
                withAnimation {
                    angle = Angle(degrees: norm(Swift.max(min - 5, Swift.min(max + 5, heartrate))) * 360)
                }
            }
        } else {
            EmptyView()
        }
    }
    
    private func norm(_ value: Int) -> CGFloat {
        if value < easyLower {
            return (0.0 ..< 0.25).mid((min ..< easyLower).p(value))
        } else {
            return (0.25 ..< 0.75).mid((easyLower ..< max).p(value))
        }
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

#if DEBUG
struct HrLimitsView_Previews: PreviewProvider {
    static var previews: some View {
        HrLimitsView(
            heartrate: 100,
            intensity: .Easy,
            hrLimits: [
                .Cold: 50..<75,
                .Easy: 75..<100,
                .Long: 75..<100,
                .Marathon: 100..<150,
                .Threshold: 150..<175,
                .Interval: 165..<220])
    }
}
#endif
