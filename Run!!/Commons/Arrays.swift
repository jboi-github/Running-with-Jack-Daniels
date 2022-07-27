//
//  Arrays.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 29.03.22.
//

import Foundation
import SwiftUI

extension Sequence {
    func array() -> [Element] {Array(self)}

    func uniqued() -> [Element] where Element: Hashable {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
    
    func sum<A: AdditiveArithmetic>(by: (Element) throws -> A) rethrows -> A {
        try map { try by($0) }.reduce(A.zero, +)
    }
}

extension BidirectionalCollection {
    func suffix(where predicate: (Element) throws -> Bool) rethrows -> [Element] {
        try reversed().prefix(while: predicate).reversed()
    }
}

extension Array {
    static func * (lhs: [Element], rhs: Int) -> [Element] {
        [[Element]](repeating: lhs, count: rhs).flatMap {$0}
    }
    
    func zipAdd(to: Self) -> Self where Element: AdditiveArithmetic {
        (startIndex ..< Swift.max(endIndex, to.endIndex))
            .map { i -> Element in
                if self.indices.contains(i) && to.indices.contains(i) {
                    return self[i] + to[i]
                } else if self.indices.contains(i) {
                    return self[i]
                } else if to.indices.contains(i) {
                    return to[i]
                } else {
                    return Element.zero
                }
            }
    }
    
    func zipSub(by: Self) -> Self where Element: AdditiveArithmetic {
        (startIndex ..< Swift.max(endIndex, by.endIndex))
            .map { i -> Element in
                if self.indices.contains(i) && by.indices.contains(i) {
                    return self[i] - by[i]
                } else if self.indices.contains(i) {
                    return self[i]
                } else if by.indices.contains(i) {
                    return Element.zero - by[i]
                } else {
                    return Element.zero
                }
            }
    }
}
