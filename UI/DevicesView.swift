import SwiftUI
import CoreBluetooth

struct DevicesView: View {
    @EnvironmentObject var ble: BLEManager

    private var likelyOBD: [CBPeripheral] {
        ble.discovered.filter { isLikelyOBD($0) }
    }
    private var others: [CBPeripheral] {
        ble.discovered.filter { !isLikelyOBD($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Подключение") {
                    if let p = ble.connectedPeripheral {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text(p.name ?? "ELM327").bold()
                                Text("Подключено").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Отключить") { ble.disconnect() }
                                .buttonStyle(.bordered)
                        }
                    } else {
                        Text(ble.statusText).foregroundColor(.secondary)
                    }
                    if let e = ble.lastError {
                        Text(e).foregroundColor(.red).font(.caption)
                    }
                }

                if !likelyOBD.isEmpty {
                    Section("Найдены OBD-адаптеры") {
                        ForEach(likelyOBD, id: \.identifier) { p in
                            deviceRow(p)
                        }
                    }
                }

                if !others.isEmpty {
                    Section("Другие устройства") {
                        ForEach(others, id: \.identifier) { p in
                            deviceRow(p)
                        }
                    }
                }

                if ble.discovered.isEmpty {
                    Section {
                        Text("Нажмите «Скан», чтобы найти ELM327").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Bluetooth")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(ble.isScanning ? "Стоп" : "Скан") {
                        if ble.isScanning { ble.stopScan() } else { ble.startScan() }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func deviceRow(_ p: CBPeripheral) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(p.name ?? "Без имени")
                Text(p.identifier.uuidString).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            if ble.connectedPeripheral?.identifier == p.identifier {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            } else {
                Button("Подключить") { ble.connect(p) }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func isLikelyOBD(_ p: CBPeripheral) -> Bool {
        let name = (p.name ?? "").lowercased()
        let keywords = ["elm", "obd", "vgate", "v-link", "icar", "vlink", "obdii", "obd2", "carista", "bluetooth"]
        return keywords.contains { name.contains($0) }
    }
}