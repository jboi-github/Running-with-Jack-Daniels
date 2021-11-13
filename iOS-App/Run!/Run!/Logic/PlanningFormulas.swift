//
//  PlanningFormulas.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import Foundation

/// A collection of functions to implement Jack Daniels running formulas for building training plans. All functions are stateless by design.

private let seasonWeeks = [
    4: (EQ: 0, TQ: 0, FQ: 1),
    5: (EQ: 0, TQ: 0, FQ: 2),
    6: (EQ: 0, TQ: 0, FQ: 3),
    7: (EQ: 0, TQ: 1, FQ: 3),
    8: (EQ: 0, TQ: 2, FQ: 3),
    9: (EQ: 0, TQ: 3, FQ: 3),
    10: (EQ: 1, TQ: 3, FQ: 3),
    11: (EQ: 2, TQ: 3, FQ: 3),
    12: (EQ: 3, TQ: 3, FQ: 3),
    13: (EQ: 3, TQ: 3, FQ: 3),
    14: (EQ: 3, TQ: 4, FQ: 3),
    15: (EQ: 3, TQ: 5, FQ: 3),
    16: (EQ: 3, TQ: 6, FQ: 3),
    17: (EQ: 3, TQ: 6, FQ: 4),
    18: (EQ: 4, TQ: 6, FQ: 4),
    19: (EQ: 5, TQ: 6, FQ: 4),
    20: (EQ: 6, TQ: 6, FQ: 4),
    21: (EQ: 6, TQ: 6, FQ: 4),
    22: (EQ: 6, TQ: 6, FQ: 5),
    23: (EQ: 6, TQ: 6, FQ: 5),
    24: (EQ: 6, TQ: 6, FQ: 6)
]

/// Layout phases of a seasonal plan according jack daniels running formula.
/// - Parameters:
///   - startDate: Date to start the season. Defaults to today.
///   - endDate: Date of the end of the season or a 3-4 days before a major race. Defaults to start + 24 weeks + breaks.
///   - plannedBreaks: Array of times with planned breaks, e.g. vacation time. Defaults to an empty array. Breaks must not overlap.
/// - Returns: For each phase of the season, the dates where this phase takes place.
///             Actual trainig time of a phase is the given daterange minus planned breaks.
public func planSeason(
    startDate: Date = Date(),
    endDate: Date? = nil,
    plannedBreaks: [(from: Date, to: Date)] = []) -> (
        FI: (from: Date, to: Date),
        EQ: (from: Date, to: Date),
        TQ: (from: Date, to: Date),
        FQ: (from: Date, to: Date))
{
    func endIncludingBreaks(_ start: Date, _ days: Int, breaks: [(from: Date, to: Date)]) -> Date {
        var end = cc.date(byAdding: .day, value: days, to: start)!
        breaks
            .sorted {$0.from <= $1.from}
            .forEach { (from: Date, to: Date) in
                let days = max(0, cc.dateComponents([.day], from: max(start, from), to: min(end, to)).day!)
                end = cc.date(byAdding: .day, value: days, to: end)!
            }
        return end
    }
    
    let cc = Calendar.current
    
    // Days without training
    let breakDays = plannedBreaks
        .map { (from: Date, to: Date) in
            cc.dateComponents([.day], from: from, to: to).day!
        }
        .reduce(0, +)

    // Get endDate, defaults to +24 weeks + breaks
    let endDate = endDate ?? cc.date(byAdding: .day, value: 24*7 + breakDays, to: startDate)!
    
    // Get weeks in training
    let weeks = (cc.dateComponents([.day], from: startDate, to: endDate).day! - breakDays) / 7
    
    // Get weeks in phases, without breaks falling into it, for each phase
    let phases = (weeks < seasonWeeks.keys.min()!) ?
        (EQ: 0, TQ: 0, FQ: 0) :
        seasonWeeks[min(weeks, seasonWeeks.keys.max()!)]!
    let fiDays = (weeks - phases.EQ - phases.TQ - phases.FQ) * 7
    let eqDays = phases.EQ * 7
    let tqDays = phases.TQ * 7
    let fqDays = phases.FQ * 7
    
    log("Days: \(fiDays), \(eqDays), \(tqDays), \(fqDays)")
    
    // Lay out phases on dates
    let fiFrom = startDate
    let fiTo = endIncludingBreaks(fiFrom, fiDays, breaks: plannedBreaks)
    let eqFrom = cc.date(byAdding: .day, value: 1, to: fiTo)!
    let eqTo = endIncludingBreaks(eqFrom, eqDays, breaks: plannedBreaks)
    let tqFrom = cc.date(byAdding: .day, value: 1, to: eqTo)!
    let tqTo = endIncludingBreaks(tqFrom, tqDays, breaks: plannedBreaks)
    let fqFrom = cc.date(byAdding: .day, value: 1, to: tqTo)!
    let fqTo = endIncludingBreaks(fqFrom, fqDays, breaks: plannedBreaks)

    return (
        FI: (from: fiFrom, to: fiTo),
        EQ: (from: eqFrom, to: eqTo),
        TQ: (from: tqFrom, to: tqTo),
        FQ: (from: fqFrom, to: fqTo))
}

public func planWeek(phase: Int, goal: Goal, sumTime: TimeInterval, days: Int, maxQdays: Int)
-> (error: Error?, plan: [Workout]?)
{
    // Do some quality checks
    guard (1...4).contains(phase) else {
        return (error: "Phase must be between 1 and 4 for FI, EQ, TQ, FQ", plan: nil)
    }
    
    guard (1...7).contains(days) else {
        return (error: "Week has only seven days available", plan: nil)
    }

    guard let intensities = emphasesPool[phase]?[goal] else {
        return (error: "No emphases for \(phase) and \(goal) found", plan: nil)
    }

    // Get optimal T, I, R, L and M's for one workout
    let qualities: [Intensity : [Workout]] = [
        .Threshold : optimalQ(.Threshold, sumTime: sumTime, optimalPercent: 0.1) ?? [],
        .Interval : optimalQ(.Interval, sumTime: sumTime, optimalPercent: 0.08) ?? [],
        .Repetition : optimalQ(.Repetition, sumTime: sumTime, optimalPercent: 0.05) ?? [],
        .Marathon : [Workout.getMarathon(goal: goal)],
        .Long : [Workout.getLong(sumTimeWeek: sumTime)]
    ]

    // Get all possible workouts for possible intensities in a week
    var weeks = [WorkoutWeek]()
    intensities
        .map {$0.compactMap {qualities[$0]}} // Combine all possible weeks
        .forEach {
            $0.forEachEach {
                let week = WorkoutWeek(workouts: $0, sumTime: sumTime, days: days, maxQdays: maxQdays)
                if week.isValid {weeks.append(week)}
            }
        }
    
    // Only the plan with max possible number of Q's returned
    return (error: nil, plan: weeks.max {$0.qDays < $1.qDays}?.workouts)
}

/// Get the next best workout ans its intensity accoridng to goal, time today and workouts so far for the running week. Rules are:
///     - Keep Easy intensity at at least 80% of the overall workout time.
///     - Do not allow for more then three quality workouts per week.
///     - Ensure always at least one Easy and recovering workout between two quality workouts.
///
/// - Parameters:
///   - phase: Phase I-IV of the seasonal plan.
///   - goal: Seasons overall goal.
///   - sumTimeWeek: Planned time for this weeks workouts all together.
///   - maxTimeToday: Max time for a workout today.
///   - intensities: Intesitiies and times in the intensity accumulated for this week.
///   - nofWorkouts: Number of workouts for the current week so far. This includes the Easy-Trainings. It might be several workouts per day.
/// - Returns: The best suited workout for the current situation.
public func nextBestWorkout(
    phase: Int, goal: Goal, sumTimeWeek: TimeInterval, maxTimeToday: TimeInterval,
    intensities: [Intensity:TimeInterval], nofWorkouts: Int) -> [Workout]
{
    let easyWorkout = [Workout(.Easy, steps: [WorkoutStep(intensity: .Easy, seconds: Int(maxTimeToday))])]
    
    // If nothing done or higher intensities exceed 80% of easy -> return Easy
    let sumTime = intensities.reduce(0.0) {$0 + $1.value}
    guard let easyTime = intensities[.Easy], easyTime >= 0.8 * sumTime else {return easyWorkout}
    
    // Ensure always at least one Easy and recovering workout between two quality workouts
    let qCount = intensities.filter {$0.key != .Easy}.count
    guard qCount < nofWorkouts - qCount else {return easyWorkout}
    
    // We can try some Q-Workout
    let plan = prioritiseQ(phase: phase, goal: goal, completedQ: Array(intensities.keys))
    guard !plan.isEmpty else {return easyWorkout}

    // Which of the possible workouts suite todays timing and available capacity for the week?
    // Get optimal T, I, R, L and M's for one workout
    let workouts = plan
        .compactMap { intensity -> [Workout]? in
            switch intensity {
            case .Long:
                return [Workout.getLong(sumTimeWeek: sumTimeWeek)]
            case .Marathon:
                return [Workout.getMarathon(goal: goal, availableTime: maxTimeToday)]
            case .Threshold:
                return optimalQ(.Threshold, sumTime: sumTime, optimalPercent: 0.1) ?? []
            case .Interval:
                return optimalQ(.Interval, sumTime: sumTime, optimalPercent: 0.08) ?? []
            case .Repetition:
                return optimalQ(.Repetition, sumTime: sumTime, optimalPercent: 0.05) ?? []
            default:
                return nil
            }
        }
        .flatMap {$0}
        //Keep only workouts, that fit into todays timing
        .filter {$0.time <= maxTimeToday}
    guard !workouts.isEmpty else {return easyWorkout}
    
    return workouts
}

public enum Goal: String, Codable, CaseIterable, Identifiable {
    case short800to3000m, mid5kTo15kOrCrossCountry, longMarathon
    public var id: String {self.rawValue}
}

public struct WorkoutStep {
    fileprivate init(intensity: Intensity, seconds: Int) {
        self.intensity = intensity
        self.time = TimeInterval(seconds)
    }
    
    fileprivate init(intensity: Intensity, minutes: Int) {
        self.intensity = intensity
        self.time = Double(minutes) * 60.0
    }
    
    public let intensity: Intensity
    public let time: TimeInterval
}

public struct Workout {
    fileprivate init(_ purpose: Intensity, steps: [WorkoutStep]...) {
        self.purpose = purpose
        self.steps = steps.flatMap {$0}
        self.totals = self.steps.reduce(into: [:]) { result, step in
            result[step.intensity, default: 0.0] += step.time
        }
    }
    
    public let purpose: Intensity
    public let steps: [WorkoutStep]
    public let totals: [Intensity : TimeInterval]
    public var time: TimeInterval {totals.reduce(0.0) {$0 + $1.value}}
    
    public static func getMarathon(goal: Goal, availableTime: TimeInterval? = nil) -> Workout {
        let (lower, upper) = goal == .short800to3000m ? (40, 60) : (90, 150)
        guard let availableTime = availableTime else {
            return Workout(
                .Marathon,
                steps: wucd, [
                    WorkoutStep(
                        intensity: .Marathon,
                        minutes: (upper - lower) / 2)],
                wucd)
        }
        let time = min(max(Int(availableTime / 60.0) - 20, lower), upper) // Time for warm up / cool down
        return Workout(.Marathon, steps: wucd, [WorkoutStep(intensity: .Marathon, minutes: time)], wucd)
    }
    
    public static func getLong(sumTimeWeek: TimeInterval) -> Workout {
        let longStep = WorkoutStep(intensity: .Easy, seconds: Int(min(2.5 * 3600.0, sumTimeWeek * 0.3)))
        return Workout(.Long, steps: [longStep])
    }
}

public struct WorkoutWeek {
    fileprivate init(workouts: [Workout], sumTime: TimeInterval, days: Int, maxQdays: Int) {
        let easies = WorkoutWeek.easies(
            sumTime: sumTime, days: days,
            sumEasy: workouts.compactMap {$0.totals[.Easy]}.reduce(0.0, +),
            daysQ: workouts.count)
        
        // Mix easy runs and workouts: Start easy and have at leat one easy between Q's
        let ws = [easies, workouts]
        self.workouts = (0..<(ws.map {$0.count}.max() ?? 0))
            .flatMap {idx in ws.filter {idx < $0.count}.map {$0[idx]}}
        self.days = days
        self.totals = self.workouts.reduce(into: [:]) { result, workout in
            workout.totals.forEach {result[$0.key, default: 0.0] += $0.value}
        }
        self.qDays = days - easies.count
        
        // Check for validity
        let totalSum = totals.reduce(0.0) {$0 + $1.value}
        let totalEasy = totals[.Easy] ?? 0.0
        
        // Easy must be at least 80% of weekly workout time and max Q days must not be exceeded.
        self.isValid = qDays <= maxQdays && totalEasy / totalSum >= 0.8
    }
    
    public let workouts: [Workout]
    public let totals: [Intensity : TimeInterval]
    public let days: Int
    public let qDays: Int
    public let isValid: Bool
    
    private static func easies(
        sumTime: TimeInterval, days: Int,
        sumEasy: TimeInterval, daysQ: Int) -> [Workout]
    {
        guard days > daysQ else {return []}
        guard sumTime > sumEasy else {return []}
        
        let step = WorkoutStep(intensity: .Easy, seconds: Int(sumTime - sumEasy) / (days - daysQ))
        return [Workout(.Easy, steps: [step])] * (days - daysQ)
    }
}

private let wucd = [WorkoutStep(intensity: .Easy, minutes: 10)]
private let t5x1 = [
    WorkoutStep(intensity: .Threshold, minutes: 5),
    WorkoutStep(intensity: .Easy, minutes: 1)
]
private let t8x1 = [
    WorkoutStep(intensity: .Threshold, minutes: 8),
    WorkoutStep(intensity: .Easy, minutes: 1)
]
private let t10x2 = [
    WorkoutStep(intensity: .Threshold, minutes: 10),
    WorkoutStep(intensity: .Easy, minutes: 2)
]
private let t15x3 = [
    WorkoutStep(intensity: .Threshold, minutes: 15),
    WorkoutStep(intensity: .Easy, minutes: 3)
]
private let t5x0 = [WorkoutStep(intensity: .Threshold, minutes: 5)]
private let t8x0 = [WorkoutStep(intensity: .Threshold, minutes: 8)]
private let t10x0 = [WorkoutStep(intensity: .Threshold, minutes: 10)]
private let t15x0 = [WorkoutStep(intensity: .Threshold, minutes: 15)]
private let t20x0 = [WorkoutStep(intensity: .Threshold, minutes: 20)]

private let i1x0 = [WorkoutStep(intensity: .Interval, minutes: 1)]

private let i1x1 = [
    WorkoutStep(intensity: .Interval, minutes: 1),
    WorkoutStep(intensity: .Easy, minutes: 1)
]

private let i2x0 = [WorkoutStep(intensity: .Interval, minutes: 2)]

private let i2x1 = [
    WorkoutStep(intensity: .Interval, minutes: 2),
    WorkoutStep(intensity: .Easy, minutes: 1)
]

private let i2x2 = [
    WorkoutStep(intensity: .Interval, minutes: 2),
    WorkoutStep(intensity: .Easy, minutes: 2)
]

private let i3x0 = [WorkoutStep(intensity: .Interval, minutes: 3)]

private let i3x2 = [
    WorkoutStep(intensity: .Interval, minutes: 3),
    WorkoutStep(intensity: .Easy, minutes: 2)
]

private let i3x3 = [
    WorkoutStep(intensity: .Interval, minutes: 3),
    WorkoutStep(intensity: .Easy, minutes: 3)
]

private let i4x0 = [WorkoutStep(intensity: .Interval, minutes: 4)]

private let i4x3 = [
    WorkoutStep(intensity: .Interval, minutes: 4),
    WorkoutStep(intensity: .Easy, minutes: 3)
]

private let i4x4 = [
    WorkoutStep(intensity: .Interval, minutes: 4),
    WorkoutStep(intensity: .Easy, minutes: 4)
]

private let i5x0 = [WorkoutStep(intensity: .Interval, minutes: 5)]

private let i5x4 = [
    WorkoutStep(intensity: .Interval, minutes: 5),
    WorkoutStep(intensity: .Easy, minutes: 4)
]

private let r30x0 = [WorkoutStep(intensity: .Repetition, seconds: 30)]

private let r30x1 = [
    WorkoutStep(intensity: .Repetition, seconds: 30),
    WorkoutStep(intensity: .Easy, minutes: 1)
]

private let r30x2 = [
    WorkoutStep(intensity: .Repetition, seconds: 30),
    WorkoutStep(intensity: .Easy, minutes: 2)
]

private let r60x0 = [WorkoutStep(intensity: .Repetition, seconds: 60)]

private let r60x30 = [
    WorkoutStep(intensity: .Repetition, seconds: 60),
    WorkoutStep(intensity: .Easy, seconds: 30)
]

private let r60x2 = [
    WorkoutStep(intensity: .Repetition, seconds: 60),
    WorkoutStep(intensity: .Easy, minutes: 2)
]

private let r60x4 = [
    WorkoutStep(intensity: .Repetition, seconds: 60),
    WorkoutStep(intensity: .Easy, minutes: 4)
]

private let workoutPool: [Intensity: [Workout]] = [
    .Threshold : [
        Workout(.Threshold, steps: wucd, t20x0,  wucd),
        Workout(.Threshold, steps: wucd, t5x1 * 5, t5x0, wucd),
        Workout(.Threshold, steps: wucd, t10x2 * 2, t10x0, wucd),
        Workout(.Threshold, steps: wucd, t15x3, t15x0, wucd),
        Workout(.Threshold, steps: wucd, t5x1 * 7, t5x0, wucd),
        Workout(.Threshold, steps: wucd, t8x1 * 4, t8x0, wucd),
        Workout(.Threshold, steps: wucd, t10x2 * 3, t10x0, wucd),
        Workout(.Threshold, steps: wucd, t15x3, t10x2 * 2, t5x0, wucd),
        Workout(.Threshold, steps: wucd, t5x1 * 9, t5x0, wucd),
        Workout(.Threshold, steps: wucd, t10x2 * 4, t10x0, wucd),
        Workout(.Threshold, steps: wucd, t15x3 * 2, t10x2, t10x0, wucd),
        Workout(.Threshold, steps: wucd, t10x2 * 5, t10x0, wucd),
        Workout(.Threshold, steps: wucd, t15x3 * 3, t15x0, wucd),
        Workout(.Threshold, steps: wucd, t15x3 * 2, t10x2 * 2, t5x1, t5x0, wucd)
    ],
    .Interval : [
        Workout(.Interval, steps: wucd, i3x2 * 3,  i3x0, wucd),
        Workout(.Interval, steps: wucd, i2x1 * 5, i2x0, wucd),
        Workout(.Interval, steps: wucd, i1x1, i2x2, i3x3 * 2, i2x2, i1x0, wucd),
        Workout(.Interval, steps: wucd, i3x2 * 4, i3x0, wucd),
        Workout(.Interval, steps: wucd, i5x4 * 2, i5x0, wucd),
        Workout(.Interval, steps: wucd, i1x1, i2x1, i3x2, i4x3, i3x2, i2x0, wucd),
        Workout(.Interval, steps: wucd, i4x3 * 4, i4x0, wucd),
        Workout(.Interval, steps: wucd, i5x4 * 3, i5x0, wucd),
        Workout(.Interval, steps: wucd, i2x1, i3x2, i5x4 * 2, i3x2, i2x0, wucd),
        Workout(.Interval, steps: wucd, i5x4 * 4, i5x0, wucd),
        Workout(.Interval, steps: wucd, i5x4 * 2, i4x3 * 2, i3x2, i3x0, wucd),
        Workout(.Interval, steps: wucd, i3x2, i4x3, i5x4 * 2, i4x3, i3x0, wucd),
        Workout(.Interval, steps: wucd, i5x4 * 5, i5x0, wucd),
        Workout(.Interval, steps: wucd, i3x2 * 9, i3x0, wucd),
        Workout(.Interval, steps: wucd, i1x1, i2x1, i3x2, i4x4, i5x4 * 2, i4x3, i3x2, i2x1, i1x0, wucd)
    ],
    .Repetition : [
        Workout(.Repetition, steps: wucd, r30x2 * 11, r30x0, wucd),
        Workout(.Repetition, steps: wucd, r60x4 * 5, r60x0, wucd),
        Workout(.Repetition, steps: wucd, r30x2 * 19, r30x0, wucd),
        Workout(.Repetition, steps: wucd, r60x4 * 9, r60x0, wucd),
        Workout(.Repetition, steps: wucd, concat(r30x1, r30x2, r60x30) * 5, wucd),
        Workout(.Repetition, steps: wucd, r60x2 * 12, r30x1 * 7, r30x0, wucd),
        Workout(.Repetition, steps: wucd, r60x2 * 15, r60x0, wucd),
        Workout(.Repetition, steps: wucd, r30x1 * 8, r60x2 * 8, r30x1 * 7, r30x0, wucd),
        Workout(.Repetition, steps: wucd, r30x1 * 39, r30x0, wucd),
        Workout(.Repetition, steps: wucd, r60x2 * 19, r60x0, wucd),
        Workout(.Repetition, steps: wucd, r30x1 * 8, r60x2 * 12, r30x1 * 7, r30x0, wucd)
    ]
]

private let emphasesPool: [Int: [Goal : [[Intensity]]]] = [
    2: [
        .short800to3000m : [
            [.Repetition],
            [.Repetition, .Threshold],
            [.Repetition, .Threshold, .Interval]
        ],
        .mid5kTo15kOrCrossCountry : [
            [.Repetition],
            [.Repetition, .Threshold],
            [.Repetition, .Threshold, .Interval]
        ],
        .longMarathon : [
            [.Repetition],
            [.Repetition, .Threshold],
            [.Repetition, .Threshold, .Long]
        ]
    ],
    3: [
        .short800to3000m : [
            [.Interval],
            [.Interval, .Repetition],
            [.Interval, .Repetition, .Threshold]
        ],
        .mid5kTo15kOrCrossCountry : [
            [.Repetition],
            [.Repetition, .Threshold],
            [.Repetition, .Threshold, .Long]
        ],
        .longMarathon : [
            [.Interval],
            [.Interval, .Threshold],
            [.Interval, .Threshold, .Marathon]
        ]
    ],
    4: [
        .short800to3000m : [
            [.Repetition],
            [.Repetition, .Threshold],
            [.Repetition, .Threshold, .Interval]
        ],
        .mid5kTo15kOrCrossCountry : [
            [.Threshold],
            [.Threshold, .Interval],
            [.Threshold, .Repetition],
            [.Threshold, .Interval, .Repetition],
            [.Threshold, .Repetition, .Interval]
        ],
        .longMarathon : [
            [.Threshold],
            [.Marathon],
            [.Threshold, .Long],
            [.Marathon, .Threshold],
            [.Marathon, .Long],
            [.Marathon, .Threshold, .Long],
            [.Threshold, .Long, .Marathon]
        ]
    ]
]

private func optimalQ(_ intensity: Intensity, sumTime: TimeInterval, optimalPercent: Double) -> [Workout]? {
    guard let pool = workoutPool[intensity] else {return nil}

    // Map all workouts of given intensity to its time in quality
    let times = pool.reduce(into: [TimeInterval : [Workout]]()) { result, workout in
        if let total = workout.totals[intensity] {
            result[total, default: [Workout]()].append(workout)
        }
    }
    
    // Which is the optimal time in quality?
    let optimalQtime = sumTime * optimalPercent
    let optimalWtime = times
        .keys
        .map {(key: $0, diff: abs($0 - optimalQtime))}
        .min {$0.diff < $1.diff}?
        .key
    
    // If optimum found, return it
    guard let optimalWtime = optimalWtime else {return nil}
    return times[optimalWtime]
}

/// Find and sort possible next intensities by priority.
///
/// Rules to apply for prios:
/// - Take only Intensities for given phase and goal
/// - Take only lines, that contain at least one entry more, then Q's completed this week. If list is empty, stop.
/// - Lines containing all completed intensities get normal prio. All other lines get low prio and are only appended to the result, if normal prios is empty.
/// - Intensities where order with Qs is kept, get higer prio
/// - Sort by normal/low prio and offset of intensity within line
///
/// - Parameters:
///   - phase: phase (I-IV) in season
///   - goal: seasons goal
///   - completedQ: List of intensities, already completed in the current week.
/// - Returns: Prioritised list of intensities. The high prio intensitites come first.
private func prioritiseQ(phase: Int, goal: Goal, completedQ: [Intensity]) -> [Intensity] {
    let completedQ = Set(completedQ.filter {$0 != .Easy})
    let countQ = completedQ.count
    
    // Take only Intensities for given phase and goal
    return emphasesPool[phase]?[goal]?
        // Take only lines, that contain at least one entry more, then Q's completed this week.
        .filter {$0.count > countQ}
        // Lines with all completed Q's get higher prio.
        .map { line -> (B: Bool, I: [Intensity]) in
            (B: completedQ.intersection(line).count == countQ, I: line)
        }
        // Save offset within line for later sorting
        .map { line -> (B: Bool, I: [(P:Int, I: Intensity)]) in
            (B: line.B, I: line.I.enumerated().map {(P: $0.offset, I: $0.element)})
        }
        // Intensities where order with Qs is kept, get higher prio
        .map { line -> (B: Bool, I: [(P:Int, C: Bool, I: Intensity)]) in
            let highestQ = line.I.filter({completedQ.contains($0.I)}).max(by: {$0.P < $1.P})?.P ?? Int.max
            return (B: line.B, I: line.I.map {(P: $0.P, C: ($0.P > highestQ && line.B), I: $0.I)})
        }
        // Flat and filter out Qs
        .flatMap { line -> [(B: Bool, C: Bool, P:Int, I: Intensity)] in
            line.I
                .map {(B: line.B, C: $0.C, P: $0.P, I: $0.I)}
                .filter {!completedQ.contains($0.I)}
        }
        // Sort by normal/low prio and offset of intensity within line
        .sorted { i1, i2 in
            if i1.B != i2.B {return i1.B}
            if i1.C != i2.C {return i1.C}
            return i1.P < i2.P
        }
        // De-duplicate
        .map {$0.I}
        .uniqued() ?? []
}

private func concat<E>(_ steps: [E]...) -> [E] {steps.flatMap {$0}}

extension Array {
    static func *(lhs: [Element], rhs: Int) -> [Element] {
        [[Element]](repeating: lhs, count: rhs).flatMap {$0}
    }
}

extension Collection where Self.Element: Collection {
    func forEachEach(soFar: [Self.Element.Element] = [], _ combination: ([Self.Element.Element]) -> Void) {
        if let first = self.first {
            first.forEach { element in
                self.dropFirst().forEachEach(soFar: soFar + [element], combination)
            }
        } else {
            combination(soFar)
        }
    }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
