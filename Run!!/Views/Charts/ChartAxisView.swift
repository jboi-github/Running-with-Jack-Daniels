//
//  ChartAxisView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 01.01.22.
//

import SwiftUI

struct ChartAxisView<Line: View, Label: View>: View {
    let line: Line
    let label: Label
    let axis: Chart.Axis
    
    var body: some View {
        if case .x = axis {
            VStack(spacing: 0) {
                line
                label
            }
        } else {
            HStack(spacing: 0) {
                label.rotated()
                line
            }
        }
    }
}

#if DEBUG
struct ChartAxisView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ChartAxisView(
                line: Rectangle().frame(height: 1),
                label: Text("Duration").font(.caption),
                axis: .x)
                .padding()
            
            ChartAxisView(
                line: Rectangle().frame(width: 1),
                label: Text("Distance").font(.caption),
                axis: .y)
                .padding()
        }
    }
}
#endif