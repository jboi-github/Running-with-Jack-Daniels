//
//  PlanView.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 18.07.21.
//

import SwiftUI
import RunDatabaseKit
import RunFormulasKit

struct PlanView: View {
    @ObservedObject var birthday = Database.sharedInstance.birthday
    @ObservedObject var gender = Database.sharedInstance.gender
    @ObservedObject var weight = Database.sharedInstance.weight
    @ObservedObject var height = Database.sharedInstance.height
    @ObservedObject var hrMax = Database.sharedInstance.hrMax
    @ObservedObject var hrResting = Database.sharedInstance.hrResting
    @ObservedObject var hrLimits = Database.sharedInstance.hrLimits

    var bmi: String {
        RunFormulasKit.bmi(weightKg: weight.value, heightM: height.value).format("%.1f", ifNan: " - ")
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
                DateInputView(title: "Your birthday:", attribute: birthday, value: birthday.bound)
                EnumInputView(title: "Your (biological) gender:", attribute: gender, bound: gender.bound)
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
                HrView()
                    .padding()
            }
        }
        .padding()
        .onAppear {Database.sharedInstance.onAppear()}
        .onDisappear {Database.sharedInstance.onDisappear()}
    }
}

private struct DateInputView: View {
    let title: String
    let attribute: Database.Attribute<Date>
    let value: Binding<Date>
    
    var body: some View {
        VStack {
            HStack {
                Text(title).font(.caption)
                Spacer()
                SourceView(source: attribute.source)
            }
            HStack {
                DatePicker(
                    selection: value,
                    in: ...Date(),
                    displayedComponents: [.date])
                {
                    EmptyView()
                }

                if attribute.source == .manual {
                    Button {
                        attribute.reset()
                    } label: {
                        ResetLabel(source: .healthkit)
                    }
                }
            }
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
where E:Codable, E:CaseIterable,
      E:Identifiable, E: Hashable,
      E.RawValue == String,
      E.AllCases: RandomAccessCollection
{
    let title: String
    let attribute: Database.Attribute<E>
    let bound: Binding<E>

    var body: some View {
        VStack {
            HStack {
                Text(title).font(.caption)
                Spacer()
                SourceView(source: attribute.source)
            }
            HStack {
                Picker(selection: bound, label: Text(title)) {
                    ForEach(E.allCases) {Text("\($0.rawValue.capitalized)").tag($0)}
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if attribute.source == .manual {
                    Button {
                        attribute.reset()
                    } label: {
                        ResetLabel(source: .healthkit)
                    }
                }
            }
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
                if attribute.hasCalculator && attribute.source != .calculated {
                    Button {
                        attribute.recalc(force: true)
                    } label: {
                        ResetLabel(source: .calculated)
                    }
                } else if attribute.source == .manual {
                    Button {
                        attribute.reset()
                    } label: {
                        ResetLabel(source: .healthkit)
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

private struct SourceView: View {
    let source: Database.Source
    
    var sourceImg: String {
        switch source {
        case .manual:
            return "hand.point.up.left"
        case .healthkit:
            return "heart.fill"
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

private struct ResetLabel: View {
    let source: Database.Source
    
    var body: some View {
        Text(Image(systemName: "clear")).font(.body)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(.gray)
                    .opacity(0.25))
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        SourceView(source: source)
                            .padding(2)
                    }
                    Spacer()
                }
            )
    }
}

struct PlanView_Previews: PreviewProvider {
    static var previews: some View {
        PlanView()
    }
}
