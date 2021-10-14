//
//  ViewExtensions.swift
//  RunFoundationKit
//
//  Created by Jürgen Boiselle on 05.10.21.
//

import Foundation
import SwiftUI

extension View {
    var anyview: AnyView {AnyView(self)}
}

// MARK: Aligning columns and rows of a view
extension View {
    func alignedView(width: Binding<CGFloat>) -> some View {
        self.modifier(AlignedWidthView(width: width))
    }
    func alignedView(height: Binding<CGFloat>) -> some View {
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
