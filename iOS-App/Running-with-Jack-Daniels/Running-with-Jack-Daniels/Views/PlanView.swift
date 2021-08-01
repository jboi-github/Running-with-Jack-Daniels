//
//  PlanView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 18.07.21.
//

import SwiftUI

struct PlanView: View {
    @ObservedObject var birthday = Database.sharedInstance.birthday
    @ObservedObject var gender = Database.sharedInstance.gender
    @ObservedObject var weight = Database.sharedInstance.weight
    @ObservedObject var height = Database.sharedInstance.height
    @ObservedObject var hrMax = Database.sharedInstance.hrMax
    @ObservedObject var hrResting = Database.sharedInstance.hrResting
    @ObservedObject var hrLimits = Database.sharedInstance.hrLimits

    var bmi: String {
        Running_with_Jack_Daniels
            .bmi(weightKg: weight.value, heightM: height.value)
            .format("%.1f", ifNan: " - ")
    }
    
    var body: some View {
        List {
            Section(
                header:
                    HStack {
                        Text(Image(systemName: "person.fill")).font(.headline)
                        Text("You").font(.headline)
                        Spacer()
                        Text("BMI: \(bmi)").font(.caption)
                    })
            {
                DateInputView(title: "Your birthday:", value: birthday.bound, source: birthday.source)
                EnumInputView(title: "Your (biological) gender:", value: gender.bound, source: gender.source)
                NumberInputView(
                    title: "Your weight:", attribute: weight,
                    range: 45...120, step: 0.1, specifier: "%.1f kg",
                    minLabel: "45 kg", maxLabel: "120 kg")
                NumberInputView(
                    title: "Your height:", attribute: height,
                    range: 1.0...2.3, step: 0.01, specifier: "%.2f m",
                    minLabel: "1.0 m", maxLabel: "2.3 m")
                NumberInputView(
                    title: "Your resting HR:", attribute: hrResting,
                    range: 30...100, step: 1, specifier: "%3.0f bpm",
                    minLabel: "30 bpm", maxLabel: "100 bpm")
                NumberInputView(
                    title: "Your maximal HR:", attribute: hrMax,
                    range: 100...250, step: 1, specifier: "%3.0f bpm",
                    minLabel: "100 bpm", maxLabel: "250 bpm")
                HrView(limits: hrLimits.value, heartrate: nil)
            }
        }
        .padding()
        .onAppear {Database.sharedInstance.onAppear()}
        .onDisappear {Database.sharedInstance.onDisappear()}
        .animation(.default)
    }
}

private struct DateInputView: View {
    let title: String
    let value: Binding<Date>
    let source: Database.Source
    
    var body: some View {
        HStack {
            DatePicker(
                selection: value,
                in: ...Date(),
                displayedComponents: [.date])
            {
                Text(title).font(.caption)
            }
            Spacer()
            SourceView(source: source)
        }
        .padding()
    }
}

/// The constrain definition look odd, but all you have to define can be copied from Discussion section.
///
///     enum xyz: String, CaseIterable, Identifiable {
///         case ...
///         var id: String {self.rawValue}
///     }
///
private struct EnumInputView<E: RawRepresentable>: View
where E:CaseIterable, E:Identifiable, E: Hashable, E.RawValue == String, E.AllCases: RandomAccessCollection
{
    let title: String
    let value: Binding<E>
    let source: Database.Source

    var body: some View {
        VStack {
            HStack {
                Text(title).font(.caption)
                Spacer()
                SourceView(source: source)
            }
            Picker(selection: value, label: Text(title)) {
                ForEach(E.allCases) {Text("\($0.rawValue.capitalized)").tag($0)}
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
    }
}

private struct NumberInputView: View {
    let title: String
    @ObservedObject var attribute: Database.Attribute<Double>
    let range: ClosedRange<Double>
    let step: Double
    let specifier: String
    let minLabel: String
    let maxLabel: String
    
    var body: some View {
        VStack {
            HStack {
                Text(title).font(.caption)
                Spacer()
                SourceView(source: attribute.source)
            }
            HStack {
                Stepper(
                    value: attribute.bound,
                    in: range, step: step,
                    onEditingChanged: {_ in})
                {
                    Text("\(attribute.value.format(specifier, ifNan: " - "))").font(.callout)
                }
                if attribute.hasCalculator {
                    Button {
                        attribute.recalc(force: true)
                    } label: {
                        Text(Image(systemName: "function"))
                            .font(.body)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .foregroundColor(.gray)
                                    .opacity(0.25))
                    }
                }
            }
                
            Slider(
                value: attribute.bound,
                in: range, step: step,
                onEditingChanged: {_ in},
                minimumValueLabel: Text(minLabel).font(.caption).scaleEffect(0.75),
                maximumValueLabel: Text(maxLabel).font(.caption).scaleEffect(0.75))
            {
                Text(title).font(.caption)
            }
        }
        .padding()
    }
}

struct SourceView: View {
    let source: Database.Source
    
    var sourceImg: String {
        switch source {
        case .manual:
            return "hand.point.up.left"
        case .healthkit:
            return "heart"
        case .calculated:
            return "function"
        }
    }
    
    var sourceCol: Color {
        switch source {
        case .manual:
            return .blue
        case .healthkit:
            return .red
        case .calculated:
            return .black
        }
    }

    var body: some View {
        Text(Image(systemName: sourceImg))
            .font(.caption)
            .foregroundColor(sourceCol)
    }
}

struct PlanView_Previews: PreviewProvider {
    static var previews: some View {
        PlanView()
    }
}
