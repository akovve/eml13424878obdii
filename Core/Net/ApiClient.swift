import Foundation

@MainActor
final class ApiClient {
    static let shared = ApiClient()
    var baseURL: String = "http://localhost:3000"

    func registerDeviceToken(_ token: String) async {
        guard let url = URL(string: "\(baseURL)/api/devices/register") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["token": token, "platform": "ios"])
        _ = try? await URLSession.shared.data(for: req)
    }

    func sendAlert(title: String, body: String, severity: String) async {
        guard let url = URL(string: "\(baseURL)/api/alerts/send") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["title": title, "body": body, "severity": severity])
        _ = try? await URLSession.shared.data(for: req)
    }
}