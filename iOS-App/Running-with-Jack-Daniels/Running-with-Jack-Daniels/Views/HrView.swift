//
//  HrView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 22.07.21.
//

import SwiftUI

struct HrView: View {
    let limits: [Intensity : ClosedRange<Int>]
    let heartrate: Int?

    @ObservedObject var hr = BleHeartRateReceiver.sharedInstance

    var body: some View {
        ZStack {
            HrViewContent(limits: limits, heartrate: heartrate)
            VStack {
                HStack {
                    Spacer()
                    Text(Image(systemName: getHeart())).font(.caption).padding(2)
                }
                Spacer()
            }
        }
    }
    
    private func getHeart() -> String {
        guard hr.localizedError == "" else {return "heart.slash"}
        if hr.receiving {return "heart.fill"}
        return "heart"
    }
}

struct HrViewContent: View {
    let limits: [Intensity : ClosedRange<Int>]
    let heartrate: Int?
    
    @ObservedObject var workout = WorkoutRecordingModel.sharedInstance
    
    var body: some View {
        guard let heartrate = heartrate else {
            return
                VStack {
                    HrLimitsTextView(limits: limits)
                    HrViewBar(limits: limits, heartrate: nil)
                }
                .anyview
        }
        
        if !limits.isEmpty {
            return ZStack {
                HrViewBar(limits: limits, heartrate: heartrate)
                VStack {
                    HStack(spacing: 0) {
                        Spacer()
                        Text("\(heartrate, specifier: "%3d")")
                            .font(.callout)
                            .background(Color(UIColor.systemBackground))
                        Text(" bpm")
                            .font(.caption)
                        Spacer()
                        workout.totals.currentPace.asPace(.callout)
                            .background(Color(UIColor.systemBackground))
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        HrLimitsTextView(limits: limits)
                        Spacer()
                    }
                }
            }
            .anyview
        } else {
            return HStack {
                Spacer()
                Text("\(heartrate, specifier: "%3d")")
                    .font(.largeTitle.monospacedDigit())
                Text(" bpm")
                    .font(.caption)
                Spacer()
                workout.totals.currentPace.asPace(.largeTitle.monospacedDigit())
                Spacer()
            }
            .anyview
        }
    }
}

private struct HrViewBar: View {
    let limits: [Intensity : ClosedRange<Int>]
    let heartrate: Int?

    var body: some View {
        let min = limits.values.map {$0.lowerBound}.min()
        let max = limits.values.map {$0.upperBound}.max()
        guard let min = min, let max = max else {return EmptyView().anyview}
        
        func t(_ x: Int?) -> CGFloat? {
            guard let x = x else {return nil}
            return tNotNil(x)
        }
        
        func tNotNil(_ x: Int) -> CGFloat {CGFloat(x - min) / CGFloat(max - min)}
        
        // Get all relevant x-positions
        guard let startE = t(limits[.Easy]?.lowerBound) else {return EmptyView().anyview}
        guard let stopE = t(limits[.Easy]?.upperBound) else {return EmptyView().anyview}
        guard let startM = t(limits[.Marathon]?.lowerBound) else {return EmptyView().anyview}
        guard let stopM = t(limits[.Marathon]?.upperBound) else {return EmptyView().anyview}
        guard let startT = t(limits[.Threshold]?.lowerBound) else {return EmptyView().anyview}
        guard let stopT = t(limits[.Threshold]?.upperBound) else {return EmptyView().anyview}
        guard let startI = t(limits[.Interval]?.lowerBound) else {return EmptyView().anyview}
        guard let stopI = t(limits[.Interval]?.upperBound) else {return EmptyView().anyview}

        // Conduct the view
        return GeometryReader { proxy in
            HStack(spacing: 0) {
                if let heartrateNotNil = self.heartrate {
                    LeftTriangle()
                        .fill(heartrateNotNil < min ? Color.secondary : Color.clear)
                        .frame(width: proxy.size.width / 20, height: proxy.size.height * 0.5)
                        .padding(.horizontal)
                }
                ZStack {
                    // Background
                    Group {
                        MovedSizedRectangle(minX: startE, maxX: stopE)
                            .fill(Color.blue)
                        MovedSizedWithTransition(minX: startM, midX: startT, maxX: stopM, leftSided: false)
                            .fill(Color.green)
                        MovedSizedWithTransition(minX: startT, midX: stopM, maxX: stopT, leftSided: true)
                            .fill(Color.yellow)
                        MovedSizedRectangle(minX: startI, maxX: stopI)
                            .fill(Color.red)
                    }
                    .scaleEffect(x: 1, y: 0.5, anchor: .center)
                    .opacity(0.5)

                    // The Indication
                    if let heartrateNotNil = self.heartrate {
                        if heartrateNotNil <= max && heartrateNotNil >= min {
                            MovedSizedRectangle(
                                minX: tNotNil(heartrateNotNil) - 0.01,
                                maxX: tNotNil(heartrateNotNil) + 0.01)
                                .fill(Color.primary)
                        }
                    }
                }
                if let heartrateNotNil = self.heartrate {
                    RightTriangle()
                        .fill(heartrateNotNil > max ? Color.secondary : Color.clear)
                        .frame(width: proxy.size.width / 20, height: proxy.size.height * 0.5)
                        .padding(.horizontal)
                }
            }
        }
        .anyview
    }
}

private struct HrLimitsTextView: View {
    let limits: [Intensity: ClosedRange<Int>]
    
    var body: some View {
        guard let easyLower = limits[.Easy]?.lowerBound else {return EmptyView().anyview}
        guard let marathonLower = limits[.Marathon]?.lowerBound else {return EmptyView().anyview}
        guard let thresholdLower = limits[.Threshold]?.lowerBound else {return EmptyView().anyview}
        guard let thresholdUpper = limits[.Threshold]?.upperBound else {return EmptyView().anyview}
        guard let intervalLower = limits[.Interval]?.lowerBound else {return EmptyView().anyview}
        guard let intervalUpper = limits[.Interval]?.upperBound else {return EmptyView().anyview}

        return HStack {
            Text("\(easyLower, specifier: "%3d")").foregroundColor(.blue)
            Spacer()
            Spacer()
            Text("\(marathonLower, specifier: "%3d")").foregroundColor(.green)
            Spacer()
            Text("\(thresholdLower, specifier: "%3d") \(thresholdUpper, specifier: "%3d")")
                .foregroundColor(.yellow)
            Spacer()
            Text("\(intervalLower, specifier: "%3d") \(intervalUpper, specifier: "%3d")")
                .foregroundColor(.red)
        }
        .font(.caption)
        .anyview
    }
}

private struct MovedSizedRectangle: Shape {
    let minX: CGFloat
    let maxX: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let minX = max(minX, 0) * rect.width + rect.minX
        let maxX = min(maxX, 1) * rect.width + rect.minX
        
        var path = Path()
        path.addRect(
            CGRect(
                x: minX - rect.minX + rect.origin.x,
                y: rect.origin.y,
                width: maxX - minX,
                height: rect.height))
        return path
    }
}

private struct MovedSizedWithTransition: Shape {
    let minX: CGFloat
    let midX: CGFloat // The position where transition starts or ends
    let maxX: CGFloat
    let leftSided: Bool // True: Triangle is on left side

    func path(in rect: CGRect) -> Path {
        let minX = max(minX, 0) * rect.width + rect.minX
        let maxX = min(maxX, 1) * rect.width + rect.minX
        let midX = max(min(midX, 1), 0) * rect.width + rect.minX

        var path = Path()
        if leftSided {
            path.move(to: CGPoint(x: maxX, y: rect.minY))
            path.addLines([
                CGPoint(x: maxX, y: rect.maxY),
                CGPoint(x: minX, y: rect.maxY),
                CGPoint(x: midX, y: rect.minY),
                CGPoint(x: maxX, y: rect.minY)
            ])
        } else {
            path.move(to: CGPoint(x: minX, y: rect.minY))
            path.addLines([
                CGPoint(x: minX, y: rect.maxY),
                CGPoint(x: midX, y: rect.maxY),
                CGPoint(x: maxX, y: rect.minY),
                CGPoint(x: minX, y: rect.minY)
            ])
        }
        return path
    }
}

private struct LeftTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLines([
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.midY)
        ])
        return path
    }
}

private struct RightTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLines([
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.midY)
        ])
        return path
    }
}

struct HrView_Previews: PreviewProvider {
    static var previews: some View {
        HrView(limits: Database.sharedInstance.hrLimits.value, heartrate: 130)
    }
}
