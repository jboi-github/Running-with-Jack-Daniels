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
        ScannerPeripheralListView(peripherals: scanner.peripherals.values.array())
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
                ForEach(peripherals) {
                    ScannerPeripheralOverviewView(peripheral: $0)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Bluetooth Scanner")
    }
}

/// Show RSSI, name, connection-status, primary and ignored, body location if available.
private struct ScannerPeripheralOverviewView: View {
    let peripheral: ScannerService.Peripheral
    @State var selection: Int = 1
    
    init(peripheral: ScannerService.Peripheral) {
        self.peripheral = peripheral
        
        if peripheral.isPrimary {
            selection = 0
        } else if peripheral.isIgnored {
            selection = 2
        } else {
            selection = 1
        }
    }
    
    var body: some View {
        HStack {
            VStack {
                PeripheralRssiView(rssi: peripheral.rssi)
                PeripheralStatusView(state: peripheral.peripheral?.state)
            }
            .font(.caption)
            VStack {
                Text("\(peripheral.peripheral?.name ?? peripheral.id.uuidString)")
                    .lineLimit(1)
                    .font(.callout)
                PrimaryIgnoredToggle(selection: $selection)
                    .font(.caption)
            }
            .layoutPriority(1)
            BodysensorLocationView(sensorLocation: peripheral.bodySensorLocation)
        }
        .padding()
        .onChange(of: selection) { [selection] newSelection in
            log(selection, newSelection)
            if selection == newSelection {return}

            if selection == 0 { // Was primary before
                PeripheralHandling.primaryUuid = nil
            } else if selection == 2 { // Was ignored before
                PeripheralHandling.ignoredUuids = PeripheralHandling.ignoredUuids.filter {$0 == peripheral.id}
            }
            
            if newSelection == 0 { // Is primary now
                PeripheralHandling.primaryUuid = peripheral.id
            } else if newSelection == 2 { // Is ignored now
                PeripheralHandling.ignoredUuids.append(peripheral.id)
            }
        }
    }
}

/// Show: name, uuid, rssi, isPrimary, isIgnored, connect status, body location (bigger), error if any, service uuids
private struct ScannerPeripheralDetailsView: View {
    let peripheral: ScannerService.Peripheral
    
    var body: some View {
        VStack {
            List {
                Section {
                    HStack {
                        PeripheralStatusView(state: peripheral.peripheral?.state)
                        Spacer()
                        Text("\(peripheral.id.uuidString)")
                    }
                    HStack {
                        PeripheralRssiView(rssi: peripheral.rssi)
                        Spacer()
                        Text("\(peripheral.rssi, specifier: "%4.1f")")
                    }
                    PrimaryIgnoredToggle(selection: .constant(peripheral.isPrimary ? 0 : (peripheral.isIgnored ? 2 : 1)))
                        .font(.caption)
                        .disabled(true)
                }
                Section {
                    if let services = peripheral.peripheral?.services, !services.isEmpty {
                        ForEach(services.map {$0.uuid.uuidString}) {
                            Text("\($0)")
                                .font(.caption)
                        }
                    } else {
                        Text("no services detected")
                    }
                }
            }
            Spacer()
            Text("\(peripheral.error?.localizedDescription ?? "")")
                .font(.callout)
                .foregroundColor(Color(UIColor.systemRed))
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(peripheral.peripheral?.name ?? peripheral.id.uuidString)
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
