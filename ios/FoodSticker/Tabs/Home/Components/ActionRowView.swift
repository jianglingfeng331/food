import SwiftUI

// MARK: - 运动消耗 / 今日饮水 行卡片

enum ActionRowType {
    case exercise
    case water

    var iconName: String {
        switch self {
        case .exercise: return "dumbbell.fill"
        case .water:    return "drop.fill"
        }
    }

    var title: String {
        switch self {
        case .exercise: return "运动消耗"
        case .water:    return "今日饮水"
        }
    }

    var valueColor: SwiftUI.Color {
        HomeTokens.Color.primary
    }

    var progressGradient: LinearGradient {
        switch self {
        case .exercise: return ProgressGradient.primary
        case .water:    return ProgressGradient.secondary
        }
    }
}

struct ActionRowView: View {
    let type: ActionRowType
    let progress: Double          // 0...100
    let value: String
    let meta: String
    var onTap: () -> Void         // 点击 + 按钮
    var onRowTap: (() -> Void)?   // 点击整行（nil 则不响应整行点击）

    var body: some View {
        HStack(spacing: HomeTokens.Spacing.actionHGap) {
            // 左侧图标
            iconContainer

            // 中间内容
            contentArea

            // 右侧 + 按钮
            plusButton
        }
        .padding(.vertical, HomeTokens.Spacing.cardGap12)
        .padding(.horizontal, HomeTokens.Spacing.cardPaddingH)
        .contentShape(Rectangle())
        .onTapGesture {
            onRowTap?()
        }
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

            Image(systemName: type.iconName)
                .font(.app(size: HomeTokens.Size.icon))
                .foregroundColor(HomeTokens.Color.primary)
        }
    }

    // MARK: - 内容区

    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题
            Text(type.title)
                .font(.app(size: HomeTokens.FontSize.body,
                              weight: HomeTokens.FontWeight.medium))
                .foregroundColor(HomeTokens.Color.foreground)
                .padding(.bottom, 2)

            // 进度条 + 数值
            HStack(spacing: 8) {
                ProgressBarView(
                    progress: progress,
                    height: HomeTokens.ProgressHeight.action,
                    cornerRadius: HomeTokens.Radius.progressBar4,
                    gradient: type.progressGradient
                )

                Text(value)
                    .font(.app(size: HomeTokens.FontSize.body,
                                  weight: HomeTokens.FontWeight.bold))
                    .foregroundColor(type.valueColor)
                    .frame(minWidth: 42, alignment: .trailing)
            }
            .padding(.bottom, 1)

            // meta 信息
            Text(meta)
                .font(.app(size: HomeTokens.FontSize.caption1))
                .foregroundColor(HomeTokens.Color.foregroundSubtle)
                .lineSpacing(HomeTokens.FontSize.caption1 *
                             (HomeTokens.LineHeight.meta - 1.0))
        }
    }

    // MARK: - + 按钮

    private var plusButton: some View {
        Button(action: onTap) {
            Image(systemName: "plus")
                .font(.app(size: HomeTokens.Size.tinyIcon,
                              weight: HomeTokens.FontWeight.bold))
                .foregroundColor(.white)
                .frame(width: HomeTokens.Size.plusButton,
                       height: HomeTokens.Size.plusButton)
                .background(
                    Circle()
                        .fill(Color(hex: 0x333333))
                )
        }
    }
}
