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
}
