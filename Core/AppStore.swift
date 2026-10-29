import Foundation
import Combine
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published var readings: [String: SensorReading] = [:]
    @Published var alerts: [AlertEvent] = []
    @Published var dtcs: [DTCCode] = []
    @Published var dtcStatus: String = ""
    @Published var rules: [Rule] = RuleEngine.defaultRules
    @Published var isMonitoring = false
    @Published var lastUpdate: Date?

    weak var ble: BLEManager?
    var driver: ELM327Driver?

    private var lastFired: [String: Date] = [:]
    private var pollTask: Task<Void, Never>?

    init() {
        if let saved: [AlertEvent] = Storage.shared.load([AlertEvent].self, from: "alerts.json") {
            alerts = saved
        }
        if let savedRules: [Rule] = Storage.shared.load([Rule].self, from: "rules.json") {
            rules = savedRules
        }
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        pollTask = Task { [weak self] in
            guard let self else { return }
            // init ELM327
            do { try await self.driver?.initialize() } catch { }
            while !Task.isCancelled && self.isMonitoring {
                await self.pollOnce()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        pollTask?.cancel()
        pollTask = nil
    }

    private func pollOnce() async {
        guard let driver = driver else { return }
        let pids = PIDDecoder.allPIDs
        for pid in pids {
            if let r = try? await driver.readPID(pid) {
                readings[pid] = r
            }
        }
        lastUpdate = Date()
        // voltage fallback
        if readings["42"] == nil, let v = try? await driver.readBatteryVoltage() {
            readings["42"] = SensorReading(pid: "42", name: "Напряжение", value: v, unit: "V")
        }
        // evaluate rules
        let events = RuleEngine.evaluate(rules: rules, readings: readings, lastFired: &lastFired)
        for e in events {
            alerts.insert(e, at: 0)
            LocalNotifier.shared.send(e)
            Task { await TelegramNotifier.shared.send(e) }
            Task { await ApiClient.shared.sendAlert(title: e.title, body: e.message, severity: e.severity.rawValue) }
        }
        Storage.shared.save(alerts, as: "alerts.json")
    }

    func scanDTC() async {
        guard let driver = driver, let ble = ble else { return }
        guard ble.isConnected else {
            dtcStatus = "Нет подключения к адаптеру"
            return
        }
        dtcStatus = "Сканирование..."
        do {
            try await driver.initialize()
            let codes = try await driver.readDTCs()
            dtcs = codes
            dtcStatus = codes.isEmpty ? "Коды ошибок не найдены" : "Найдено: \(codes.count)"
        } catch {
            dtcStatus = "Ошибка: \(error.localizedDescription)"
        }
    }

    func clearAlerts() {
        alerts.removeAll()
        Storage.shared.save(alerts, as: "alerts.json")
    }

    func saveRules() {
        Storage.shared.save(rules, as: "rules.json")
    }
}