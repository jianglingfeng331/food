import SwiftUI

// MARK: - 今日体重 行卡片

struct WeightRowView: View {
    let weight: String?       // nil 时显示 "—"
    let progress: Double      // 0...100
    let meta: String
    var onTap: () -> Void

    var body: some View {
        HStack(spacing: HomeTokens.Spacing.weightHGap) {
            // 左侧图标
            iconContainer

            // 中间内容
            contentArea

            // 右侧 + 按钮
            plusButton
        }
        .padding(.vertical, HomeTokens.Spacing.cardGap12)
        .padding(.horizontal, HomeTokens.Spacing.cardPaddingH)
        .flatCard()
        .padding(.bottom, HomeTokens.Spacing.cardGap10)
    }

    // MARK: - 图标容器

    private var iconContainer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: HomeTokens.Radius.iconContainer)
                .fill(HomeTokens.Color.background)
                .frame(width: HomeTokens.Size.iconContainer,
                       height: HomeTokens.Size.iconContainer)

            Image(systemName: "scalemass.fill")
                .font(.app(size: HomeTokens.Size.icon))
                .foregroundColor(HomeTokens.Color.foregroundMuted)
        }
    }

    // MARK: - 内容区

    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题行：文字 + 迷你折线图
            HStack(spacing: 6) {
                Text("今日体重")
                    .font(.app(size: HomeTokens.FontSize.body,
                                  weight: HomeTokens.FontWeight.medium))
                    .foregroundColor(HomeTokens.Color.foreground)

                sparklineView
            }
            .padding(.bottom, 2)

            // 进度条 + 数值
            HStack(spacing: 8) {
                ProgressBarView(
                    progress: progress,
                    height: HomeTokens.ProgressHeight.action,
                    cornerRadius: HomeTokens.Radius.progressBar4,
                    gradient: ProgressGradient.primary
                )

                Text(weight ?? "—")
                    .font(.app(size: HomeTokens.FontSize.body,
                                  weight: HomeTokens.FontWeight.bold))
                    .foregroundColor(HomeTokens.Color.foreground)
                    .frame(minWidth: 42, alignment: .trailing)
            }
            .padding(.bottom, 1)

            // meta 信息
            Text(meta)
                .font(.app(size: HomeTokens.FontSize.caption1))
                .foregroundColor(HomeTokens.Color.foregroundSubtle)
        }
    }

    // MARK: - 迷你折线图 (SVG polyline → SwiftUI Path)

    private var sparklineView: some View {
        // 模拟 Web 端 polyline 点位: (0,12) (8,9) (16,10) (24,6) (32,7) (40,4) (48,5)
        // 映射到 40×14 空间
        Sparkline(points: [
            CGPoint(x: 0, y: 12),
            CGPoint(x: 8, y: 9),
            CGPoint(x: 16, y: 10),
            CGPoint(x: 24, y: 6),
            CGPoint(x: 32, y: 7),
            CGPoint(x: 40, y: 4),
            CGPoint(x: 48, y: 5),
        ])
        .stroke(HomeTokens.Color.primary.opacity(0.7),
                style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
        .frame(width: HomeTokens.Size.sparklineW,
               height: HomeTokens.Size.sparklineH)
    }

    // MARK: - + 按钮

    private var plusButton: some View {
        Button(action: onTap) {
            Image(systemName: "plus")
                .font(.app(size: HomeTokens.Size.tinyIcon,
                              weight: HomeTokens.FontWeight.bold))
                .foregroundColor(HomeTokens.Color.primary)
                .frame(width: HomeTokens.Size.plusButton,
                       height: HomeTokens.Size.plusButton)
                .background(
                    Circle()
                        .fill(HomeTokens.Color.background)
                )
        }
    }
}

// MARK: - 迷你折线图 Shape

private struct Sparkline: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        guard points.count >= 2 else { return Path() }

        // 原始坐标范围 (x: 0~48, y: 0~14)
        let sourceW: CGFloat = 48
        let sourceH: CGFloat = 14

        let scaleX = rect.width / sourceW
        let scaleY = rect.height / sourceH

        var path = Path()
        path.move(to: CGPoint(x: points[0].x * scaleX,
                              y: points[0].y * scaleY))

        for pt in points.dropFirst() {
            path.addLine(to: CGPoint(x: pt.x * scaleX,
                                     y: pt.y * scaleY))
        }
        return path
    }
}
