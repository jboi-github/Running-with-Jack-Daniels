//
//  TimeSeriesMaintenanceTests.swift
//  Run!!Tests
//
//  Created by Jürgen Boiselle on 27.07.22.
//

import XCTest
@testable import Run__

class TimeSeriesMaintenanceTests: XCTestCase {
    
    private struct TestTimeSeries: GenericTimeseriesElement, Equatable {
        static let key: String = "TS"
        var vector: VectorElement<String>
        init(_ vector: VectorElement<String>) {self.vector = vector}
        init(_ element: Self) {self.init(element.vector)}
        
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
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            guard lhs.string == rhs.string else {return false}
            guard lhs.value == rhs.value else {return false}
            guard Int(lhs.date.timeIntervalSinceReferenceDate) == Int(rhs.date.timeIntervalSinceReferenceDate) else {return false}
            return true
        }
    }
    
    var queue: SerialQueue!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        queue = SerialQueue("X")
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: Save and load
    
    func testNotSavedWhileInForeground() throws {
        Files.unlink(from: "TS.json")
        let ts = TimeSeries<TestTimeSeries, Date>(queue: queue)
        ts.reset()
        XCTAssertFalse(ts.isDirty)
        ts.isInBackground = false
        
        // Read original elements
        let original: [TestTimeSeries] = Files.read(from: "TS.json") ?? []
        XCTAssertEqual(ts.elements, original)
        
        // Do something while in foreground
        ts.insert(TestTimeSeries(date: .now, string: "X", value: 1))
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
        let ts = TimeSeries<TestTimeSeries, Date>(queue: queue)
        ts.reset()
        XCTAssertFalse(ts.isDirty)
        ts.isInBackground = false
        
        // Read original elements
        let original: [TestTimeSeries] = Files.read(from: "TS.json") ?? []
        
        // Do something while in foreground
        ts.insert(TestTimeSeries(date: .now, string: "X", value: 1))
        
        // Go to background
        ts.isInBackground = true
        XCTAssertNotEqual(original, ts.elements)
        XCTAssertEqual(Files.read(from: "TS.json") ?? [], ts.elements)
        XCTAssertNotEqual(original, Files.read(from: "TS.json") ?? [])
        XCTAssertFalse(ts.isDirty)
    }
    
    func testSavedStayingInBackground() throws {
        Files.unlink(from: "TS.json")
        let ts = TimeSeries<TestTimeSeries, Date>(queue: queue)
        ts.reset()
        XCTAssertFalse(ts.isDirty)
        ts.isInBackground = false
        
        // Read original elements
        let original: [TestTimeSeries] = Files.read(from: "TS.json") ?? []
        
        // Do something while in foreground
        ts.insert(TestTimeSeries(date: .now, string: "X", value: 1))
        
        // Go to background
        ts.isInBackground = true
        
        // Do something while in background
        ts.insert(TestTimeSeries(date: .now + 10, string: "Y", value: 2))
        XCTAssertNotEqual(original, ts.elements)
        XCTAssertNotEqual(Files.read(from: "TS.json") ?? [], ts.elements)
        XCTAssertNotEqual(original, Files.read(from: "TS.json") ?? [])
        XCTAssertTrue(ts.isDirty)

        // Wait
        let expectation = XCTestExpectation()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            log(timer.fireDate)
            if ts.isDirty {return}
            timer.invalidate()
            
            // Shoud be saved now
            XCTAssertFalse(ts.isDirty)
            
            let ts2: [TestTimeSeries] = Files.read(from: "TS.json") ?? []
            XCTAssertNotEqual(original, ts.elements)
            XCTAssertEqual(ts2, ts.elements)
            XCTAssertEqual(ts2.count, ts.elements.count)
            ts2.indices.forEach {
                XCTAssertEqual(ts2[$0], ts.elements[$0], "\($0)")
            }
            XCTAssertNotEqual(original, ts2)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 60)
    }
    
    // MARK: Test migration for vector elements
    
    struct OldVersion: GenericTimeseriesElement {
        // MARK: Implement GenericTimeseriesElement
        static let key: String = "MigrationTest"
        let vector: VectorElement<None>
        init(_ vector: VectorElement<None>) {self.vector = vector}

        // MARK: Implement specifics
        init(date: Date, oldVersion: Int) {
            vector = VectorElement(date: date, ints: [oldVersion])
        }
    }

    struct NewVersion: GenericTimeseriesElement {
        // MARK: Implement GenericTimeseriesElement
        static let key: String = "MigrationTest"
        let vector: VectorElement<None>
        init(_ vector: VectorElement<None>) {self.vector = vector}

        // MARK: Implement specifics
        init(date: Date, oldVersion: Int, newVersion: Int) {
            vector = VectorElement(date: date, ints: [oldVersion, newVersion])
        }
        
        var oldVersion: Int {vector.ints![0]}
        var newVersion: Int {vector.ints![1]}
        
        private static func _migrate(_ element: NewVersion) -> NewVersion {
            var vector = element.vector
            while let ints = vector.ints, ints.count < 2 {
                vector.ints?.append(-1)
            }
            return NewVersion(vector)
        }
        
        init(_ element: Self) {
            self = Self._migrate(element)
        }
    }
    
    func testMigration() throws {
        // Create, initialise and save old version
        let ts = TimeSeries<OldVersion, None>(queue: queue)
        ts.isInBackground = false
        ts.reset()
        
        ts.insert(OldVersion(date: makeDt(1000), oldVersion: 10))
        ts.insert(OldVersion(date: makeDt(2000), oldVersion: 10))
        ts.insert(OldVersion(date: makeDt(3000), oldVersion: 10))
        ts.archive(upTo: makeDt(10000))
        
        // Create new version with same key. This should call `migrate(()`
        let tsNew = TimeSeries<NewVersion, None>(queue: queue)

        // Check for padded value
        XCTAssertTrue(tsNew.elements.allSatisfy {$0.oldVersion == 10})
        XCTAssertTrue(tsNew.elements.allSatisfy {$0.vector.ints?.indices.contains(1) ?? false})
    }
    
    func testBackwardMigration() throws {
        // Create, initialise and save old version
        // Create new version with same key
        // Read with old version
        // Check for old values
    }
    
    // MARK: Range tests

    func testGetIdxRangeFullyIncluded() throws {
        // Define a timeseries, add 4 elements
        let ts = TimeSeries<TestTimeSeries, Date>(queue: queue)
        ts.reset()
        ts.insert(TestTimeSeries(date: makeDt(1000), string: "X", value: 1000))
        ts.insert(TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000))
        ts.insert(TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000))
        ts.insert(TestTimeSeries(date: makeDt(4000), string: "A", value: 4000))

        // Get range of index which includes the middle 2 elements and check
        XCTAssertEqual(ts[1 ..< 3], [
            TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000),
            TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000)
        ])
    }

    func testGetIdxRangeAllBfore() throws {
        // Define a timeseries, add 4 elements
        let ts = TimeSeries<TestTimeSeries, Date>(queue: queue)
        ts.reset()
        ts.insert(TestTimeSeries(date: makeDt(1000), string: "X", value: 1000))
        ts.insert(TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000))
        ts.insert(TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000))
        ts.insert(TestTimeSeries(date: makeDt(4000), string: "A", value: 4000))

        XCTAssertTrue(ts[-1 ..< 0].isEmpty)
    }

    func testGetIdxRangeAllAfter() throws {
        // Define a timeseries, add 4 elements
        let ts = TimeSeries<TestTimeSeries, Date>(queue: queue)
        ts.reset()
        ts.insert(TestTimeSeries(date: makeDt(1000), string: "X", value: 1000))
        ts.insert(TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000))
        ts.insert(TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000))
        ts.insert(TestTimeSeries(date: makeDt(4000), string: "A", value: 4000))

        XCTAssertTrue(ts[4 ..< 10].isEmpty)
    }

    func testGetIdxRangeStartsBefore() throws {
        // Define a timeseries, add 4 elements
        let ts = TimeSeries<TestTimeSeries, Date>(queue: queue)
        ts.reset()
        ts.insert(TestTimeSeries(date: makeDt(1000), string: "X", value: 1000))
        ts.insert(TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000))
        ts.insert(TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000))
        ts.insert(TestTimeSeries(date: makeDt(4000), string: "A", value: 4000))

        XCTAssertEqual(ts[-1 ..< 3], [
            TestTimeSeries(date: makeDt(1000), string: "X", value: 1000),
            TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000),
            TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000)
        ])
    }

    func testGetIdxRangeEndsAfter() throws {
        // Define a timeseries, add 4 elements
        let ts = TimeSeries<TestTimeSeries, Date>(queue: queue)
        ts.reset()
        ts.insert(TestTimeSeries(date: makeDt(1000), string: "X", value: 1000))
        ts.insert(TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000))
        ts.insert(TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000))
        ts.insert(TestTimeSeries(date: makeDt(4000), string: "A", value: 4000))

        XCTAssertEqual(ts[1 ..< 13], [
            TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000),
            TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000),
            TestTimeSeries(date: makeDt(4000), string: "A", value: 4000)
        ])
    }

    func testGetDateRangeExactMatch() throws {
        // Define a timeseries, add 4 elements
        let ts = TimeSeries<TestTimeSeries, Date>(queue: queue)
        ts.reset()
        ts.insert(TestTimeSeries(date: makeDt(1000), string: "X", value: 1000))
        ts.insert(TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000))
        ts.insert(TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000))
        ts.insert(TestTimeSeries(date: makeDt(4000), string: "A", value: 4000))

        XCTAssertEqual(ts[makeDt(2000) ..< makeDt(3000)], [
            TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000),
            TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000)
        ])
    }

    func testGetDateRangeBothInBetween() throws {
        // Define a timeseries, add 4 elements
        let ts = TimeSeries<TestTimeSeries, Date>(queue: queue)
        ts.reset()
        ts.insert(TestTimeSeries(date: makeDt(1000), string: "X", value: 1000))
        ts.insert(TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000))
        ts.insert(TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000))
        ts.insert(TestTimeSeries(date: makeDt(4000), string: "A", value: 4000))

        XCTAssertEqual(ts[makeDt(1500) ..< makeDt(3500)], [
            TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000),
            TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000)
        ])
    }

    func testGetDateRangeOneBefore() throws {
        // Define a timeseries, add 4 elements
        let ts = TimeSeries<TestTimeSeries, Date>(queue: queue)
        ts.reset()
        ts.insert(TestTimeSeries(date: makeDt(1000), string: "X", value: 1000))
        ts.insert(TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000))
        ts.insert(TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000))
        ts.insert(TestTimeSeries(date: makeDt(4000), string: "A", value: 4000))

        XCTAssertEqual(ts[makeDt(500) ..< makeDt(3500)], [
            TestTimeSeries(date: makeDt(1000), string: "X", value: 1000),
            TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000),
            TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000)
        ])
    }

    func testGetDateRangeOneAfter() throws {
        // Define a timeseries, add 4 elements
        let ts = TimeSeries<TestTimeSeries, Date>(queue: queue)
        ts.reset()
        ts.insert(TestTimeSeries(date: makeDt(1000), string: "X", value: 1000))
        ts.insert(TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000))
        ts.insert(TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000))
        ts.insert(TestTimeSeries(date: makeDt(4000), string: "A", value: 4000))

        XCTAssertEqual(ts[makeDt(1500) ..< makeDt(4500)], [
            TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000),
            TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000),
            TestTimeSeries(date: makeDt(4000), string: "A", value: 4000)
        ])
    }

    func testGetDateRangeBothBefore() throws {
        // Define a timeseries, add 4 elements
        let ts = TimeSeries<TestTimeSeries, Date>(queue: queue)
        ts.reset()
        ts.insert(TestTimeSeries(date: makeDt(1000), string: "X", value: 1000))
        ts.insert(TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000))
        ts.insert(TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000))
        ts.insert(TestTimeSeries(date: makeDt(4000), string: "A", value: 4000))

        XCTAssertTrue(ts[makeDt(500) ..< makeDt(750)].isEmpty)
    }

    func testGetDateRangeBothAfter() throws {
        // Define a timeseries, add 4 elements
        let ts = TimeSeries<TestTimeSeries, Date>(queue: queue)
        ts.reset()
        ts.insert(TestTimeSeries(date: makeDt(1000), string: "X", value: 1000))
        ts.insert(TestTimeSeries(date: makeDt(2000), string: "Y", value: 2000))
        ts.insert(TestTimeSeries(date: makeDt(3000), string: "Z", value: 3000))
        ts.insert(TestTimeSeries(date: makeDt(4000), string: "A", value: 4000))

        XCTAssertTrue(ts[makeDt(4500) ..< makeDt(4750)].isEmpty)
    }

    private func makeDt(_ x: Double) -> Date {
        Date(timeIntervalSinceReferenceDate: x)
    }
}
