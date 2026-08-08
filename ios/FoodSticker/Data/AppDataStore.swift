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
    var createdAt: String // ISO 8601 格式的创建时间，用于上传到云端保持原始时间
    var imageFileName: String?  // 食物贴纸图片文件名（实际图片存在 Documents/sticker_images/ 目录）
    // 营养成分与小贴士（保存后回显到贴纸详情）
    var protein: Int = 0
    var carbs: Int = 0
    var fat: Int = 0
    var fiber: Int = 0
    var sugar: Int = 0
    var salt: Double = 0
    var tip: String = ""

    /// 旧版兼容字段：CodingKeys 映射 imageData → 忽略（迁移用）
    private enum CodingKeys: String, CodingKey {
        case id, type, name, calories, amount, unit, time, date, createdAt
        case imageFileName
        case imageData  // 仅用于解码旧数据迁移，不参与编码
        case protein, carbs, fat, fiber, sugar, salt, tip
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decode(RecordType.self, forKey: .type)
        name = try c.decode(String.self, forKey: .name)
        calories = try c.decode(Int.self, forKey: .calories)
        amount = try c.decode(Double.self, forKey: .amount)
        unit = try c.decode(String.self, forKey: .unit)
        time = try c.decode(String.self, forKey: .time)
        date = try c.decode(String.self, forKey: .date)
        // 旧数据可能没有 createdAt 字段，使用当前时间
        createdAt = (try? c.decode(String.self, forKey: .createdAt)) ?? ISO8601DateFormatter().string(from: Date())
        imageFileName = try c.decodeIfPresent(String.self, forKey: .imageFileName)
        protein = (try? c.decode(Int.self, forKey: .protein)) ?? 0
        carbs = (try? c.decode(Int.self, forKey: .carbs)) ?? 0
        fat = (try? c.decode(Int.self, forKey: .fat)) ?? 0
        fiber = (try? c.decode(Int.self, forKey: .fiber)) ?? 0
        sugar = (try? c.decode(Int.self, forKey: .sugar)) ?? 0
        salt = (try? c.decode(Double.self, forKey: .salt)) ?? 0
        tip = (try? c.decode(String.self, forKey: .tip)) ?? ""

        // 旧数据迁移：imageData 字段存在时存为文件
        if imageFileName == nil, let legacyData = try? c.decodeIfPresent(Data.self, forKey: .imageData), !legacyData.isEmpty {
            let fn = "\(id).jpg"
            let url = AppDataStore.stickerImagesDir.appendingPathComponent(fn)
            try? legacyData.write(to: url)
            imageFileName = fn
        }
    }

    init(id: String? = nil, type: RecordType, name: String, calories: Int = 0, amount: Double = 0, unit: String? = nil, time: String? = nil, date: String? = nil, createdAt: String? = nil, imageFileName: String? = nil, imageData: Data? = nil, protein: Int = 0, carbs: Int = 0, fat: Int = 0, fiber: Int = 0, sugar: Int = 0, salt: Double = 0, tip: String = "") {
        let rid = id ?? UUID().uuidString
        self.id = rid
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
        self.createdAt = createdAt ?? ISO8601DateFormatter().string(from: Date())
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.salt = salt
        self.tip = tip
        // 图片写入文件系统，JSON 中只存文件名
        let data = imageData
        let fn = "\(rid).jpg"
        if let d = data {
            try? d.write(to: AppDataStore.stickerImagesDir.appendingPathComponent(fn))
        }
        self.imageFileName = data != nil ? fn : imageFileName
    }

    /// 仅编码存储属性，imageData 不参与编码（已转为文件存储）
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        try c.encode(name, forKey: .name)
        try c.encode(calories, forKey: .calories)
        try c.encode(amount, forKey: .amount)
        try c.encode(unit, forKey: .unit)
        try c.encode(time, forKey: .time)
        try c.encode(date, forKey: .date)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(imageFileName, forKey: .imageFileName)
        try c.encode(protein, forKey: .protein)
        try c.encode(carbs, forKey: .carbs)
        try c.encode(fat, forKey: .fat)
        try c.encode(fiber, forKey: .fiber)
        try c.encode(sugar, forKey: .sugar)
        try c.encode(salt, forKey: .salt)
        try c.encode(tip, forKey: .tip)
    }

    /// 从文件系统加载贴纸图片
    func loadImage() -> UIImage? {
        guard let fn = imageFileName else { return nil }
        let url = AppDataStore.stickerImagesDir.appendingPathComponent(fn)
        return UIImage(contentsOfFile: url.path)
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
    /// 近7天每日数组（索引 0 = 6天前，索引 6 = 今天）
    let dailyIntake: [Int]
    let dailyBurned: [Int]
    let dailyExerciseMin: [Int]
    let dailyWater: [Int]
    let dailyWeights: [Double]
}

struct UserProfile {
    var name: String = ""
    var avatar: String = "👦"
    /// 图片头像（从后端 avatar_b64 解码），为 nil 时回退 emoji avatar
    var avatarImage: UIImage? = nil
    var currentWeight: Double = 0
    var targetWeight: Double = 0
    var height: Double = 0
    var bmi: Double { height > 0 ? Double(Int(currentWeight / ((height / 100) * (height / 100)) * 10)) / 10.0 : 0 }
    var days: Int = 0
    /// 已减体重：仅当用户设置了目标体重才计算（currentWeight 与 targetWeight 均有效时）。
    /// 新用户未设置资料时显示 0，避免基于硬编码基准产生假数据。
    var weightLost: Double {
        guard targetWeight > 0, currentWeight > 0 else { return 0 }
        return max(0, currentWeight - targetWeight)
    }
    var waterGoal: Int = 0
    var calorieTarget: Int = 0
}

// MARK: - 今日PK 缓存快照

/// 用于 App 启动时即时展示「今日PK」模块，无需等待网络请求返回。
/// 仅持久化 PK 相关字段；今日摄入 / 饮水 / 体重等易变字段不缓存，
/// 由首页各卡片回落到本地 store（todayRecords），避免显示昨日陈旧值。
struct CachedPKSnapshot: Codable {
    var hasOpponent: Bool
    var myNickname: String?
    var myAvatarURL: String?
    var myScore: Int?
    var todayCalorieGoal: Int
    var opponentNickname: String?
    var opponentAvatarURL: String?
    var opponentScore: Int?
    var opponentCalorieGoal: Int?
    var opponentIsLeader: Bool
}

// MARK: - 全局数据存储（单例）

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    /// 贴纸图片存储目录
    static let stickerImagesDir: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("sticker_images")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

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

    /// 下拉刷新入口：重新从云端拉取仪表盘与 PK 数据（不覆盖本地已存记录）
    /// 使用 isSyncing 防止并发调用；cancellation 静默处理（SwiftUI .refreshable
    /// 在视图重建时会取消 Task，但 sync 的核心操作应继续完成）。
    private var isSyncing = false

    @MainActor
    func refresh() async {
        guard AuthService.shared.isLoggedIn, CloudAPI.shared.isLoggedIn else { return }
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        // 确保使用远程仓库
        if !(dashboardRepo is RemoteDashboardRepository) {
            useRemoteRepositories()
        }
        do {
            try await sync()
        } catch is CancellationError {
            // Task 被取消（下拉刷新过程中视图重建等），静默处理
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLSession 请求被取消，静默处理
        } catch {
            Log("[AppDataStore] refresh 失败: \(error.localizedDescription)")
        }
    }

    /// 根据当前登录状态更新仪表盘仓库
    func refreshDashboardRepo() {
        if AuthService.shared.isLoggedIn {
            dashboardRepo = RemoteDashboardRepository()
        } else {
            dashboardRepo = GuestDashboardRepository()
        }
    }

    // 用户信息
    @Published var profile = UserProfile()
    @Published var partnerProfile = UserProfile()

    /// 首页仪表盘聚合数据（HomeView 的单一数据源）。
    /// 启动时由 bootstrap → sync 填充，下拉刷新时由 refresh() 填充。
    /// HomeView 订阅此属性，不再独立发起重复的网络请求。
    /// 初始值取本地 PK 缓存快照，确保首帧即展示 PK 模块。
    @Published var homeDashboard: DashboardData? = AppDataStore.dashboardDataFromCacheStatic()

    /// 今日PK 缓存快照：启动时从本地恢复，首页据此即时渲染 PK 卡片；
    /// 随后 HomeView .task 拉取最新仪表盘后调用 updateCachedPK 刷新。
    private var cachedPKSnapshot: CachedPKSnapshot? = AppDataStore.loadCachedPK()
    private static let pkCacheKey = "fs_cachedPK"

    /// 每日热量预算（用户自行设定，持久化至 UserDefaults，默认 0）
    @Published var calorieTarget: Int = UserDefaults.standard.integer(forKey: "fs_calorieTarget") {
        didSet {
            // 异步写入，避免阻塞主线程
            DispatchQueue.main.async { [self] in
                UserDefaults.standard.set(self.calorieTarget, forKey: "fs_calorieTarget")
            }
        }
    }

    // PK 数据（默认空；仅在登录并加载真实/演示 PK 数据后填充，游客态全为 0）
    var pkWeeks: [PKWeekData] = []

    var todayPK: (meCalories: Int, partnerCalories: Int) {
        if let week = pkWeeks.first {
            return (meCalories: week.me.calorieIn, partnerCalories: week.partner.calorieIn)
        }
        return (0, 0)
    }

    // MARK: - 本周 PK 对比（皇冠归属判定）

    /// 本周 PK 对比结果，与 PKPage 的 weeklyMetrics/meWins/rivalWins/leaderIsMe/leaderIsRival 逻辑完全一致。
    /// 首页今日PK 卡片和 PK 模块共用此逻辑，确保皇冠规则统一。
    struct WeeklyPKComparison {
        let meWins: Int
        let rivalWins: Int
        let leaderIsMe: Bool
        let leaderIsRival: Bool
        let hasData: Bool
    }

    /// 今日在本周的索引（0=周一 ... 6=周日）
    private var todayWeekIndex: Int {
        let cal = Calendar.current
        let now = Date()
        var mondayComp = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        mondayComp.weekday = 2 // 周一
        guard let monday = cal.date(from: mondayComp) else { return 0 }
        return max(0, min(6, cal.dateComponents([.day], from: monday, to: now).day ?? 0))
    }

    var weeklyPKComparison: WeeklyPKComparison {
        let todayIdx = todayWeekIndex
        let me = pkWeeks.first?.me
        let partner = pkWeeks.first?.partner

        // 我方 7 天数组（服务端优先，兜底用本地当日数据）
        let meIntake: [Double] = me.map {
            $0.dailyIntake.isEmpty ? [Double(todayCaloriesConsumed), 0,0,0,0,0,0] : $0.dailyIntake.map(Double.init)
        } ?? [Double(todayCaloriesConsumed), 0,0,0,0,0,0]
        let meBurned: [Double] = me.map {
            $0.dailyBurned.isEmpty ? [Double(todayExerciseCalories), 0,0,0,0,0,0] : $0.dailyBurned.map(Double.init)
        } ?? [Double(todayExerciseCalories), 0,0,0,0,0,0]
        var meWater: [Double] = me.map {
            $0.dailyWater.isEmpty ? Array(repeating: 0.0, count: 7) : $0.dailyWater.map(Double.init)
        } ?? Array(repeating: 0.0, count: 7)
        if todayWaterIntake > 0 { meWater[todayIdx] = Double(todayWaterIntake) }
        var meWeights: [Double] = me?.dailyWeights ?? Array(repeating: 0.0, count: 7)
        if todayWeight > 0 { meWeights[todayIdx] = todayWeight }

        // 对方 7 天数组
        let rivalIntake: [Double] = partner.map { $0.dailyIntake.map(Double.init) } ?? [0,0,0,0,0,0,0]
        let rivalBurned: [Double] = partner.map { $0.dailyBurned.map(Double.init) } ?? [0,0,0,0,0,0,0]
        let rivalWater: [Double] = partner.map { $0.dailyWater.map(Double.init) } ?? [0,0,0,0,0,0,0]
        var rivalWeights: [Double] = {
            if let w = partner?.dailyWeights, w.contains(where: { $0 > 0 }) { return w }
            return Array(repeating: partnerProfile.currentWeight, count: 7)
        }()
        if partnerProfile.currentWeight > 0 { rivalWeights[todayIdx] = partnerProfile.currentWeight }

        // 是否有实际数据
        let myTotal = meIntake.reduce(0, +) + meBurned.reduce(0, +) + meWater.reduce(0, +)
        let rivalTotal = rivalIntake.reduce(0, +) + rivalBurned.reduce(0, +) + rivalWater.reduce(0, +)
        let hasData = myTotal > 0 || rivalTotal > 0
        guard hasData else {
            return WeeklyPKComparison(meWins: 0, rivalWins: 0, leaderIsMe: false, leaderIsRival: false, hasData: false)
        }

        // 4 项指标
        func avg(_ a: [Double]) -> Double { a.reduce(0, +) / Double(max(a.count, 1)) }
        func sum(_ a: [Double]) -> Double { a.reduce(0, +) }
        func weightLossPercent(_ ws: [Double]) -> Double {
            let valid = ws.enumerated().filter { $0.element > 0 }.sorted(by: { $0.offset < $1.offset })
            guard valid.count >= 2 else { return 0 }
            let latest = valid.last!.element
            let previous = valid[valid.count - 2].element
            guard previous > 0 else { return 0 }
            return -(latest - previous) / previous * 100.0
        }

        struct WMetric {
            let me: Double; let rival: Double; let lowerBetter: Bool
            var isTie: Bool { me == rival }
            var meWin: Bool { isTie ? false : (lowerBetter ? me < rival : me > rival) }
            var rivalWin: Bool { isTie ? false : (lowerBetter ? rival < me : rival > me) }
        }

        let metrics = [
            WMetric(me: avg(meIntake).rounded(), rival: avg(rivalIntake).rounded(), lowerBetter: true),
            WMetric(me: sum(meBurned), rival: sum(rivalBurned), lowerBetter: false),
            WMetric(me: round(weightLossPercent(meWeights) * 10) / 10,
                    rival: round(weightLossPercent(rivalWeights) * 10) / 10, lowerBetter: false),
            WMetric(me: sum(meWater), rival: sum(rivalWater), lowerBetter: false),
        ]

        let meWins = metrics.filter { $0.meWin }.count
        let rivalWins = metrics.filter { $0.rivalWin }.count
        return WeeklyPKComparison(
            meWins: meWins, rivalWins: rivalWins,
            leaderIsMe: meWins > rivalWins, leaderIsRival: rivalWins > meWins,
            hasData: true
        )
    }

    /// 获取今天的日期字符串（格式：M月d日），用于判断记录是否属于今天
    private static var todayDateString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "M月d日"
        return fmt.string(from: Date())
    }

    // 今日记录（我方），以本地持久化为准；无持久化数据时返回空
    // 注意：这里存储所有历史记录（供贴纸页面显示），首页统计时通过计算属性只取今天的
    @Published var todayRecords: [DailyRecord] = {
        if let data = UserDefaults.standard.data(forKey: "fs_todayRecords"),
           let list = try? JSONDecoder().decode([DailyRecord].self, from: data) {
            return list
        }
        return []
    }() {
        didSet {
            // todayRecords 变化时更新今日统计缓存
            updateTodayStatsCache()
        }
    }

    /// 今日统计数据缓存（包含日期，用于检测跨天）
    private struct TodayStats {
        var date: String = ""
        var calories: Int = 0
        var exercise: Int = 0
        var water: Int = 0
        var weight: Double = 0
    }
    @Published private var cachedTodayStats = TodayStats()

    /// 更新今日统计数据缓存（私有方法）
    private func updateTodayStatsCache() {
        let today = Self.todayDateString
        Log("[updateCache] 开始更新，今天=\(today)")
        // 检查是否需要更新（日期变了或记录数变了）
        if cachedTodayStats.date != today {
            let todays = todayRecords.filter { $0.date == today }
            Log("[updateCache] 今日记录数=\(todays.count)")
            let waterRecs = todays.filter { $0.type == .water }
            Log("[updateCache] 饮水记录数=\(waterRecs.count), 最后水量=\(waterRecs.last?.amount ?? 0)")
            cachedTodayStats = TodayStats(
                date: today,
                calories: todays.filter { $0.type == .food }.reduce(0) { $0 + $1.calories },
                exercise: todays.filter { $0.type == .exercise }.reduce(0) { $0 + $1.calories },
                water: Int(todays.filter { $0.type == .water }.last?.amount ?? 0),
                weight: todays.filter { $0.type == .weight }.last?.amount ?? profile.currentWeight
            )
            Log("[updateCache] 缓存已更新: 饮水=\(cachedTodayStats.water)")
        } else {
            Log("[updateCache] 日期未变化，跳过")
        }
    }

    /// 检查日期是否变化并更新缓存
    func checkDayChangeAndUpdate() {
        let today = Self.todayDateString
        Log("[checkDayChange] 缓存日期=\(cachedTodayStats.date), 今天=\(today)")
        if cachedTodayStats.date != today {
            Log("[checkDayChange] 日期变化，更新缓存")
            updateTodayStatsCache()
            Log("[checkDayChange] 更新后: 饮水=\(cachedTodayStats.water), 运动=\(cachedTodayStats.exercise)")
        }
    }

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
    @Published var savedStickers: [FoodSticker] = [] {
        didSet { persistSavedStickers() }
    }

    /// savedStickers 的 UserDefaults 持久化 key
    private static let savedStickersKey = "fs_savedStickers"

    /// 将 savedStickers 序列化到 UserDefaults（图片存为 JPEG Data）
    private func persistSavedStickers() {
        let dtos: [PersistedSticker] = savedStickers.map { s in
            PersistedSticker(
                recordId: s.recordId,
                imageName: s.imageName,
                imageData: s.uiImage?.jpegData(compressionQuality: 0.8),
                name: s.name,
                cal: s.cal,
                protein: s.protein,
                carbs: s.carbs,
                fat: s.fat,
                fiber: s.fiber,
                sugar: s.sugar,
                salt: s.salt,
                tip: s.tip
            )
        }
        if let data = try? JSONEncoder().encode(dtos) {
            UserDefaults.standard.set(data, forKey: Self.savedStickersKey)
        }
    }

    /// 从 UserDefaults 恢复 savedStickers
    private func loadSavedStickers() {
        guard let data = UserDefaults.standard.data(forKey: Self.savedStickersKey),
              let dtos = try? JSONDecoder().decode([PersistedSticker].self, from: data) else { return }
        savedStickers = dtos.map { d in
            FoodSticker(
                imageName: d.imageName,
                uiImage: d.imageData.flatMap { UIImage(data: $0) },
                name: d.name,
                cal: d.cal,
                protein: d.protein,
                carbs: d.carbs,
                fat: d.fat,
                fiber: d.fiber,
                sugar: d.sugar,
                salt: d.salt,
                tip: d.tip,
                recordId: d.recordId
            )
        }
    }

    // 本周概览

    /// 今日摄入热量：使用缓存
    var todayCaloriesConsumed: Int { cachedTodayStats.calories }
    /// 今日运动消耗：使用缓存
    var todayExerciseCalories: Int { cachedTodayStats.exercise }
    /// 今日饮水量：使用缓存
    var todayWaterIntake: Int { cachedTodayStats.water }
    /// 今日体重：使用缓存
    var todayWeight: Double { cachedTodayStats.weight }

    private init() {
        loadSavedStickers()
        // 初始化后更新今日统计缓存
        updateTodayStatsCache()
    }

    /// 将今日记录持久化到本地，保证云端不可达时（如 -1004）数据不丢失、重启后仍在
    private func persistRecords() {
        if let data = try? JSONEncoder().encode(todayRecords) {
            UserDefaults.standard.set(data, forKey: "fs_todayRecords")
        }
    }

    func addRecord(_ record: DailyRecord) {
        // 饮水类型：当天只保留一条记录，新设置覆盖旧值（而非累加）
        if record.type == .water {
            if let existingIdx = todayRecords.firstIndex(where: { $0.type == .water && $0.date == record.date }) {
                // 更新已有饮水记录
                let existingID = todayRecords[existingIdx].id
                todayRecords[existingIdx] = record
                persistRecords()
                Task {
                    try? await CloudAPI.shared.updateRecord(id: existingID,
                        type: record.type.rawValue, name: record.name,
                        calories: Double(record.calories), amount: record.amount,
                        unit: record.unit, time: record.time,
                        proteinG: Double(record.protein), carbG: Double(record.carbs),
                        fatG: Double(record.fat), dietaryFiberG: Double(record.fiber),
                        sugarG: Double(record.sugar),
                        sodiumMg: record.salt * 1000,
                        vitaminTips: record.tip)
                    // 更新成功后刷新 PK 周数据
                    refreshPKWeek()
                }
                return
            }
        }

        let localID = record.id
        todayRecords.append(record)
        persistRecords()
        // 体重记录同步更新 profile.currentWeight，确保 PK 页面等依赖 profile 的地方保持一致
        if record.type == .weight {
            profile.currentWeight = record.amount
        }
        Task {
            if let serverID = try? await CloudAPI.shared.addRecord(
                type: record.type.rawValue, name: record.name,
                calories: Double(record.calories), amount: record.amount,
                unit: record.unit, time: record.time,
                imageFileName: record.imageFileName,
                proteinG: Double(record.protein), carbG: Double(record.carbs),
                fatG: Double(record.fat), dietaryFiberG: Double(record.fiber),
                sugarG: Double(record.sugar),
                sodiumMg: record.salt * 1000,   // g → mg
                vitaminTips: record.tip,
                createdAt: record.createdAt) {
                // 将本地记录 ID 同步为服务端 ID，确保后续 mergeRecords 能正确去重
                await MainActor.run {
                    if let idx = todayRecords.firstIndex(where: { $0.id == localID }) {
                        todayRecords[idx].id = serverID
                        // 更新图片文件名以匹配新 ID
                        if let oldFn = todayRecords[idx].imageFileName {
                            let oldURL = Self.stickerImagesDir.appendingPathComponent(oldFn)
                            let newFn = "\(serverID).jpg"
                            let newURL = Self.stickerImagesDir.appendingPathComponent(newFn)
                            try? FileManager.default.moveItem(at: oldURL, to: newURL)
                            todayRecords[idx].imageFileName = newFn
                        }
                        persistRecords()
                    }
                }
                // 上传成功后刷新 PK 周数据，确保 PK 页面及时反映最新值
                refreshPKWeek()
            }
        }
    }

    func removeRecord(_ id: String) {
        // 删除关联的贴纸图片文件
        if let record = todayRecords.first(where: { $0.id == id }),
           let fn = record.imageFileName {
            try? FileManager.default.removeItem(at: Self.stickerImagesDir.appendingPathComponent(fn))
        }
        todayRecords.removeAll { $0.id == id }
        persistRecords()
        Task {
            try? await CloudAPI.shared.deleteRecord(id: id)
            refreshPKWeek()
        }
    }

    /// 替换指定类型的所有今日记录（用于体重/饮水等覆盖式更新）
    /// 同时同步到云端：先删除云端旧记录，再上传新记录，确保 PK 页能看到最新数据。
    func replaceRecords(ofType type: RecordType, with records: [DailyRecord]) {
        // 找出被替换掉的旧记录（可能已上传云端，需删除）
        let removed = todayRecords.filter { $0.type == type }

        // 更新本地记录
        for r in removed {
            if let fn = r.imageFileName {
                try? FileManager.default.removeItem(at: Self.stickerImagesDir.appendingPathComponent(fn))
            }
        }
        todayRecords.removeAll { $0.type == type }
        todayRecords.append(contentsOf: records)
        persistRecords()

        // 体重记录同步更新 profile.currentWeight
        if type == .weight, let lastWeight = records.last?.amount {
            profile.currentWeight = lastWeight
        }

        // 异步同步到云端
        Task { @MainActor in
            let typeName = type.rawValue
            Log("[Upload] 开始上传 \(typeName) 记录，数量: \(records.count)")
            Log("[Upload] 待删除旧记录数: \(removed.count)")

            // 1. 删除云端旧记录（只删除已上传的，server ID 格式为 "r-xxx"）
            for oldRecord in removed {
                if oldRecord.id.hasPrefix("r-") {
                    do {
                        try await CloudAPI.shared.deleteRecord(id: oldRecord.id)
                        Log("[Upload] 已删除旧记录: \(oldRecord.id)")
                    } catch {
                        Log("[Upload] 删除旧记录失败: \(oldRecord.id), error: \(error.localizedDescription)")
                    }
                }
            }

            // 2. 上传新记录
            for newRecord in records {
                let localID = newRecord.id
                do {
                    let serverID = try await CloudAPI.shared.addRecord(
                        type: newRecord.type.rawValue,
                        name: newRecord.name,
                        calories: Double(newRecord.calories),
                        amount: newRecord.amount,
                        unit: newRecord.unit,
                        time: newRecord.time,
                        imageFileName: newRecord.imageFileName,
                        proteinG: Double(newRecord.protein),
                        carbG: Double(newRecord.carbs),
                        fatG: Double(newRecord.fat),
                        dietaryFiberG: Double(newRecord.fiber),
                        sugarG: Double(newRecord.sugar),
                        sodiumMg: newRecord.salt * 1000,
                        vitaminTips: newRecord.tip,
                        createdAt: newRecord.createdAt
                    )
                    Log("[Upload] 上传成功: localID=\(localID), serverID=\(serverID)")
                    // 上传成功：更新本地记录 ID 为服务端 ID
                    if let idx = todayRecords.firstIndex(where: { $0.id == localID }) {
                        todayRecords[idx].id = serverID
                        persistRecords()
                    }
                } catch {
                    Log("[Upload] 上传失败: localID=\(localID), type=\(typeName), error: \(error.localizedDescription)")
                }
            }

            // 3. 上传完成后主动刷新 PK 数据，确保首页和 PK 页立即看到最新数据
            Log("[Upload] 上传完成，开始 sync() 刷新数据")
            do {
                try await sync()
                Log("[Upload] sync() 完成")
            } catch {
                Log("[Upload] sync() 失败: \(error.localizedDescription)")
            }
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
            Log("[AppDataStore] Dashboard bootstrap failed: \(error)")
        }
    }

    // MARK: - 今日PK 缓存（即时展示）

    /// 启动时同步从 UserDefaults 恢复上次 PK 快照（同步、无网络）
    private static func loadCachedPK() -> CachedPKSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: pkCacheKey) else { return nil }
        return try? JSONDecoder().decode(CachedPKSnapshot.self, from: data)
    }

    /// 由缓存快照构造一份 DashboardData：仅 PK 字段有效，
    /// 今日摄入 / 饮水 / 体重等易变字段为 nil，让首页相应卡片回落到本地 store，避免陈旧值。
    /// 静态版本用于 @Published 初始化（无需实例）。
    static func dashboardDataFromCacheStatic() -> DashboardData? {
        guard let s = loadCachedPK() else { return nil }
        // 对手预算为 0 时置 nil → HomeView pkRival 兜底用我方预算/默认 2000
        let opGoal: Int? = (s.opponentCalorieGoal ?? 0) > 0 ? s.opponentCalorieGoal : nil
        return DashboardData(
            myNickname: s.myNickname,
            myAvatarURL: s.myAvatarURL,
            opponentNickname: s.opponentNickname,
            opponentAvatarURL: s.opponentAvatarURL,
            opponentScore: s.opponentScore,
            opponentCalorieGoal: opGoal,
            opponentIsLeader: s.opponentIsLeader,
            hasOpponent: s.hasOpponent,
            myScore: s.myScore,
            myWins: nil,
            opponentWins: nil,
            todayCalorieIntake: nil,
            todayCalorieGoal: s.todayCalorieGoal,
            todayExerciseCalories: nil,
            todayExerciseMinutes: nil,
            todayWaterML: nil,
            waterGoalML: 2000,
            latestWeight: nil,
            lastWeightTime: nil
        )
    }

    /// 实例方法版本，委托给静态方法
    func dashboardDataFromCache() -> DashboardData? {
        Self.dashboardDataFromCacheStatic()
    }

    /// 用最新仪表盘数据刷新 PK 缓存并持久化。
    /// HomeView .task 拉取成功后调用；无论是否绑定对手都写入，保证下次启动反映最新状态。
    func updateCachedPK(from data: DashboardData) {
        // 对手预算为 0 时存 nil,下次启动 dashboardDataFromCacheStatic 正确兜底
        let opGoal: Int? = (data.opponentCalorieGoal ?? 0) > 0 ? data.opponentCalorieGoal : nil
        let snap = CachedPKSnapshot(
            hasOpponent: data.hasOpponent,
            myNickname: data.myNickname,
            myAvatarURL: data.myAvatarURL,
            myScore: data.myScore,
            todayCalorieGoal: data.todayCalorieGoal,
            opponentNickname: data.opponentNickname,
            opponentAvatarURL: data.opponentAvatarURL,
            opponentScore: data.opponentScore,
            opponentCalorieGoal: opGoal,
            opponentIsLeader: data.opponentIsLeader
        )
        cachedPKSnapshot = snap
        if let d = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(d, forKey: Self.pkCacheKey)
        }
    }

    /// 加入"我的贴纸/预设"列表：同名食物去重（替换旧记录），始终插到最前
    /// 若贴纸未带 recordId（如来自 buildSticker），自动生成一个，保证可被识别为自定义贴纸并支持删除
    func addSavedSticker(_ s: FoodSticker) {
        var sticker = s
        if sticker.recordId.isEmpty {
            sticker = FoodSticker(
                imageName: s.imageName,
                uiImage: s.uiImage,
                name: s.name,
                cal: s.cal,
                date: s.date,
                time: s.time,
                protein: s.protein,
                carbs: s.carbs,
                fat: s.fat,
                fiber: s.fiber,
                sugar: s.sugar,
                salt: s.salt,
                tip: s.tip,
                recordId: UUID().uuidString
            )
        }
        savedStickers.removeAll { $0.name == sticker.name }
        savedStickers.insert(sticker, at: 0)
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
            Log("[AppDataStore] Sticker repo fetch failed: \(error)")
            return []
        }
    }

    /// 将 FoodSticker 异步上传到贴纸仓库（保存/预设都调用）
    func uploadFoodStickerToRepo(_ sticker: FoodSticker) {
        Log("[AppDataStore] uploadFoodStickerToRepo 开始, name=\(sticker.name), hasImage=\(sticker.uiImage != nil)")
        // 确保使用远程仓库（避免登录后未 refresh 时仍为 Mock）
        if !(stickerRepo is RemoteStickerRepository) {
            Log("[AppDataStore] stickerRepo 是 Mock, 切换为 Remote")
            useRemoteRepositories()
        }
        Log("[AppDataStore] 当前 stickerRepo 类型: \(type(of: stickerRepo))")
        let repo = stickerRepo
        Task {
            do {
                let nutrition = sticker.toStickerNutrition()
                Log("[AppDataStore] 调用 repo.uploadSticker...")
                _ = try await repo.uploadSticker(
                    image: sticker.uiImage ?? UIImage(),
                    name: sticker.name,
                    nutrition: nutrition
                )
                Log("[AppDataStore] Sticker 上传成功!")
            } catch {
                Log("[AppDataStore] Sticker upload to repo failed: \(error)")
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
            Log("[AppDataStore] Sticker delete from repo failed: \(error)")
        }
    }

    /// 删除指定 recordId 的自定义贴纸：同时清除本地 savedStickers 与云端仓库记录
    /// - Parameter recordId: 自定义贴纸的稳定标识（内置 CardMock 贴纸 recordId 为空，不会被误删）
    func deleteCustomSticker(recordId: String) {
        let target = savedStickers.first { $0.recordId == recordId }
        guard let sticker = target else { return }
        // 1) 本地移除（didSet 自动持久化到 UserDefaults）
        savedStickers.removeAll { $0.recordId == recordId }
        // 2) 异步删除云端记录（失败不阻塞 UI，下次 sync 会重新拉取）
        Task { await deleteStickerFromRepo(named: sticker.name) }
    }

    /// 将云端拉取的贴纸合并到本地 savedStickers（跨设备同步用）。
    /// 策略：按名称去重，云端新增的贴纸追加到本地；本地已有的保留（本地可能含图片，云端无图时不覆盖）。
    func mergeCloudStickers(_ cloudStickers: [FoodSticker]) {
        guard !cloudStickers.isEmpty else { return }
        let localNames = Set(savedStickers.map { $0.name })
        var added = false
        for cs in cloudStickers where !localNames.contains(cs.name) {
            // 云端贴纸 recordId 为空时生成一个，保证 BoardSticker.id 稳定
            var sticker = cs
            if sticker.recordId.isEmpty {
                sticker = FoodSticker(
                    imageName: cs.imageName,
                    uiImage: cs.uiImage,
                    name: cs.name,
                    cal: cs.cal,
                    date: cs.date,
                    time: cs.time,
                    protein: cs.protein,
                    carbs: cs.carbs,
                    fat: cs.fat,
                    fiber: cs.fiber,
                    sugar: cs.sugar,
                    salt: cs.salt,
                    tip: cs.tip,
                    recordId: UUID().uuidString
                )
            }
            savedStickers.append(sticker)
            added = true
        }
        if added {
            Log("[AppDataStore] merged \(cloudStickers.count) cloud stickers, \(savedStickers.count) total saved")
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
        // 删除所有贴纸图片文件
        if let files = try? FileManager.default.contentsOfDirectory(at: Self.stickerImagesDir,
                                                                     includingPropertiesForKeys: nil) {
            for f in files { try? FileManager.default.removeItem(at: f) }
        }
        todayRecords = []
        persistRecords()
        partnerRecords = []
        persistPartnerRecords()
        profile = UserProfile()
        partnerProfile = UserProfile()
        savedStickers = []
        pkWeeks = []
        calorieTarget = 0
        // 清空今日PK 缓存，避免下一用户启动时看到上一用户的 PK 卡片
        cachedPKSnapshot = nil
        UserDefaults.standard.removeObject(forKey: Self.pkCacheKey)
        // 重置首页仪表盘数据
        homeDashboard = nil
    }

    @MainActor
    func bootstrap() async {
        let t0 = CFAbsoluteTimeGetCurrent()
        Log("[Boot] start")
        // 根据登录态设置正确的数据仓库
        refreshDashboardRepo()
        guard AuthService.shared.isLoggedIn else {
            // 游客：清空所有可能残留的持久化数据，防止上一用户信息泄漏
            clearAllData()
            // 同时清空 ProfileStore 里的游客种子（体重历史曲线等 Mock 数据）
            ProfileStore.shared.clearGuestData()
            Log("[Boot] guest mode, done in \(String(format:"%.0f",(CFAbsoluteTimeGetCurrent()-t0)*1000))ms")
            return
        }
        // 已登录：仅当已持有 CloudAPI token（如恢复会话/演示账号手动登录）时才同步云端数据。
        // 新注册用户没有 cloud token，跳过云端同步，使用 Mock 数据仓库（全零初始值）。
        // 无论是否同步云端，先清空上一轮游客态遗留的体重种子曲线（若有真实数据则不会被清）。
        ProfileStore.shared.clearGuestData()
        guard CloudAPI.shared.isLoggedIn else {
            Log("[Boot] no cloud token, done in \(String(format:"%.0f",(CFAbsoluteTimeGetCurrent()-t0)*1000))ms")
            return
        }
        do {
            try await sync()
            Log("[Boot] sync succeeded in \(String(format:"%.0f",(CFAbsoluteTimeGetCurrent()-t0)*1000))ms")
        } catch {
            Log("[Boot] sync failed after \(String(format:"%.0f",(CFAbsoluteTimeGetCurrent()-t0)*1000))ms: \(error)")
        }
    }

    /// 从后端刷新首页仪表盘与 PK 对比数据。
    /// 注意：todayRecords 采用「本地优先 + 云端合并」，绝不整体覆盖本地，
    /// 以免云端不可达（-1004）或云端为空时把用户本地已保存的记录清掉。
    @MainActor
    func sync() async throws {
        let t0 = CFAbsoluteTimeGetCurrent()
        Log("[Sync] start")
        let dash = try await CloudAPI.shared.dashboard()
        Log("[Sync] dashboard done in \(String(format:"%.0f",(CFAbsoluteTimeGetCurrent()-t0)*1000))ms")
        applyProfile(dash.user)
        // 从云端恢复每日热量预算（重装 app 后本地 UserDefaults 已清空）
        if dash.dailyStats.target > 0 {
            calorieTarget = Int(dash.dailyStats.target)
        }
        let cloudRecords: [DailyRecord] = dash.todayRecords.map {
            // 后端返回的 date 格式为 "yyyy-MM-dd"，需要转换为 "M月d日" 显示格式
            let displayDate: String
            if let srvDate = $0.date, !srvDate.isEmpty {
                let srvFmt = DateFormatter(); srvFmt.dateFormat = "yyyy-MM-dd"
                let dispFmt = DateFormatter(); dispFmt.dateFormat = "M月d日"
                if let d = srvFmt.date(from: srvDate) {
                    displayDate = dispFmt.string(from: d)
                } else {
                    displayDate = dispFmt.string(from: Date())
                }
            } else {
                let dispFmt = DateFormatter(); dispFmt.dateFormat = "M月d日"
                displayDate = dispFmt.string(from: Date())
            }

            return DailyRecord(id: $0.id, type: RecordType(rawValue: $0.type) ?? .food,
                        name: $0.name, calories: Int($0.calories),
                        amount: $0.amount, unit: $0.unit, time: $0.time,
                        date: displayDate,
                        imageData: $0.imageB64.flatMap { Data(base64Encoded: $0) },
                        protein: Int($0.proteinG ?? 0),
                        carbs: Int($0.carbG ?? 0),
                        fat: Int($0.fatG ?? 0),
                        fiber: Int($0.dietaryFiberG ?? 0),
                        sugar: Int($0.sugarG ?? 0),
                        salt: ($0.sodiumMg ?? 0) / 1000,   // mg → g
                        tip: $0.vitaminTips ?? "")
        }
        Log("[Sync] 准备合并记录，云端总数=\(cloudRecords.count)")
        mergeRecords(cloud: cloudRecords)
        Log("[Sync] 合并完成，本地记录总数=\(todayRecords.count)")
        // 补上传放在独立 Task 中：不阻塞 sync，也不受 .refreshable 取消影响
        let cloudIDs = Set(cloudRecords.map { $0.id })
        Task { @MainActor in
            await self.backfillUnsyncedRecords(cloudIDs: cloudIDs)
        }

        // 并行获取 PK 数据（不阻塞仪表盘已填充的部分）
        let t1 = CFAbsoluteTimeGetCurrent()
        let wk = try? await CloudAPI.shared.pkWeek()
        Log("[Sync] pkWeek done in \(String(format:"%.0f",(CFAbsoluteTimeGetCurrent()-t1)*1000))ms")

        if let wk = wk {
            applyPKWeek(wk)
        }

        // 构造仪表盘数据供 HomeView 使用 + 刷新 PK 缓存
        // pkWeek 失败时（wk=nil）保留旧 homeDashboard 的对手信息，避免下拉刷新把 PK 卡片刷没
        let data = buildDashboardData(dash: dash, pkWeek: wk, fallback: homeDashboard, localRecords: todayRecords)
        homeDashboard = data
        updateCachedPK(from: data)

        // 同步后强制更新缓存，确保跨天后数据显示正确
        Log("[Sync] 强制更新今日统计缓存")
        // 强制更新：不管日期是否变化都重新计算
        let today = Self.todayDateString
        cachedTodayStats.date = ""  // 清空日期以强制更新
        updateTodayStatsCache()
        Log("[Sync] 缓存更新完成: 饮水=\(cachedTodayStats.water), 运动=\(cachedTodayStats.exercise)")

        persistRecords()

        // 从云端恢复用户自定义贴纸（跨设备同步：重装 app 或换设备后拉取已保存的预设）
        // 放在独立 Task 中：不阻塞 sync 主流程，失败静默处理
        Task { @MainActor in
            let cloudStickers = await self.fetchStickersAsFoodStickers()
            self.mergeCloudStickers(cloudStickers)
        }

        Log("[Sync] total \(String(format:"%.0f",(CFAbsoluteTimeGetCurrent()-t0)*1000))ms")
    }

    /// 根据原始 API 响应构造 DashboardData（与 RemoteDashboardRepository 逻辑一致）
    /// - Parameter fallback: pkWeek 请求失败时（pkWeek=nil），用 fallback 的对手信息兜底，
    ///   避免下拉刷新网络抖动把已有 PK 卡片刷没。pkWeek 成功时（含无对手）以最新数据为准。
    /// - Parameter localRecords: 本地记录，weight/water 优先使用本地数据（服务端有 60 秒缓存）
    private func buildDashboardData(dash: CloudAPI.CkDashboard,
                                    pkWeek: CloudAPI.CkPKWeek?,
                                    fallback: DashboardData? = nil,
                                    localRecords: [DailyRecord] = []) -> DashboardData {
        // 按今日日期过滤云端记录，避免昨天的记录被当作今日数据回显
        // 云端 date 格式 "yyyy-MM-dd"，本地 DailyRecord.date 格式 "M月d日"
        let isoFmt = DateFormatter(); isoFmt.dateFormat = "yyyy-MM-dd"
        let todayISO = isoFmt.string(from: Date())
        let todayDisp = Self.todayDateString

        let cloudToday = dash.todayRecords.filter { rec in
            guard let d = rec.date, !d.isEmpty else { return true }
            return d == todayISO
        }
        let localToday = localRecords.filter { $0.date == todayDisp }

        let foodRecords = cloudToday.filter { $0.type == "food" }
        let exerciseRecords = cloudToday.filter { $0.type == "exercise" }
        let waterRecords = cloudToday.filter { $0.type == "water" }
        let weightRecords = cloudToday.filter { $0.type == "weight" }

        let intake = Int(foodRecords.reduce(0) { $0 + $1.calories })
        let exercise = Int(exerciseRecords.reduce(0) { $0 + $1.calories })
        let exerciseMinutes = Int(exerciseRecords.reduce(0) { $0 + $1.amount })

        // weight/water 优先使用本地今日数据（服务端有 60 秒缓存，本地修改后云端可能是旧值）
        let localWater = localToday.filter { $0.type == .water }.last?.amount
        let localWeight = localToday.filter { $0.type == .weight }.last

        let water = Int(localWater ?? Double(waterRecords.last?.amount ?? 0))
        let latestWeight = localWeight?.amount ?? weightRecords.last.map { $0.amount }
        let weightTime = localWeight?.time ?? weightRecords.last?.time

        // PK 对手信息：pkWeek 成功用最新数据；pkWeek 失败（nil）保留 fallback 旧值
        let opponent = pkWeek?.partner
        let hasOpponent: Bool
        let opponentNickname: String?
        let opponentAvatarURL: String?
        let opponentScore: Int?
        let opponentCalorieGoal: Int?
        let opponentIsLeader: Bool
        let myScore: Int?

        if let op = opponent {
            // pkWeek 成功且有对手
            hasOpponent = true
            opponentNickname = op.user.name
            opponentAvatarURL = op.user.avatar

            // PK 卡片分数改为"今日"口径：
            // 从 pkWeek 的今日记录中自行计算今日食物热量，不再用 dailyStats.intake（7天聚合）
            let todayISO2 = todayISO  // 复用前面已计算的今日日期
            let myTodayRecs = pkWeek?.me.todayRecords ?? []
            let opTodayRecs = op.todayRecords
            let myTodayIntake = myTodayRecs.filter {
                ($0.date == todayISO2 || $0.date == nil) && $0.type == "food"
            }.reduce(0) { $0 + Int($1.calories) }
            let opTodayIntake = opTodayRecs.filter {
                ($0.date == todayISO2 || $0.date == nil) && $0.type == "food"
            }.reduce(0) { $0 + Int($1.calories) }
            myScore = myTodayIntake
            opponentScore = opTodayIntake

            // 对手预算为 0 时当作 nil,让 HomeView 兜底用我方预算或默认 2000,
            // 避免 max(1, 0)=1 导致进度条满格(rivalScore/1=100%)
            let opGoal = Int(op.dailyStats.target)
            opponentCalorieGoal = opGoal > 0 ? opGoal : nil
            opponentIsLeader = false  // 冠军逻辑已由 weeklyPK 接管，此处不再用 dailyStats 判断
        } else if pkWeek != nil {
            // pkWeek 成功但无对手（真的解绑了）→ 清空对手信息
            hasOpponent = false
            opponentNickname = nil
            opponentAvatarURL = nil
            opponentScore = nil
            opponentCalorieGoal = nil
            opponentIsLeader = false
            myScore = nil
        } else {
            // pkWeek 失败（网络错误）→ 保留旧 homeDashboard 的对手信息
            hasOpponent = fallback?.hasOpponent ?? false
            opponentNickname = fallback?.opponentNickname
            opponentAvatarURL = fallback?.opponentAvatarURL
            opponentScore = fallback?.opponentScore
            opponentCalorieGoal = fallback?.opponentCalorieGoal
            opponentIsLeader = fallback?.opponentIsLeader ?? false
            myScore = fallback?.myScore
        }

        return DashboardData(
            myNickname: dash.user.name,
            myAvatarURL: dash.user.avatar,
            opponentNickname: opponentNickname,
            opponentAvatarURL: opponentAvatarURL,
            opponentScore: opponentScore,
            opponentCalorieGoal: opponentCalorieGoal,
            opponentIsLeader: opponentIsLeader,
            hasOpponent: hasOpponent,
            myScore: myScore,
            myWins: nil,
            opponentWins: nil,
            todayCalorieIntake: foodRecords.isEmpty ? nil : intake,
            todayCalorieGoal: dash.dailyStats.target > 0 ? Int(dash.dailyStats.target) : 0,
            todayExerciseCalories: exerciseRecords.isEmpty ? nil : exercise,
            todayExerciseMinutes: exerciseRecords.isEmpty ? nil : exerciseMinutes,
            todayWaterML: (localWater != nil || !waterRecords.isEmpty) ? water : nil,
            waterGoalML: 2000,
            latestWeight: latestWeight,
            lastWeightTime: weightTime
        )
    }

    /// 合并云端与本地记录：先按 ID 去重；云端记录不带图片，若本地已有同名+同类型+同时间的记录则跳过
    /// 只合并今天日期的云端记录，避免昨天的数据被拉取到本地
    private func mergeRecords(cloud: [DailyRecord]) {
        let localIDs = Set(todayRecords.map { $0.id })
        // 只保留今天日期的云端记录
        let today = Self.todayDateString
        let todaysCloud = cloud.filter { $0.date == today }
        Log("[mergeRecords] 云端记录=\(cloud.count), 过滤后今天记录=\(todaysCloud.count)")

        // 检查本地是否已有今天日期的 weight/water 记录（覆盖式类型，不应被云端旧值覆盖）
        let hasLocalWeight = todayRecords.contains { $0.type == .weight && $0.date == today }
        let hasLocalWater = todayRecords.contains { $0.type == .water && $0.date == today }

        for record in todaysCloud {
            // ID 已有 → 跳过
            if localIDs.contains(record.id) { continue }

            // weight/water 覆盖式类型：本地已有记录时跳过云端同类记录，避免旧值覆盖新值
            if record.type == .weight && hasLocalWeight { continue }
            if record.type == .water && hasLocalWater { continue }

            // 内容匹配（云端无图片，local 有图片时不应覆盖）→ 更新本地 ID 为云端 ID，确保下次 sync 能正确去重
            if let idx = todayRecords.firstIndex(where: {
                $0.id != record.id &&
                $0.type == record.type &&
                $0.name == record.name &&
                $0.date == record.date &&
                $0.time == record.time &&
                $0.calories == record.calories
            }) {
                todayRecords[idx].id = record.id
                // 同步更新图片文件名（仅在 moveItem 成功时才更新引用）
                if let oldFn = todayRecords[idx].imageFileName {
                    let oldURL = Self.stickerImagesDir.appendingPathComponent(oldFn)
                    let newFn = "\(record.id).jpg"
                    let newURL = Self.stickerImagesDir.appendingPathComponent(newFn)
                    if (try? FileManager.default.moveItem(at: oldURL, to: newURL)) != nil {
                        todayRecords[idx].imageFileName = newFn
                    }
                }
                continue
            }
            // 全新记录 → 追加
            todayRecords.append(record)
        }
    }

    /// 补上传本地未同步的记录：检测本地有但云端没有的记录（按 ID 比对），
    /// 自动重新上传。解决因网络故障/后端字段缺失导致 addRecord 上传失败、
    /// 记录只存在本地的问题。
    private func backfillUnsyncedRecords(cloudIDs: Set<String>) async {
        let unsynced = todayRecords.filter { !cloudIDs.contains($0.id) }
        guard !unsynced.isEmpty else { return }
        Log("[AppDataStore] 检测到 \(unsynced.count) 条未同步记录，开始补上传")
        for record in unsynced {
            guard let serverID = try? await CloudAPI.shared.addRecord(
                type: record.type.rawValue, name: record.name,
                calories: Double(record.calories), amount: record.amount,
                unit: record.unit, time: record.time,
                imageFileName: record.imageFileName,
                proteinG: Double(record.protein), carbG: Double(record.carbs),
                fatG: Double(record.fat), dietaryFiberG: Double(record.fiber),
                sugarG: Double(record.sugar),
                sodiumMg: record.salt * 1000,   // g → mg
                vitaminTips: record.tip,
                createdAt: record.createdAt) else { continue }
            // 上传成功：更新本地记录 ID 为服务端 ID，确保后续 sync 能正确去重
            if let idx = todayRecords.firstIndex(where: { $0.id == record.id }) {
                todayRecords[idx].id = serverID
                // 同步更新图片文件名以匹配新 ID
                if let oldFn = todayRecords[idx].imageFileName {
                    let oldURL = Self.stickerImagesDir.appendingPathComponent(oldFn)
                    let newFn = "\(serverID).jpg"
                    let newURL = Self.stickerImagesDir.appendingPathComponent(newFn)
                    if oldFn != newFn {
                        try? FileManager.default.moveItem(at: oldURL, to: newURL)
                        todayRecords[idx].imageFileName = newFn
                    }
                }
            }
        }
        persistRecords()
    }

    @MainActor
    private func applyProfile(_ u: CloudAPI.CkUser) {
        profile.name = u.name; profile.avatar = u.avatar
        // 体重：本地优先（用户刚设置的值不应被云端旧缓存覆盖）
        let localWeight = todayRecords.filter { $0.type == .weight }.last?.amount ?? 0
        profile.currentWeight = localWeight > 0 ? localWeight : u.currentWeight
        profile.targetWeight = u.targetWeight
        profile.height = u.height
        // 解码图片头像（云端为空时保留本地已有头像，避免上传失败后被清空）
        if let b64 = u.avatarB64, !b64.isEmpty, let data = Data(base64Encoded: b64) {
            let cloudAvatar = UIImage(data: data)
            profile.avatarImage = cloudAvatar
            // 同步到 AvatarStore（不触发上传，避免循环）
            AvatarStore.shared.restoreFromCloud(cloudAvatar)
        }

        // 同步到 ProfileStore（减脂目标 / 身高 / 当前体重）
        ProfileStore.shared.restoreFromCloud(
            currentWeight: profile.currentWeight,
            targetWeight: u.targetWeight,
            height: u.height
        )
    }

    private func applyPartner(_ u: CloudAPI.CkUser) {
        partnerProfile.name = u.name; partnerProfile.avatar = u.avatar
        partnerProfile.currentWeight = u.currentWeight
        partnerProfile.targetWeight = u.targetWeight
        partnerProfile.height = u.height
        // 解码对方图片头像
        if let b64 = u.avatarB64, !b64.isEmpty, let data = Data(base64Encoded: b64) {
            partnerProfile.avatarImage = UIImage(data: data)
        } else {
            partnerProfile.avatarImage = nil
        }
    }

    /// 应用 PK 周数据：更新对手资料、对方食物记录、pkWeeks、体重趋势
    @MainActor
    func applyPKWeek(_ wk: CloudAPI.CkPKWeek) {
        if let pu = wk.partner?.user { applyPartner(pu) }
        // 用伴侣的今日记录更新 partnerProfile.currentWeight，确保无 pkWeek 数据时也能显示最新体重
        if let partnerRecs = wk.partner?.todayRecords {
            let weightRec = partnerRecs.filter { $0.type == "weight" }.last
            if let w = weightRec?.amount, w > 0 {
                partnerProfile.currentWeight = w
            }
        }
        // 将对手的今日食物记录写入 partnerRecords，供卡片页面"对方的"模式展示
        if let partnerRecs = wk.partner?.todayRecords {
            // 服务端 date 为 "yyyy-MM-dd"（UTC+8），转成本地 "M月d日" 显示
            let srvFmt = DateFormatter(); srvFmt.dateFormat = "yyyy-MM-dd"
            let dispFmt = DateFormatter(); dispFmt.dateFormat = "M月d日"
            partnerRecords = partnerRecs
                .filter { $0.type == "food" }
                .map {
                    var displayDate = ""
                    if let srvDate = $0.date, let d = srvFmt.date(from: srvDate) {
                        displayDate = dispFmt.string(from: d)
                    } else {
                        displayDate = dispFmt.string(from: Date())
                    }
                    return DailyRecord(id: $0.id, type: .food,
                                name: $0.name, calories: Int($0.calories),
                                amount: $0.amount, unit: $0.unit,
                                time: $0.time, date: displayDate,
                                imageFileName: nil,
                                imageData: $0.imageB64.flatMap { Data(base64Encoded: $0) },
                                protein: Int($0.proteinG ?? 0),
                                carbs: Int($0.carbG ?? 0),
                                fat: Int($0.fatG ?? 0),
                                fiber: Int($0.dietaryFiberG ?? 0),
                                sugar: Int($0.sugarG ?? 0),
                                salt: ($0.sodiumMg ?? 0) / 1000,   // mg → g
                                tip: $0.vitaminTips ?? "")
                }
            persistPartnerRecords()
        }
        pkWeeks = [mapPK(wk)]

        // 从本周 PK 数据中恢复体重趋势（重装 app 后 ProfileStore.weightHistory 为空）
        restoreWeightHistory(from: wk.me.todayRecords)
    }

    /// 刷新 PK 周数据（addRecord/removeRecord 成功后调用，确保 PK 页面及时更新）
    func refreshPKWeek() {
        Task { @MainActor in
            let wk = try? await CloudAPI.shared.pkWeek()
            if let wk = wk {
                applyPKWeek(wk)
            }
        }
    }

    /// 将后端 PK 周数据映射为本地的 PKWeekData（本周）
    private func mapPK(_ wk: CloudAPI.CkPKWeek) -> PKWeekData {
        func person(_ p: CloudAPI.CkPerson) -> PKPersonData {
            let (intake, burned, exMin, water, weights) = Self.buildDailyArrays(from: p.todayRecords)
            // 减重 = 周初体重 - 当前体重（weights 已前向填充，0 表示无数据）
            let weightChange = (weights.first ?? 0) - (weights.last ?? 0)
            return PKPersonData(
                calorieIn: intake.reduce(0, +),
                exerciseCal: burned.reduce(0, +),
                exerciseMin: exMin.reduce(0, +),
                weightChange: weightChange,
                waterIntake: water.reduce(0, +),
                starCount: 4,
                dailyIntake: intake,
                dailyBurned: burned,
                dailyExerciseMin: exMin,
                dailyWater: water,
                dailyWeights: weights)
        }
        return PKWeekData(weekLabel: "本周", me: person(wk.me),
                          partner: wk.partner.map(person) ?? person(wk.me))
    }

    /// 从云端本周记录中提取体重数据，恢复到 ProfileStore.weightHistory（用于趋势图）。
    /// 仅当本地 weightHistory 为空时才恢复，避免覆盖用户本地已有的更完整数据。
    @MainActor
    private func restoreWeightHistory(from records: [CloudAPI.CkRecord]) {
        let weightRecs = records.filter { $0.type == "weight" }
        guard !weightRecs.isEmpty else { return }

        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        var pts: [WeightPoint] = []
        for r in weightRecs {
            guard let dateStr = r.date, let d = fmt.date(from: dateStr), r.amount > 0 else { continue }
            // 同一天只保留最后一条
            if let idx = pts.firstIndex(where: { cal.isDate($0.date, inSameDayAs: d) }) {
                pts[idx] = WeightPoint(date: d, weight: r.amount)
            } else {
                pts.append(WeightPoint(date: d, weight: r.amount))
            }
        }
        guard !pts.isEmpty else { return }

        // 合并本地已有的历史数据（本地可能有更早的记录）
        let existing = ProfileStore.shared.weightHistory
        var merged = pts
        for p in existing {
            if !merged.contains(where: { cal.isDate($0.date, inSameDayAs: p.date) }) {
                merged.append(p)
            }
        }
        ProfileStore.shared.restoreWeightHistory(merged)
    }

    /// 将记录按日期分桶生成本周 7 天每日数组（索引对齐图表：0 = 周一 ... 6 = 周日）
    private static func buildDailyArrays(from records: [CloudAPI.CkRecord])
        -> (intake: [Int], burned: [Int], exerciseMin: [Int], water: [Int], weights: [Double])
    {
        let cal = Calendar.current
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"

        // 计算本周一的日期 + 今天是本周第几天（0=周一 ... 6=周日）
        let now = Date()
        var mondayComp = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        mondayComp.weekday = 2 // 周一
        guard let monday = cal.date(from: mondayComp) else {
            return ([0,0,0,0,0,0,0], [0,0,0,0,0,0,0], [0,0,0,0,0,0,0], [0,0,0,0,0,0,0], [0,0,0,0,0,0,0])
        }
        let todayIndex = max(0, min(6, cal.dateComponents([.day], from: monday, to: now).day ?? 0))

        // 构建周一～周日日期标签（索引 0=周一 ... 6=周日）
        var dateLabels: [String] = []
        for i in 0..<7 {
            if let d = cal.date(byAdding: .day, value: i, to: monday) {
                dateLabels.append(fmt.string(from: d))
            }
        }

        // 按 date 字段分组
        var byDate: [String: [CloudAPI.CkRecord]] = [:]
        for r in records {
            guard let d = r.date else { continue }
            byDate[d, default: []].append(r)
        }

        var intake = Array(repeating: 0, count: 7)
        var burned = Array(repeating: 0, count: 7)
        var exerciseMin = Array(repeating: 0, count: 7)
        var water = Array(repeating: 0, count: 7)
        var weights = Array(repeating: 0.0, count: 7)

        for (i, label) in dateLabels.enumerated() {
            guard let dayRecs = byDate[label] else { continue }
            intake[i] = Int(dayRecs.filter { $0.type == "food" }.reduce(0) { $0 + $1.calories })
            burned[i] = Int(dayRecs.filter { $0.type == "exercise" }.reduce(0) { $0 + $1.calories })
            exerciseMin[i] = Int(dayRecs.filter { $0.type == "exercise" }.reduce(0) { $0 + $1.amount })
            // 饮水：服务端按 created_at desc 返回（最新在前），取 first 即最新值
            if let w = dayRecs.filter({ $0.type == "water" }).first {
                water[i] = Int(w.amount)
            }
            // 体重：服务端按 created_at desc 返回（最新在前），取 first 即最新值
            if let w = dayRecs.filter({ $0.type == "weight" }).first {
                weights[i] = w.amount
            }
        }

        // 体重填充：只在「周一 ~ 今天」范围内前向填充（缺测天用前一次登记值）
        // 今天之后的未来天保持 0，不显示未登记的数据
        var lastWeight: Double = 0
        for i in 0...todayIndex {
            if weights[i] > 0 {
                lastWeight = weights[i]
            } else if lastWeight > 0 {
                weights[i] = lastWeight
            }
        }

        return (intake, burned, exerciseMin, water, weights)
    }
}

// MARK: - 持久化贴纸 DTO（用于 UserDefaults 序列化，不含 UIImage）

struct PersistedSticker: Codable {
    let recordId: String
    let imageName: String
    let imageData: Data?
    let name: String
    let cal: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let fiber: Int
    let sugar: Int
    let salt: Double
    let tip: String
}
