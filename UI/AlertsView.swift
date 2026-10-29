import SwiftUI

struct AlertsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.alerts) { a in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(a.severity.rawValue).font(.caption).bold()
                                .foregroundColor(color(a.severity))
                            Spacer()
                            Text(a.timestamp, style: .time).font(.caption2)
                        }
                        Text(a.title).bold()
                        Text(a.message).font(.caption)
                    }
                }
            }
            .navigationTitle("Алерты")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Очистить") { store.clearAlerts() }
                }
            }
        }
    }

    func color(_ s: AlertSeverity) -> Color {
        switch s {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}