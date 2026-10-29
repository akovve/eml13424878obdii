import Foundation
import CoreBluetooth
import Combine

@MainActor
final class BLEManager: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var isConnected = false
    @Published var discovered: [CBPeripheral] = []
    @Published var connectedPeripheral: CBPeripheral?
    @Published var statusText = "Отключено"
    @Published var lastError: String?

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var rxChar: CBCharacteristic? // write
    private var txChar: CBCharacteristic? // notify
    private var buffer = ""
    private var pending: CheckedContinuation<String, Error>?
    private var userDisconnected = false
    private var reconnectTask: Task<Void, Never>?

    // NUS / common UUIDs
    private let serviceUUIDs: [CBUUID] = [
        CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"), // Nordic UART
        CBUUID(string: "FFF0"),
        CBUUID(string: "FFE0"),
    ]

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        guard central.state == .poweredOn else {
            statusText = "Bluetooth выключен"
            return
        }
        discovered.removeAll()
        isScanning = true
        statusText = "Поиск..."
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScan() {
        central.stopScan()
        isScanning = false
    }

    func connect(_ p: CBPeripheral) {
        stopScan()
        userDisconnected = false
        reconnectTask?.cancel()
        peripheral = p
        p.delegate = self
        statusText = "Подключение к \(p.name ?? "устройство")..."
        central.connect(p, options: nil)

        // Таймаут подключения
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            await MainActor.run {
                guard let self, self.peripheral?.identifier == p.identifier, !self.isConnected else { return }
                self.central.cancelPeripheralConnection(p)
                self.lastError = "Таймаут подключения"
                self.statusText = "Ошибка подключения"
            }
        }
    }

    func disconnect() {
        userDisconnected = true
        reconnectTask?.cancel()
        if let p = peripheral { central.cancelPeripheralConnection(p) }
        peripheral = nil
        connectedPeripheral = nil
        isConnected = false
        statusText = "Отключено"
    }

    // MARK: - Send command
    func send(_ command: String, timeout: TimeInterval = 5.0) async throws -> String {
        guard let p = peripheral, let rx = rxChar else {
            throw NSError(domain: "BLE", code: -1, userInfo: [NSLocalizedDescriptionKey: "Нет подключения"])
        }
        buffer = ""
        return try await withCheckedThrowingContinuation { cont in
            self.pending = cont
            let data = (command + "\r").data(using: .ascii)!
            p.writeValue(data, for: rx, type: rx.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse)

            // timeout
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                await MainActor.run {
                    if let pending = self?.pending {
                        self?.pending = nil
                        self?.buffer = ""
                        pending.resume(throwing: NSError(domain: "BLE", code: -2, userInfo: [NSLocalizedDescriptionKey: "Таймаут"]))
                    }
                }
            }
        }
    }

    private func handleIncoming(_ data: Data) {
        guard let str = String(data: data, encoding: .ascii) ?? String(data: data, encoding: .utf8) else { return }
        buffer += str
        // ELM327 prompt '>'
        if buffer.contains(">") {
            if let cont = pending {
                pending = nil
                let result = buffer
                buffer = ""
                cont.resume(returning: result)
            }
        }
    }

    private func setupCharacteristics(for p: CBPeripheral) {
        // find rx/tx
        for service in p.services ?? [] {
            for c in service.characteristics ?? [] {
                if c.properties.contains(.notify) || c.properties.contains(.indicate) {
                    if txChar == nil { txChar = c; p.setNotifyValue(true, for: c) }
                }
                if c.properties.contains(.write) || c.properties.contains(.writeWithoutResponse) {
                    if rxChar == nil { rxChar = c }
                }
            }
        }
        if rxChar != nil && txChar != nil {
            isConnected = true
            statusText = "Подключено"
        } else {
            lastError = "Не найдены характеристики RX/TX"
            statusText = "Ошибка характеристик"
        }
    }
}

extension BLEManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            if central.state == .poweredOn {
                self.statusText = "Готово"
            } else {
                self.statusText = "Bluetooth недоступен"
            }
        }
    }
    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? ""
        // Filter likely ELM327
        let lower = name.lowercased()
        let isCandidate = lower.contains("elm") || lower.contains("obd") || lower.contains("vagate") || lower.contains("icar") || lower.contains("vgate")
        // Показываем все найденные устройства; фильтрация по имени — опциональна
        _ = isCandidate
        Task { @MainActor in
            if !self.discovered.contains(where: { $0.identifier == peripheral.identifier }) {
                self.discovered.append(peripheral)
            }
        }
    }
    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            self.connectedPeripheral = peripheral
            self.statusText = "Обнаружение сервисов..."
            peripheral.discoverServices(self.serviceUUIDs)
            if peripheral.services == nil { peripheral.discoverServices(nil) }
        }
    }
    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.lastError = error?.localizedDescription
            self.statusText = "Ошибка подключения"
            self.isConnected = false
        }
    }
    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.isConnected = false
            self.rxChar = nil
            self.txChar = nil
            self.statusText = error != nil ? "Связь потеряна" : "Отключено"
            let shouldReconnect = !self.userDisconnected && self.connectedPeripheral?.identifier == peripheral.identifier
            if shouldReconnect {
                self.statusText = "Переподключение..."
                self.reconnectTask = Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        guard let self, let p = self.connectedPeripheral else { return }
                        self.central.connect(p, options: nil)
                    }
                }
            } else {
                self.connectedPeripheral = nil
            }
        }
    }
}

extension BLEManager: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            for s in peripheral.services ?? [] {
                peripheral.discoverCharacteristics(nil, for: s)
            }
        }
    }
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Task { @MainActor in
            self.setupCharacteristics(for: peripheral)
        }
    }
    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            Task { @MainActor in
                self.handleIncoming(data)
            }
        }
    }
    nonisolated func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let e = error {
            Task { @MainActor in self.lastError = e.localizedDescription }
        }
    }
}