import SwiftUI

// MARK: - 首页主视图

struct HomeView: View {
    /// 点击右上角「我的」头像时触发（由 HomeViewController 注入，present 个人中心页）
    var onProfile: (() -> Void)? = nil

    // MARK: - 数据源

    @ObservedObject private var store = AppDataStore.shared
    @ObservedObject private var avatarStore = AvatarStore.shared

    /// 从 Repository 异步加载的仪表盘数据（PK 分数、昵称、目标等）
    @State private var dashboardData: DashboardData?

    // 运动·饮水·体重弹窗
    @State private var activeSheet: ActiveSheet?
    @State private var savedSports: [SavedSport] = []

    private enum ActiveSheet: Identifiable {
        case exercise, exerciseList, weight, water
        var id: Int { hashValue }
    }

    // MARK: - 派生数据（全部由 AppDataStore + Repository 驱动）

    /// 昵称：AvatarStore（全站中枢）→ 仪表盘 → 用户资料 → 后备
    private var displayNickname: String {
        if store.dashboardRepo is GuestDashboardRepository { return "未登录" }
        let avatarName = avatarStore.nickname
        if avatarName != "未登录" && !avatarName.isEmpty { return avatarName }
        let n = dashboardData?.myNickname ?? store.profile.name
        return n.isEmpty ? "我" : n
    }

    // MARK: PK 双方数据

    private var pkMe: PKUserInfo {
        let meScore = dashboardData?.todayCalorieIntake ?? store.todayCaloriesConsumed
        let goal    = max(1, dashboardData?.todayCalorieGoal ?? max(store.calorieTarget, 2000))
        let rival   = dashboardData?.opponentScore ?? 0
        let meProg  = min(100, Double(meScore) / Double(goal) * 100)
        return PKUserInfo(
            name: displayNickname,
            avatar: avatarStore.avatarImage,
            score: meScore,
            progress: meProg,
            isSelf: true,
            isLeader: meScore > rival
        )
    }

    private var pkRival: PKUserInfo {
        let rivalScore = dashboardData?.opponentScore ?? 0
        let goal       = max(1, dashboardData?.todayCalorieGoal ?? max(store.calorieTarget, 2000))
        let meScore    = dashboardData?.todayCalorieIntake ?? store.todayCaloriesConsumed
        let rivalProg  = min(100, Double(rivalScore) / Double(goal) * 100)
        return PKUserInfo(
            name: dashboardData?.opponentNickname ?? "对方",
            avatar: nil,
            score: rivalScore,
            progress: rivalProg,
            isSelf: false,
            isLeader: rivalScore > meScore
        )
    }

    // MARK: 热量卡

    private var intake: Int { AuthService.shared.isLoggedIn ? store.todayCaloriesConsumed : 0 }
    private var calorieTarget: Int { store.calorieTarget > 0 ? store.calorieTarget : 2000 }
    private var exerciseCals: Int { store.todayExerciseCalories }
    private var burned: Int { exerciseCals }
    private var remaining: Int { max(0, calorieTarget - intake) }

    // MARK: 进度条

    private var exerciseProgress: Double {
        min(100, Double(exerciseCals) / 700.0 * 100.0)
    }

    private var waterGoal: Double {
        let g = Double(dashboardData?.waterGoalML ?? 0)
        return g > 0 ? g : 0
    }

    private var waterProgress: Double {
        let goal = waterGoal
        guard goal > 0 else { return 0 }
        return min(100, Double(store.todayWaterIntake) / goal * 100.0)
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
        let goal = waterGoal
        return String(format: "目标 %.1fL · 今日已记录",
                      goal / 1000.0)
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
                        // PK 卡片（登录 + 绑定对手后显示）
                        if AuthService.shared.isLoggedIn, dashboardData?.hasOpponent == true {
                            PKCardView(user1: pkMe, user2: pkRival, hasOpponent: true)
                        }

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
                            onTap: { activeSheet = .exercise },
                            onRowTap: { activeSheet = .exerciseList }
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
                // 合并仪表盘数据到用户资料（仅昵称，热量预算由用户自行设定）
                if let name = data.myNickname, !name.isEmpty {
                    store.profile.name = name
                }
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
                onConfirm: { name, calories, duration in
                    let record = DailyRecord(
                        type: .exercise, name: name,
                        calories: calories, amount: Double(duration), unit: "min")
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
        case .exerciseList:
            AnyView(ExerciseRecordListSheet(
                records: exerciseRecords,
                onDelete: { indexSet in
                    deleteExerciseRecords(at: indexSet)
                },
                onAdd: { activeSheet = .exercise },
                onDismiss: { activeSheet = nil }
            ))
        }
    }

    // MARK: - 运动记录辅助

    private var exerciseRecords: [DailyRecord] {
        store.todayRecords.filter { $0.type == .exercise }
    }

    private func deleteExerciseRecords(at offsets: IndexSet) {
        let toRemove = offsets.map { exerciseRecords[$0] }
        for record in toRemove {
            store.removeRecord(record.id)
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
