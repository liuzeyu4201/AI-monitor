import SwiftUI

struct TrendChartView: View {
    let samples: [TokenUsageSample]
    let lineColor: Color

    private var values: [Double] {
        samples.sorted { $0.timestamp < $1.timestamp }.map { $0.remaining }
    }

    var body: some View {
        GeometryReader { geometry in
            let points = values
            let maxValue = points.max() ?? 1
            let minValue = points.min() ?? 0
            let range = max(maxValue - minValue, 1)
            let stepX = geometry.size.width / CGFloat(max(points.count - 1, 1))

            ZStack {
                if points.isEmpty {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(white: 0.94))
                    Text("No data yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Path { path in
                        for index in points.indices {
                            let value = points[index]
                            let x = CGFloat(index) * stepX
                            let y = geometry.size.height - CGFloat((value - minValue) / range) * geometry.size.height
                            if index == points.startIndex {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                    .background(
                        Path { path in
                            guard !points.isEmpty else { return }
                            for index in points.indices {
                                let value = points[index]
                                let x = CGFloat(index) * stepX
                                let y = geometry.size.height - CGFloat((value - minValue) / range) * geometry.size.height
                                if index == points.startIndex {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                            path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                            path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                            path.closeSubpath()
                        }
                        .fill(lineColor.opacity(0.15))
                    )
                }
            }
        }
        .frame(height: 120)
    }
}
