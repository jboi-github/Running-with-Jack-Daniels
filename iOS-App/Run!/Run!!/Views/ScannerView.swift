//
//  ScannerView.swift
//  Run!!
//
//  Created by Jürgen Boiselle on 12.03.22.
//

import SwiftUI
import CoreBluetooth

struct ScannerView: View {
    @State private var scanner = ScannerClient()
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) {_ in
            VStack(spacing: 0) {
                ScannerToolbarView(
                    scnStatus: scanner.status,
                    peripheralsFound: !scanner.peripherals.isEmpty)
                    .frame(alignment: .topTrailing)
                ScannerPeripheralListView(peripherals: scanner.sorted)
                    .refreshable {
                        log("restart scanner")
                        scanner.stop(asOf: .now)
                        scanner.start(asOf: .now)
                    }
            }
        }
        .onAppear {
            log("start scanner")
            scanner.start(asOf: .now)
        }
        .onDisappear {
            log("stop scanner")
            scanner.stop(asOf: .now)
        }
    }
}

private struct ScannerPeripheralListView: View {
    let peripherals: [ScannerClient.Peripheral]

    var body: some View {
        List {
            if peripherals.isEmpty {
                Text("no devices found")
            } else {
                ForEach(peripherals) { peripheral in
                    Section {
                        ScannerPeripheralView(peripheral: peripheral)
                    }
                }
            }
        }
    }
}

/// Show RSSI, name, connection-status, primary and ignored, body location if available.
private struct ScannerPeripheralView: View {
    let peripheral: ScannerClient.Peripheral
    @State private var selection: Int = 1
    
    var body: some View {
        VStack {
            HStack {
                BodysensorLocationView(sensorLocation: peripheral.bodySensorLocation)
                    .font(.largeTitle)
                VStack {
                    Text("\(peripheral.peripheral?.name ?? peripheral.id.uuidString)")
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .font(.headline)
                    Divider()
                    HStack {
                        PeripheralRssiView(rssi: peripheral.rssi)
                        Spacer()
                        PeripheralStatusView(state: PeripheralEvent.State(rawValue: peripheral.peripheral?.state.rawValue ?? 0) ?? .disconnected)
                        Spacer()
                        BatteryStatusView(status: peripheral.batteryLevel)
                    }
                    if let heartrate = peripheral.heartrate {
                        HStack(spacing: 0) {
                            Image(systemName: "heart")
                            HeartrateText(heartrate: heartrate.heartrate)
                            Text(" bpm")
                            Spacer()
                            Image(systemName: "flame")
                            if let energyExpended = heartrate.energyExpended {
                                Text("\(energyExpended, specifier: "%4d") kJ")
                            } else {
                                Image(systemName: "questionmark")
                            }
                            Spacer()
                            SkinContactedView(skinIsContacted: peripheral.heartrate?.skinIsContacted)
                            Spacer()
                            Text(heartrate.timestamp, style: .time)
                        }
                    }
                    Divider()
                    PrimaryIgnoredToggle(selection: $selection)
                }
                .font(.caption)
            }
            Divider()
            Text("\(peripheral.id)")
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
            Text("\(peripheral.error?.localizedDescription ?? "")")
                .font(.subheadline)
                .foregroundColor(Color(UIColor.systemRed))
        }
        .padding()
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
                Store.primaryPeripheral = nil
            } else if selection == 2 { // Was ignored before
                Store.ignoredPeripherals = Store.ignoredPeripherals.filter {$0 != peripheral.id}
            }
            
            if newSelection == 0 { // Is primary now
                Store.primaryPeripheral = peripheral.id
            } else if newSelection == 2 { // Is ignored now
                var ignoredPeripherals = Store.ignoredPeripherals
                ignoredPeripherals.append(peripheral.id)
                Store.ignoredPeripherals = ignoredPeripherals
            }
        }
    }
}

private struct ScannerToolbarView: View {
    let scnStatus: ClientStatus
    let peripheralsFound: Bool
    
    var body: some View {
        HStack {
            Spacer()
            Image(systemName: "gear")
                .foregroundColor(.accentColor)
            BleHrStatusView(status: scnStatus, graphHasLength: peripheralsFound)
        }
        .font(.callout)
        .padding(.horizontal)
        .onTapGesture {
            guard let url = URL(string: UIApplication.openSettingsURLString) else {return}
            UIApplication.shared.open(url)
        }
    }
}

#if DEBUG
struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}
#endif

/*
 * name -> none, text
 * bodySensorLocation: BodySensorLocation = .Other -> other, chest, etc.
 * rssi -> .nan, value, good - bad
 * Connection state -> unknown, disconnected, connecting, contected, disconnecting
 * Battery Level -> unknown, %
 * heartrate -> unknonw, value
 * timestamp -> unknonw, seconds since last
 * skinIsContacted -> unknonw, contacted, not contacted
 * energyExpended -> not available, energy in KJ
 * isPrimary -> Yes/no
 * isIgnored -> Yes/no
 * id -> text
 * error: no error, error description

 var peripheral: CBPeripheral? = nil
    Services
        isPrimary
        Characteristics
 
 var heartrate: Heartrate? = nil
 rr = nil
 */
