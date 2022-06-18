//
//  RunStandardChart.swift
//  Run!
//
//  Created by Jürgen Boiselle on 14.01.22.
//

import SwiftUI

struct RunStandardChart<DataPoint: ChartDataPoint>: View {
    let data: Array<DataPoint>.Prepared
    let xLabel: String
    let yLabel: String
    
    var body: some View {
        ChartView(
            preparedData: data,
            xAxis: ChartAxisView(
                line: Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor.systemGray)),
                label: Text(xLabel)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.systemGray)),
                axis: .x),
            yAxis: ChartAxisView(
                line: Rectangle()
                    .frame(width: 1)
                    .foregroundColor(Color(UIColor.systemGray)),
                label: Text(yLabel)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.systemGray)),
                axis: .y),
            xTick: { sz, _ in
                Rectangle()
                    .frame(width: 1, height: sz.height)
                    .foregroundColor(Color(UIColor.systemGray4))
            },
            yTick: { sz, _ in
                Rectangle()
                    .frame(width: sz.width, height: 1)
                    .foregroundColor(Color(UIColor.systemGray4))
            })
            .background(Color(UIColor.systemGray6))
    }
}

#if DEBUG
struct RunStandardChart_Previews: PreviewProvider {
    struct PreviewDataPoint: ChartDataPoint {
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
    
    private static let preparedData = stride(from: -10, to: 15, by: 1)
        .map {PreviewDataPoint(classifier: "Sinus", x: $0, y: $0 * sin($0 * .pi / 8))}
        .prepared(nx: 10, ny: 5)
    
    private static let preparedEmpty = [PreviewDataPoint]().prepared(nx: 10, ny: 5)

    static var previews: some View {
        RunStandardChart(data: preparedData, xLabel: "Duration", yLabel: "Distance")
    }
}
#endif
