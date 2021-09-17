import Foundation
import Combine

var p = PassthroughSubject<Int, Error>()
var sinks = Set<AnyCancellable>()

p.sink {
    print($0)
} receiveValue: {
    print($0)
}
.store(in: &sinks)

p.send(1)
p.send(completion: .finished)
p.send(2)

p = PassthroughSubject<Int, Error>()
p.sink {
    print($0)
} receiveValue: {
    print($0)
}
.store(in: &sinks)

p.send(3)

sinks.count
