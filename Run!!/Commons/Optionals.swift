//
//  Optionals.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 29.03.22.
//

import Foundation

extension Optional: AdditiveArithmetic where Wrapped: AdditiveArithmetic {
    public static var zero: Self {Wrapped.zero}
    
    public static func + (lhs: Self, rhs: Self) -> Self {
        if let lhs = lhs, let rhs = rhs {
            return lhs + rhs
        } else if let lhs = lhs {
            return lhs
        } else {
            return rhs
        }
    }

    public static func - (lhs: Self, rhs: Self) -> Self {
        if let lhs = lhs, let rhs = rhs {
            return lhs - rhs
        } else if let lhs = lhs {
            return lhs
        } else {
            return Wrapped.zero - rhs
        }
    }
}

extension Optional where Wrapped == Double {
    /// Derived from `Stridable`
    func distance(to: Self) -> Self {
        guard let x = self, let y = to else {return nil}
        return y - x
    }
    
    /// Derived from `Stridable`
    func advanced(by: Self) -> Self {
        guard let x = self, let delta = by else {return nil}
        return x + delta
    }
}

extension Optional where Wrapped == Int {
    /// Derived from `Stridable`
    func distance(to: Self) -> Self {
        guard let x = self, let y = to else {return nil}
        return y - x
    }
    
    /// Derived from `Stridable`
    func advanced(by: Self) -> Self {
        guard let x = self, let delta = by else {return nil}
        return x + delta
    }
}
