//
//  Views.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 23.03.22.
//

import Foundation
import SwiftUI

extension View {
    public var anyview: AnyView {AnyView(self)}
}

// MARK: Aligning columns and rows of a view
extension View {
    public func alignedView(width: Binding<CGFloat>) -> some View {
        self.modifier(AlignedWidthView(width: width))
    }
    
    public func alignedView(height: Binding<CGFloat>) -> some View {
        self.modifier(AlignedHeightView(height: height))
    }
}

public struct AlignedWidthView: ViewModifier {
    @Binding var width: CGFloat

    public func body(content: Content) -> some View {
        content
            .background(
                GeometryReader {
                    Color.clear
                        .preference(key: ViewWidthKey.self, value: $0.frame(in: .local).size.width)
                })
            .onPreferenceChange(ViewWidthKey.self) {self.width = max(self.width, $0)}
            .frame(minWidth: width)
    }
    
    private struct ViewWidthKey: PreferenceKey {
        typealias Value = CGFloat
        static var defaultValue = CGFloat.zero
        static func reduce(value: inout Value, nextValue: () -> Value) {
            value += nextValue()
        }
    }
}

public struct AlignedHeightView: ViewModifier {
    @Binding var height: CGFloat

    public func body(content: Content) -> some View {
        content
            .background(
                GeometryReader {
                    Color.clear
                        .preference(key: ViewHeightKey.self, value: $0.frame(in: .local).size.height)
                })
            .onPreferenceChange(ViewHeightKey.self) {self.height = max(self.height, $0)}
            .frame(minWidth: height)
    }
    
    private struct ViewHeightKey: PreferenceKey {
        typealias Value = CGFloat
        static var defaultValue = CGFloat.zero
        static func reduce(value: inout Value, nextValue: () -> Value) {
            value += nextValue()
        }
    }
}

// MARK: Rotate view including its frame
private struct SizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {value = nextValue()}
}

private struct Rotated<Rotated: View>: View {
    var view: Rotated
    var angle: Angle

    @State private var size: CGSize = .zero

    var body: some View {
        // Rotate the frame, and compute the smallest integral frame that contains it
        let newFrame = CGRect(origin: .zero, size: size)
            .offsetBy(dx: -size.width/2, dy: -size.height/2)
            .applying(.init(rotationAngle: CGFloat(angle.radians)))
            .integral

        return view
            .fixedSize()                    // Don't change the view's ideal frame
            .captureSize(in: $size)         // Capture the size of the view's ideal frame
            .rotationEffect(angle)          // Rotate the view
            .frame(width: newFrame.width, height: newFrame.height)
    }
}

extension View {
    func captureSize(in binding: Binding<CGSize>) -> some View {
        overlay(
            GeometryReader { proxy in
                Color.clear.preference(key: SizeKey.self, value: proxy.size)
            }
        )
        .onPreferenceChange(SizeKey.self) { size in binding.wrappedValue = size }
    }
    
    func rotated(_ angle: Angle = .degrees(-90)) -> some View {
        Rotated(view: self, angle: angle)
    }
}
