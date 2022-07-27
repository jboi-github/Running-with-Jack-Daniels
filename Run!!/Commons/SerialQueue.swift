//
//  SerialQueue.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 10.07.22.
//

import Foundation

class SerialQueue {
    let queue: DispatchQueue
    private (set) var length = 0
    
    init(_ label: String) {
        queue = DispatchQueue.main // (label: label)
    }
    
    func async(work: @escaping () -> Void) {
        work()
//        length += 1
//        queue.async { [self] in
//            length -= 1
//            work()
//        }
    }
    
    func asyncAfter(delay: TimeInterval, work: @escaping () -> Void) {
        length += 1
        queue.asyncAfter(deadline: .now() + delay) { [self] in
            length -= 1
            work()
        }
    }
}
