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
            .commit(before: Date(timeIntervalSince1970: 2100)),
            .rollback(after: Date(timeIntervalSince1970: 2400)),
            .publish
        ]
        var cnt = 0
        let expectation = self.expectation(description: "Await")
        
        // setup queus and sources
        let i = PassthroughSubject<IntEvent, Never>()
        let s = PassthroughSubject<StringEvent, Never>()

        let intQ = EventQueue(source: i, type: .forward(deferredBy: 1000))
        let stringQ = EventQueue(source: s, type: .backward)

        let sq = StatusQueue(eq0: intQ, eq1: stringQ, eq2: voidEventQueue, eq3: voidEventQueue, eq4: voidEventQueue, eq5: voidEventQueue, eq6: voidEventQueue, eq7: voidEventQueue, eq8: voidEventQueue, publishEvery: 5)

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
                    cnt += 1
                }
                if cnt == expected.count {
                    expectation.fulfill()
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
        
        waitForExpectations(timeout: 10) { error in
            if let error = error {print(error)}
            XCTAssertEqual(cnt, expected.count)
        }
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
