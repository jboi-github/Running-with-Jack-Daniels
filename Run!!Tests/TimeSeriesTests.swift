//
//  TimeSeriesTests.swift
//  Run!!Tests
//
//  Created by Jürgen Boiselle on 10.05.22.
//

import XCTest
@testable import Run__

class TimeSeriesTests: XCTestCase {

    private struct Continuos: KeyedTimeSeriesElement, Equatable {
        typealias Stride = Double
        static var key: String = ""
        
        let date: Date
        let value: Double
        
        func extrapolate(at: Date) -> Continuos {Continuos(date: at, value: value)}
        func interpolate(at: Date, _ towards: Continuos) -> Continuos {
            let p = (date ..< towards.date).p(at)
            return Continuos(date: at, value: (value ..< towards.value).mid(p))
        }
        func distance(to other: Continuos) -> Double {other.value - value}
        func advanced(by n: Double) -> Continuos {Continuos(date: date, value: value + n)}
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Continuos.key = UUID().uuidString
        log(Continuos.key)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: Inserts
    func testInsertFirst() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        ts.insert(makeEl(1000))
        XCTAssertEqual(ts.elements, [makeEl(1000)])
    }

    func testInsertBeforeAll() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        ts.insert(makeEl(1000))
        XCTAssertEqual(ts.elements, [makeEl(1000)])
        ts.insert(makeEl(2000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000)])

        ts.insert(makeEl(500))
        XCTAssertEqual(ts.elements, [makeEl(500), makeEl(1000), makeEl(2000)])
    }

    func testInsertAfterAll() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        ts.insert(makeEl(1000))
        XCTAssertEqual(ts.elements, [makeEl(1000)])
        ts.insert(makeEl(2000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000)])
    }

    func testInsertWithin() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        ts.insert(makeEl(1000))
        XCTAssertEqual(ts.elements, [makeEl(1000)])
        ts.insert(makeEl(2000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000)])

        ts.insert(makeEl(1500))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(1500), makeEl(2000)])
    }

    func testInsertOnFirst() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        ts.insert(makeEl(1000))
        XCTAssertEqual(ts.elements, [makeEl(1000)])
        ts.insert(makeEl(2000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000)])

        ts.insert(makeEl(1000, 1))
        XCTAssertEqual(ts.elements, [makeEl(1000, 1), makeEl(2000)])
    }

    func testInsertOnLast() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        ts.insert(makeEl(1000))
        XCTAssertEqual(ts.elements, [makeEl(1000)])
        ts.insert(makeEl(2000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000)])

        ts.insert(makeEl(2000, 2))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000, 2)])
    }

    // MARK: Archives
    func testArchiveBeforeAll() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        ts.insert(makeEl(1000))
        XCTAssertEqual(ts.elements, [makeEl(1000)])
        ts.insert(makeEl(2000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000)])

        ts.archive(upTo: makeDt(500))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000)])
    }

    func testArchiveAfterAll() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        ts.insert(makeEl(500))
        XCTAssertEqual(ts.elements, [makeEl(500)])
        ts.insert(makeEl(1000))
        XCTAssertEqual(ts.elements, [makeEl(500), makeEl(1000)])
        ts.insert(makeEl(2000))
        XCTAssertEqual(ts.elements, [makeEl(500), makeEl(1000), makeEl(2000)])

        ts.archive(upTo: makeDt(3000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000)])
    }

    func testArchiveOnMid() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        ts.insert(makeEl(1000))
        XCTAssertEqual(ts.elements, [makeEl(1000)])
        ts.insert(makeEl(2000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000)])
        ts.insert(makeEl(3000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000), makeEl(3000)])
        ts.insert(makeEl(4000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000), makeEl(3000), makeEl(4000)])

        ts.archive(upTo: makeDt(3000))
        XCTAssertEqual(ts.elements, [makeEl(2000), makeEl(3000), makeEl(4000)])
    }

    func testArchiveWithin() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        ts.insert(makeEl(1000))
        XCTAssertEqual(ts.elements, [makeEl(1000)])
        ts.insert(makeEl(2000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000)])
        ts.insert(makeEl(3000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000), makeEl(3000)])
        ts.insert(makeEl(4000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000), makeEl(3000), makeEl(4000)])

        ts.archive(upTo: makeDt(3500))
        XCTAssertEqual(ts.elements, [makeEl(2000), makeEl(3000), makeEl(4000)])
    }

    func testArchiveOnEmpty() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        ts.archive(upTo: makeDt(1500))
        XCTAssertTrue(ts.elements.isEmpty)
    }

    // MARK: Get single element
    func testGetOneDirect() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        ts.insert(makeEl(1000))
        XCTAssertEqual(ts.elements, [makeEl(1000)])
        ts.insert(makeEl(2000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000)])

        XCTAssertEqual(ts[makeDt(1000)], makeEl(1000))
        XCTAssertEqual(ts[makeDt(2000)], makeEl(2000))
    }

    func testGetOneBeforeAll() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        ts.insert(makeEl(1000))
        XCTAssertEqual(ts.elements, [makeEl(1000)])
        
        // Extrapolate
        XCTAssertEqual(ts[makeDt(500)], makeEl(500, 1000))

        // Interpolate
        ts.insert(makeEl(2000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000)])
        XCTAssertEqual(ts[makeDt(500)], makeEl(500, 500))
    }

    func testGetOneAfterAll() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        ts.insert(makeEl(1000))
        XCTAssertEqual(ts.elements, [makeEl(1000)])
        
        // Extrapolate
        XCTAssertEqual(ts[makeDt(1500)], makeEl(1500, 1000))

        // Interpolate
        ts.insert(makeEl(2000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000)])
        XCTAssertEqual(ts[makeDt(2500)], makeEl(2500, 2500))
    }

    func testGetOneWithin() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        ts.insert(makeEl(1000))
        XCTAssertEqual(ts.elements, [makeEl(1000)])
        ts.insert(makeEl(2000))
        XCTAssertEqual(ts.elements, [makeEl(1000), makeEl(2000)])

        // Interpolate
        XCTAssertEqual(ts[makeDt(1700)], makeEl(1700, 1700))
    }

    func testGetFromEmpty() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        // Interpolate
        // XCTAssertThrowsError(ts[makeDt(1700)]) Cannot Test a crash
    }

    func testBinSearch() throws {
        let ts = TimeSeries<Continuos, None>(queue: DispatchQueue.global())
        XCTAssertTrue(ts.elements.isEmpty)

        stride(from: 1000, to: 2000, by: 10).forEach {ts.insert(makeEl($0))}

        XCTAssertEqual(ts[makeDt(500)], makeEl(500, 500))
        XCTAssertEqual(ts[makeDt(1000)], makeEl(1000))
        XCTAssertEqual(ts[makeDt(1500)], makeEl(1500))
        XCTAssertEqual(ts[makeDt(1505)], makeEl(1505, 1505))
        XCTAssertEqual(ts[makeDt(1990)], makeEl(1990))
        XCTAssertEqual(ts[makeDt(2500)], makeEl(2500, 2500))
    }
    
    struct TestTimeSeries: GenericTimeseriesElement, Equatable {
        static let key: String = "TS"
        var vector: VectorElement<String>
        init(_ vector: VectorElement<String>) {self.vector = vector}

        init(date: Date, string: String, value: Int) {
            vector = VectorElement(
                date: date,
                ints: [value],
                categorical: string)
        }
        
        var string: String {vector.categorical!}
        var value: Int {
            get {vector.ints![0]}
            set {vector.ints![0] = newValue}
        }
    }
    
    func testTimeseriesMutation() throws {
        let ts = TimeSeries<TestTimeSeries, None>(queue: DispatchQueue.global())
        ts.reset()
        ts.insert(TestTimeSeries(date: makeDt(1000), string: "A", value: 0))
        ts.insert(TestTimeSeries(date: makeDt(2000), string: "B", value: 1))
        ts.insert(TestTimeSeries(date: makeDt(3000), string: "C", value: 2))
        XCTAssertEqual(ts.elements, [
            TestTimeSeries(date: makeDt(1000), string: "A", value: 0),
            TestTimeSeries(date: makeDt(2000), string: "B", value: 1),
            TestTimeSeries(date: makeDt(3000), string: "C", value: 2)
        ])
        
        ts.insert(TestTimeSeries(date: makeDt(1000), string: "D", value: 3))
        XCTAssertEqual(ts.elements, [
            TestTimeSeries(date: makeDt(1000), string: "D", value: 3),
            TestTimeSeries(date: makeDt(2000), string: "B", value: 1),
            TestTimeSeries(date: makeDt(3000), string: "C", value: 2)
        ])
        
        var x = ts.elements[1]
        x.value = 5
        XCTAssertEqual(ts.elements, [
            TestTimeSeries(date: makeDt(1000), string: "D", value: 3),
            TestTimeSeries(date: makeDt(2000), string: "B", value: 1),
            TestTimeSeries(date: makeDt(3000), string: "C", value: 2)
        ])

        ts[2]!.value = 5
        XCTAssertEqual(ts.elements, [
            TestTimeSeries(date: makeDt(1000), string: "D", value: 3),
            TestTimeSeries(date: makeDt(2000), string: "B", value: 1),
            TestTimeSeries(date: makeDt(3000), string: "C", value: 5)
        ])
    }
    
    func testMeta() throws {
        let ts = TimeSeries<TestTimeSeries, Date>(queue: DispatchQueue.global())
        ts.reset()
        XCTAssertNil(ts.meta)
        
        ts.meta = makeDt(1000)
        XCTAssertEqual(ts.meta, makeDt(1000))
    }
    
    // MARK: Save and load
    
    func testNotSavedWhileInForeground() throws {
        let ts = TimeSeries<TestTimeSeries, Date>(queue: DispatchQueue.global())
        XCTAssertFalse(ts.isDirty)
        ts.isInBackground = false
        
        // Read original elements
        let original: [TestTimeSeries] = Files.read(from: "TS.json") ?? []
        XCTAssertEqual(ts.elements, original)
        
        // Do something while in foreground
        ts.insert(TestTimeSeries(date: makeDt(10000), string: "X", value: 1))
        XCTAssertNotEqual(original, ts.elements)
        XCTAssertNotEqual(Files.read(from: "TS.json") ?? [], ts.elements)
        XCTAssertEqual(original, Files.read(from: "TS.json") ?? [])
        XCTAssertTrue(ts.isDirty)
        
        // Even after some time it stays unsafed
        let expectation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 45) {
            XCTAssertNotEqual(original, ts.elements)
            XCTAssertNotEqual(Files.read(from: "TS.json") ?? [], ts.elements)
            XCTAssertEqual(original, Files.read(from: "TS.json") ?? [])
            XCTAssertTrue(ts.isDirty)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 60)
    }
    
    func testSavedGoingToBackground() throws {
        let ts = TimeSeries<TestTimeSeries, Date>(queue: DispatchQueue.global())
        XCTAssertFalse(ts.isDirty)
        ts.isInBackground = false
        
        // Read original elements
        let original: [TestTimeSeries] = Files.read(from: "TS.json") ?? []
        
        // Do something while in foreground
        ts.insert(TestTimeSeries(date: makeDt(10000), string: "X", value: 1))
        
        // Go to background
        ts.isInBackground = true
        XCTAssertNotEqual(original, ts.elements)
        XCTAssertEqual(Files.read(from: "TS.json") ?? [], ts.elements)
        XCTAssertNotEqual(original, Files.read(from: "TS.json") ?? [])
        XCTAssertFalse(ts.isDirty)
    }
    
    func testSavedStayingInBackground() throws {
        let ts = TimeSeries<TestTimeSeries, Date>(queue: DispatchQueue.global())
        XCTAssertFalse(ts.isDirty)
        ts.isInBackground = false
        
        // Read original elements
        let original: [TestTimeSeries] = Files.read(from: "TS.json") ?? []
        
        // Do something while in foreground
        ts.insert(TestTimeSeries(date: makeDt(10000), string: "X", value: 1))
        
        // Go to background
        ts.isInBackground = true
        
        // Do something while in background
        ts.insert(TestTimeSeries(date: makeDt(20000), string: "Y", value: 2))
        XCTAssertNotEqual(original, ts.elements)
        XCTAssertNotEqual(Files.read(from: "TS.json") ?? [], ts.elements)
        XCTAssertEqual(original, Files.read(from: "TS.json") ?? [])
        XCTAssertTrue(ts.isDirty)

        // Wait
        let expectation = XCTestExpectation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 45) {
            // Shoud be saved now
            XCTAssertNotEqual(original, ts.elements)
            XCTAssertEqual(Files.read(from: "TS.json") ?? [], ts.elements)
            XCTAssertNotEqual(original, Files.read(from: "TS.json") ?? [])
            XCTAssertFalse(ts.isDirty)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 60)
    }

    private func makeEl(_ x: Double, _ y: Double? = nil) -> Continuos {
        Continuos(date: makeDt(x), value: y ?? x)
    }

    private func makeDt(_ x: Double) -> Date {
        Date(timeIntervalSinceReferenceDate: x)
    }
}
