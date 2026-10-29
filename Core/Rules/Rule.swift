import Foundation

struct Rule: Identifiable, Codable {
    let id: String
    var name: String
    var pid: String?          // nil = системное правило (offline)
    var threshold: Double?
    var comparator: String    // ">", "<", ">=", "<="
    var severity: AlertSeverity
    var cooldownSeconds: TimeInterval
    var enabled: Bool
}

enum RuleEngine {
    static let defaultRules: [Rule] = [
        Rule(id: "coolant_high", name: "Перегрев антифриза", pid: "05", threshold: 110, comparator: ">", severity: .critical, cooldownSeconds: 60, enabled: true),
        Rule(id: "coolant_low", name: "Антифриз не прогрет", pid: "05", threshold: 60, comparator: "<", severity: .info, cooldownSeconds: 300, enabled: true),
        Rule(id: "voltage_low", name: "Низкое напряжение", pid: "42", threshold: 12.0, comparator: "<", severity: .warning, cooldownSeconds: 120, enabled: true),
        Rule(id: "voltage_high", name: "Высокое напряжение", pid: "42", threshold: 14.8, comparator: ">", severity: .warning, cooldownSeconds: 120, enabled: true),
    ]

    static func evaluate(rules: [Rule], readings: [String: SensorReading], lastFired: inout [String: Date]) -> [AlertEvent] {
        var events: [AlertEvent] = []
        let now = Date()
        for rule in rules where rule.enabled {
            if let pid = rule.pid, let reading = readings[pid], let thr = rule.threshold {
                let hit: Bool
                switch rule.comparator {
                case ">": hit = reading.value > thr
                case "<": hit = reading.value < thr
                case ">=": hit = reading.value >= thr
                case "<=": hit = reading.value <= thr
                default: hit = false
                }
                if hit {
                    if let last = lastFired[rule.id], now.timeIntervalSince(last) < rule.cooldownSeconds {
                        continue
                    }
                    lastFired[rule.id] = now
                    events.append(AlertEvent(ruleId: rule.id,
                                           title: rule.name,
                                           message: "\(reading.name): \(String(format: "%.1f", reading.value)) \(reading.unit) (порог \(rule.comparator) \(thr))",
                                           severity: rule.severity))
                }
            }
        }
        return events
    }
}