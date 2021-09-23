//
//  BleScanner.swift
//  Running-with-Jack-Daniels
//
//  Created by Jürgen Boiselle on 21.09.21.
//

import SwiftUI

struct BleScannerViewWrapper: View {
    @ObservedObject var scanner = BleScannerModel.sharedInstance
    
    var body: some View {
        BleScannerView(
            peripherals: scanner.peripherals.values.map {$0}.sorted {$0.rssi > $1.rssi},
            primary: scanner.primaryPeripheral)
    }
}

private struct BleScannerView: View {
    let peripherals: [BleScannerModel.Peripheral]
    let primary: UUID

    @State private var width0 = CGFloat.zero
    @State private var width1 = CGFloat.zero
    @State private var width2 = CGFloat.zero
    @State private var width3 = CGFloat.zero

    var body: some View {
        VStack {
            Text("Bluetooth Scanner")
                .font(.headline)
            ProgressView("scanning for heartrate devices").font(.subheadline)
            Divider()
            Spacer()
            List {
                Section(
                    header:
                        HStack {
                            Text("Device").font(.subheadline).alignedView(width: $width1)
                            Spacer()
                            Text("ignore").font(.subheadline).alignedView(width: $width3)
                        })
                {
                    ForEach(peripherals) { peripheral in
                        HStack {
                            Button {
                                BleScannerModel.sharedInstance.setPrimary(peripheral.id)
                                BleScannerModel.sharedInstance.setIgnore(peripheral.id, ignore: false)
                            } label: {
                                HStack {
                                    Text(Image(systemName: getHeart(peripheral, primary)))
                                        .alignedView(width: $width0)

                                    Text("\(peripheral.name)")
                                        .alignedView(width: $width1)

                                    Spacer()
                                    Text("\(peripheral.rssi, specifier: "%3.0f")")
                                        .font(.caption)
                                        .alignedView(width: $width2)
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button {
                                BleScannerModel.sharedInstance.setIgnore(
                                    peripheral.id,
                                    ignore: !peripheral.ignore)
                            } label: {
                                Text(Image(systemName: peripheral.ignore ? "nosign" : "rectangle"))
                                    .foregroundColor(peripheral.ignore ? Color(UIColor.systemRed) : .secondary)
                                    .alignedView(width: $width3)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(peripheral.id == primary)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
        .onAppear {BleScannerModel.sharedInstance.start()}
        .onDisappear {BleScannerModel.sharedInstance.stop()}
    }
    
    private func getHeart(_ peripheral: BleScannerModel.Peripheral, _ primary: UUID) -> String {
        if !peripheral.available {return "heart.slash"}
        if peripheral.id == primary {return "heart.fill"}
        return "heart"
    }
}

struct BleScannerView_Previews: PreviewProvider {
    static var previews: some View {
        BleScannerView(peripherals: [BleScannerModel.Peripheral](), primary: UUID())
    }
}
