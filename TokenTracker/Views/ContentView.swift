import SwiftUI

struct ContentView: View {
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            DashboardView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar")
                }

            SettingsView(viewModel: settingsViewModel) {
                dashboardViewModel.refresh()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .onAppear { dashboardViewModel.start() }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                dashboardViewModel.start()
            case .background, .inactive:
                dashboardViewModel.stop()
            @unknown default:
                break
            }
        }
    }
}
