//
//  ResetButton.swift
//  Run!
//
//  Created by Jürgen Boiselle on 20.11.21.
//

import SwiftUI

struct ResetButton<Value>: View {
    @ObservedObject var attribute: ProfileService.Attribute<Value>

    var body: some View {
        if attribute.source == .manually {
            Button {
                attribute.onReset()
            } label: {
                Text(Image(systemName: "delete.backward"))
                    .font(.callout)
                    .padding(6)
                    .background(
                        Color
                            .secondary
                            .colorInvert()
                            .clipShape(RoundedRectangle(cornerRadius: 6)))
            }
            .buttonStyle(BorderlessButtonStyle()) // Buttons in List-Rows are triggered all at once.
            .padding(.leading)
        }
    }
}

#if DEBUG
struct ResetButton_Previews: PreviewProvider {
    static var previews: some View {
        ResetButton<Date>(attribute: ProfileService.Attribute<Date>(
            config: ProfileService.Attribute<Date>.Config(
                readFromStore: {(Date(), Date())},
                readFromHealth: nil,
                calculate: nil,
                writeToStore: {log($0, $1)},
                writeToHealth: nil)))
    }
}
#endif
