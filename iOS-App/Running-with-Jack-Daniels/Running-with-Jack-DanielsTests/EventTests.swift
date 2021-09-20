//
//  EventTests.swift
//  Running-with-Jack-DanielsTests
//
//  Created by Jürgen Boiselle on 27.08.21.
//

import XCTest
import Combine
@testable import Running_with_Jack_Daniels

class EventTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAddWithError() throws {
        let bigNumber: Double = exp(500.0)
        let smallNumber: Double = exp(-1.0)
        
        print(bigNumber, smallNumber, bigNumber.addWithError(smallNumber).error)
        XCTAssertNotEqual(bigNumber.addWithError(smallNumber).error, 0)
    }
    
    func testAvgBuilder() throws {
        let smallNumber: Double = exp(-10.0)
        let x = [Double](repeating: smallNumber, count: 1000000)
        
        XCTAssertLessThan(
            abs(smallNumber - x.reduce(into: AvgBuilder()) {$0.merge($1)}.avg),
            abs(smallNumber - x.reduce(Double.zero, +) / Double(x.count)))
        
        XCTAssertLessThan(
            abs(smallNumber - x.reduce(into: AvgBuilder()) {$0.merge($1)}.avg),
            abs(smallNumber - x.reduce(Double.zero, {$0 + $1 / Double(x.count)})))
    }
    
    func testNgramN() throws {
        let actual = Array([1,3,4,6,2,7,3,7,9,1].ngram(3))
        let expected = [[1], [1, 3], [1, 3, 4], [3, 4, 6], [4, 6, 2], [6, 2, 7], [2, 7, 3], [7, 3, 7], [3, 7, 9], [7, 9, 1], [9, 1], [1]]
        
        XCTAssertEqual(actual.count, expected.count, "same count")
        (0 ..< expected.endIndex).forEach { i in
            assertIntArrays(array1: Array(actual[i]), array2: expected[i], message: "same")
        }
    }

    func testNgram1() throws {
        let actual = Array([1].ngram(3))
        let expected = [[1]]
        
        print(actual)
        XCTAssertEqual(actual.count, expected.count, "same count")
        (0 ..< expected.endIndex).forEach { i in
            assertIntArrays(array1: Array(actual[i]), array2: expected[i], message: "same")
        }
    }

    func testNgram0() throws {
        let actual = Array([Int]().ngram(3))
        let expected: [[Int]] = []
        
        print(actual)
        XCTAssertEqual(actual.count, expected.count, "same count")
        (0 ..< expected.endIndex).forEach { i in
            assertIntArrays(array1: Array(actual[i]), array2: expected[i], message: "same")
        }
    }
    
    func testFlatMapNoStore() throws {
        XCTAssertEqual(Array([Int]().flatMapNoStore {[$0, $0 * -1]}), [Int]())
        XCTAssertEqual(Array([1].flatMapNoStore {[$0, $0 * -1]}), [1, -1])
        XCTAssertEqual(Array([1,2].flatMapNoStore {[$0, $0 * -1]}), [1, -1, 2, -2])
        XCTAssertEqual(Array([1,2].flatMapNoStore {$0 == 1 ? [] : [15, 20, 30]}), [15, 20, 30])
    }
    
    func testEnsureSize() throws {
        let x1 = [1].ensureSize(2)
        XCTAssertEqual(Array(x1), [1,nil])

        let x2 = [1, 2].ensureSize(2)
        XCTAssertEqual(Array(x2), [1,2])

        let x3 = [1,2,3].ensureSize(2)
        XCTAssertEqual(Array(x3), [1,2,3])

        let x0 = [Int]().ensureSize(2)
        XCTAssertEqual(Array(x0), [nil,nil])
    }
    
    func testForEachMerged() throws {
        let x = [[0,1,2,3,4,5,6,7,8,9], [3,6,7,9], [], [2,5,7]]
        XCTAssertEqual(Array(x.mapMerged().map {$0.offset}), [0,0,0,3,0,1,0,0,3,0,1,0,1,3,0,0,1])
        XCTAssertEqual(
            Array(x.mapMerged().map {$0.elements}),
            [
                [  0,   3, nil,   2],
                [  1,   3, nil,   2],
                [  2,   3, nil,   2],
                [  3,   3, nil,   2],
                [  3,   3, nil,   5],
                [  4,   3, nil,   5],
                [  4,   6, nil,   5],
                [  5,   6, nil,   5],
                [  6,   6, nil,   5],
                [  6,   6, nil,   7],
                [  7,   6, nil,   7],
                [  7,   7, nil,   7],
                [  8,   7, nil,   7],
                [  8,   9, nil,   7],
                [  8,   9, nil, nil],
                [  9,   9, nil, nil],
                [nil,   9, nil, nil],
            ])
        
        XCTAssertEqual(Array([[Int]]().mapMerged().map {$0.offset}), [Int]())
        XCTAssertEqual(Array([[Int]]().mapMerged().map {$0.elements}), [[Int]]())
    }

    func testMapExtended() throws {
        let actual = [1,3,4,9,15]
            .mapExtended{[$0]}
                mid: {[$0, $1]}
                after: {[$0]}
        
        let expected = [
            [1],
            [1,3],
            [3,4],
            [4,9],
            [9,15],
            [15]
        ]

        XCTAssertEqual(Array(actual), expected)
    }

    func testMapExtended1() throws {
        let actual: [[Int?]] = Array([0]
            .mapExtended{[$0]}
                mid: {[$0, $1]}
                after: {[$0]})
        
        let expected: [[Int?]] = [[0], [0]]

        XCTAssertEqual(actual, expected)
    }

    func testMapExtended0() throws {
        let actual: [[Int?]] = Array([]
            .mapExtended{[$0]}
                mid: {[$0, $1]}
                after: {[$0]})
        
        let expected: [[Int?]] = [[nil],[nil]]

        XCTAssertEqual(actual, expected)
    }

    func testMinIndex() {
        XCTAssertNil([String]().minIndex(by: {$0 < $1}))
        XCTAssertEqual(["A", "B", "0", "A"].minIndex(by: {$0 < $1}), 2)
    }

    func testMaxIndex() {
        XCTAssertNil([String]().maxIndex(by: {$0 < $1}))
        XCTAssertEqual(["A", "B", "0", "A"].maxIndex(by: {$0 < $1}), 1)
    }

    func testLastIndex() throws {
        XCTAssertNil([].lastIndex, "collection empty")
        XCTAssertEqual([1].lastIndex, 0, "collection one")
        XCTAssertEqual([1, 3, 4].lastIndex, 2, "collection many")
    }
    
    func testIndexOrNilBefore() throws {
        XCTAssertNil([].indexOrNil(before: 10), "collection empty")
        XCTAssertNil([3,5,2].indexOrNil(before: 10), "collection out of range")
        XCTAssertNil([3,5,2].indexOrNil(before: 0), "collection at start")

        XCTAssertEqual([1, 3, 4].indexOrNil(before: 1), 0, "collection at start")
        XCTAssertEqual([1, 3, 4].indexOrNil(before: 2), 1, "collection at end")
        XCTAssertEqual([1, 3, 4].indexOrNil(before: 3), 2, "collection behind end")
    }
    
    func testIndexOrNilAfter() throws {
        XCTAssertNil([].indexOrNil(after: 10), "collection empty")
        XCTAssertNil([3,5,2].indexOrNil(after: -10), "collection out of range")
        XCTAssertNil([3,5,2].indexOrNil(after: 2), "collection at end")

        XCTAssertEqual([1, 3, 4].indexOrNil(after: 1), 2, "collection at end")
        XCTAssertEqual([1, 3, 4].indexOrNil(after: 0), 1, "collection at start")
        XCTAssertEqual([1, 3, 4].indexOrNil(after: -1), 0, "collection before start")
    }
    
    func testBefore() throws {
        XCTAssertNil([].before(10), "collection empty")
        XCTAssertNil([3,5,2].before(10), "collection out of range")
        XCTAssertNil([3,5,2].before(0), "collection at start")

        XCTAssertEqual(["a", "b", "x"].before(1), "a", "collection at start")
        XCTAssertEqual(["a", "b", "x"].before(2), "b", "collection at end")
        XCTAssertEqual(["a", "b", "x"].before(3), "x", "collection behind end")
    }
    
    func testAfter() throws {
        XCTAssertNil([].after(10), "collection empty")
        XCTAssertNil([3,5,2].after(-10), "collection out of range")
        XCTAssertNil([3,5,2].after(2), "collection at end")

        XCTAssertEqual(["a", "b", "x"].after(1), "x", "collection at end")
        XCTAssertEqual(["a", "b", "x"].after(0), "b", "collection at start")
        XCTAssertEqual(["a", "b", "x"].after(-1), "a", "collection before start")
    }
    
    func testTwoArray() throws {
        let x = MultipleArrays([1,2,3,4,5], [6,7,8,9], [0,-1,-2])
        let expected = [1,2,3,4,5,6,7,8,9, 0, -1, -2]
        
        XCTAssertEqual(x.map {$0}, expected)
    }
    
    private struct E: Event {
        typealias Content = Int
        
        func interpolate(to when: Date, until next: E) -> E {
            E(when: when)
        }
        
        func extrapolate(to when: Date) -> E {
            E(when: when)
        }
        
        let when: Date
        var content: Int = 0
        let hasBackwardImpact: Bool = false
    }
    
    func testInsertIndex() throws {
        let x: [E] = [
            E(when: Date(timeIntervalSince1970: 1000)),
            E(when: Date(timeIntervalSince1970: 2000)),
            E(when: Date(timeIntervalSince1970: 3000))
        ]
        
        XCTAssertEqual(x.insertIndex(for: Date(timeIntervalSince1970: 500), element2key: {$0.when}), 0)
        XCTAssertEqual(x.insertIndex(for: Date(timeIntervalSince1970: 1000), element2key: {$0.when}), 1)
        XCTAssertEqual(x.insertIndex(for: Date(timeIntervalSince1970: 2500), element2key: {$0.when}), 2)
        XCTAssertEqual(x.insertIndex(for: Date(timeIntervalSince1970: 2000), element2key: {$0.when}), 2)
        XCTAssertEqual(x.insertIndex(for: Date(timeIntervalSince1970: 3000), element2key: {$0.when}), 3)
        XCTAssertEqual(x.insertIndex(for: Date(timeIntervalSince1970: 5000), element2key: {$0.when}), 3)
        XCTAssertEqual([E]().insertIndex(for: Date(timeIntervalSince1970: 500), element2key: {$0.when}), 0)
    }
    
    func testInsertIndexPerf() throws {
        let x: [E] = stride(from: 600, to: 1000000*60+600, by: 60)
            .map {E(when: Date(timeIntervalSince1970: $0))}
        
        self.measure {
            let _ = x.insertIndex(for: Date(timeIntervalSince1970: 300), element2key: {$0.when})
            let _ = x.insertIndex(for: Date(timeIntervalSince1970: (1000000*60+600) / 2), element2key: {$0.when})
            let _ = x.insertIndex(for: Date(timeIntervalSince1970: 1000000*60+600 + 3600), element2key: {$0.when})
        }
    }

    private struct IntEvent: Event {
        typealias Content = Int
        
        func interpolate(to when: Date, until next: IntEvent) -> IntEvent {
            Self(when: when, content: (content + next.content) / 2)
        }
        
        func extrapolate(to when: Date) -> IntEvent {
            Self(when: when, content: content)
        }
                
        let when: Date
        var content: Int = 0
        let hasBackwardImpact: Bool = true

        init(when: Date, content: Int) {
            self.when = when
            self.content = content
        }
    }

    private struct StringEvent: Event {
        typealias Content = String
        
        func interpolate(to when: Date, until next: StringEvent) -> StringEvent {
            Self(
                when: when,
                content: "\(content): I \(Int(self.when.timeIntervalSince1970)) - \(Int(when.timeIntervalSince1970)) - \(Int(next.when.timeIntervalSince1970))")
        }
        
        func extrapolate(to when: Date) -> StringEvent {
            Self(
                when: when,
                content: "\(content): E - \(Int(when.timeIntervalSince1970))")
        }
                
        let when: Date
        var content: String = "A"
        let hasBackwardImpact: Bool = false

        init(when: Date, content: String) {
            self.when = when
            self.content = content
        }
    }
    
    private func assertIntArrays(array1: [Int], array2: [Int], message: String) {
        XCTAssertEqual(array1.count, array2.count, message)
        (0 ..< array2.endIndex).forEach { i in
            XCTAssertEqual(array1[i], array2[i], "\(message) at \(i)")
        }
    }
    
    private func assertDoubleArrays(array1: [Double], array2: [Double], message: String) {
        print(array1)
        XCTAssertEqual(array1.count, array2.count, message)
        (0 ..< array2.endIndex).forEach { i in
            XCTAssertTrue(
                (array1[i].isNaN && array2[i].isNaN) ||
                    (array1[i].isFinite && array2[i].isFinite && array1[i] == array2[i]),
                "\(message) at \(i): \(array1[i]) \(array2[i])")
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testQs() throws {
        let expected: [StatusType<IntEvent.Content, StringEvent.Content, VoidEvent.Content, VoidEvent.Content, VoidEvent.Content, VoidEvent.Content, VoidEvent.Content, VoidEvent.Content, VoidEvent.Content>] = [
            .rollback(after: Date(timeIntervalSince1970: 600)),
            .commit(before: Date(timeIntervalSince1970: 600)),
            .rollback(after: Date(timeIntervalSince1970: 1200)),
            .commit(before: Date(timeIntervalSince1970: 1200)),
            .rollback(after: Date(timeIntervalSince1970: 1800)),
            .commit(before: Date(timeIntervalSince1970: 1200)),
            .rollback(after: Date(timeIntervalSince1970: 1800)),
            .commit(before: Date(timeIntervalSince1970: 1400)),
            .rollback(after: Date(timeIntervalSince1970: 1500)),
            .commit(before: Date(timeIntervalSince1970: 1500)),
            .rollback(after: Date(timeIntervalSince1970: 2100)),
            .commit(before: Date(timeIntervalSince1970: 2100))
        ]
        var cnt = 0
        
        // setup queus and sources
        let i = PassthroughSubject<IntEvent, Never>()
        let s = PassthroughSubject<StringEvent, Never>()

        let intQ = EventQueue(source: i, type: .forward(deferredBy: 1000))
        let stringQ = EventQueue(source: s, type: .backward)

        let sq = StatusQueue(eq0: intQ, eq1: stringQ, eq2: voidEventQueue, eq3: voidEventQueue, eq4: voidEventQueue, eq5: voidEventQueue, eq6: voidEventQueue, eq7: voidEventQueue, eq8: voidEventQueue, publishEvery: 100)

        // Listen to result
        var subscribers = Set<AnyCancellable>()
        
        sq.publisher
            .sink {
                switch $0 {
                case .commit(let at):
                    print("commit", at)
                    self.cmpStatus($0, expected[cnt])
                    cnt += 1
                case .rollback(let after):
                    print("rollback", after)
                    self.cmpStatus($0, expected[cnt])
                    cnt += 1
                case .status(let status):
                    print("status", status.when, status.c0, status.c1, status.c2)
                case .publish:
                    print("publish")
                }
            }
            .store(in: &subscribers)

        // Run the tests
        print("send 600 / 1")
        i.send(IntEvent(when: Date(timeIntervalSince1970: 600), content: 1))
        print("send 1200 / 2")
        i.send(IntEvent(when: Date(timeIntervalSince1970: 1200), content: 2))
        print("send 1800 / A")
        s.send(StringEvent(when: Date(timeIntervalSince1970: 1800), content: "A"))
        print("send 2400 / B")
        s.send(StringEvent(when: Date(timeIntervalSince1970: 2400), content: "B"))
        print("send 1500 / 3")
        i.send(IntEvent(when: Date(timeIntervalSince1970: 1500), content: 3))
        print("send 2100 / 4")
        i.send(IntEvent(when: Date(timeIntervalSince1970: 2100), content: 4))

        // Done
        print("send completion / Int")
        i.send(completion: .finished)
        print("send completion / String")
        s.send(completion: .finished)
    }
    
    private func cmpStatus(
        _ s1: StatusType<IntEvent.Content, StringEvent.Content, VoidEvent.Content, VoidEvent.Content, VoidEvent.Content, VoidEvent.Content, VoidEvent.Content, VoidEvent.Content, VoidEvent.Content>,
        _ s2: StatusType<IntEvent.Content, StringEvent.Content, VoidEvent.Content, VoidEvent.Content, VoidEvent.Content, VoidEvent.Content, VoidEvent.Content, VoidEvent.Content, VoidEvent.Content>)
    {
        switch (s1, s2) {
        case (.commit(let at1), .commit(let at2)):
            XCTAssertEqual(Int(at1.timeIntervalSince1970), Int(at2.timeIntervalSince1970))
        case (.rollback(let after1), .rollback(let after2)):
            XCTAssertEqual(Int(after1.timeIntervalSince1970), Int(after2.timeIntervalSince1970))
        case (.status(let status1), .status(let status2)):
            XCTAssertEqual(Int(status1.when.timeIntervalSince1970), Int(status2.when.timeIntervalSince1970))
            XCTAssertEqual(status1.c0, status2.c0)
            XCTAssertEqual(status1.c1, status2.c1)
        default:
            XCTFail()
        }
    }
}

extension Double {
    var asInt: Int {Int(self)}
}
