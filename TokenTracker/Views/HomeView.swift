import SwiftUI

struct HomeView: View {
    @ObservedObject var dashboardViewModel: DashboardViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("选择监控")
                        .font(.title2)
                        .fontWeight(.semibold)

                    NavigationLink(destination: TokenUsageDashboardView(viewModel: dashboardViewModel)) {
                        MonitorCardView(
                            title: "Token 用量监控",
                            subtitle: "查看各模型用量与趋势",
                            systemImage: "chart.xyaxis.line",
                            color: Color(red: 0.05, green: 0.65, blue: 0.45)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    NavigationLink(destination: DockerMonitorView()) {
                        MonitorCardView(
                            title: "Docker 监控",
                            subtitle: "容器与资源监控（即将上线）",
                            systemImage: "shippingbox",
                            color: Color(red: 0.20, green: 0.40, blue: 0.95)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
            }
            .navigationTitle("开始")
        }
    }
}
