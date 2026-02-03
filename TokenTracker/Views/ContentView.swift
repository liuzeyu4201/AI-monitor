import SwiftUI

struct ContentView: View {
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            HomeView(dashboardViewModel: dashboardViewModel)
                .tabItem {
                    Label("开始", systemImage: "square.grid.2x2")
                }

            SettingsView(viewModel: settingsViewModel) {
                dashboardViewModel.reloadProviders()
                dashboardViewModel.refresh()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape")
            }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                break
            case .background, .inactive:
                dashboardViewModel.stop()
            @unknown default:
                break
            }
        }
        .onAppear {
            settingsViewModel.onSaveSuccess = {
                dashboardViewModel.reloadProviders()
                dashboardViewModel.refresh()
            }
        }
    }
}
