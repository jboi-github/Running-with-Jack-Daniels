//
//  NavigationView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

enum Picks: String, Nicable, CaseIterable, Identifiable {
    case first, Second, THIRD, OneMore
    
    var id: RawValue {rawValue}
    func toNiceString() -> String {rawValue.capitalized}
}

let intensities: [Intensity: Range<Int>] = [
    .Cold: 50..<75,
    .Easy: 75..<100,
    .Long: 75..<100,
    .Marathon: 100..<150,
    .Threshold: 150..<175,
    .Interval: 165..<220]

struct DP: ChartDataPoint {
    let classifier: String
    let x: Double
    let y: Double
    
    func makeBody(
        _ canvas: CGRect,
        _ pos: CGPoint,
        _ prevPos: CGPoint,
        _ nearestPos: CGPoint)
    -> some View
    {
        let dx = nearestPos.x - pos.x
        let dy = nearestPos.y - pos.y
        let diameter = sqrt(dx * dx + dy * dy)
        
        return Text("\(String(classifier.prefix(1)))")
            .frame(width: diameter, height: diameter)
            .foregroundColor(classifier == "Sinus" ? .green : .blue)
            .background(Circle().foregroundColor(classifier == "Sinus" ? .green : .blue).opacity(0.5))
            .offset(x: pos.x, y: pos.y)
    }
}

private let dps1 = stride(from: -10, to: 15, by: 1)
    .map {
        DP(
            classifier: "Sinus",
            x: Double($0),
            y: Double($0) * sin(Double($0) * .pi / 8))
    }
private let dps2 = stride(from: -10, to: 15, by: 1)
    .map {
        DP(
            classifier: "Cosinus",
            x: Double($0),
            y: Double($0) * cos(Double($0) * .pi / 8))
    }
private let preparedData = (dps1 + dps2).prepared(nx: 10, ny: 5)

struct GalleryView: View {
    let attribute1 = ProfileService.Attribute<Date>(
        config: ProfileService.Attribute<Date>.Config(
            readFromStore: {(Date(), Date())},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {log($0, $1)},
            writeToHealth: nil))
    
    let attribute2 = ProfileService.Attribute<Int>(
        config: ProfileService.Attribute<Int>.Config(
            readFromStore: {(Date(), 5)},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {log($0, $1)},
            writeToHealth: nil))
    
    let attributeDP1 = ProfileService.Attribute<Date>(
        config: ProfileService.Attribute<Date>.Config(
            readFromStore: {(Date(), Date())},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {log($0, $1)},
            writeToHealth: nil))
    
    let attributeDP2 = ProfileService.Attribute<Date>(
        config: ProfileService.Attribute<Date>.Config(
            readFromStore: {nil},
            readFromHealth: nil,
            calculate: {Date().advanced(by: 3*24*3600)},
            writeToStore: {log($0, $1)},
            writeToHealth: nil))
    
    let attributeDP3 = ProfileService.Attribute<Date>(
        config: ProfileService.Attribute<Date>.Config(
            readFromStore: {nil},
            readFromHealth: {$0(Date(), Date().advanced(by: 7*24*3600))},
            calculate: nil,
            writeToStore: {log($0, $1)},
            writeToHealth: nil))
    
    let attributeNP1 = ProfileService.Attribute<Double>(
        config: ProfileService.Attribute<Double>.Config(
            readFromStore: {(Date(), 13.0)},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {log($0, $1)},
            writeToHealth: nil))
    
    let attributeNP2 = ProfileService.Attribute<Int>(
        config: ProfileService.Attribute<Int>.Config(
            readFromStore: {(Date(), 13)},
            readFromHealth: nil,
            calculate: nil,
            writeToStore: {log($0, $1)},
            writeToHealth: nil))

    @State private var darkScheme: Bool = false
    @State private var hr: Double = 100
    
    var body: some View {
        VStack {
            Toggle("Dark Mode", isOn: $darkScheme)
                .padding()
            List {
                Section {
                    ChartView(
                        preparedData: preparedData,
                        xAxis: ChartAxisView(
                            line: Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(UIColor.systemGray)),
                            label: Text("Duration")
                                .font(.caption)
                                .foregroundColor(Color(UIColor.systemGray)),
                            axis: .X),
                        yAxis: ChartAxisView(
                            line: Rectangle()
                                .frame(width: 1)
                                .foregroundColor(Color(UIColor.systemGray)),
                            label: Text("Distance")
                                .font(.caption)
                                .foregroundColor(Color(UIColor.systemGray)),
                            axis: .Y),
                        xTick: { sz, _ in
                            Rectangle()
                                .frame(width: 1, height: sz.height)
                                .foregroundColor(Color(UIColor.systemGray4))
                        },
                        yTick: { sz, _ in
                            Rectangle()
                                .frame(width: sz.width, height: 1)
                                .foregroundColor(Color(UIColor.systemGray4))
                        })
                        .background(Color(UIColor.systemGray6))
                        .frame(width: 300, height: 300)
                    
                    RunStandardChart(data: preparedData, xLabel: "Duration", yLabel: "Distance")
                        .frame(width: 300, height: 300)
                }
                
                Section {
                    RunTotalsView(graphical: true, totals: [
                        TotalsService.Total(
                            activityType: .pause,
                            intensity: .Cold,
                            durationSec: 100,
                            distanceM: 0,
                            heartrateBpm: 100,
                            paceSecPerKm: .nan,
                            vdot: .nan),
                        TotalsService.Total(
                            activityType: .running,
                            intensity: .Easy,
                            durationSec: 500,
                            distanceM: 1400,
                            heartrateBpm: 150,
                            paceSecPerKm: 500 / 1.4,
                            vdot: 24),
                        TotalsService.Total(
                            activityType: .running,
                            intensity: .Marathon,
                            durationSec: 3500,
                            distanceM: 1300,
                            heartrateBpm: 160,
                            paceSecPerKm: 1400 / 1.4,
                            vdot: 34)
                    ])
                        .frame(width: 300, height: 400)
                    
                    RunTotalsView(graphical: false, totals: [
                        TotalsService.Total(
                            activityType: .pause,
                            intensity: .Cold,
                            durationSec: 100,
                            distanceM: 0,
                            heartrateBpm: 100,
                            paceSecPerKm: .nan,
                            vdot: .nan),
                        TotalsService.Total(
                            activityType: .running,
                            intensity: .Easy,
                            durationSec: 500,
                            distanceM: 1400,
                            heartrateBpm: 150,
                            paceSecPerKm: 500 / 1.4,
                            vdot: 24),
                        TotalsService.Total(
                            activityType: .running,
                            intensity: .Marathon,
                            durationSec: 3500,
                            distanceM: 1400,
                            heartrateBpm: 160,
                            paceSecPerKm: 1400 / 1.4,
                            vdot: 34)
                    ])
                }
                Section {
                    HStack {
                        Spacer()
                        RunStatusView(
                            aclStatus: .stopped,
                            bleStatus: .started(asOf: Date()),
                            gpsStatus: .notAuthorized(asOf: Date()),
                            intensity: .Marathon,
                            gpsPath: [],
                            hrGraph: [])
                    }
                }
                Section {
                    RunCurrentsView(
                        hr: 100,
                        intensity: .Easy,
                        intensities: [
                            .Cold: 50..<75,
                            .Easy: 75..<100,
                            .Long: 75..<100,
                            .Marathon: 100..<150,
                            .Threshold: 150..<175,
                            .Interval: 165..<220],
                        duration: 3600+550,
                        distance: 10400,
                        pace: 550,
                        vdot: 23.4,
                        activityType: .running)
                }
                Section {
                    VStack {
                        HrLimitsView(
                            hr: Int(hr),
                            intensity: intensities.first {$0.value.contains(Int(hr))}?.key ?? .Cold,
                            intensities: intensities)
                        Slider(value: $hr, in: 0...260)
                    }
                }
                .frame(height: 200)

                Section {
                    RunMapView(path: [])
                        .background(Color.primary.colorInvert())
                }
                .frame(height: 400)

                Section {
                    VStack {
                        EnumPickerView<Picks>(
                            title: "Another title",
                            attribute: ProfileService.Attribute<Picks>(
                                config: ProfileService.Attribute<Picks>.Config(
                                    readFromStore: {(Date(), .THIRD)},
                                    readFromHealth: nil,
                                    calculate: nil,
                                    writeToStore: {log($0, $1)},
                                    writeToHealth: nil)))
                    }
                    .border(Color.gray)
                    
                    VStack {
                        NumberPickerView(
                            title: "Another very long title, just to show ellispes.",
                            range: -10.0 ... +50.0,
                            step: 0.5,
                            specifier: "%3.1f",
                            toDouble: {$0 ?? .nan},
                            toValue: {$0.isFinite ? $0 : nil},
                            attribute: attributeNP1)
                        
                        NumberPickerView(
                            title: "Short title",
                            range: -10 ... +50,
                            step: 2,
                            specifier: "%3.0f",
                            toDouble: {$0 == nil ? -1 : Double($0!)},
                            toValue: {($0.isFinite && $0 >= 0) ? Int($0) : nil},
                            attribute: attributeNP2)
                    }
                    .border(Color.gray)

                    VStack {
                        DatePickerView(
                            title: "title with long name, isn't it?",
                            attribute: attributeDP1)

                        DatePickerView(
                            title: "title",
                            attribute: attributeDP2)

                        DatePickerView(
                            title: "title with long name, isn't it?",
                            attribute: attributeDP3)
                    }
                    .border(Color.gray)
                }
                
                Section {
                    VStack {
                        Group {
                            PaceText(paceSecPerKm: 100, short: true, max: 3600)
                            PaceText(paceSecPerKm: 100, short: false, max: 3600)
                            PaceText(paceSecPerKm: .nan, short: true, max: 3600)
                            PaceText(paceSecPerKm: .nan, short: false, max: 3600)
                            PaceText(paceSecPerKm: 0, short: true, max: 3600)
                            PaceText(paceSecPerKm: 0, short: false, max: 3600)
                        }
                        Group {
                            PaceText(paceSecPerKm: 3600, short: true, max: 3600)
                            PaceText(paceSecPerKm: 3600, short: false, max: 3600)
                            PaceText(paceSecPerKm: 3599, short: true, max: 3600)
                            PaceText(paceSecPerKm: 3599, short: false, max: 3600)
                            PaceText(paceSecPerKm: 3700, short: true, max: 3600)
                            PaceText(paceSecPerKm: 3700, short: false, max: 3600)
                        }
                    }
                    .padding()
                    .border(Color.gray)
                    VStack {
                        VdotText(vdot: .nan)
                        VdotText(vdot: 0)
                        VdotText(vdot: -1)
                        VdotText(vdot: 12.3)
                        VdotText(vdot: 2.3)
                        VdotText(vdot: 2.0)
                        VdotText(vdot: 12342.1)
                    }
                    .padding()
                    .border(Color.gray)
                    VStack {
                        HrText(heartrate: -1)
                        HrText(heartrate: 0)
                        HrText(heartrate: 10)
                        HrText(heartrate: 200)
                        HrText(heartrate: 300)
                    }
                    .padding()
                    .border(Color.gray)
                    VStack {
                        DistanceText(distance: .nan)
                        DistanceText(distance: -100)
                        DistanceText(distance: 0)
                        DistanceText(distance: 10)
                        DistanceText(distance: 1000)
                        DistanceText(distance: 5000)
                        DistanceText(distance: 5001)
                        DistanceText(distance: 7600)
                        DistanceText(distance: 42193)
                        DistanceText(distance: 1050050)
                    }
                    .padding()
                    .border(Color.gray)
                    VStack {
                        Group {
                            TimeText(time: .nan, short: true)
                            TimeText(time: .nan, short: false)
                            TimeText(time: -100, short: true)
                            TimeText(time: -100, short: false)
                            TimeText(time: 0, short: true)
                            TimeText(time: 0, short: false)
                            TimeText(time: 10.456, short: true)
                            TimeText(time: 10.456, short: false)
                            TimeText(time: 100, short: true)
                            TimeText(time: 100, short: false)
                        }
                        Group {
                            TimeText(time: 3599, short: true)
                            TimeText(time: 3599, short: false)
                            TimeText(time: 3600, short: true)
                            TimeText(time: 3600, short: false)
                            TimeText(time: 35990, short: true)
                            TimeText(time: 35990, short: false)
                            TimeText(time: 36000, short: true)
                            TimeText(time: 36000, short: false)
                        }
                    }
                    .padding()
                    .border(Color.gray)
                }
                
                Section {
                    VStack {
                        HStack {
                            MotionStatusView(status: .stopped, intensity: .Cold)
                            MotionStatusView(status: .stopped, intensity: .Easy)
                            MotionStatusView(status: .started(asOf: Date()), intensity: .Cold)
                            MotionStatusView(status: .started(asOf: Date()), intensity: .Easy)
                            MotionStatusView(status: .paused, intensity: .Cold)
                            MotionStatusView(status: .paused, intensity: .Easy)
                            MotionStatusView(status: .resumed, intensity: .Cold)
                            MotionStatusView(status: .resumed, intensity: .Easy)
                        }
                        HStack {
                            MotionStatusView(status: .notAuthorized(asOf: Date()), intensity: .Cold)
                            MotionStatusView(status: .notAuthorized(asOf: Date()), intensity: .Easy)
                            MotionStatusView(status: .nonRecoverableError(asOf: Date(), error: "X"), intensity: .Cold)
                            MotionStatusView(status: .nonRecoverableError(asOf: Date(), error: "X"), intensity: .Easy)
                        }
                    }
                    .padding()
                    .border(Color.gray)
                    VStack {
                        HStack {
                            GpsStatusView(status: .stopped, pathHasLength: false)
                            GpsStatusView(status: .stopped, pathHasLength: true)
                            GpsStatusView(status: .started(asOf: Date()), pathHasLength: false)
                            GpsStatusView(status: .started(asOf: Date()), pathHasLength: true)
                            GpsStatusView(status: .paused, pathHasLength: false)
                            GpsStatusView(status: .paused, pathHasLength: true)
                            GpsStatusView(status: .resumed, pathHasLength: false)
                            GpsStatusView(status: .resumed, pathHasLength: true)
                        }
                        HStack {
                            GpsStatusView(status: .notAuthorized(asOf: Date()), pathHasLength: false)
                            GpsStatusView(status: .notAuthorized(asOf: Date()), pathHasLength: true)
                            GpsStatusView(status: .nonRecoverableError(asOf: Date(), error: "X"), pathHasLength: false)
                            GpsStatusView(status: .nonRecoverableError(asOf: Date(), error: "X"), pathHasLength: true)
                        }
                    }
                    .padding()
                    .border(Color.gray)
                    VStack {
                        HStack {
                            BleHrStatusView(status: .stopped, graphHasLength: false)
                            BleHrStatusView(status: .stopped, graphHasLength: true)
                            BleHrStatusView(status: .started(asOf: Date()), graphHasLength: false)
                            BleHrStatusView(status: .started(asOf: Date()), graphHasLength: true)
                            BleHrStatusView(status: .paused, graphHasLength: false)
                            BleHrStatusView(status: .paused, graphHasLength: true)
                            BleHrStatusView(status: .resumed, graphHasLength: false)
                            BleHrStatusView(status: .resumed, graphHasLength: true)
                        }
                        HStack {
                            BleHrStatusView(status: .notAuthorized(asOf: Date()), graphHasLength: false)
                            BleHrStatusView(status: .notAuthorized(asOf: Date()), graphHasLength: true)
                            BleHrStatusView(status: .nonRecoverableError(asOf: Date(), error: "X"), graphHasLength: false)
                            BleHrStatusView(status: .nonRecoverableError(asOf: Date(), error: "X"), graphHasLength: true)
                            BleHrStatusView(status: .error(UUID(), "Y"), graphHasLength: false)
                            BleHrStatusView(status: .error(UUID(), "Y"), graphHasLength: true)
                        }
                    }
                    .padding()
                    .border(Color.gray)
                    HStack {
                        Text("I")
                            .font(.largeTitle)
                            .foregroundColor(Intensity.Cold.textColor)
                            .background(Intensity.Cold.color)
                        Text("E")
                            .font(.largeTitle)
                            .background(Intensity.Easy.color)
                            .foregroundColor(Intensity.Easy.textColor)
                        Text("L")
                            .font(.largeTitle)
                            .background(Intensity.Long.color)
                            .foregroundColor(Intensity.Long.textColor)
                        Text("M")
                            .font(.largeTitle)
                            .background(Intensity.Marathon.color)
                            .foregroundColor(Intensity.Marathon.textColor)
                        Text("T")
                            .font(.largeTitle)
                            .background(Intensity.Threshold.color)
                            .foregroundColor(Intensity.Threshold.textColor)
                        Text("I")
                            .font(.largeTitle)
                            .background(Intensity.Interval.color)
                            .foregroundColor(Intensity.Interval.textColor)
                        Text("R")
                            .font(.largeTitle)
                            .background(Intensity.Repetition.color)
                            .foregroundColor(Intensity.Repetition.textColor)
                        Text("C")
                            .font(.largeTitle)
                            .background(Intensity.Race.color)
                            .foregroundColor(Intensity.Race.textColor)
                    }
                    .padding()
                    .border(Color.gray)
                    HStack {
                        Text(Image(systemName: "stop.fill"))
                            .foregroundColor(Color(IsActiveProducer.ActivityType.pause.uiColor))
                        Text(Image(systemName: "stop.fill"))
                            .foregroundColor(Color(IsActiveProducer.ActivityType.walking.uiColor))
                        Text(Image(systemName: "stop.fill"))
                            .foregroundColor(Color(IsActiveProducer.ActivityType.running.uiColor))
                        Text(Image(systemName: "stop.fill"))
                            .foregroundColor(Color(IsActiveProducer.ActivityType.cycling.uiColor))
                        Text(Image(systemName: "stop.fill"))
                            .foregroundColor(Color(IsActiveProducer.ActivityType.unknown.uiColor))
                    }
                    .padding()
                    .border(Color.gray)
                    
                    VStack {
                        HStack {
                            MotionSymbolsView(activityType: .walking, intensity: .Cold)
                            MotionSymbolsView(activityType: .running, intensity: .Cold)
                            MotionSymbolsView(activityType: .cycling, intensity: .Cold)
                            MotionSymbolsView(activityType: .unknown, intensity: .Cold)
                        }
                        HStack {
                            MotionSymbolsView(activityType: .pause, intensity: .Cold)
                            MotionSymbolsView(activityType: .pause, intensity: .Easy)
                            MotionSymbolsView(activityType: .pause, intensity: .Long)
                            MotionSymbolsView(activityType: .pause, intensity: .Marathon)
                        }
                    }
                    .padding()
                    .border(Color.gray)
                    VStack {
                        HStack {
                            BatteryStatusView(status: -10)
                            BatteryStatusView(status: 0)
                            BatteryStatusView(status: 12)
                            BatteryStatusView(status: 13)
                        }
                        HStack {
                            BatteryStatusView(status: 25)
                            BatteryStatusView(status: 37)
                            BatteryStatusView(status: 38)
                            BatteryStatusView(status: 50)
                        }
                        HStack {
                            BatteryStatusView(status: 62)
                            BatteryStatusView(status: 63)
                            BatteryStatusView(status: 75)
                            BatteryStatusView(status: 87)
                        }
                        HStack {
                            BatteryStatusView(status: 88)
                            BatteryStatusView(status: 100)
                            BatteryStatusView(status: 1000)
                        }
                    }
                    .padding()
                    .border(Color.gray)
                    HStack {
                        SourceView<Int>(source: .manually)
                        SourceView<Int>(source: .store)
                        SourceView<Int>(source: .health)
                        SourceView<Int>(source: .calculated)
                    }
                    .padding()
                    .border(Color.gray)

                    HStack {
                        ResetButton<Date>(attribute: attribute1)
                        ResetButton<Int>(attribute: attribute2)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            attribute1.onChange(to: Date().advanced(by: 3*24*3600))
                            attribute2.onChange(to: 10)
                        }
                    }
                    .padding()
                    .border(Color.gray)
                }
                Text("--- The End ---")
            }
            .listStyle(PlainListStyle())
            .font(.caption)
            .animation(.default)
            .colorScheme(darkScheme ? .dark : .light)
        }
    }
}

#if DEBUG
struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView()
    }
}
#endif
