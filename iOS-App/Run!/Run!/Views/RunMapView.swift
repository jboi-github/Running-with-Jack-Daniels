//
//  RunMapView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

/**
 Show a map over half available height or width (whichever is larger)
 - Show path of locations on the map, colored by intensities
 - Automatically set size and zoom to make whole path visible
 - add button to allow manual navigation on map
 - add button to set navigation back to automatic-mode
 - add button to collaps/uncollaps the map (saves power)
 
 Design hints:
 - Use MapKit of UIKit. It allows for more navigation control and for polygon overlays
 */
struct RunMapView: View {
    let path: [PathService.PathElement]
    
    @State private var isAutoRegion: Bool = true
    
    var body: some View {
        ZStack {
            MapView(path: path, isAutoRegion: isAutoRegion)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Toggle(isOn: $isAutoRegion, label: {EmptyView()})
                        .labelsHidden()
                        .toggleStyle(UserInteractionStyle())
                    Spacer()
                }
            }
        }
    }
}

private struct UserInteractionStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 0.0) {
            getImage("mappin.and.ellipse", isOn: !configuration.isOn)
            getImage("hand.point.up.left", isOn: configuration.isOn)
        }
        .clipShape(Capsule())
        .scaleEffect(0.75)
        .onTapGesture {configuration.isOn.toggle()}
    }
    
    private func getImage(_ systemName: String, isOn: Bool) -> some View {
        Text(Image(systemName: systemName))
            .font(.callout)
            .foregroundColor(.accentColor)
            .padding()
            .background(Color.primary.opacity(isOn ? 0.75 : 0.5))
    }
}

#if DEBUG
struct RunMapView_Previews: PreviewProvider {
    static var previews: some View {
        RunMapView(path: [PathService.PathElement]())
    }
}
#endif
