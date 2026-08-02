import SwiftUI

// MARK: - 体重趋势

struct WeightTrendView: View {
    @StateObject private var store = ProfileStore.shared

    private var points: [WeightPoint] { store.weightHistory }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 概览
                HStack(spacing: 12) {
                    stat(title: "最新", value: String(format: "%.1f", store.currentWeight), unit: "kg")
                    Divider().frame(height: 36)
                    stat(title: "最高", value: highest, unit: "kg")
                    Divider().frame(height: 36)
                    stat(title: "已减", value: String(format: "%.1f", store.weightLost), unit: "kg")
                }
                .padding(16)
                .profileCard()

                // 折线图
                VStack(alignment: .leading, spacing: 8) {
                    Text("近 14 天走势")
                        .font(.app(size: 14, weight: .semibold))
                        .foregroundColor(CardTokens.Color.foreground)
                    if points.count >= 2 {
                        chart
                            .frame(height: 200)
                    } else {
                        Text("暂无足够数据")
                            .font(.app(size: 13))
                            .foregroundColor(CardTokens.Color.foregroundSubtle)
                    }
                }
                .padding(16)
                .profileCard()

                // 明细列表
                VStack(spacing: 0) {
                    ForEach(points.reversed()) { p in
                        HStack {
                            Text(p.date, formatter: dateFmt)
                                .font(.app(size: 13))
                                .foregroundColor(CardTokens.Color.foregroundMuted)
                            Spacer()
                            Text(String(format: "%.1f kg", p.weight))
                                .font(.app(size: 14, weight: .medium))
                                .foregroundColor(CardTokens.Color.foreground)
                        }
                        .padding(.vertical, 10)
                        Divider().opacity(0.5)
                    }
                }
                .padding(.horizontal, 16)
                .profileCard()
            }
            .padding(20)
        }
        .background(CardTokens.Color.background.ignoresSafeArea())
        .navigationTitle("体重趋势")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var highest: String {
        guard let m = points.map({ $0.weight }).max() else { return "—" }
        return String(format: "%.1f", m)
    }

    private var chart: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let weights = points.map { $0.weight }
            let minW = (weights.min() ?? 0) - 1
            let maxW = (weights.max() ?? 1) + 1
            let span = max(0.1, maxW - minW)
            let stepX = w / CGFloat(max(1, points.count - 1))
            let coords = points.enumerated().map { (i, p) in
                CGPoint(x: CGFloat(i) * stepX,
                        y: h - CGFloat((p.weight - minW) / span) * (h - 20) - 10)
            }
            ZStack {
                // 网格线
                Path { path in
                    for i in 0..<3 {
                        let y = CGFloat(i) * h / 3
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: w, y: y))
                    }
                }
                .stroke(Color.black.opacity(0.04), lineWidth: 1)

                // 面积填充
                Path { path in
                    path.move(to: CGPoint(x: coords.first!.x, y: h))
                    coords.forEach { path.addLine(to: $0) }
                    path.addLine(to: CGPoint(x: coords.last!.x, y: h))
                    path.closeSubpath()
                }
                .fill(CardTokens.Color.primaryBg10)

                // 折线
                Path { path in
                    path.move(to: coords.first!)
                    coords.forEach { path.addLine(to: $0) }
                }
                .stroke(CardTokens.Color.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                // 数据点
                ForEach(coords.indices, id: \.self) { i in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 7, height: 7)
                        .overlay(Circle().stroke(CardTokens.Color.primary, lineWidth: 2))
                        .position(coords[i])
                }
            }
        }
    }

    private func stat(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(title).font(.app(size: 12)).foregroundColor(CardTokens.Color.foregroundSubtle)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.app(size: 20, weight: .bold)).foregroundColor(CardTokens.Color.foreground)
                Text(unit).font(.app(size: 11)).foregroundColor(CardTokens.Color.foregroundSubtle)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var dateFmt: DateFormatter {
        let f = DateFormatter(); f.dateFormat = "M月d日"; return f
    }
}
