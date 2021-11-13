//
//  Collections.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import Foundation

// MARK: Insert an Element
extension RandomAccessCollection {
    /// Look forward, backwards or by binary search to get insertion point. Expects collection to be increasingly sorted.
    public func insertIndex<Key>(for key: Key, element2key: (Element) -> Key) -> Index where Key: Comparable {
        func forward() -> Index {
            var i = startIndex
            while i < endIndex && key >= element2key(self[i]) {i = index(after: i)}
            
            return i
        }
        
        func backward() -> Index {
            var i = index(before: endIndex)
            while i >= startIndex && key < element2key(self[i]) {i = index(before: i)}
            
            return index(after: i)
        }
        
        func binarySearch(_ indices: Range<Index>) -> Index {
            if indices.isEmpty {return indices.lowerBound}
            
            let midIndex = index(
                indices.lowerBound,
                offsetBy: distance(from: indices.lowerBound, to: indices.upperBound) / 2)
            
            if key >= element2key(self[midIndex]) {
                return binarySearch(index(after: midIndex) ..< indices.upperBound)
            } else {
                return binarySearch(indices.lowerBound ..< midIndex)
            }
        }
        
        let ld2 = 64 - UInt64(count).leadingZeroBitCount // Estimate for ld
        let upper = startIndex ..< Swift.max(startIndex, index(endIndex, offsetBy: -ld2))
        let lower = Swift.min(index(startIndex, offsetBy: ld2), endIndex) ..< endIndex

        if let last = self[upper].last, element2key(last) < key {
            return backward()
        } else if let first = self[lower].first, element2key(first) > key {
            return forward()
        } else {
            return binarySearch(startIndex ..< endIndex)
        }
    }
}

// MARK: index
extension BidirectionalCollection {
    public var lastIndex: Index {index(before: endIndex)}
}

// MARK: Identifiable, Hashable
protocol HashedIdentifiable: Identifiable, Hashable {}
extension HashedIdentifiable {
    static func == (lhs: Self, rhs: Self) -> Bool {lhs.id == rhs.id}
    func hash(into hasher: inout Hasher) {hasher.combine(id)}
}
