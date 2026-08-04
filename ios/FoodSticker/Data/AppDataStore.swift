import Foundation
import UIKit

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
    var date: String      // 归属日期（"M月d日"），用于贴纸页按日期查看
    var imageData: Data?  // 食物贴纸图片（保存后回显）
    // 营养成分与小贴士（保存后回显到贴纸详情）
    var protein: Int = 0
    var carbs: Int = 0
    var fat: Int = 0
    var fiber: Int = 0
    var sugar: Int = 0
    var salt: Double = 0
    var tip: String = ""

    init(id: String? = nil, type: RecordType, name: String, calories: Int = 0, amount: Double = 0, unit: String? = nil, time: String? = nil, date: String? = nil, imageData: Data? = nil, protein: Int = 0, carbs: Int = 0, fat: Int = 0, fiber: Int = 0, sugar: Int = 0, salt: Double = 0, tip: String = "") {
        self.id = id ?? UUID().uuidString
        self.type = type
        self.name = name
        self.calories = calories
        self.amount = amount
        self.unit = unit ?? type.unit
        self.time = time ?? {
            let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: Date())
        }()
        self.date = date ?? {
            let f = DateFormatter(); f.dateFormat = "M月d日"; return f.string(from: Date())
        }()
        self.imageData = imageData
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.salt = salt
        self.tip = tip
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
    var name: String = ""
    var avatar: String = "👦"
    var currentWeight: Double = 0
    var targetWeight: Double = 0
    var height: Double = 0
    var bmi: Double { height > 0 ? Double(Int(currentWeight / ((height / 100) * (height / 100)) * 10)) / 10.0 : 0 }
    var days: Int = 0
    var weightLost: Double { max(0, (76.0 - currentWeight)) }
    var waterGoal: Int = 0
    var calorieTarget: Int = 0
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
    @Published var partnerProfile = UserProfile()

    /// 每日热量预算（用户自行设定，持久化至 UserDefaults，默认 0）
    @Published var calorieTarget: Int = UserDefaults.standard.integer(forKey: "fs_calorieTarget") {
        didSet { UserDefaults.standard.set(calorieTarget, forKey: "fs_calorieTarget") }
    }

    // PK 数据（默认空；仅在登录并加载真实/演示 PK 数据后填充，游客态全为 0）
    var pkWeeks: [PKWeekData] = []

    var todayPK: (meCalories: Int, partnerCalories: Int) {
        if let week = pkWeeks.first {
            return (meCalories: week.me.calorieIn, partnerCalories: week.partner.calorieIn)
        }
        return (0, 0)
    }

    // 今日记录（我方），以本地持久化为准；无持久化数据时返回空
    @Published var todayRecords: [DailyRecord] = {
        if let data = UserDefaults.standard.data(forKey: "fs_todayRecords"),
           let list = try? JSONDecoder().decode([DailyRecord].self, from: data) {
            return list
        }
        return []
    }()

    // 对方（二维码关联用户）的饮食记录，独立存储，与"我的"区分
    @Published var partnerRecords: [DailyRecord] = {
        if let data = UserDefaults.standard.data(forKey: "fs_partnerRecords"),
           let list = try? JSONDecoder().decode([DailyRecord].self, from: data) {
            return list
        }
        return []
    }()

    private func persistPartnerRecords() {
        if let data = try? JSONEncoder().encode(partnerRecords) {
            UserDefaults.standard.set(data, forKey: "fs_partnerRecords")
        }
    }

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
        // 体重记录同步更新 profile.currentWeight，确保 PK 页面等依赖 profile 的地方保持一致
        if record.type == .weight {
            profile.currentWeight = record.amount
        }
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
        // 体重记录同步更新 profile.currentWeight
        if type == .weight, let lastWeight = records.last?.amount {
            profile.currentWeight = lastWeight
        }
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

    // MARK: - 贴纸仓库桥接（Phase 3）

    /// 从 stickerRepo 获取贴纸列表并转为 FoodSticker（异步，含 CardMock 降级）
    func fetchStickersAsFoodStickers() async -> [FoodSticker] {
        let repo = stickerRepo
        do {
            let items = try await repo.fetchStickers()
            guard !items.isEmpty else {
                // 仓库无数据：返回空，游客态/未记录时不展示任何预设贴纸
                return []
            }
            return items.map { $0.toFoodSticker() }
        } catch {
            print("[AppDataStore] Sticker repo fetch failed: \(error)")
            return []
        }
    }

    /// 将 FoodSticker 异步上传到贴纸仓库（仅 preset 时调用）
    func uploadFoodStickerToRepo(_ sticker: FoodSticker) {
        let repo = stickerRepo
        Task {
            do {
                let nutrition = sticker.toStickerNutrition()
                _ = try await repo.uploadSticker(
                    image: sticker.uiImage ?? UIImage(),
                    name: sticker.name,
                    nutrition: nutrition
                )
            } catch {
                print("[AppDataStore] Sticker upload to repo failed: \(error)")
            }
        }
    }

    /// 从贴纸仓库删除指定名称的贴纸
    func deleteStickerFromRepo(named name: String) async {
        let repo = stickerRepo
        do {
            let items = try await repo.fetchStickers()
            if let target = items.first(where: { $0.name == name }) {
                try await repo.deleteSticker(id: target.id)
            }
        } catch {
            print("[AppDataStore] Sticker delete from repo failed: \(error)")
        }
    }

    // MARK: - 云端同步（替代硬编码 mock）
    /// App 启动时调用。
    /// 游客模式：不强制登录，直接以本地 mock 数据浏览；
    /// 已登录（AuthService 有用户）：尝试用 CloudAPI 同步真实数据（失败则保留本地）。
    // MARK: - 清空所有数据

    /// 将全部持久化数据与内存状态彻底清空（不会清除登录态 token）
    @MainActor
    func clearAllData() {
        todayRecords = []
        persistRecords()
        partnerRecords = []
        persistPartnerRecords()
        profile = UserProfile()
        partnerProfile = UserProfile()
        savedStickers = []
        pkWeeks = []
        calorieTarget = 0
    }

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
