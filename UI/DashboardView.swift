import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let r = store.readings["05"] {
                        CoolantCard(reading: r)
                    } else {
                        CoolantCardPlaceholder()
                    }

                    Text("Все датчики").font(.headline)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                        ForEach(PIDDecoder.allPIDs.filter { $0 != "05" }, id: \.self) { pid in
                            if let r = store.readings[pid] {
                                SensorCard(reading: r)
                            }
                        }
                    }

                    HStack {
                        Button(store.isMonitoring ? "Остановить" : "Старт мониторинга") {
                            if store.isMonitoring { store.stopMonitoring() } else { store.startMonitoring() }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Сканировать DTC") {
                            Task { await store.scanDTC() }
                        }
                        .buttonStyle(.bordered)
                    }

                    if !store.dtcStatus.isEmpty {
                        Text(store.dtcStatus).font(.caption).foregroundColor(.secondary)
                    }
                    if !store.dtcs.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Коды ошибок").font(.headline)
                            ForEach(store.dtcs) { d in
                                HStack {
                                    Text(d.code).bold()
                                    Text(d.description).font(.caption)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("ELM327 Monitor")
        }
    }
}

struct CoolantCard: View {
    let reading: SensorReading
    var body: some View {
        VStack {
            Text("Температура антифриза").font(.headline)
            Text(String(format: "%.1f", reading.value))
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(color(for: reading.value))
            Text(reading.unit).font(.title3)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.15)))
    }
    func color(for v: Double) -> Color {
        if v > 110 { return .red }
        if v > 95 { return .orange }
        return .blue
    }
}

struct CoolantCardPlaceholder: View {
    var body: some View {
        VStack {
            Text("Температура антифриза").font(.headline)
            Text("--").font(.system(size: 64, weight: .bold)).foregroundColor(.gray)
            Text("°C")
        }
        .frame(maxWidth: .infinity).padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.15)))
    }
}

struct SensorCard: View {
    let reading: SensorReading
    var body: some View {
        VStack(alignment: .leading) {
            Text(reading.name).font(.caption).foregroundColor(.secondary)
            Text(String(format: "%.1f", reading.value)).font(.title2).bold()
            Text(reading.unit).font(.caption2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.15)))
    }
}