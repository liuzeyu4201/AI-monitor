import SwiftUI

struct DockerMonitorView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Docker 监控")
                .font(.title2)
                .fontWeight(.semibold)

            Text("该模块尚未实现，后续会接入容器状态与资源使用监控。")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.97))
        .navigationTitle("Docker 监控")
    }
}
