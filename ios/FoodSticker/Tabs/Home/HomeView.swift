import SwiftUI

// MARK: - 首页主视图

struct HomeView: View {
    /// 点击右上角「我的」头像时触发（由 HomeViewController 注入，present 个人中心页）
    var onProfile: (() -> Void)? = nil

    // MARK: - 数据源

    @ObservedObject private var store = AppDataStore.shared
    @ObservedObject private var avatarStore = AvatarStore.shared

    /// 仪表盘数据（PK 分数、昵称、目标等），订阅 AppDataStore.homeDashboard。
    /// 初始值取本地 PK 缓存快照（启动即时展示），bootstrap → sync 完成后自动更新。
    private var dashboardData: DashboardData? { store.homeDashboard }

    // 运动·饮水·体重弹窗
    @State private var activeSheet: ActiveSheet?
    @State private var savedSports: [SavedSport] = []

    private enum ActiveSheet: Identifiable {
        case exercise, exerciseList, weight, water
        var id: Int { hashValue }
    }

    // MARK: - 派生数据（全部由 AppDataStore + Repository 驱动）

    private var isGuest: Bool { store.dashboardRepo is GuestDashboardRepository }

    /// 昵称：AvatarStore（全站中枢）→ 仪表盘 → 用户资料 → 后备
    private var displayNickname: String {
        if isGuest { return "游客" }
        let avatarName = avatarStore.nickname
        if avatarName != "游客" && !avatarName.isEmpty { return avatarName }
        let n = dashboardData?.myNickname ?? store.profile.name
        return n.isEmpty ? "我" : n
    }

    // MARK: PK 双方数据

    /// 本周 PK 对比结果（与 PK 模块完全一致的皇冠规则）
    private var weeklyPK: AppDataStore.WeeklyPKComparison { store.weeklyPKComparison }

    private var pkMe: PKUserInfo {
        // 进度条数据源与 CalorieCardView 一致：用本地今日摄入 + 本地预算
        let meScore = intake                              // store.todayCaloriesConsumed（本地）
        let goal    = max(1, calorieTarget)               // 与 CalorieCardView 同源
        let meProg  = goal > 0 ? min(100, Double(meScore) / Double(goal) * 100) : 0
        return PKUserInfo(
            name: displayNickname,
            avatar: avatarStore.avatarImage,
            emojiAvatar: dashboardData?.myAvatarURL,
            score: meScore,
            progress: meProg,
            isSelf: true,
            isLeader: weeklyPK.leaderIsMe                  // 皇冠：本周赢的项数 > 对手
        )
    }

    private var pkRival: PKUserInfo {
        let rivalScore = dashboardData?.opponentScore ?? 0
        // 对手进度条：分母优先用对手自己的预算（opponentCalorieGoal），
        // 为 0/nil 时回退到我方预算（todayCalorieGoal → store.calorieTarget → 默认 2000）。
        // 双重检查（dashboardData 层 + UI 层）避免 opGoal=0 时 max(1,0)=1 导致进度条满。
        let opGoal = dashboardData?.opponentCalorieGoal ?? 0
        let myGoalDash = dashboardData?.todayCalorieGoal ?? 0
        let myGoalLocal = max(store.calorieTarget, 2000)
        let rivalGoal: Int = {
            if opGoal > 0 { return opGoal }
            if myGoalDash > 0 { return myGoalDash }
            return myGoalLocal
        }()
        let rivalProg  = min(100, Double(rivalScore) / Double(rivalGoal) * 100)
        // 昵称优先用 partnerProfile（pk/week 实时同步），头像同理
        let rivalName = store.partnerProfile.name.isEmpty
            ? (dashboardData?.opponentNickname ?? "对方")
            : store.partnerProfile.name
        return PKUserInfo(
            name: rivalName,
            avatar: store.partnerProfile.avatarImage,
            emojiAvatar: dashboardData?.opponentAvatarURL,
            score: rivalScore,
            progress: rivalProg,
            isSelf: false,
            isLeader: weeklyPK.leaderIsRival               // 皇冠：本周对手赢的项数 > 我方
        )
    }

    // MARK: 热量卡

    private var intake: Int {
        guard AuthService.shared.isLoggedIn else { return 0 }
        // 云端今日摄入优先（贴纸页写入云端后，首页需同步显示）
        // 云端尚未返回(nil)时回退本地，保证首帧和离线可用
        return dashboardData?.todayCalorieIntake ?? store.todayCaloriesConsumed
    }
    private var calorieTarget: Int { (isGuest || store.calorieTarget == 0) ? 2000 : store.calorieTarget }
    private var exerciseCals: Int { isGuest ? 0 : store.todayExerciseCalories }
    private var burned: Int { exerciseCals }
    private var remaining: Int { max(0, calorieTarget - intake) }

    // MARK: 进度条

    private var exerciseProgress: Double {
        guard !isGuest else { return 0 }
        return min(100, Double(exerciseCals) / 700.0 * 100.0)
    }

    /// 当日饮水毫升数：只取本地 cachedTodayStats，不回退到云端。
    /// 跨天未录入时显示 0，直到用户今天录入。
    private var todayWaterML: Int {
        isGuest ? 0 : store.todayWaterIntake
    }

    private var waterGoal: Double {
        guard !isGuest else { return 0 }
        let fromDash = Double(dashboardData?.waterGoalML ?? 0)
        // 仪表盘未返回有效目标（远程 2000 / Mock 0）时，兜底使用默认日饮水量 2000ml
        return fromDash > 0 ? fromDash : 2000
    }

    private var waterProgress: Double {
        guard !isGuest else { return 0 }
        let goal = waterGoal
        guard goal > 0 else { return 0 }
        return min(100, Double(todayWaterML) / goal * 100.0)
    }

    private var weightProgress: Double {
        guard !isGuest else { return 0 }
        return store.todayWeight > 0 ? 50 : 0
    }

    // MARK: 体重显示

    private var weightText: String? {
        guard !isGuest else { return nil }
        let w = store.todayWeight
        guard w > 0 else { return nil }
        return String(format: "%.1f kg", w)
    }

    private var weightMetaText: String {
        guard !isGuest else { return "登录后记录体重" }
        if store.todayWeight > 0 {
            return "已记录 · 点击可修改"
        }
        return "点击加号记录今日体重"
    }

    // MARK: 运动 meta

    private var exerciseMetaText: String {
        guard !isGuest else { return "登录后记录运动" }
        let recs = store.todayRecords.filter { $0.type == .exercise }
        if recs.isEmpty { return "今日运动 · 暂无记录" }
        return "今日运动 · 上次记录 \(recs.last!.time)"
    }

    // MARK: 饮水 meta

    private var waterMetaText: String {
        guard !isGuest else { return "登录后记录饮水" }
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
                            PKCardView(user1: pkMe, user2: pkRival, hasOpponent: true,
                                       hasData: weeklyPK.hasData)
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
                            onTap: { handleTap(for: .exercise) },
                            onRowTap: { handleTap(for: .exerciseList) }
                        )

                        // 今日体重
                        WeightRowView(
                            weight: weightText,
                            progress: weightProgress,
                            meta: weightMetaText,
                            onTap: { handleTap(for: .weight) }
                        )

                        // 今日饮水
                        ActionRowView(
                            type: .water,
                            progress: waterProgress,
                        value: String(format: "%.2fL",
                                      Double(todayWaterML) / 1000.0),
                            meta: waterMetaText,
                            onTap: { handleTap(for: .water) }
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
        .onAppear {
            // 首次显示时检查日期变化（跨天后自动清空旧数据）
            store.checkDayChangeAndUpdate()
        }
        .refreshable {
            // 下拉刷新：重新拉取仪表盘 + PK 数据
            // 用 detached Task 确保 refresh 不被视图重建（如弹窗开关）取消
            await Task.detached { @MainActor in
                await store.refresh()
            }.value
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
                    ProfileStore.shared.addWeightPoint(v)
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

    // MARK: - 交互守卫（游客模式需先登录）

    private func handleTap(for sheet: ActiveSheet) {
        guard AuthService.shared.isLoggedIn else {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let vc = scene.windows.first?.rootViewController {
                AuthCoordinator.shared.requireLogin(from: vc) {}
            }
            return
        }
        activeSheet = sheet
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
