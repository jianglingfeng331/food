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

final class AppDataStore {
    static let shared = AppDataStore()

    // 用户信息
    var profile = UserProfile()
    var partnerProfile: UserProfile = {
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

    // 今日记录
    @Published var todayRecords: [DailyRecord] = [
        DailyRecord(type: .food, name: "鸡胸肉沙拉", calories: 320, amount: 200),
        DailyRecord(type: .food, name: "全麦面包", calories: 180, amount: 100),
        DailyRecord(type: .exercise, name: "跑步", calories: 300, amount: 30),
        DailyRecord(type: .water, name: "白开水", calories: 0, amount: 500),
        DailyRecord(type: .water, name: "矿泉水", calories: 0, amount: 300),
        DailyRecord(type: .weight, name: "今日体重", calories: 0, amount: 72.5),
    ]

    // 本周概览
    var todayCaloriesConsumed: Int { todayRecords.filter { $0.type == .food }.reduce(0) { $0 + $1.calories } }
    var todayExerciseCalories: Int { todayRecords.filter { $0.type == .exercise }.reduce(0) { $0 + $1.calories } }
    var todayWaterIntake: Int { todayRecords.filter { $0.type == .water }.reduce(0) { $0 + Int($1.amount) } }
    var todayWeight: Double { todayRecords.filter { $0.type == .weight }.last?.amount ?? profile.currentWeight }

    private init() {}

    func addRecord(_ record: DailyRecord) {
        todayRecords.append(record)
        Task {
            try? await CloudAPI.shared.addRecord(
                type: record.type.rawValue, name: record.name,
                calories: Double(record.calories), amount: record.amount,
                unit: record.unit, time: record.time)
        }
    }

    func removeRecord(_ id: String) {
        todayRecords.removeAll { $0.id == id }
        Task { try? await CloudAPI.shared.deleteRecord(id: id) }
    }

    // MARK: - 云端同步（替代硬编码 mock）
    /// App 启动时调用：登录演示账号并拉取首页/PK 数据
    @MainActor
    func bootstrap() async {
        if !CloudAPI.shared.isLoggedIn {
            _ = try? await CloudAPI.shared.login(userID: "user-1", password: "123456")
        }
        try? await sync()
    }

    /// 从后端刷新首页仪表盘与 PK 对比数据
    @MainActor
    func sync() async throws {
        let dash = try await CloudAPI.shared.dashboard()
        applyProfile(dash.user)
        todayRecords = dash.todayRecords.map {
            DailyRecord(id: $0.id, type: RecordType(rawValue: $0.type) ?? .food,
                        name: $0.name, calories: Int($0.calories),
                        amount: $0.amount, unit: $0.unit, time: $0.time)
        }
        if let wk = try? await CloudAPI.shared.pkWeek() {
            if let pu = wk.partner?.user { applyPartner(pu) }
            pkWeeks = [mapPK(wk)]
        }
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
