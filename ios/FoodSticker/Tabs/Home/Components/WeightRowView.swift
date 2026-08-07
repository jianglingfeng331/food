import SwiftUI

// MARK: - 今日体重 行卡片

struct WeightRowView: View {
    let weight: String?       // nil 时显示 "—"
    let progress: Double      // 保留参数兼容调用方，内部不再使用（体重不适合用进度条表达）
    let meta: String
    var onTap: () -> Void

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

    // MARK: - 内容区（左侧标题+meta，右侧体重数值垂直居中）

    private var contentArea: some View {
        HStack(spacing: 8) {
            // 左侧：标题 + meta
            VStack(alignment: .leading, spacing: 1) {
                Text("今日体重")
                    .font(.app(size: HomeTokens.FontSize.body,
                                  weight: HomeTokens.FontWeight.medium))
                    .foregroundColor(HomeTokens.Color.foreground)

                Text(meta)
                    .font(.app(size: HomeTokens.FontSize.caption1))
                    .foregroundColor(HomeTokens.Color.foregroundSubtle)
                    .lineSpacing(HomeTokens.FontSize.caption1 *
                                 (HomeTokens.LineHeight.meta - 1.0))
            }

            Spacer()

            // 右侧：体重数值（垂直居中）
            Text(weight ?? "—")
                .font(.app(size: HomeTokens.FontSize.body,
                              weight: HomeTokens.FontWeight.bold))
                .foregroundColor(HomeTokens.Color.foreground)
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
