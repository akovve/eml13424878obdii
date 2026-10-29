import SwiftUI

struct ContentView: View {
    @EnvironmentObject var ble: BLEManager
    @EnvironmentObject var store: AppStore
    @State private var showSettings = false

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Дашборд", systemImage: "speedometer") }
            AlertsView()
                .tabItem { Label("Алерты", systemImage: "bell") }
            DevicesView()
                .tabItem { Label("Устройства", systemImage: "antenna.radiowaves.left.and.right") }
            SettingsView()
                .tabItem { Label("Настройки", systemImage: "gear") }
        }
    }
}