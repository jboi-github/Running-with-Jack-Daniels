//
//  PlanProfileView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct PlanProfileView: View {
    @State private var size: CGSize = .zero
    @State private var limitSize: CGSize = .zero
    @ObservedObject private var hrLimits = ProfileService.sharedInstance.hrLimits
    
    @State private var angle: CGFloat = .pi / 4.0
    @State private var radius: CGFloat = 1
    
    var body: some View {
        List {
            Section("Profile\ncalculate heartrate limits") {
                EnumPickerView(title: "Biological Gender", attribute: ProfileService.sharedInstance.gender)
                DatePickerView(title: "Birthday", attribute: ProfileService.sharedInstance.birthday)
                NumberPickerView(
                    title: "Height [m]",
                    range: 1.0 ... 2.5,
                    step: 0.01,
                    specifier: "%5.2f",
                    toDouble: {$0 ?? .nan},
                    toValue: {$0.isFinite ? $0 : nil},
                    attribute: ProfileService.sharedInstance.height)
                NumberPickerView(
                    title: "Weight [kg]",
                    range: 40 ... 150,
                    step: 0.1,
                    specifier: "%4.1f",
                    toDouble: {$0 ?? .nan},
                    toValue: {$0.isFinite ? $0 : nil},
                    attribute: ProfileService.sharedInstance.weight)
            }
            Section("Heartrate\ncontrol over calculated limits") {
                NumberPickerView(
                    title: "HR max [bpm]",
                    range: 120 ... 250,
                    step: 1,
                    specifier: "%3.0f",
                    toDouble: {$0 == nil ? -1 : Double($0!)},
                    toValue: {($0.isFinite && $0 >= 0) ? Int($0) : nil},
                    attribute: ProfileService.sharedInstance.hrMax)
                NumberPickerView(
                    title: "HR resting [bpm]",
                    range: 30 ... 100,
                    step: 1,
                    specifier: "%3.0f",
                    toDouble: {$0 == nil ? -1 : Double($0!)},
                    toValue: {($0.isFinite && $0 >= 0) ? Int($0) : nil},
                    attribute: ProfileService.sharedInstance.hrResting)
            }
            ZStack {
                HrLimitsView(
                    hr: nil,
                    intensity: .Race,
                    intensities: hrLimits.value ?? [:])
                    .captureSize(in: $limitSize)
                HrLimitText(hr: hrLimits.value?[.Easy]?.lowerBound, angle: 85, inner: true, size: limitSize)
                HrLimitText(hr: hrLimits.value?[.Easy]?.upperBound, angle: 165, inner: true, size: limitSize)
                HrLimitText(hr: hrLimits.value?[.Marathon]?.upperBound, angle: 220, inner: false, size: limitSize)
                HrLimitText(hr: hrLimits.value?[.Threshold]?.lowerBound, angle: 200, inner: true, size: limitSize)
                HrLimitText(hr: hrLimits.value?[.Threshold]?.upperBound, angle: 260, inner: true, size: limitSize)
                HrLimitText(hr: hrLimits.value?[.Interval]?.lowerBound, angle: 230, inner: false, size: limitSize)
                HrLimitText(hr: hrLimits.value?[.Interval]?.upperBound, angle: 275, inner: false, size: limitSize)
            }
            .frame(height: size.height / 2)
        }
        .captureSize(in: $size)
    }
}

private struct HrLimitText: View {
    let hr: Int?
    let angle: CGFloat
    let inner: Bool
    let size: CGSize
    
    var body: some View {
        HrText(heartrate: hr ?? -1)
            .font(.caption)
            .offset(
                x: cos((angle + 135) * CGFloat.pi / 180) * min(size.height, size.width) * (inner ? 0.3 : 0.5),
                y: sin((angle + 135) * CGFloat.pi / 180) * min(size.height, size.width) * (inner ? 0.3 : 0.5))
    }
}

extension Gender: Nicable {
    func toNiceString() -> String {rawValue.localizedCapitalized}
}

#if DEBUG
struct PlanProfileView_Previews: PreviewProvider {
    static var previews: some View {
        PlanProfileView()
    }
}
#endif
