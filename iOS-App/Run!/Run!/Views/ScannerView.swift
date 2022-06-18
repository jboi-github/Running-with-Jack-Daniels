//
//  ScannerView.swift
//  Run!
//
//  Created by Jürgen Boiselle on 02.11.21.
//

import SwiftUI
import CoreBluetooth

struct ScannerView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var scanner = ScannerService.sharedInstance
    
    var body: some View {
        ScannerPeripheralListView(peripherals: ScannerService.sort(peripherals: scanner.peripherals))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ScannerToolbarView(
                    bleStatus: scanner.status,
                    peripheralsFound: !scanner.peripherals.isEmpty)
            }
            .onAppear {
                log("start ScannerService")
                ScannerService.sharedInstance.start(
                    producer: BleProducer.sharedInstance,
                    asOf: Date())
            }
            .onDisappear {
                log("stop ScannerService")
                ScannerService.sharedInstance.stop()
            }
            .onChange(of: scenePhase) {
                switch $0 {
                case .active:
                    log("resume ScannerService")
                    ScannerService.sharedInstance.resume()
                case .inactive:
                    log("pause ScannerService")
                    ScannerService.sharedInstance.pause()
                default:
                    log("no action necessary")
                }
            }
    }
}

private struct ScannerPeripheralListView: View {
    let peripherals: [ScannerService.Peripheral]

    var body: some View {
        List {
            if peripherals.isEmpty {
                Text("no devices found")
            } else {
                ForEach(peripherals) { peripheral in
                    Section {
                        ScannerPeripheralView(peripheral: peripheral)                }
                    }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Bluetooth Scanner")
    }
}

/// Show RSSI, name, connection-status, primary and ignored, body location if available.
private struct ScannerPeripheralView: View {
    let peripheral: ScannerService.Peripheral
    @State var selection: Int = 1
    @State private var size = CGSize.zero
    
    var body: some View {
        VStack {
            HStack {
                BodysensorLocationView(sensorLocation: peripheral.bodySensorLocation)
                    .padding(.vertical)
                    .frame(width: size.width / 4)
                Spacer()
                VStack {
                    HStack {
                        Text("\(peripheral.peripheral?.name ?? peripheral.id.uuidString)")
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .font(.callout)
                        Spacer()
                        if let timestamp = peripheral.heartrate?.timestamp {
                            Text(timestamp.formatted(date: .omitted, time: .standard))
                        }
                    }
                    Spacer()
                    HStack {
                        PeripheralRssiView(rssi: peripheral.rssi)
                        Spacer()
                        PeripheralStatusView(state: peripheral.peripheral?.state)
                        Spacer()
                        if let hr = peripheral.heartrate?.heartrate {
                            HStack {
                                HrText(heartrate: hr)
                                Text("bpm")
                            }
                        }
                    }
                    HStack {
                        Text("\(peripheral.id)")
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        SkinContactedView(skinIsContacted: peripheral.heartrate?.skinIsContacted)
                        Spacer()
                        Text("\(peripheral.heartrate?.energyExpended ?? -1)")
                    }
                    Spacer()
                    PrimaryIgnoredToggle(selection: $selection)
                }
            }
            .font(.caption)
            Spacer()
            Text("\(peripheral.error?.localizedDescription ?? "")")
                .font(.callout)
                .foregroundColor(Color(UIColor.systemRed))
        }
        .padding()
        .captureSize(in: $size)
        .onAppear {
            if peripheral.isPrimary {
                selection = 0
            } else if peripheral.isIgnored {
                selection = 2
            } else {
                selection = 1
            }
        }
        .onChange(of: selection) { [selection] newSelection in
            log(selection, newSelection)
            if selection == newSelection {return}

            if selection == 0 { // Was primary before
                PeripheralHandling.primaryUuid = nil
            } else if selection == 2 { // Was ignored before
                PeripheralHandling.ignoredUuids = PeripheralHandling.ignoredUuids.filter {$0 != peripheral.id}
            }
            
            if newSelection == 0 { // Is primary now
                PeripheralHandling.primaryUuid = peripheral.id
            } else if newSelection == 2 { // Is ignored now
                PeripheralHandling.ignoredUuids.append(peripheral.id)
            }
        }
    }
}

private struct ScannerToolbarView: View {
    let bleStatus: BleProducer.Status
    let peripheralsFound: Bool
    
    var body: some View {
        HStack {
            if shouldShowProgress {ProgressView()}
            
            Image(systemName: "gear")
                .foregroundColor(.accentColor)
            
            BleHrStatusView(status: bleStatus, graphHasLength: peripheralsFound)
                .scaleEffect(0.75)
        }
        .font(.callout)
        .padding(.horizontal)
        .onTapGesture {
            guard let url = URL(string: UIApplication.openSettingsURLString) else {return}
            UIApplication.shared.open(url)
        }
    }
    
    private var shouldShowProgress: Bool {
        switch bleStatus {
        case .started(asOf: _):
            return true
        case .resumed:
            return true
        default:
            return false
        }
    }
}

#if DEBUG
struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUI.NavigationView {
            ScannerView()
        }
    }
}
#endif
