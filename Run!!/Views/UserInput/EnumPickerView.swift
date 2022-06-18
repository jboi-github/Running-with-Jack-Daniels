//
//  EnumPickerView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 20.11.21.
//

import SwiftUI
import HealthKit

protocol Nicable {
    func toNiceString() -> String
}

struct EnumPickerView<E: RawRepresentable>: View
where E: CaseIterable, E: Identifiable, E: Nicable,
      E: Hashable, E.AllCases: RandomAccessCollection
{
    let title: String
    
    @ObservedObject var attribute: Profile.Attribute<E>
    @State private var selection: E = E.allCases.first!
    
    var body: some View {
        VStack {
            Text(title)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.tail)
            HStack {
                ResetButton(attribute: attribute)
                Spacer()
                Picker(title, selection: $selection) {
                    ForEach(E.allCases) { item in
                        Text("\(item.toNiceString())").tag(item)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                Spacer()
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
        .onChange(of: selection) {if attribute.value != $0 {attribute.onChange(to: $0)}}
        .onChange(of: attribute.value) {if selection != $0 {selection = $0 ?? E.allCases.first!}}
    }
}

#if DEBUG
struct EnumPickerView_Previews: PreviewProvider {
    enum TestTimeSeries: String, Nicable, CaseIterable, Identifiable {
        case a, bdfdf, cdf, ddsd
        
        var id: RawValue {rawValue}
        func toNiceString() -> String {rawValue.capitalized}
    }

    static var previews: some View {
        EnumPickerView<TestTimeSeries>(
            title: "Some loooong title. Really!",
            attribute: Profile.Attribute<EnumPickerView_Previews.TestTimeSeries>(
                config: Profile.Attribute<EnumPickerView_Previews.TestTimeSeries>.Config(
                    readFromStore: {(Date(), .bdfdf)},
                    readFromHealth: nil,
                    calculate: nil,
                    writeToStore: {log($0, $1)},
                    writeToHealth: nil)))
    }
}
#endif
