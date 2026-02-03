import SwiftUI

struct UsageDonutView: View {
    let usedFraction: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(usedFraction, 0), 1)))
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 64, height: 64)
    }
}
