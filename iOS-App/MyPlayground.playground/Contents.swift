import Foundation

extension Array {
    func ngram(_ n: Int) -> [[Element]] {
        (n...count).map {Array(self[($0 - n) ..< $0])}
    }
}

struct Event {
    let time: Date
    let dimension: String
}

let ref = Date()

var events = [
    Event(time: ref, dimension: "0000"),
    Event(time: ref.addingTimeInterval(1200), dimension: "1200"),
    Event(time: ref.addingTimeInterval(1800), dimension: "1800")
]

func findIdx(event: Event) -> Int {
    if event.time >= events.last?.time ?? Date.distantPast {
        // append
        return events.count
    } else if let idx = (0 ..< events.count)
                .reversed()
                .ngram(2)
                .first(where: {(events[$0[1]].time ..< events[$0[0]].time).contains(event.time)})
    {
        // middle position
        return idx[0]
    } else {
        return 0
    }
}

findIdx(event: Event(time: ref.addingTimeInterval(+2400), dimension: "2400"))
findIdx(event: Event(time: ref.addingTimeInterval(+1800), dimension: "1800"))
findIdx(event: Event(time: ref.addingTimeInterval(+1400), dimension: "1400"))
findIdx(event: Event(time: ref.addingTimeInterval(+1200), dimension: "1200"))
findIdx(event: Event(time: ref.addingTimeInterval(+1000), dimension: "1000"))
findIdx(event: Event(time: ref.addingTimeInterval(+0), dimension: "0"))
findIdx(event: Event(time: ref.addingTimeInterval(-1), dimension: "-1"))

events.removeAll()
findIdx(event: Event(time: ref.addingTimeInterval(+2400), dimension: "2400"))

