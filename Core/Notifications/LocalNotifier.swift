import Foundation
import UserNotifications

@MainActor
final class LocalNotifier {
    static let shared = LocalNotifier()

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func send(_ event: AlertEvent) {
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.message
        content.sound = .default
        if event.severity == .critical {
            content.interruptionLevel = .timeSensitive
        }
        let req = UNNotificationRequest(identifier: event.id.uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}