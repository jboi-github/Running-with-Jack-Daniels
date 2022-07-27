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
    
    /// Truncate wrapped value to an `Int?`
    func int(_ rounded: Bool = true) -> Int? {
        guard let x = self else {return nil}
        guard x.isFinite else {return nil}
        return Int(x + (rounded ? 0.5 : 0.0))
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
    
    /// Convert to `Double` if not nil, else keep nil
    func double() -> Double? {
        guard let x = self else {return nil}
        return Double(x)
    }
}

extension Optional: Scalable where Wrapped: Scalable {
    static func * (lhs: Self, rhs: Double) -> Self {
        guard let lhs = lhs else {return nil}
        return lhs * rhs
    }
}

extension Optional: Comparable where Wrapped: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        if let lhs = lhs, let rhs = rhs {
            return lhs < rhs
        } else if lhs != nil {
            return false
        } else if rhs != nil {
            return true
        } else {
            return false
        }
    }
}

extension Double {
    func ifNotFinite(_ replacement: Double) -> Double {
        self.isFinite ? self : replacement
    }
}
