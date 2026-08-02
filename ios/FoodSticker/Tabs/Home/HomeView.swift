import SwiftUI

// MARK: - 首页主视图

struct HomeView: View {
    /// 点击右上角「我的」头像时触发（由 HomeViewController 注入，present 个人中心页）
    var onProfile: (() -> Void)? = nil

    // MARK: - 数据源

    @ObservedObject private var store = AppDataStore.shared

    /// 从 Repository 异步加载的仪表盘数据（PK 分数、昵称、目标等）
    @State private var dashboardData: DashboardData?

    // 运动·饮水·体重弹窗
    @State private var activeSheet: ActiveSheet?
    @State private var savedSports: [SavedSport] = []

    private enum ActiveSheet: Identifiable {
        case exercise, weight, water
        var id: Int { hashValue }
    }

    // MARK: - 派生数据（全部由 AppDataStore + Repository 驱动）

    /// 昵称：仪表盘 → 用户资料 → 后备
    private var displayNickname: String {
        if store.dashboardRepo is GuestDashboardRepository { return "未登录" }
        return dashboardData?.myNickname ?? store.profile.name
    }

    // MARK: PK 双方数据

    private var pkMe: PKUserInfo {
        let refGoal = max(Double(dashboardData?.todayCalorieGoal ?? store.profile.calorieTarget), 100)
        let score = dashboardData?.myScore ?? store.todayCaloriesConsumed
        return PKUserInfo(
            name: displayNickname,
            avatar: "AvatarMe",
            score: score,
            progress: min(100, Double(score) / refGoal * 100),
            isSelf: true,
            isLeader: false
        )
    }

    private var pkRival: PKUserInfo {
        let refGoal = max(Double(dashboardData?.todayCalorieGoal ?? store.profile.calorieTarget), 100)
        let score = dashboardData?.opponentScore ?? 0
        return PKUserInfo(
            name: dashboardData?.opponentNickname ?? "暂无对手",
            avatar: "AvatarRival",
            score: score,
            progress: min(100, Double(score) / refGoal * 100),
            isSelf: false,
            isLeader: dashboardData?.opponentIsLeader ?? false
        )
    }

    // MARK: 热量卡

    private var intake: Int { store.todayCaloriesConsumed }
    private var calorieTarget: Int {
        dashboardData?.todayCalorieGoal ?? store.profile.calorieTarget
    }
    private var exerciseCals: Int { store.todayExerciseCalories }
    private var burned: Int { exerciseCals + 174 }
    private var remaining: Int { max(0, calorieTarget - intake + exerciseCals) }

    // MARK: 进度条

    private var exerciseProgress: Double {
        min(100, Double(exerciseCals) / 700.0 * 100.0)
    }

    private var waterProgress: Double {
        min(100, Double(store.todayWaterIntake)
            / Double(dashboardData?.waterGoalML ?? 2000) * 100.0)
    }

    private var weightProgress: Double {
        store.todayWeight > 0 ? 50 : 0
    }

    // MARK: 体重显示

    private var weightText: String? {
        let w = store.todayWeight
        guard w > 0 else { return nil }
        return String(format: "%.1f kg", w)
    }

    private var weightMetaText: String {
        if store.todayWeight > 0 {
            return "已记录 · 点击可修改"
        }
        return "点击加号记录 · 上次 \(dashboardData?.lastWeightTime ?? "--:--")"
    }

    // MARK: 运动 meta

    private var exerciseMetaText: String {
        let recs = store.todayRecords.filter { $0.type == .exercise }
        if recs.isEmpty { return "今日运动 · 暂无记录" }
        return "今日运动 · 上次记录 \(recs.last!.time)"
    }

    // MARK: 饮水 meta

    private var waterMetaText: String {
        let goal = dashboardData?.waterGoalML ?? 2000
        return String(format: "目标 %.1fL · 今日已记录",
                      Double(goal) / 1000.0)
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
                    TopBarView(nickname: displayNickname, onProfileTap: onProfile)

                    // 2. 主内容区
                    VStack(spacing: 0) {
                        // PK 卡片
                        PKCardView(user1: pkMe, user2: pkRival)

                        // 热量概览
                        CalorieCardView(
                            intake: intake,
                            burned: burned,
                            remaining: remaining,
                            target: calorieTarget
                        )

                        // 运动消耗
                        ActionRowView(
                            type: .exercise,
                            progress: exerciseProgress,
                            value: "\(exerciseCals) kcal",
                            meta: exerciseMetaText,
                            onTap: { activeSheet = .exercise }
                        )

                        // 今日体重
                        WeightRowView(
                            weight: weightText,
                            progress: weightProgress,
                            meta: weightMetaText,
                            onTap: { activeSheet = .weight }
                        )

                        // 今日饮水
                        ActionRowView(
                            type: .water,
                            progress: waterProgress,
                            value: String(format: "%.2fL",
                                          Double(store.todayWaterIntake) / 1000.0),
                            meta: waterMetaText,
                            onTap: { activeSheet = .water }
                        )

                        // 底部留白
                        Spacer().frame(height: 16)
                    }
                    .padding(.top, HomeTokens.Spacing.mainTop)
                    .padding(.horizontal, HomeTokens.Spacing.horizontal)
                }
                .padding(.bottom, HomeTokens.Spacing.bottom)
            }
            .disabled(activeSheet != nil)

            // 弹窗层
            if let sheet = activeSheet {
                modalContent(for: sheet)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: activeSheet)
        .task {
            // 确保仓库匹配当前登录态
            store.refreshDashboardRepo()
            let repo = store.dashboardRepo
            do {
                let data = try await repo.fetchDashboard()
                // 合并仪表盘数据到用户资料（昵称、目标）
                if let name = data.myNickname, !name.isEmpty {
                    store.profile.name = name
                }
                store.profile.calorieTarget = data.todayCalorieGoal
                dashboardData = data
            } catch {
                print("[HomeView] Dashboard fetch failed: \(error)")
            }
        }
    }

    // MARK: - 弹窗内容（回调写回 AppDataStore）

    @ViewBuilder
    private func modalContent(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .exercise:
            AnyView(ExerciseModalView(
                savedSports: $savedSports,
                onConfirm: { _, calories in
                    let record = DailyRecord(
                        type: .exercise, name: "运动",
                        calories: calories, amount: 30)
                    store.addRecord(record)
                    activeSheet = nil
                },
                onDismiss: { activeSheet = nil }
            ))
        case .weight:
            AnyView(WeightModalView(
                initial: weightText,
                onConfirm: { v in
                    let record = DailyRecord(
                        type: .weight, name: "今日体重",
                        calories: 0, amount: v, unit: "kg")
                    store.replaceRecords(ofType: .weight, with: [record])
                    activeSheet = nil
                },
                onDismiss: { activeSheet = nil }
            ))
        case .water:
            AnyView(WaterModalView(
                initial: store.todayWaterIntake,
                onConfirm: { v in
                    let total = min(3000, v)
                    let record = DailyRecord(
                        type: .water, name: "饮水",
                        calories: 0, amount: Double(total), unit: "ml")
                    store.replaceRecords(ofType: .water, with: [record])
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
