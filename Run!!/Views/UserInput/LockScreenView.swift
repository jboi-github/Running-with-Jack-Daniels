//
//  LockScreenView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 23.01.22.
//

import SwiftUI

/// Lock and unlock a screen. Cover with glas pane style while locked.
/// Add back button and Lock-Button to navigation bar.
/// Use  this as the outer view with content included as inner view.
struct LockScreenView<Content: View>: View {
    let withLocker: Bool
    let content: (Binding<Bool>) -> Content

    @State private var dragged: CGFloat = 1000
    @State private var isLocked: Bool = false
    @State private var size: CGSize = CGSize(width: 1000, height: 1000)
    
    var body: some View {
        ZStack {
            Group {
                content($isLocked)
                    .captureSize(in: $size)
                    .onChange(of: isLocked) {
                        dragged = $0 ? 0 : (size.width * (dragged < 0 ? -1 : 1))
                        UIApplication.shared.isIdleTimerDisabled = $0
                    }
                if withLocker {
                    VStack {
                        Button {
                            isLocked.toggle()
                            dragged = isLocked ? 0 : (size.width * (dragged < 0 ? -1 : 1))
                        } label: {
                            Text(Image(systemName: "lock.fill"))
                                .font(.headline)
                                .padding(.horizontal)
                                .background(Capsule().foregroundColor(Color.white).opacity(0.75))
                        }
                        Spacer()
                    }
                }
            }
            .disabled(isLocked)
            
            Image("glass")
                .resizable()
                .ignoresSafeArea()
                .offset(x: dragged)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            dragged = gesture.translation.width
                        }
                        .onEnded { gesture in
                            dragged = gesture.translation.width
                            isLocked = abs(dragged) <= size.width * 2.0 / 3.0
                            dragged = isLocked ? 0 : (size.width * (dragged < 0 ? -1 : 1))
                        }
                )
        }
        .animation(.easeInOut, value: dragged)
    }
}

#if DEBUG
private struct LockScreenTest: View {
    @State private var withLocker: Bool = true
    
    var body: some View {
        LockScreenView(withLocker: withLocker) { isLocked in
            SwiftUI.NavigationView {
                List {
                    Toggle(isOn: $withLocker) {
                        Text("with Locker:")
                    }
                    .padding()
                    Text("well")
                    NavigationLink {
                        VStack {
                            Spacer()
                            Text("Hello-ho world")
                            Spacer()
                            Toggle(isOn: isLocked) {
                                Text("locked:")
                            }
                            .padding()
                            Spacer()
                        }
                        .navigationBarTitle("Hello")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label("Gallery", systemImage: "photo.on.rectangle.angled")
                            .font(.footnote)
                    }
                }
            }
        }
    }
}

struct LockScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LockScreenTest()
    }
}
#endif
