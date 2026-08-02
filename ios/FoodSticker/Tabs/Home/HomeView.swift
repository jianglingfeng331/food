import SwiftUI

// MARK: - 首页主视图

struct HomeView: View {
    let nickname: String = "小鹿"
    /// 点击右上角「我的」头像时触发（由 HomeViewController 注入，present 个人中心页）
    var onProfile: (() -> Void)? = nil

    // 模拟数据 (实际应来自 AppDataStore)
    @State private var exerciseCalories: Int = 256
    @State private var waterAmount: Int = 1050
    @State private var weight: String? = nil
    @State private var weightMeta: String = "点击加号记录 · 上次 08:15"

    @State private var activeSheet: ActiveSheet?
    @State private var savedSports: [SavedSport] = []

    private enum ActiveSheet: Identifiable {
        case exercise, weight, water
        var id: Int { hashValue }
    }

    // MARK: - 模拟数据

    private var user1: PKUserInfo {
        PKUserInfo(
            name: "小鹿",
            avatar: "AvatarMe",
            score: 1420,
            progress: 72,
            isSelf: true,
            isLeader: false
        )
    }

    private var user2: PKUserInfo {
        PKUserInfo(
            name: "小宇",
            avatar: "AvatarRival",
            score: 1080,
            progress: 58,
            isSelf: false,
            isLeader: true
        )
    }

    // CalorieCard 数据
    private let intake: Int = 1450
    private let target: Int = 1500
    private var burned: Int { exerciseCalories + 174 }
    private var remaining: Int {
        max(0, target - intake + exerciseCalories)
    }

    private var exerciseProgress: Double {
        min(100, Double(exerciseCalories) / 700.0 * 100.0)
    }
    private var waterProgress: Double {
        min(100, Double(waterAmount) / 2500.0 * 100.0)
    }
    private var weightProgress: Double {
        weight != nil ? 50 : 0
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            HomeTokens.Color.background
                .ignoresSafeArea()

            // 内容
            ScrollView {
                VStack(spacing: 0) {
                    // 1. 顶部栏
                    TopBarView(nickname: nickname, onProfileTap: onProfile)

                    // 2. 主内容区 (对应 Web <main>)
                    VStack(spacing: 0) {
                        // PK 卡片
                        PKCardView(user1: user1, user2: user2)

                        // 热量概览
                        CalorieCardView(
                            intake: intake,
                            burned: burned,
                            remaining: remaining,
                            target: target
                        )

                        // 运动消耗
                        ActionRowView(
                            type: .exercise,
                            progress: exerciseProgress,
                            value: "\(exerciseCalories) kcal",
                            meta: "今日运动 · 上次记录 18:30",
                            onTap: { activeSheet = .exercise }
                        )

                        // 今日体重
                        WeightRowView(
                            weight: weight,
                            progress: weightProgress,
                            meta: weightMeta,
                            onTap: { activeSheet = .weight }
                        )

                        // 今日饮水
                        ActionRowView(
                            type: .water,
                            progress: waterProgress,
                            value: String(format: "%.2fL", Double(waterAmount) / 1000.0),
                            meta: "目标 2.5L · 上次 19:20",
                            onTap: { activeSheet = .water }
                        )

                        // 底部留白 (对应 Web <div h-[16px]>)
                        Spacer().frame(height: 16)
                    }
                    .padding(.top, HomeTokens.Spacing.mainTop)
                    .padding(.horizontal, HomeTokens.Spacing.horizontal)
                }
                .padding(.bottom, HomeTokens.Spacing.bottom)
            }
            .disabled(activeSheet != nil)

            // 弹窗层：以内嵌浮层呈现（半透明遮罩可透出首页，非全屏漆黑）
            if let sheet = activeSheet {
                modalContent(for: sheet)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: activeSheet)
    }

    // MARK: - 弹窗内容（对照 Web 端 addExercise / setWeight / setWaterAmount）

    @ViewBuilder
    private func modalContent(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .exercise:
            AnyView(ExerciseModalView(
                savedSports: $savedSports,
                onConfirm: { _, calories in
                    exerciseCalories = min(1200, exerciseCalories + calories)
                    activeSheet = nil
                },
                onDismiss: { activeSheet = nil }
            ))
        case .weight:
            AnyView(WeightModalView(
                initial: weight,
                onConfirm: { v in
                    weight = String(format: "%.1f kg", v)
                    weightMeta = "已记录 · 点击可修改"
                    activeSheet = nil
                },
                onDismiss: { activeSheet = nil }
            ))
        case .water:
            AnyView(WaterModalView(
                initial: waterAmount,
                onConfirm: { v in
                    waterAmount = min(3000, v)
                    activeSheet = nil
                },
                onDismiss: { activeSheet = nil }
            ))
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
