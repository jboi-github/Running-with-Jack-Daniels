//
//  NumberPickerView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

struct NumberPickerView<Value: Equatable>: View {
    let title: String
    let range: ClosedRange<Double>
    let step: Double
    let specifier: String
    let toDouble: (Value?) -> Double
    let toValue: (Double) -> Value?

    @ObservedObject var attribute: ProfileService.Attribute<Value>
    @State private var selection: Double = .nan

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(title)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
            }
            
            HStack {
                ResetButton(attribute: attribute)
                Stepper(
                    value: $selection,
                    in: range, step: step,
                    onEditingChanged: {_ in})
                {
                    Text("\(selection, specifier: specifier)")
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.horizontal)
            }

            Slider(
                value: $selection,
                in: range, step: step,
                onEditingChanged: {_ in},
                minimumValueLabel:
                    Text("\(range.lowerBound, specifier: specifier)")
                        .font(.caption)
                        .scaleEffect(0.75),
                maximumValueLabel:
                    Text("\(range.upperBound, specifier: specifier)")
                        .font(.caption)
                        .scaleEffect(0.75))
            {
                EmptyView()
            }
        }
        .background(
            VStack {
                HStack {
                    Spacer()
                    SourceView(source: attribute.source).font(.caption)
                }
                Spacer()
            }
        )
        .animation(.default, value: attribute.source)
        .onAppear {attribute.onAppear()}
        .onDisappear {attribute.onDisappear()}
        .onChange(of: selection) {
            if attribute.value != toValue($0) {attribute.onChange(to: toValue($0))}
        }
        .onReceive(attribute.$value, perform: {
            if selection != toDouble($0) {selection = toDouble($0)}
        })
    }
}

#if DEBUG
struct NumberPickerView_Previews: PreviewProvider {
    static var previews: some View {
        NumberPickerView(
            title: "Another very long title, just to show ellispes.",
            range: -10.0 ... +50.0,
            step: 5.0,
            specifier: "%3.1f",
            toDouble: {$0 ?? .nan},
            toValue: {$0},
            attribute: ProfileService.Attribute<Double>(
                config: ProfileService.Attribute<Double>.Config(
                    readFromStore: {(Date(), 13.0)},
                    readFromHealth: nil,
                    calculate: nil,
                    writeToStore: {log($0, $1)},
                    writeToHealth: nil)))
    }
}
#endif
