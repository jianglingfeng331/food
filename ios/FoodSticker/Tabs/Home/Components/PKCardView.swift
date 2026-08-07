import SwiftUI

// MARK: - PK 信息模型

struct PKUserInfo {
    let name: String
    let avatar: UIImage?            // 已上传头像；为 nil 时使用 emojiAvatar 或默认占位
    let emojiAvatar: String?        // 后端 emoji 头像（兜底）
    let score: Int
    let progress: Double            // 0...100
    let isSelf: Bool
    let isLeader: Bool
}

// MARK: - 今日PK 卡片

struct PKCardView: View {
    let user1: PKUserInfo
    let user2: PKUserInfo
    let hasOpponent: Bool
    /// 双方是否有任何实际数据：无数据时均不显示皇冠（与 PK 模块一致）
    var hasData: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // 标题行
            pkHeader
                .padding(.bottom, HomeTokens.Spacing.cardGap12)

            // 双人对战区(有对手) / 单人展示(无对手)
            if hasOpponent {
                HStack(spacing: 0) {
                    userColumn(user1, isLeft: true)
                    pkDivider
                    userColumn(user2, isLeft: false)
                }
            } else {
                singleUserView
            }
        }
        .padding(.vertical, HomeTokens.Spacing.cardPaddingV)
        .padding(.horizontal, HomeTokens.Spacing.cardPaddingH)
        .flatCard()
        .padding(.bottom, HomeTokens.Spacing.cardGap12)
    }

    // MARK: - 无对手时的单人展示

    private var singleUserView: some View {
        HStack(spacing: 12) {
            avatarView(user: user1)

            VStack(alignment: .leading, spacing: 6) {
                Text(user1.name)
                    .font(.app(size: HomeTokens.FontSize.footnote,
                                  weight: HomeTokens.FontWeight.medium))
                    .foregroundColor(HomeTokens.Color.foregroundMuted)

                (Text("\(user1.score)")
                    .font(.app(size: HomeTokens.FontSize.body, weight: .bold))
                    .foregroundColor(HomeTokens.Color.foreground)
                + Text(" kcal")
                    .font(.app(size: HomeTokens.FontSize.caption2))
                    .foregroundColor(HomeTokens.Color.foregroundSubtle)
                )

                ProgressBarView(
                    progress: user1.progress,
                    height: HomeTokens.ProgressHeight.pk,
                    cornerRadius: HomeTokens.Radius.progressBar6,
                    gradient: ProgressGradient.primary
                )
            }

            Spacer()
        }
    }

    // MARK: - 标题行

    private var pkHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: hasOpponent ? "trophy.fill" : "flame.fill")
                    .font(.app(size: HomeTokens.Size.smallIcon))
                    .foregroundColor(HomeTokens.Color.primary)

                Text(hasOpponent ? "今日PK" : "今日摄入")
                    .font(.app(size: HomeTokens.FontSize.body,
                                  weight: HomeTokens.FontWeight.semibold))
                    .foregroundColor(HomeTokens.Color.foreground)

                if hasOpponent {
                    VSbadge
                }
            }

            Spacer()
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
            if let img = user.avatar {
                AvatarView(img, size: HomeTokens.Size.avatar)
            } else if let emoji = user.emojiAvatar, !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: HomeTokens.Size.avatar * 0.55))
                    .frame(width: HomeTokens.Size.avatar, height: HomeTokens.Size.avatar)
                    .background(HomeTokens.Color.primaryBg10)
                    .clipShape(Circle())
            } else {
                AvatarView(nil, size: HomeTokens.Size.avatar)
            }

            // 领先方显示皇冠（自己或对手均可，与 PK 模块一致；无数据时不显示）
            if hasData && user.isLeader {
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
