//
//  RunningFormulas.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 16.06.21.
//

import Foundation

/// A collection of functions to implement Jack Daniels running formulas. All functions are stateless by design.

public func bmi(weightKg: Double, heightM: Double) -> Double {weightKg / (heightM * heightM)}

/// Max Heartate by WINFRIED SPANAUS: (Male: 223 - 0.9 x age), (Female: 226 - 0.9 x age)
/// - Parameter birthday: Birthday to calculate current age.
/// - Parameter gender: male or female. This is the biological gender.
/// - Returns: A rough estimation of max heartrate. `nil`, if gender is `.none`
public func hrMaxBpm(birthday: Date, gender: Gender) -> Int? {
    guard gender != .other else {return nil}

    let age = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year!
    let maxHr = (gender == .male ? 223.0 : 226.0) - 0.9 * Double(age) + 0.5
    return maxHr.isFinite ? Int(maxHr) : nil
}

/// Max Heartate by SALLY EDWARDS: (Male: 214 - 0.5 x age - 0.11 x weight), (Female: 210 - 0.5 x age - 0.11 x weight)
/// - Parameter birthday: Birthday to calculate current age.
/// - Parameter gender: male or female. This is the biological gender.
/// - Parameter weightKg: current weight in kg
/// - Returns: A rough estimation of max heartrate. `nil`, if gender is `.none`
public func hrMaxBpm(birthday: Date, gender: Gender, weightKg: Double) -> Int? {
    guard gender != .other else {return nil}

    let age = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year!
    let maxHr = (gender == .male ? 214.0 : 210.0) - 0.5 * Double(age) - 0.11 * weightKg + 0.5
    return maxHr.isFinite ? Int(maxHr) : nil
}

public func hrLimits(hrMaxBpm: Int, restingHrBpm: Int = 0) -> [Intensity : ClosedRange<Int>] {
    Intensity
        .allCases
        .compactMap { (intensity: Intensity) -> (intensity: Intensity, lower: Int, upper: Int)? in
            if let percent = intensity.getHrPercent() {
                let lower = percent.lowerBound * Double(hrMaxBpm - restingHrBpm) + Double(restingHrBpm)
                let upper = percent.upperBound * Double(hrMaxBpm - restingHrBpm) + Double(restingHrBpm)
                return (intensity: intensity, lower: Int(lower + 0.5), upper: Int(upper + 0.5))
            } else {
                return nil
            }
        }
        .reduce(into: [:]) { dict, item in
            dict[item.intensity] = (item.lower...item.upper)
        }
}

public enum Intensity: String, CaseIterable, Identifiable, Codable {
    case Cold, Easy, Long, Marathon, Threshold, Interval, Repetition, Race
    
    public var id: String {rawValue}

    func getHrPercent() -> ClosedRange<Double>? {
        switch self {
        case .Cold:
            return 0...0.65
        case .Easy:
            return 0.65...0.80
        case .Long:
            return 0.65...0.80
        case .Marathon:
            return 0.80...0.90
        case .Threshold:
            return 0.88...0.98 // Original ...0.92
        case .Interval:
            return 0.92...1.0 // Original 0.98...
        case .Repetition:
            return nil
        case .Race:
            return nil
        }
    }
    
    public func getHrLimit(hrMaxBpm: Int, restingBpm: Int = 0) -> ClosedRange<Int>? {
        guard let hrPercent = getHrPercent() else {return nil}
        
        let l = hrPercent.lowerBound * Double(hrMaxBpm)
            + (1.0 - hrPercent.lowerBound) * Double(restingBpm)
        let u = hrPercent.upperBound * Double(hrMaxBpm)
            + (1.0 - hrPercent.upperBound) * Double(restingBpm)
        
        return Int(l + 0.5) ... Int(u + 0.5)
    }
    
    func getVdotPercent() -> ClosedRange<Double> {
        switch self {
        case .Cold:
            return 0...0.59
        case .Easy:
            return 0.59...0.74
        case .Long:
            return 0.59...0.74
        case .Marathon:
            return 0.75...0.84
        case .Threshold:
            return 0.83...0.88
        case .Interval:
            return 0.95...1.0
        case .Repetition:
            return 1.05...1.2
        case .Race:
            return 1.0...1.0
        }
    }
}

public enum Gender: String, Codable, CaseIterable, Identifiable {
    case male, female, other
    public var id: String {self.rawValue}
}

private let weeksOffAdjustment = [
    0: 1.0,
    1: 0.994,
    2: 0.973,
    3: 0.952,
    4: 0.931,
    5: 0.910,
    6: 0.889,
    7: 0.868,
    8: 0.847,
    9: 0.826,
    10: 0.805,
    -1: 0.800,
]

/// Calculate along Jack Daniels/Gilbert vdot.
/// - Parameters:
///   - vdot: vdot as calcuated from recent achievements or estimated from training paces
///   - percent: as value betwenn 0..1
/// - Returns: pace in seconds per km
public func pace4VdotPercent(vdot: Double, percent: Double) -> TimeInterval {
    let vo2 = vdot * percent
    let q = -(vo2 + 4.6) / 0.000104
    let p2 = 0.5 * 0.182258 / 0.000104
    
    return 60000.0 / (-p2 + sqrt(p2*p2 - q))
}

/// Calculate along Jack Daniels/Gilbert vdot.
/// - Parameters:
///   - paceSecPerKm: pace in seconds per km
///   - percent: as value between 0..1
/// - Returns: pace in seconds per km
public func vdot4PacePercent(paceSecPerKm: TimeInterval, percent: Double) -> Double {
    let v = 60000.0 / paceSecPerKm
    let vo2 = -4.60 + 0.182258 * v + 0.000104 * v * v

    return vo2 / percent
}

/// Calculate along Jack Daniels/Gilbert vdot.
/// - Parameters:
///   - distanceM: distance in meter
///   - timeSec: time in seconds
/// - Returns: vdot from distance and time
public func vdot4DistTime(distanceM: Double, timeSec: TimeInterval) -> Double {
    let timeMinD = Double(timeSec) / 60.0
    let v = Double(distanceM) / timeMinD
    
    let percent_max = 0.8 + 0.1894393 * exp(-0.012778 * timeMinD) + 0.2989558 * exp(-0.1932605 * timeMinD)
    let vo2 = -4.60 + 0.182258 * v + 0.000104 * v * v
    
    return vo2 / percent_max
}

/// Calculate along Jack Daniels/Gilbert vdot.
/// - Parameters:
///   - vdot: vdot as calcuated from recent achievements or estimated from training paces
///   - timeSec: time in seconds
/// - Returns: distance for vdot and time in meter
public func dist4VdotTime(vdot: Double, timeSec: TimeInterval) -> Double {
    let timeMinD = Double(timeSec) / 60.0
    let percent = 0.8 + 0.1894393 * exp(-0.012778 * timeMinD) + 0.2989558 * exp(-0.1932605 * timeMinD)
    
    let vo2 = vdot * percent
    let q = -(vo2 + 4.6) / 0.000104
    let p2 = 0.5 * 0.182258 / 0.000104
    
    return (-p2 + sqrt(p2*p2 - q)) * timeMinD
}

/// Calculate along Jack Daniels/Gilbert vdot.
/// - Parameters:
///   - vdot: vdot as calcuated from recent achievements or estimated from training paces
///   - distanceM: distance in meter
/// - Returns: time in seconds for given distance and vdot
public func time4VdotDist(vdot: Double, distanceM: Double) -> TimeInterval {
    // Define starting point
    var lowerTime = distanceM * pace4VdotPercent(vdot: vdot, percent: 2.0) / 1000 - 1 // @ 200%
    var upperTime = distanceM * pace4VdotPercent(vdot: vdot, percent: 0.5) / 1000 + 1 // @ 50%, which is < Easy
    var midTime: TimeInterval {(lowerTime + upperTime) / 2}
    
    // Define approach constant
    let epsilon = 0.05
    var maxIterations = 10

    while maxIterations > 0 {
        let estimatedVdot = vdot4DistTime(distanceM: distanceM, timeSec: midTime)
        if estimatedVdot > vdot + epsilon {
            lowerTime = midTime
        } else if estimatedVdot < vdot - epsilon {
            upperTime = midTime
        } else {
            break
        }
        maxIterations -= 1
    }
    return (lowerTime + upperTime) / 2
}

/// Estimate time to be reached for a race.
/// - Parameters:
///   - vdot: vdot as estimated or calculated.
///   - distanceM: distance of the race in meter.
/// - Returns: time in seconds for the full distance of the race.
public func planRace(vdot: Double, distanceM: Double) -> TimeInterval {
    time4VdotDist(vdot: vdot, distanceM: distanceM)
}

/// Get all paces for a training.
/// - Parameter vdot: vdot as estimated or calculated.
/// - Returns: for each intensity the lower and upper pace limit in seconds per km.
public func planTraining(vdot: Double) -> [Intensity : (lower: TimeInterval, upper: TimeInterval)] {
    let pEasy = Intensity.Easy.getVdotPercent()
    let pLong = Intensity.Long.getVdotPercent()
    let pThreshold = Intensity.Threshold.getVdotPercent()
    let pInterval = Intensity.Interval.getVdotPercent()
    let pRepetitions = Intensity.Repetition.getVdotPercent()

    return [
        .Easy:(
            lower: pace4VdotPercent(vdot: vdot, percent: pEasy.lowerBound),
            upper: pace4VdotPercent(vdot: vdot, percent: pEasy.upperBound)),
        .Long:(
            lower: pace4VdotPercent(vdot: vdot, percent: pLong.lowerBound),
            upper: pace4VdotPercent(vdot: vdot, percent: pLong.upperBound)),
        .Threshold:(
            lower: pace4VdotPercent(vdot: vdot, percent: pThreshold.lowerBound),
            upper: pace4VdotPercent(vdot: vdot, percent: pThreshold.upperBound)),
        .Interval:(
            lower: pace4VdotPercent(vdot: vdot, percent: pInterval.lowerBound),
            upper: pace4VdotPercent(vdot: vdot, percent: pInterval.upperBound)),
        .Repetition:(
            lower: pace4VdotPercent(vdot: vdot, percent: pRepetitions.lowerBound),
            upper: pace4VdotPercent(vdot: vdot, percent: pRepetitions.upperBound))
    ]
}

/// Estimate vdot for current heartrate and pace.
/// - Parameters:
///   - hrBpm: Current heartrate during training in beats per minute.
///   - hrMaxBpm: Max heartrate in beats per minute.
///   - paceSecPerKm: Current pace in seconds per km.
/// - Returns: vdot, estimated from hr% into vdot% of training intensity and together with pace into vdot. Return nil for any value out of range.
public func train(hrBpm: Int, hrMaxBpm: Int, restingBpm: Int = 0, paceSecPerKm: TimeInterval) -> Double? {
    func hrPercent2vdotPercent(
        hrPercent: Double,
        lowerHrPercent: Double,
        upperHrPercent: Double,
        lowerVdotPercent: Double,
        upperVdotPercent: Double) -> Double?
    {
        let p = (hrPercent - lowerHrPercent) / (upperHrPercent - lowerHrPercent)
        guard (0...1).contains(p) else {return nil}

        // Linear interpolation of values
        return lowerVdotPercent + (upperVdotPercent - lowerVdotPercent) * p
    }
    
    let hrPercent = Double(hrBpm - restingBpm) / Double(hrMaxBpm - restingBpm)
    
    if let percent = hrPercent2vdotPercent(
        hrPercent: hrPercent,
        lowerHrPercent: Intensity.Easy.getHrPercent()!.lowerBound,
        upperHrPercent: Intensity.Easy.getHrPercent()!.upperBound,
        lowerVdotPercent: Intensity.Easy.getVdotPercent().lowerBound,
        upperVdotPercent: Intensity.Easy.getVdotPercent().upperBound)
    {
        return vdot4PacePercent(paceSecPerKm: paceSecPerKm, percent: percent)
    }
    if let percent = hrPercent2vdotPercent(
        hrPercent: hrPercent,
        lowerHrPercent: Intensity.Threshold.getHrPercent()!.lowerBound,
        upperHrPercent: Intensity.Threshold.getHrPercent()!.upperBound,
        lowerVdotPercent: Intensity.Threshold.getVdotPercent().lowerBound,
        upperVdotPercent: Intensity.Threshold.getVdotPercent().upperBound)
    {
        return vdot4PacePercent(paceSecPerKm: paceSecPerKm, percent: percent)
    }
    if let percent = hrPercent2vdotPercent(
        hrPercent: hrPercent,
        lowerHrPercent: Intensity.Marathon.getHrPercent()!.lowerBound,
        upperHrPercent: Intensity.Marathon.getHrPercent()!.upperBound,
        lowerVdotPercent: Intensity.Marathon.getVdotPercent().lowerBound,
        upperVdotPercent: Intensity.Marathon.getVdotPercent().upperBound)
    {
        return vdot4PacePercent(paceSecPerKm: paceSecPerKm, percent: percent)
    }
    if let percent = hrPercent2vdotPercent(
        hrPercent: hrPercent,
        lowerHrPercent: Intensity.Interval.getHrPercent()!.lowerBound,
        upperHrPercent: Intensity.Interval.getHrPercent()!.upperBound,
        lowerVdotPercent: Intensity.Interval.getVdotPercent().lowerBound,
        upperVdotPercent: Intensity.Interval.getVdotPercent().upperBound)
    {
        return vdot4PacePercent(paceSecPerKm: paceSecPerKm, percent: percent)
    }
    return nil
}

/// Calcuate vdot out of a recently achieved race time.
/// - Parameters:
///   - distanceM: Meters of distance of the race.
///   - timeSec: time achieved in seconds.
/// - Returns: vdot calculated out of the achieved race time.
public func vdot4Race(distanceM: Double, timeSec: TimeInterval) -> Double {
    return vdot4DistTime(distanceM: distanceM, timeSec: timeSec)
}

/// Adjust vdot for time off and change in weight.
/// - Parameters:
///   - vdotAtStart: vdot as it was calculated, when the time off period started.
///   - timeOffStart: Date, when time off started.
///   - timeOffEnd: Date, when time off ended. Defaults to today.
///   - weightKgAtStart: weight in kilogram at start of time off. Defaults to NaN.
///   - weightKgAtEnd: weight in kilogram at end of time off. Defaults to NaN.
/// - Returns: Adjusted vdot for weeks of time off and change in weight. If one of the weights is NaN, it is considered as unchanged.
public func vdot4TimeOff(
    vdotAtStart: Double,
    timeOffStart: Date, timeOffEnd: Date = Date(),
    weightAtStart: Double = Double.nan, weightAtEnd: Double = Double.nan) -> Double
{
    // Adjust for weight
    let weightAdjustment = (weightAtStart.isNaN || weightAtEnd.isNaN) ? 1.0 : weightAtStart / weightAtEnd
    
    // Adjust for time off
    var weeksOff = Calendar.current.dateComponents([.day], from: timeOffStart, to: timeOffEnd).day! / 7
    if weeksOff < 0 {weeksOff = 0}
    if weeksOff > weeksOffAdjustment.keys.max()! {weeksOff = -1}
    
    return vdotAtStart * (weeksOffAdjustment[weeksOff] ?? 1.0) * weightAdjustment
}

/// Get intensity for heartrate percent and previous intensity.
/// - Parameters:
///   - hrBpm: Current heartrate during training in beats per minute.
///   - hrMaxBpm: Max heartrate in beats per minute.
///   - restingBpm: Resting heartrate if known, Otherwise defaults to 0.
///   - prevIntensity: previous intensity. Nil, if no previous intensity exists or was a pause.
/// - Returns:
///     - nil, if heartrate is below easy-limits.
///     - The corresponding intensity between easy and interval, if uniquely identifiable.
///     - repetition, if hr is above interval limit.
///     - If hr is in the overlap between marathon and threshold, the intensity which is closer to the previous intensity is returned.
///     - If hr is in the gep between threshold and interval, the intensity which is closer to the previous intensity is returned.
public func intensity4Hr(hrBpm: Int, hrMaxBpm: Int, restingBpm: Int = 0, prevHrBpm: Int?) -> Intensity {
    let hrPercent = Double(hrBpm - restingBpm) / Double(hrMaxBpm - restingBpm)

    let intensities = Intensity
        .allCases
        .filter {$0.getHrPercent()?.contains(hrPercent) ?? false}
    
    if intensities.isEmpty {
        return .Repetition
    } else {
        return (prevHrBpm ?? 0) < hrBpm ? intensities.first! : intensities.last!
    }
}

/*
 Plan Workout -> (last vdot, last training day (tiem off, weight change), %Easy this week)
    - Paces
 */
