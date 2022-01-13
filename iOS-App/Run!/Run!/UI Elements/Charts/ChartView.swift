//
//  ChartView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 31.12.21.
//

import SwiftUI
/**
 Low Level main class to create data driven 2d-charts.
 */
struct ChartView<DataPoint: ChartDataPoint, Line: View, Label: View, XTick: View, YTick: View>: View {
    init(
        preparedData: Array<DataPoint>.Prepared,
        xAxis: ChartAxisView<Line, Label>,
        yAxis: ChartAxisView<Line, Label>,
        xTick: @escaping (CGSize, Double) -> XTick,
        yTick: @escaping (CGSize, Double) -> YTick)
    {
        self.preparedData = preparedData
        self.xAxis = xAxis
        self.yAxis = yAxis
        self.xTick = xTick
        self.yTick = yTick
        
        self.dataRect = CGRect(
            x: preparedData.xPrettyTicks.first!, y: preparedData.yPrettyTicks.first!,
            width: preparedData.xPrettyTicks.last! - preparedData.xPrettyTicks.first!,
            height:  preparedData.yPrettyTicks.last! - preparedData.yPrettyTicks.first!)

    }
    
    let preparedData: Array<DataPoint>.Prepared
    let xAxis: ChartAxisView<Line, Label>
    let yAxis: ChartAxisView<Line, Label>
    let xTick: (CGSize, Double) -> XTick
    let yTick: (CGSize, Double) -> YTick

    @State private var xAxisSize: CGSize = .zero
    @State private var yAxisSize: CGSize = .zero
    @State private var chartSize: CGSize = .zero
    
    private var canvasRect: CGRect {
        CGRect(
            x: (chartSize.width - yAxisSize.width) / -2,
            y: 0,
            width: chartSize.width - yAxisSize.width,
            height:  chartSize.height - xAxisSize.height)
    }
    private let dataRect: CGRect
    
    private func pos(x: Double, y: Double) -> CGPoint {
        return CGPoint(
            x: posX(from: dataRect, x, to: canvasRect),
            y: posY(from: dataRect, y, to: canvasRect))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    yAxis.captureSize(in: $yAxisSize)
                    Spacer()
                        .background(ZStack {
                            XTicks(
                                prettyTicks: preparedData.xPrettyTicks,
                                dataRect: dataRect,
                                canvasRect: canvasRect,
                                xTick: xTick)
                            
                            YTicks(
                                prettyTicks: preparedData.yPrettyTicks,
                                dataRect: dataRect,
                                canvasRect: canvasRect,
                                yTick: yTick)
                        })
                        .overlay(ZStack {
                            ForEach(preparedData.dps) { dp in
                                dp.dataPoint.makeBody(
                                    canvasRect,
                                    pos(x: dp.dataPoint.x, y: dp.dataPoint.y),
                                    pos(x: dp.previous.x, y: dp.previous.y),
                                    pos(x: dp.nearest.x, y: dp.nearest.y))
                            }
                        })
                }
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: yAxisSize.width, height: xAxisSize.height)
                    xAxis.captureSize(in: $xAxisSize)
                }
            }
            .captureSize(in: $chartSize)
        }
    }
}

private func posX(from dataRect: CGRect, _ value: Double, to canvasRect: CGRect) -> CGFloat {
    (dataRect.minX ..< dataRect.maxX).transform(value, canvasRect.minX ..< canvasRect.maxX)
}

private func posY(from dataRect: CGRect, _ value: Double, to canvasRect: CGRect) -> CGFloat {
    canvasRect.height / 2 - (dataRect.minY ..< dataRect.maxY).transform(value, canvasRect.minY ..< canvasRect.maxY)
}

private struct XTicks<XTick: View>: View {
    let prettyTicks: [Double]
    let dataRect: CGRect
    let canvasRect: CGRect
    let xTick: (CGSize, Double) -> XTick

    var body: some View {
        ForEach(prettyTicks) { tick in
            xTick(canvasRect.size, tick)
                .offset(
                    x: posX(from: dataRect, tick, to: canvasRect),
                    y: 0)
        }
    }
}

private struct YTicks<YTick: View>: View {
    let prettyTicks: [Double]
    let dataRect: CGRect
    let canvasRect: CGRect
    let yTick: (CGSize, Double) -> YTick

    var body: some View {
        ForEach(prettyTicks) { tick in
            yTick(canvasRect.size, tick)
                .offset(
                    x: 0,
                    y: posY(from: dataRect, tick, to: canvasRect))
        }
    }
}

struct ChartView_Previews: PreviewProvider {
    struct DP: ChartDataPoint {
        let classifier: String
        let x: Double
        let y: Double
        
        func makeBody(
            _ canvas: CGRect,
            _ pos: CGPoint,
            _ prevPos: CGPoint,
            _ nearestPos: CGPoint)
        -> some View
        {
            Circle()
                .offset(pos)
                .foregroundColor(.blue)
        }
    }
    
    private static let dps1 = stride(from: -10, to: 15, by: 1)
        .map {
            DP(
                classifier: "Sinus",
                x: Double($0),
                y: Double($0) * sin(Double($0) * .pi / 8))
        }
    private static let dps2 = stride(from: -10, to: 15, by: 1)
        .map {
            DP(
                classifier: "Cosinus",
                x: Double($0),
                y: $0 * cos(Double($0) * .pi / 8))
        }
    private static let preparedData = (dps1 + dps2).prepared(nx: 10, ny: 5)

    static var previews: some View {
        ChartView(
            preparedData: preparedData,
            xAxis: ChartAxisView(
                line: Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor.systemGray)),
                label: Text("Duration")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.systemGray)),
                axis: .X),
            yAxis: ChartAxisView(
                line: Rectangle()
                    .frame(width: 1)
                    .foregroundColor(Color(UIColor.systemGray)),
                label: Text("Distance")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.systemGray)),
                axis: .Y),
            xTick: { sz, _ in
                Rectangle()
                    .frame(width: 1, height: sz.height)
                    .foregroundColor(Color(UIColor.systemGray4))
            },
            yTick: { sz, _ in
                Rectangle()
                    .frame(width: sz.width, height: 1)
                    .foregroundColor(Color(UIColor.systemRed))
            })
            .frame(width: 300, height: 300)
            .background(Color(UIColor.systemGray6))
    }
}
