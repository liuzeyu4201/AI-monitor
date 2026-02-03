import SwiftUI

struct ChartSeries: Identifiable {
    let id: ProviderID
    let name: String
    let color: Color
    let points: [Double]
}

struct LineChartView: View {
    let series: [ChartSeries]

    var body: some View {
        GeometryReader { geometry in
            let allPoints = series.flatMap { $0.points }
            let maxValue = allPoints.max() ?? 1
            let minValue = allPoints.min() ?? 0
            let range = max(maxValue - minValue, 1)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.97, green: 0.93, blue: 0.85))

                if allPoints.isEmpty {
                    Text("No data yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(series) { line in
                        Path { path in
                            let count = line.points.count
                            let stepX = geometry.size.width / CGFloat(max(count - 1, 1))
                            for index in line.points.indices {
                                let value = line.points[index]
                                let x = CGFloat(index) * stepX
                                let y = geometry.size.height - CGFloat((value - minValue) / range) * geometry.size.height
                                if index == line.points.startIndex {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(line.color, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                    }
                }
            }
        }
        .frame(height: 180)
    }
}
