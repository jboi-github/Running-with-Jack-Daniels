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
where E:CaseIterable, E:Identifiable, E:Nicable,
      E: Hashable, E.AllCases: RandomAccessCollection
{
    let title: String
    
    @ObservedObject var attribute: ProfileService.Attribute<E>
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
        .onAppear {attribute.onAppear()}
        .onDisappear {attribute.onDisappear()}
        .onChange(of: selection) {if attribute.value != $0 {attribute.onChange(to: $0)}}
        .onChange(of: attribute.value) {if selection != $0 {selection = $0 ?? E.allCases.first!}}
    }
}

#if DEBUG
struct EnumPickerView_Previews: PreviewProvider {
    enum X: String, Nicable, CaseIterable, Identifiable {
        case A, bdfdf, Cdf, Ddsd
        
        var id: RawValue {rawValue}
        func toNiceString() -> String {rawValue.capitalized}
    }

    static var previews: some View {
        EnumPickerView<X>(
            title: "Some loooong title. Really!",
            attribute: ProfileService.Attribute<EnumPickerView_Previews.X>(
                config: ProfileService.Attribute<EnumPickerView_Previews.X>.Config(
                    readFromStore: {(Date(), .bdfdf)},
                    readFromHealth: nil,
                    calculate: nil,
                    writeToStore: {log($0, $1)},
                    writeToHealth: nil)))
    }
}
#endif
