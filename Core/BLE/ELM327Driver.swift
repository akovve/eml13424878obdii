import Foundation

@MainActor
final class ELM327Driver {
    let ble: BLEManager

    init(ble: BLEManager) { self.ble = ble }

    func initialize() async throws {
        _ = try await ble.send("ATZ")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        _ = try await ble.send("ATE0")
        _ = try await ble.send("ATL0")
        _ = try await ble.send("ATH0")
        _ = try await ble.send("ATSP0")
    }

    func readPID(_ pid: String) async throws -> SensorReading? {
        let resp = try await ble.send("01 \(pid)")
        guard let bytes = PIDDecoder.parseResponse(resp, pid: pid) else { return nil }
        return PIDDecoder.decode(pid: pid, bytes: bytes)
    }

    func readDTCs() async throws -> [DTCCode] {
        let resp = try await ble.send("03")
        let upper = resp.uppercased()
        if upper.contains("UNABLE") || upper.contains("ERROR") || upper.contains("SEARCHING") {
            throw NSError(domain: "ELM327", code: -3, userInfo: [NSLocalizedDescriptionKey: resp.trimmingCharacters(in: .whitespacesAndNewlines)])
        }
        return DTCDecoder.decode(resp)
    }

    func clearDTCs() async throws {
        _ = try await ble.send("04")
    }

    func readBatteryVoltage() async throws -> Double? {
        let resp = try await ble.send("ATRV")
        // Response like "12.6V" or "12.6"
        let cleaned = resp.replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "V", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned)
    }
}