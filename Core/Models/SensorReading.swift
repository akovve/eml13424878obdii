import Foundation

struct SensorReading: Identifiable, Codable, Equatable {
    let id: UUID
    let pid: String
    let name: String
    let value: Double
    let unit: String
    let timestamp: Date

    init(pid: String, name: String, value: Double, unit: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.pid = pid
        self.name = name
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
    }
}

enum AlertSeverity: String, Codable, CaseIterable {
    case info = "INFO"
    case warning = "WARNING"
    case critical = "CRITICAL"
}

struct AlertEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let ruleId: String
    let title: String
    let message: String
    let severity: AlertSeverity
    let timestamp: Date
    var acknowledged: Bool

    init(ruleId: String, title: String, message: String, severity: AlertSeverity, timestamp: Date = Date(), acknowledged: Bool = false) {
        self.id = UUID()
        self.ruleId = ruleId
        self.title = title
        self.message = message
        self.severity = severity
        self.timestamp = timestamp
        self.acknowledged = acknowledged
    }
}

struct DTCCode: Identifiable, Codable, Equatable {
    let id: UUID
    let code: String
    let description: String
    let timestamp: Date

    init(code: String, description: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.code = code
        self.description = description
        self.timestamp = timestamp
    }
}