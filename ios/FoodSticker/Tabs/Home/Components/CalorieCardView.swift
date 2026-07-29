import SwiftUI

// MARK: - 今日热量概览 卡片

struct CalorieCardView: View {
    let intake: Int
    let burned: Int
    let remaining: Int
    let target: Int

    private var progress: Double {
        min(Double(intake) / Double(target) * 100.0, 100.0)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题行
            calorieHeader
                .padding(.bottom, HomeTokens.Spacing.cardGap12)

            // 三列数字
            threeColumns
                .padding(.bottom, HomeTokens.Spacing.cardGap12)

            // 底部进度条 + 文字
            bottomProgress
        }
        .padding(.vertical, HomeTokens.Spacing.cardPaddingV)
        .padding(.horizontal, HomeTokens.Spacing.cardPaddingH)
        .flatCard()
        .padding(.bottom, HomeTokens.Spacing.cardGap12)
    }

    // MARK: - 标题行

    private var calorieHeader: some View {
        HStack {
            Text("今日热量概览")
                .font(.app(size: HomeTokens.FontSize.body,
                              weight: HomeTokens.FontWeight.semibold))
                .foregroundColor(HomeTokens.Color.foreground)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.app(size: HomeTokens.FontSize.caption1))
                Text("实时")
                    .font(.app(size: HomeTokens.FontSize.caption1))
            }
            .foregroundColor(HomeTokens.Color.foregroundSubtle)
        }
    }

    // MARK: - 三列数字

    private var threeColumns: some View {
        HStack(spacing: 0) {
            statColumn(
                value: "\(intake)",
                unit: "kcal",
                label: "摄入",
                icon: "fork.knife",
                valueColor: HomeTokens.Color.foreground,
                iconColor: HomeTokens.Color.foregroundMuted
            )

            columnDivider

            statColumn(
                value: "\(burned)",
                unit: "kcal",
                label: "消耗",
                icon: "flame.fill",
                valueColor: HomeTokens.Color.primary,
                iconColor: HomeTokens.Color.primary
            )

            columnDivider

            statColumn(
                value: "\(remaining)",
                unit: "kcal",
                label: "剩余",
                icon: "clock",
                valueColor: remaining > 0 ? HomeTokens.Color.primary : HomeTokens.Color.error,
                iconColor: remaining > 0 ? HomeTokens.Color.primary : HomeTokens.Color.error
            )
        }
    }

    private func statColumn(value: String,
                            unit: String,
                            label: String,
                            icon: String,
                            valueColor: SwiftUI.Color,
                            iconColor: SwiftUI.Color) -> some View
    {
        VStack(spacing: 0) {
            // 大数字 (iOS 15 兼容: 不含 tracking)
            (Text(value)
                .font(.app(size: HomeTokens.FontSize.heroNumber, weight: .bold))
                .foregroundColor(valueColor)
            + Text(" \(unit)")
                .font(.app(size: HomeTokens.FontSize.footnote))
                .foregroundColor(HomeTokens.Color.foregroundSubtle)
            )
            .lineSpacing(0)

            Spacer().frame(height: 3)

            // 图标 + 标签
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.app(size: HomeTokens.Size.tinyIcon))
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.app(size: HomeTokens.FontSize.caption1,
                                  weight: HomeTokens.FontWeight.medium))
                    .foregroundColor(HomeTokens.Color.foregroundMuted)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // 列间分隔线
    private var columnDivider: some View {
        Rectangle()
            .fill(HomeTokens.Color.divider)
            .frame(width: 1)
            .padding(.vertical, 4)
    }

    // MARK: - 底部进度

    private var bottomProgress: some View {
        VStack(spacing: 4) {
            HStack {
                Text("已摄入 \(intake) kcal")
                    .font(.app(size: HomeTokens.FontSize.caption1))
                    .foregroundColor(HomeTokens.Color.foregroundMuted)

                Spacer()

                Text("预算 \(target) kcal")
                    .font(.app(size: HomeTokens.FontSize.caption1))
                    .foregroundColor(HomeTokens.Color.foregroundMuted)
            }

            ProgressBarView(
                progress: progress,
                height: HomeTokens.ProgressHeight.calorie,
                cornerRadius: HomeTokens.Radius.progressBar6,
                gradient: ProgressGradient.primary
            )
        }
    }
}
