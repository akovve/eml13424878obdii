import Foundation

@MainActor
final class TelegramNotifier {
    static let shared = TelegramNotifier()

    private let tokenKey = "telegram.botToken"
    private let chatKey = "telegram.chatId"

    var botToken: String {
        get { UserDefaults.standard.string(forKey: tokenKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }

    var chatId: String {
        get { UserDefaults.standard.string(forKey: chatKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: chatKey) }
    }

    var isConfigured: Bool {
        !botToken.isEmpty && !chatId.isEmpty
    }

    func send(text: String) async {
        guard isConfigured else { return }
        guard let url = URL(string: "https://api.telegram.org/bot\(botToken)/sendMessage") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "chat_id": chatId,
            "text": text,
            "parse_mode": "HTML"
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: req)
    }

    func send(_ event: AlertEvent) async {
        let emoji: String
        switch event.severity {
        case .info: emoji = "ℹ️"
        case .warning: emoji = "⚠️"
        case .critical: emoji = "🚨"
        }
        let text = "\(emoji) <b>\(event.title)</b>\n\(event.message)\n\(event.timestamp.formatted(date: .numeric, time: .shortened))"
        await send(text: text)
    }
}