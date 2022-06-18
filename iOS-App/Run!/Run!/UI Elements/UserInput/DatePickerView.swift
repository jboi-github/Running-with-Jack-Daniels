//
//  DatePickerView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI

/**
What it shows:
 - A title and a date-picker
 - The source, where the data is taken from
 - A reset-button
 Functions:
 - Alow changing value manually by picking new date
 - Reset to value at beginning
 - call on appear and on disappear
 */
struct DatePickerView: View {
    let title: String
    
    @ObservedObject var attribute: ProfileService.Attribute<Date>
    @State private var selection: Date = Date()
    
    var body: some View {
        HStack {
            ResetButton(attribute: attribute)

            DatePicker(
                selection: $selection,
                displayedComponents: .date) {
                    Text(title)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding()
                .background(
                    VStack {
                        HStack {
                            Spacer()
                            SourceView(source: attribute.source).font(.caption)
                        }
                        Spacer()
                    }
                )
        }
        .animation(.default, value: attribute.source)
        .onAppear {attribute.onAppear()}
        .onDisappear {attribute.onDisappear()}
        .onChange(of: selection) {if attribute.value != $0 {attribute.onChange(to: $0)}}
        .onChange(of: attribute.value ?? .distantPast) {if selection != $0 {selection = $0}}
    }
}

#if DEBUG
struct DatePickerView_Previews: PreviewProvider {
    static var previews: some View {
        DatePickerView(
            title: "title with long name, isn't it?",
            attribute: ProfileService.Attribute<Date>(
                config: ProfileService.Attribute<Date>.Config(
                    readFromStore: {(Date(), Date())},
                    readFromHealth: nil,
                    calculate: nil,
                    writeToStore: {log($0, $1)},
                    writeToHealth: nil)))
    }
}
#endif
