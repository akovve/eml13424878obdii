import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var botToken: String = TelegramNotifier.shared.botToken
    @State private var chatId: String = TelegramNotifier.shared.chatId
    @State private var testStatus: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Правила") {
                    ForEach($store.rules) { $rule in
                        Toggle(rule.name, isOn: $rule.enabled)
                        if let thr = rule.threshold {
                            HStack {
                                Text("Порог")
                                Spacer()
                                Text(String(format: "%.1f", thr))
                            }
                        }
                    }
                }

                Section("Telegram-уведомления") {
                    TextField("Bot Token", text: $botToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Chat ID", text: $chatId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Сохранить") {
                        TelegramNotifier.shared.botToken = botToken
                        TelegramNotifier.shared.chatId = chatId
                        testStatus = "Сохранено"
                    }
                    Button("Тестовое сообщение") {
                        Task {
                            await TelegramNotifier.shared.send(text: "✅ Тест ELM327 Monitor")
                            testStatus = "Отправлено"
                        }
                    }
                    if !testStatus.isEmpty {
                        Text(testStatus).font(.caption).foregroundColor(.secondary)
                    }
                    Text("Создайте бота через @BotFather, получите token. Chat ID можно узнать через @userinfobot.")
                        .font(.caption2).foregroundColor(.secondary)
                }

                Section {
                    Button("Сохранить правила") {
                        store.saveRules()
                    }
                }
            }
            .navigationTitle("Настройки")
        }
    }
}