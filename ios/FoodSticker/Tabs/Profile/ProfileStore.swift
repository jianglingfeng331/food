import Foundation
import SwiftUI
import Combine

// MARK: - 个人中心数据存储（Mock 持久化）

/// 承载"我的"页各功能所需的本地数据：减脂目标、体重历史、运动计划、提醒设置。
/// 全部存 UserDefaults（Mock 阶段），后期可整体替换为云端。
final class ProfileStore: ObservableObject {
    static let shared = ProfileStore()

    // MARK: 减脂目标
    @Published var heightCm: Double          // 身高
    @Published var currentWeight: Double     // 当前体重
    @Published var targetWeight: Double      // 目标体重

    // MARK: 体重历史（日期 -> 公斤），用于趋势图
    @Published var weightHistory: [WeightPoint]

    // MARK: 运动计划（周一到周日）
    @Published var workouts: [WorkoutItem]

    // MARK: 提醒设置
    @Published var waterReminderOn: Bool
    @Published var waterReminderTime: Date
    @Published var weighReminderOn: Bool
    @Published var weighReminderTime: Date
    @Published var exerciseReminderOn: Bool
    @Published var exerciseReminderTime: Date

    private let defaults = UserDefaults.standard

    /// 登录用户昵称（注册/登录成功后由 AuthService 同步，供个人中心使用）
    @Published var profileName: String = ""

    // MARK: 初始化（含 Mock 种子数据）

    private init() {
        // 新用户注册后默认为 0，需手动进入减脂目标页设置
        let seedHeight: Double = 0
        let seedCurrent: Double = 0
        let seedTarget: Double = 0

        heightCm        = defaults.load("profile_height", default: seedHeight)
        currentWeight   = defaults.load("profile_currentWeight", default: seedCurrent)
        targetWeight    = defaults.load("profile_targetWeight", default: seedTarget)

        if let loaded = defaults.decode([WeightPoint].self, key: "profile_weightHistory") {
            weightHistory = loaded
        } else {
            // 不再生成 Mock 假数据，新用户初始为空
            weightHistory = []
        }

        if let loaded = defaults.decode([WorkoutItem].self, key: "profile_workouts") {
            workouts = loaded
        } else {
            workouts = WorkoutItem.seed()
        }

        waterReminderOn     = defaults.load("reminder_water_on", default: true)
        waterReminderTime   = defaults.load("reminder_water_time", default: Self.date(hour: 9, minute: 0))
        weighReminderOn     = defaults.load("reminder_weigh_on", default: true)
        weighReminderTime   = defaults.load("reminder_weigh_time", default: Self.date(hour: 8, minute: 0))
        exerciseReminderOn  = defaults.load("reminder_exercise_on", default: false)
        exerciseReminderTime = defaults.load("reminder_exercise_time", default: Self.date(hour: 19, minute: 0))
    }

    // MARK: 派生指标

    var bmi: Double {
        guard heightCm > 0 else { return 0 }
        let m = heightCm / 100
        return currentWeight / (m * m)
    }

    var bmiCategory: String {
        switch bmi {
        case 0..<18.5: return "偏瘦"
        case 18.5..<24: return "正常"
        case 24..<28: return "偏胖"
        default: return "肥胖"
        }
    }

    /// 已减公斤数：初始历史最高点 - 当前
    var weightLost: Double {
        guard let max0 = weightHistory.map({ $0.weight }).max() else { return 0 }
        return max(0, max0 - currentWeight)
    }

    /// 距目标剩余
    var remainingToTarget: Double {
        max(0, currentWeight - targetWeight)
    }

    // MARK: 写操作（自动持久化）

    /// 同步登录用户昵称（注册/登录成功后调用，确保「我的」页即时显示）
    func setLoggedInNickname(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profileName = trimmed.isEmpty ? profileName : trimmed
    }

    /// 首页/弹窗记录体重时同步写入历史（用于趋势图即时刷新）
    func addWeightPoint(_ kg: Double) {
        guard kg > 0 else { return }
        let today = WeightPoint(date: Date(), weight: kg)
        if let idx = weightHistory.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today.date) }) {
            weightHistory[idx] = today
        } else {
            weightHistory.append(today)
            weightHistory.sort { $0.date < $1.date }
        }
        currentWeight = kg
        defaults.save(weightHistory, key: "profile_weightHistory")
        defaults.save(currentWeight, key: "profile_currentWeight")
    }

    /// 清空游客态遗留的数据（体重历史曲线、目标/身高等）。
    /// 基于 uid 比较：仅当登录用户变化（新登录/切换账号）时才清理，
    /// 避免老用户重启 App 时误清真实数据。
    func clearGuestData() {
        let currentUid = AuthService.shared.currentUser?.uid ?? ""
        let lastUid = defaults.string(forKey: "profile_last_uid") ?? ""
        // uid 相同（同一用户重启）→ 不清理
        guard currentUid != lastUid else { return }
        // uid 变化（新登录/换账号）→ 清理游客/上一用户残留
        currentWeight = 0
        targetWeight = 0
        heightCm = 0
        weightHistory = []
        defaults.removeObject(forKey: "profile_currentWeight")
        defaults.removeObject(forKey: "profile_targetWeight")
        defaults.removeObject(forKey: "profile_height")
        defaults.removeObject(forKey: "profile_weightHistory")
        // 运动计划恢复成默认模板（不保留上一用户勾选状态）
        workouts = WorkoutItem.seed()
        defaults.save(workouts, key: "profile_workouts")
        // 记录当前 uid，下次同一用户重启不再清理
        defaults.set(currentUid, forKey: "profile_last_uid")
    }

    func saveGoals() {
        defaults.save(heightCm, key: "profile_height")
        defaults.save(currentWeight, key: "profile_currentWeight")
        defaults.save(targetWeight, key: "profile_targetWeight")
        // 同步今日体重点到历史
        let today = WeightPoint(date: Date(), weight: currentWeight)
        if let idx = weightHistory.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today.date) }) {
            weightHistory[idx] = today
        } else {
            weightHistory.append(today)
            weightHistory.sort { $0.date < $1.date }
        }
        defaults.save(weightHistory, key: "profile_weightHistory")
    }

    func toggleWorkout(_ id: UUID) {
        guard let idx = workouts.firstIndex(where: { $0.id == id }) else { return }
        workouts[idx].done.toggle()
        defaults.save(workouts, key: "profile_workouts")
    }

    func saveReminders() {
        defaults.save(waterReminderOn, key: "reminder_water_on")
        defaults.save(waterReminderTime, key: "reminder_water_time")
        defaults.save(weighReminderOn, key: "reminder_weigh_on")
        defaults.save(weighReminderTime, key: "reminder_weigh_time")
        defaults.save(exerciseReminderOn, key: "reminder_exercise_on")
        defaults.save(exerciseReminderTime, key: "reminder_exercise_time")
    }

    // MARK: - 从云端恢复（登录后 sync 调用）

    /// 从云端恢复减脂目标数据。仅写内存 + UserDefaults，不触发其他副作用。
    /// 用于重装 app 后从云端拉取用户资料并恢复到本地。
    /// 云端值为 0 时不覆盖本地已有值（云端可能未设置）。
    func restoreFromCloud(currentWeight: Double, targetWeight: Double, height: Double) {
        if currentWeight > 0 {
            self.currentWeight = currentWeight
            defaults.save(currentWeight, key: "profile_currentWeight")
        }
        if targetWeight > 0 {
            self.targetWeight = targetWeight
            defaults.save(targetWeight, key: "profile_targetWeight")
        }
        if height > 0 {
            self.heightCm = height
            defaults.save(height, key: "profile_height")
        }
    }

    /// 从云端恢复体重历史曲线（用于趋势图）。
    func restoreWeightHistory(_ points: [WeightPoint]) {
        guard !points.isEmpty else { return }
        weightHistory = points.sorted { $0.date < $1.date }
        defaults.save(weightHistory, key: "profile_weightHistory")
    }

    /// 修改昵称 / 头像：回写到登录态（AuthService），个人中心即时刷新
    func updateProfile(nickname: String, avatar: String) {
        guard let user = AuthService.shared.currentUser else { return }
        let updated = AuthUser(uid: user.uid, phone: user.phone, nickname: nickname.isEmpty ? user.nickname : nickname, avatar: avatar, loginType: user.loginType)
        AuthService.shared.updateCurrentUser(updated)
    }

    // MARK: 工具

    private static func date(hour: Int, minute: Int) -> Date {
        var c = DateComponents(); c.hour = hour; c.minute = minute
        return Calendar.current.date(from: c) ?? Date()
    }
}

// MARK: - 模型

struct WeightPoint: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let weight: Double
}

struct WorkoutItem: Codable, Identifiable {
    var id = UUID()
    let weekday: String
    let title: String
    let detail: String
    var done: Bool

    static func seed() -> [WorkoutItem] {
        let data: [(String, String, String)] = [
            ("周一", "慢跑", "30 分钟 · 配速 6'00\""),
            ("周二", "力量训练", "上肢 4 组 × 12"),
            ("周三", "休息 / 拉伸", "泡沫轴放松"),
            ("周四", "骑行", "40 分钟 · 中等强度"),
            ("周五", "HIIT", "20 分钟燃脂"),
            ("周六", "游泳", "1000 米"),
            ("周日", "散步", "8000 步"),
        ]
        return data.map { WorkoutItem(weekday: $0.0, title: $0.1, detail: $0.2, done: false) }
    }
}

// MARK: - UserDefaults 扩展

private extension UserDefaults {
    func save<T: Encodable>(_ value: T, key: String) {
        if let e = try? JSONEncoder().encode(value) { set(e, forKey: key) }
    }
    func load<T: Decodable>(_ key: String, default def: T) -> T {
        (decode(T.self, key: key) ?? def)
    }
    func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
