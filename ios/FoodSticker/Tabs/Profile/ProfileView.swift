import SwiftUI

// MARK: - 「我的」主页面（SwiftUI，统一设计规范）
//
// 设计规范：色系 / 间距 / 字体沿用 CardTokens 体系；图标全部使用
// 项目规范 LucideIcons（禁用 emoji）；头像统一走 AvatarView（含默认头像）。
// 菜单移除「成就徽章」「运动计划」，新增「注册 / 登录」入口。

enum ProfileDestination {
    case goal, trend, reminder, account
}

struct ProfileView: View {
    @StateObject private var store = ProfileStore.shared
    @ObservedObject private var avatarStore = AvatarStore.shared

    var onClose: (() -> Void)? = nil
    var onNavigate: ((ProfileDestination) -> Void)? = nil
    var onLogin: (() -> Void)? = nil

    private var isGuest: Bool { AuthService.shared.currentUser == nil }
    private var displayName: String {
        if let u = AuthService.shared.currentUser {
            return u.nickname.isEmpty ? "用户" : u.nickname
        }
        return avatarStore.nickname
    }

    // 减重进度数据
    private var startWeight: Double { store.currentWeight + store.weightLost }
    private var totalLose: Double { max(0.1, startWeight - store.targetWeight) }
    private var ratio: Double { min(1.0, store.weightLost / totalLose) }

    var body: some View {
        VStack(spacing: 0) {
            // 顶栏
            HStack {
                Text("我的")
                    .font(.app(size: 18, weight: .bold))
                    .foregroundColor(CardTokens.Color.foreground)
                Spacer()
                Button(action: { onClose?() }) {
                    Text("完成")
                        .font(.app(size: 15, weight: .semibold))
                        .foregroundColor(CardTokens.Color.primary)
                }
            }
            .padding(.horizontal, CardTokens.Spacing.h)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: CardTokens.Spacing.section) {
                    // 用户卡
                    userCard

                    // 减重进度
                    progressCard

                    // 功能菜单
                    menuCard

                    // 注册 / 登录（游客可见）
                    if isGuest {
                        loginCard
                    }
                }
                .padding(.horizontal, CardTokens.Spacing.h)
                .padding(.bottom, 24)
            }
        }
        .background(CardTokens.Color.background.ignoresSafeArea())
    }

    // MARK: 用户卡
    private var userCard: some View {
        Button(action: {
                    if isGuest { onLogin?() } else { onNavigate?(.account) }
                }) {
            HStack(spacing: 16) {
                AvatarView(avatarStore.avatarImage, size: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.app(size: 20, weight: .bold))
                        .foregroundColor(CardTokens.Color.foreground)
                    Text(isGuest ? "登录后解锁 PK 与更多功能" : (AuthService.shared.currentUser?.phone ?? "已登录"))
                        .font(.app(size: 13))
                        .foregroundColor(CardTokens.Color.foregroundMuted)
                }
                Spacer()
                ChevronRightIcon()
                    .stroke(CardTokens.Color.foregroundSubtle, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 18, height: 18)
            }
            .padding(16)
            .profileCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: 减重进度
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                FlameIcon()
                    .stroke(CardTokens.Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 18, height: 18)
                Text("减重进度")
                    .font(.app(size: 14, weight: .semibold))
                    .foregroundColor(CardTokens.Color.foreground)
            }

            if isGuest {
                Text("登录后查看减重数据")
                    .font(.app(size: 13))
                    .foregroundColor(CardTokens.Color.foregroundSubtle)
            } else {
                Text("已减 \(String(format: "%.1f", store.weightLost)) kg（\(Int(ratio * 100))%）· 剩 \(String(format: "%.1f", max(0, store.currentWeight - store.targetWeight))) kg")
                    .font(.app(size: 13))
                    .foregroundColor(CardTokens.Color.foregroundMuted)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(CardTokens.Color.foreground.opacity(0.08))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(CardTokens.Color.primary)
                        .frame(width: geo.size.width * CGFloat(isGuest ? 0 : ratio))
                }
                .frame(height: 12)
            }
            .frame(height: 12)
        }
        .padding(16)
        .profileCard()
    }

    // MARK: 功能菜单
    private var menuCard: some View {
        VStack(spacing: 0) {
            menuRow(icon: { FlameIcon()
                .stroke(CardTokens.Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 20, height: 20) },
                title: "减脂目标") {
                    if isGuest { onLogin?() } else { onNavigate?(.goal) }
                }

            divider
            menuRow(icon: { TrendingUpIcon()
                .stroke(CardTokens.Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 20, height: 20) },
                title: "体重趋势") {
                    if isGuest { onLogin?() } else { onNavigate?(.trend) }
                }

            divider
            menuRow(icon: { BellIcon()
                .stroke(CardTokens.Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 20, height: 20) },
                title: "提醒设置") {
                    if isGuest { onLogin?() } else { onNavigate?(.reminder) }
                }

            divider
            menuRow(icon: { SettingsIcon()
                .stroke(CardTokens.Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 20, height: 20) },
                title: "账户设置") {
                    if isGuest { onLogin?() } else { onNavigate?(.account) }
                }
        }
        .profileCard()
    }

    private var divider: some View {
        Rectangle()
            .fill(CardTokens.Color.foreground.opacity(0.06))
            .frame(height: 0.5)
    }

    private func menuRow<Icon: View>(@ViewBuilder icon: () -> Icon,
                                     title: String,
                                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon()
                Text(title)
                    .font(.app(size: 15))
                    .foregroundColor(CardTokens.Color.foreground)
                Spacer()
                if isGuest {
                    Text("登录后可用")
                        .font(.app(size: 11))
                        .foregroundColor(CardTokens.Color.foregroundSubtle)
                }
                ChevronRightIcon()
                    .stroke(CardTokens.Color.foregroundSubtle, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 18, height: 18)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
        }
        .buttonStyle(.plain)
    }

    // MARK: 注册 / 登录
    private var loginCard: some View {
        Button(action: { onLogin?() }) {
            HStack(spacing: 12) {
                LogInIcon()
                    .stroke(CardTokens.Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 20, height: 20)
                Text("注册 / 登录")
                    .font(.app(size: 15, weight: .semibold))
                    .foregroundColor(CardTokens.Color.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .profileCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 卡片修饰（沿用 Home/Card 视觉语言）

extension View {
    func profileCard() -> some View {
        self
            .background(CardTokens.Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(CardTokens.Color.foreground.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
    }
}
