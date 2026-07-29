import SwiftUI

// MARK: - PK 信息模型

struct PKUserInfo {
    let name: String
    let avatar: String      // 本地图片名 或 URL
    let score: Int
    let progress: Double    // 0...100
    let isSelf: Bool
    let isLeader: Bool
}

// MARK: - 今日PK 卡片

struct PKCardView: View {
    let user1: PKUserInfo
    let user2: PKUserInfo

    var body: some View {
        VStack(spacing: 0) {
            // 标题行
            pkHeader
                .padding(.bottom, HomeTokens.Spacing.cardGap12)

            // 双人对战区
            HStack(spacing: 0) {
                userColumn(user1, isLeft: true)
                pkDivider
                userColumn(user2, isLeft: false)
            }
        }
        .padding(.vertical, HomeTokens.Spacing.cardPaddingV)
        .padding(.horizontal, HomeTokens.Spacing.cardPaddingH)
        .flatCard()
        .padding(.bottom, HomeTokens.Spacing.cardGap12)
    }

    // MARK: - 标题行

    private var pkHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.app(size: HomeTokens.Size.smallIcon))
                    .foregroundColor(HomeTokens.Color.primary)

                Text("今日PK")
                    .font(.app(size: HomeTokens.FontSize.body,
                                  weight: HomeTokens.FontWeight.semibold))
                    .foregroundColor(HomeTokens.Color.foreground)

                VSbadge
            }

            Spacer()

            Text("剩 6h · 已打卡")
                .font(.app(size: HomeTokens.FontSize.caption1,
                              weight: HomeTokens.FontWeight.medium))
                .foregroundColor(HomeTokens.Color.foregroundSubtle)
        }
    }

    // MARK: - VS 标签

    private var VSbadge: some View {
        Text("VS")
            .font(.app(size: HomeTokens.FontSize.caption2,
                          weight: HomeTokens.FontWeight.bold))
            .foregroundColor(HomeTokens.Color.primary)
            .padding(.horizontal, HomeTokens.Spacing.vsBadgeH)
            .padding(.vertical, HomeTokens.Spacing.vsBadgeV)
            .background(
                RoundedRectangle(cornerRadius: HomeTokens.Radius.vsBadge)
                    .fill(HomeTokens.Color.primaryBg10)
            )
    }

    // MARK: - 用户列

    private func userColumn(_ user: PKUserInfo, isLeft: Bool) -> some View {
        VStack(spacing: 3) {
            // 头像 + 名字 + 卡路里
            HStack(spacing: 8) {
                avatarView(user: user)

                VStack(spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(user.name)
                            .font(.app(size: HomeTokens.FontSize.footnote,
                                          weight: HomeTokens.FontWeight.medium))
                            .foregroundColor(HomeTokens.Color.foregroundMuted)

                        Spacer()

                        (Text("\(user.score)")
                            .font(.app(size: HomeTokens.FontSize.body, weight: .bold))
                            .foregroundColor(HomeTokens.Color.foreground)
                        +
                        Text(" kcal")
                            .font(.app(size: HomeTokens.FontSize.caption2))
                            .foregroundColor(HomeTokens.Color.foregroundSubtle)
                        )
                    }
                }
            }

            // 进度条
            ProgressBarView(
                progress: user.progress,
                height: HomeTokens.ProgressHeight.pk,
                cornerRadius: HomeTokens.Radius.progressBar6,
                gradient: ProgressGradient.primary
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 头像 (含皇冠)

    private func avatarView(user: PKUserInfo) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(user.avatar)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: HomeTokens.Size.avatar, height: HomeTokens.Size.avatar)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(SwiftUI.Color.white.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: SwiftUI.Color.black.opacity(0.05),
                        radius: 1, y: 1)

            // 对方领先显示皇冠
            if !user.isSelf && user.isLeader {
                crownIcon
            }
        }
    }

    // MARK: - 皇冠图标

    private var crownIcon: some View {
        ZStack {
            Image(systemName: "crown.fill")
                .font(.app(size: 12))
                .foregroundColor(HomeTokens.Color.crownStroke)
                .offset(x: 0.5, y: 0.5)
            Image(systemName: "crown.fill")
                .font(.app(size: 11))
                .foregroundColor(HomeTokens.Color.crownFill)
        }
        .offset(x: 2, y: -10)
    }

    // MARK: - PK 分隔线

    private var pkDivider: some View {
        VStack(spacing: 1) {
            Rectangle()
                .fill(HomeTokens.Color.divider)
                .frame(width: HomeTokens.Size.dividerW)

            Text("PK")
                .font(.app(size: HomeTokens.FontSize.tiny,
                              weight: HomeTokens.FontWeight.bold))
                .foregroundColor(HomeTokens.Color.primary)
                .fixedSize()

            Rectangle()
                .fill(HomeTokens.Color.divider)
                .frame(width: HomeTokens.Size.dividerW)
        }
        .frame(minHeight: 20)
        .padding(.horizontal, 2)
    }
}
