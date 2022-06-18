//
//  Ranges.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 16.03.22.
//

import Foundation

extension Range where Bound: Strideable, Bound.Stride: BinaryFloatingPoint {
    func p(_ bound: Bound) -> Double {
        Double(lowerBound.distance(to: bound) / lowerBound.distance(to: upperBound))
    }
    
    func mid(_ p: Double) -> Bound {
        lowerBound.advanced(by: Bound.Stride(p * Double(lowerBound.distance(to: upperBound))))
    }
}

extension Range where Bound: Strideable, Bound.Stride: BinaryInteger {
    func p(_ bound: Bound) -> Double {
        Double(lowerBound.distance(to: bound)) / Double(lowerBound.distance(to: upperBound))
    }
    
    func mid(_ p: Double) -> Bound {
        lowerBound.advanced(by: Bound.Stride(p * Double(lowerBound.distance(to: upperBound)) + 0.5))
    }
}
