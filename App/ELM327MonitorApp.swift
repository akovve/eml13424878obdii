import SwiftUI

@main
struct ELM327MonitorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var ble = BLEManager()
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ble)
                .environmentObject(store)
                .onAppear {
                    LocalNotifier.shared.requestAuthorization()
                    store.ble = ble
                    store.driver = ELM327Driver(ble: ble)
                }
        }
    }
}