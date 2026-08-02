import Foundation

// MARK: - 数据类型

enum RecordType: String, CaseIterable, Codable {
    case food, exercise, water, weight
    var label: String {
        switch self {
        case .food: "饮食"
        case .exercise: "运动"
        case .water: "饮水"
        case .weight: "体重"
        }
    }
    var unit: String {
        switch self {
        case .food: "g"
        case .exercise: "min"
        case .water: "ml"
        case .weight: "kg"
        }
    }
}

struct DailyRecord: Identifiable, Codable {
    var id: String
    var type: RecordType
    var name: String
    var calories: Int
    var amount: Double
    var unit: String
    var time: String

    init(id: String? = nil, type: RecordType, name: String, calories: Int = 0, amount: Double = 0, unit: String? = nil, time: String? = nil) {
        self.id = id ?? UUID().uuidString
        self.type = type
        self.name = name
        self.calories = calories
        self.amount = amount
        self.unit = unit ?? type.unit
        self.time = time ?? {
            let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: Date())
        }()
    }
}

struct PKWeekData {
    let weekLabel: String
    let me: PKPersonData
    let partner: PKPersonData
}

struct PKPersonData {
    let calorieIn: Int
    let exerciseCal: Int
    let exerciseMin: Int
    let weightChange: Double
    let waterIntake: Int
    let starCount: Int
}

struct UserProfile {
    var name: String = "小明"
    var avatar: String = "👦"
    var currentWeight: Double = 72.5
    var targetWeight: Double = 65.0
    var height: Double = 175
    var bmi: Double { Double(Int(currentWeight / ((height / 100) * (height / 100)) * 10)) / 10.0 }
    var days: Int = 15
    var weightLost: Double { max(0, (76.0 - currentWeight)) }
    var waterGoal: Int = 2000
    var calorieTarget: Int = 1600
}

// MARK: - 全局数据存储（单例）

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    // MARK: Repository 注入（默认 Mock 确保 UI 无感过渡）

    /// 首页仪表盘仓库（根据登录态自动切换 Guest/Mock/Remote）
    var dashboardRepo: DashboardRepository = GuestDashboardRepository()

    /// 贴纸仓库
    var stickerRepo: StickerRepository = MockStickerRepository()

    /// PK 仓库
    var pkRepo: PKRepository = MockPKRepository()

    /// 切换为远程仓库（后端就绪后调用）
    func useRemoteRepositories() {
        dashboardRepo = RemoteDashboardRepository()
        stickerRepo = RemoteStickerRepository()
        pkRepo = RemotePKRepository()
    }

    /// 根据当前登录状态更新仪表盘仓库
    func refreshDashboardRepo() {
        if AuthService.shared.isLoggedIn {
            // 已登录：使用 Mock（后端就绪后改为 RemoteDashboardRepository()）
            dashboardRepo = MockDashboardRepository()
        } else {
            dashboardRepo = GuestDashboardRepository()
        }
    }

    // 用户信息
    @Published var profile = UserProfile()
    @Published var partnerProfile: UserProfile = {
        var p = UserProfile()
        p.name = "小鹿"; p.avatar = "🦌"; p.currentWeight = 63.2; p.targetWeight = 58
        p.height = 165; p.days = 18; p.waterGoal = 1800; p.calorieTarget = 1400
        return p
    }()

    // PK 数据
    var pkWeeks: [PKWeekData] = [
        PKWeekData(weekLabel: "本周", me:    PKPersonData(calorieIn: 1480, exerciseCal: 320, exerciseMin: 45, weightChange: -0.8, waterIntake: 1800, starCount: 4),
                  partner: PKPersonData(calorieIn: 1350, exerciseCal: 280, exerciseMin: 50, weightChange: -0.6, waterIntake: 1600, starCount: 3)),
        PKWeekData(weekLabel: "上周", me:    PKPersonData(calorieIn: 1520, exerciseCal: 290, exerciseMin: 40, weightChange: -0.4, waterIntake: 1750, starCount: 3),
                  partner: PKPersonData(calorieIn: 1600, exerciseCal: 240, exerciseMin: 35, weightChange: -0.2, waterIntake: 1580, starCount: 2)),
        PKWeekData(weekLabel: "上上周", me:  PKPersonData(calorieIn: 1550, exerciseCal: 260, exerciseMin: 38, weightChange: -0.5, waterIntake: 1700, starCount: 3),
                  partner: PKPersonData(calorieIn: 1680, exerciseCal: 200, exerciseMin: 30, weightChange: +0.1, waterIntake: 1420, starCount: 2)),
        PKWeekData(weekLabel: "三周前", me:  PKPersonData(calorieIn: 1620, exerciseCal: 220, exerciseMin: 30, weightChange: -0.3, waterIntake: 1550, starCount: 2),
                  partner: PKPersonData(calorieIn: 1550, exerciseCal: 180, exerciseMin: 25, weightChange: -0.1, waterIntake: 1400, starCount: 1)),
    ]

    var todayPK: (meCalories: Int, partnerCalories: Int) {
        if let week = pkWeeks.first {
            return (meCalories: week.me.calorieIn, partnerCalories: week.partner.calorieIn)
        }
        return (0, 0)
    }

    // 今日记录（首次启动用 mock，之后以本地持久化为准，避免云端不可达时数据丢失）
    @Published var todayRecords: [DailyRecord] = {
        if let data = UserDefaults.standard.data(forKey: "fs_todayRecords"),
           let list = try? JSONDecoder().decode([DailyRecord].self, from: data) {
            return list
        }
        return [
            DailyRecord(type: .food, name: "鸡胸肉沙拉", calories: 320, amount: 200),
            DailyRecord(type: .food, name: "全麦面包", calories: 180, amount: 100),
            DailyRecord(type: .exercise, name: "跑步", calories: 300, amount: 30),
            DailyRecord(type: .water, name: "白开水", calories: 0, amount: 500),
            DailyRecord(type: .water, name: "矿泉水", calories: 0, amount: 300),
            DailyRecord(type: .weight, name: "今日体重", calories: 0, amount: 72.5),
        ]
    }()

    // 我的贴纸（拍摄生成的预设）
    @Published var savedStickers: [FoodSticker] = []

    // 本周概览
    var todayCaloriesConsumed: Int { todayRecords.filter { $0.type == .food }.reduce(0) { $0 + $1.calories } }
    var todayExerciseCalories: Int { todayRecords.filter { $0.type == .exercise }.reduce(0) { $0 + $1.calories } }
    var todayWaterIntake: Int { todayRecords.filter { $0.type == .water }.reduce(0) { $0 + Int($1.amount) } }
    var todayWeight: Double { todayRecords.filter { $0.type == .weight }.last?.amount ?? profile.currentWeight }

    private init() {}

    /// 将今日记录持久化到本地，保证云端不可达时（如 -1004）数据不丢失、重启后仍在
    private func persistRecords() {
        if let data = try? JSONEncoder().encode(todayRecords) {
            UserDefaults.standard.set(data, forKey: "fs_todayRecords")
        }
    }

    func addRecord(_ record: DailyRecord) {
        todayRecords.append(record)
        persistRecords()
        Task {
            try? await CloudAPI.shared.addRecord(
                type: record.type.rawValue, name: record.name,
                calories: Double(record.calories), amount: record.amount,
                unit: record.unit, time: record.time)
        }
    }

    func removeRecord(_ id: String) {
        todayRecords.removeAll { $0.id == id }
        persistRecords()
        Task { try? await CloudAPI.shared.deleteRecord(id: id) }
    }

    /// 替换指定类型的所有今日记录（用于体重/饮水等覆盖式更新）
    func replaceRecords(ofType type: RecordType, with records: [DailyRecord]) {
        todayRecords.removeAll { $0.type == type }
        todayRecords.append(contentsOf: records)
        persistRecords()
    }

    /// 加载仪表盘数据并合并至本地状态（首页 onAppear 专用）
    func bootstrapDashboardIfNeeded() async {
        let repo = dashboardRepo
        do {
            let data = try await repo.fetchDashboard()
            await MainActor.run {
                if let name = data.myNickname, !name.isEmpty {
                    profile.name = name
                }
                profile.calorieTarget = data.todayCalorieGoal
            }
        } catch {
            print("[AppDataStore] Dashboard bootstrap failed: \(error)")
        }
    }

    /// 加入"我的贴纸/预设"列表：同名食物去重（替换旧记录），始终插到最前
    func addSavedSticker(_ s: FoodSticker) {
        savedStickers.removeAll { $0.name == s.name }
        savedStickers.insert(s, at: 0)
    }

    func removeSavedSticker(_ id: UUID) {
        savedStickers.removeAll { $0.id == id }
    }

    // MARK: - 云端同步（替代硬编码 mock）
    /// App 启动时调用。
    /// 游客模式：不强制登录，直接以本地 mock 数据浏览；
    /// 已登录（AuthService 有用户）：尝试用 CloudAPI 同步真实数据（失败则保留本地）。
    @MainActor
    func bootstrap() async {
        // 根据登录态设置正确的数据仓库
        refreshDashboardRepo()
        guard AuthService.shared.isLoggedIn else {
            // 游客：仅确保本地记录已就绪（无需云端）
            return
        }
        // 已登录：尝试演示账号同步（AuthService 切换为云登录后可替换为真实 token）
        if !CloudAPI.shared.isLoggedIn {
            _ = try? await CloudAPI.shared.login(userID: "user-1", password: "123456")
        }
        try? await sync()
    }

    /// 从后端刷新首页仪表盘与 PK 对比数据。
    /// 注意：todayRecords 采用「本地优先 + 云端合并」，绝不整体覆盖本地，
    /// 以免云端不可达（-1004）或云端为空时把用户本地已保存的记录清掉。
    @MainActor
    func sync() async throws {
        let dash = try await CloudAPI.shared.dashboard()
        applyProfile(dash.user)
        let cloudRecords: [DailyRecord] = dash.todayRecords.map {
            DailyRecord(id: $0.id, type: RecordType(rawValue: $0.type) ?? .food,
                        name: $0.name, calories: Int($0.calories),
                        amount: $0.amount, unit: $0.unit, time: $0.time)
        }
        mergeRecords(cloud: cloudRecords)
        if let wk = try? await CloudAPI.shared.pkWeek() {
            if let pu = wk.partner?.user { applyPartner(pu) }
            pkWeeks = [mapPK(wk)]
        }
        persistRecords()
    }

    /// 合并云端与本地记录：本地已有（按 id）的保留，云端新增的补充进来
    private func mergeRecords(cloud: [DailyRecord]) {
        let localIDs = Set(todayRecords.map { $0.id })
        let additions = cloud.filter { !localIDs.contains($0.id) }
        todayRecords.append(contentsOf: additions)
    }

    private func applyProfile(_ u: CloudAPI.CkUser) {
        profile.name = u.name; profile.avatar = u.avatar
        profile.currentWeight = u.currentWeight
        profile.targetWeight = u.targetWeight
        profile.height = u.height
    }

    private func applyPartner(_ u: CloudAPI.CkUser) {
        partnerProfile.name = u.name; partnerProfile.avatar = u.avatar
        partnerProfile.currentWeight = u.currentWeight
        partnerProfile.targetWeight = u.targetWeight
        partnerProfile.height = u.height
    }

    /// 将后端 PK 周数据映射为本地的 PKWeekData（本周）
    private func mapPK(_ wk: CloudAPI.CkPKWeek) -> PKWeekData {
        func person(_ p: CloudAPI.CkPerson) -> PKPersonData {
            let exMin = Int(p.todayRecords.filter { $0.type == "exercise" }
                                .reduce(0) { $0 + $1.amount })
            let water = Int(p.todayRecords.filter { $0.type == "water" }
                                .reduce(0) { $0 + $1.amount })
            return PKPersonData(
                calorieIn: Int(p.dailyStats.intake),
                exerciseCal: Int(p.dailyStats.burned),
                exerciseMin: exMin,
                weightChange: 0,
                waterIntake: water,
                starCount: 4)
        }
        return PKWeekData(weekLabel: "本周", me: person(wk.me),
                          partner: wk.partner.map(person) ?? person(wk.me))
    }
}
