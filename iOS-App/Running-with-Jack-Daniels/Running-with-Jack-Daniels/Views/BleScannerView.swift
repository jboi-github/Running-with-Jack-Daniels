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
            peripherals: scanner
                .peripherals
                .values
                .sorted {
                    Optional.lessThen(
                        lhs: $0.peripheral.rssi,
                        rhs: $1.peripheral.rssi,
                        isNilMax: false) {
                            $0.doubleValue < $1.doubleValue
                        }
                },
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
                    ForEach(peripherals) { p in
                        HStack {
                            Button {
                                BleScannerModel.sharedInstance.setPrimary(p.id)
                                BleScannerModel.sharedInstance.setIgnore(p.id, ignore: false)
                            } label: {
                                HStack {
                                    Text(Image(systemName: getHeart(p, primary)))
                                        .alignedView(width: $width0)

                                    Text("\(p.peripheral.name ?? "no-name")")
                                        .alignedView(width: $width1)

                                    Spacer()
                                    Text("\(p.peripheral.rssi?.doubleValue ?? .nan, specifier: "%3.0f")")
                                        .font(.caption)
                                        .alignedView(width: $width2)
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button {
                                BleScannerModel.sharedInstance.setIgnore(
                                    p.id,
                                    ignore: !p.ignore)
                            } label: {
                                Text(Image(systemName: p.ignore ? "nosign" : "rectangle"))
                                    .foregroundColor(p.ignore ? Color(UIColor.systemRed) : .secondary)
                                    .alignedView(width: $width3)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(p.id == primary)
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
        if peripheral.peripheral.state != .connected {return "heart.slash"}
        if peripheral.id == primary {return "heart.fill"}
        return "heart"
    }
}

struct BleScannerView_Previews: PreviewProvider {
    static var previews: some View {
        BleScannerView(peripherals: [BleScannerModel.Peripheral](), primary: UUID())
    }
}
