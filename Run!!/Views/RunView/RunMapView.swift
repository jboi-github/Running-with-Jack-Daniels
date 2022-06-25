//
//  RunMapView.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 07.04.22.
//

import SwiftUI
import MapKit

struct RunMapView: View {
    let size: CGSize
    let path: [PathEvent]
    let gpsStatus: ClientStatus
    
    @State private var region = MKCoordinateRegion()
    @State private var userTrackingMode = MapUserTrackingMode.follow
    
    var body: some View {
        ZStack {
            MapView(
                size: size,
                path: path,
                region: $region,
                userTrackingMode: $userTrackingMode)
            if userTrackingMode != .follow {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            DispatchQueue.main.async {
                                userTrackingMode = .follow
                            }
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.callout)
                                .foregroundColor(.accentColor)
                                .padding(4)
                                .background(Color.primary.opacity(0.75))
                                .clipShape(Capsule())
                                .contentShape(Capsule())
                                .padding(4)
                        }
                    }
                    Spacer()
                }
            }
            if case .notAllowed = gpsStatus {
                Button {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else {return}
                    UIApplication.shared.open(url)
                } label: {
                    Text("Klick to provide GPS allowance")
                        .font(.callout)
                        .foregroundColor(.accentColor)
                        .padding()
                        .background(Color.primary.opacity(0.75))
                        .clipShape(Capsule())
                        .contentShape(Capsule())
                        .padding()
                }
            }
        }
        .animation(.default, value: userTrackingMode)
    }
}

#if DEBUG
struct RunMapView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            RunMapView(
                size: CGSize(width: 600, height: 400),
                path: [],
                gpsStatus: .started(since: .now))
                .frame(height: 400)
        }
    }
}
#endif
