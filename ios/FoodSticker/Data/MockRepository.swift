import UIKit

// MARK: - 模拟 Dashboard 仓库

/// 返回与当前 HomeView 中硬编码数据完全一致的 mock 结构，
/// 确保切换到 Repository 模式后 UI 表现无差异。
final class MockDashboardRepository: DashboardRepository {

    /// 模拟昵称（与 HomeView.nickname = "小鹿" 一致）
    static let mockNickname = "小鹿"
    /// 模拟对手昵称（与 HomeView.user2.name = "小宇" 一致）
    static let rivalNickname = "小宇"

    func fetchDashboard() async throws -> DashboardData {
        // 模拟 200ms 网络延迟，让 UI 感知数据加载过程
        try? await Task.sleep(nanoseconds: 200_000_000)

        return DashboardData(
            // 本人
            myNickname: Self.mockNickname,
            myAvatarURL: nil,                     // 演示阶段无远端头像，使用本地 AvatarStore

            // 对手
            opponentNickname: Self.rivalNickname,
            opponentAvatarURL: nil,
            opponentScore: 1080,
            opponentIsLeader: true,

            // PK 概要
            hasOpponent: true,
            myScore: 1420,
            myWins: 2,
            opponentWins: 2,

            // 今日数据（对齐 HomeView：intake=1450, target=1500, exerciseCal=256,
            // water=1050, weight=nil, weightMeta="点击加号记录 · 上次 08:15"）
            todayCalorieIntake: 1450,
            todayCalorieGoal: 1500,
            todayExerciseCalories: 256,
            todayExerciseMinutes: nil,             // 首页不展示此字段
            todayWaterML: 1050,
            waterGoalML: 2000,                     // 对齐 AppDataStore.waterGoal
            latestWeight: nil,
            lastWeightTime: "08:15"
        )
    }
}

/// 返回空/占位数据的游客态 Dashboard
final class GuestDashboardRepository: DashboardRepository {
    func fetchDashboard() async throws -> DashboardData {
        try? await Task.sleep(nanoseconds: 100_000_000)

        return DashboardData(
            myNickname: nil,                       // 游客无昵称，UI 显示"未登录"
            myAvatarURL: nil,
            opponentNickname: nil,
            opponentAvatarURL: nil,
            opponentScore: nil,
            opponentIsLeader: false,
            hasOpponent: false,
            myScore: nil,
            myWins: nil,
            opponentWins: nil,
            todayCalorieIntake: nil,
            todayCalorieGoal: 1500,               // 默认目标
            todayExerciseCalories: nil,
            todayExerciseMinutes: nil,
            todayWaterML: nil,
            waterGoalML: 2000,
            latestWeight: nil,
            lastWeightTime: nil
        )
    }
}

// MARK: - 模拟 Sticker 仓库

final class MockStickerRepository: StickerRepository {
    /// 模拟预设贴纸（沿用 CardMock.stickers 逻辑 + AppDataStore.savedStickers）
    private var items: [StickerItem]

    init() {
        self.items = MockStickerRepository.buildMockItems()
    }

    private static func buildMockItems() -> [StickerItem] {
        // 直接复用 AppDataStore 或 CardMock 的贴纸数据
        // 这里使用简洁的占位列表，实际接入时从 AppDataStore.shared.savedStickers 映射
        return []
    }

    func fetchStickers() async throws -> [StickerItem] {
        try? await Task.sleep(nanoseconds: 150_000_000)
        // 当前：与 AppDataStore.savedStickers 保持同步
        // 后续 Remote 实现将替换此逻辑为远端 API
        return items
    }

    func uploadSticker(image: UIImage, name: String, nutrition: StickerNutrition) async throws -> StickerItem {
        try? await Task.sleep(nanoseconds: 300_000_000)
        let item = StickerItem(
            id: UUID().uuidString,
            name: name,
            imageURL: nil,
            imageData: image.pngData(),
            thumbnailData: nil,
            kcalPer100g: nutrition.kcalPer100g,
            proteinG: nutrition.proteinG,
            carbG: nutrition.carbG,
            fatG: nutrition.fatG,
            typicalPortionG: nutrition.typicalPortionG,
            useCount: 0,
            isPreset: false,
            createdAt: Date()
        )
        items.insert(item, at: 0)
        return item
    }

    func updateSticker(id: String, name: String?, nutrition: StickerNutrition?) async throws -> StickerItem {
        try? await Task.sleep(nanoseconds: 200_000_000)
        guard let idx = items.firstIndex(where: { $0.id == id }) else {
            throw StickerRepoError.notFound
        }
        let old = items[idx]
        let updated = StickerItem(
            id: old.id, name: name ?? old.name,
            imageURL: old.imageURL, imageData: old.imageData,
            thumbnailData: old.thumbnailData,
            kcalPer100g: nutrition?.kcalPer100g ?? old.kcalPer100g,
            proteinG: nutrition?.proteinG ?? old.proteinG,
            carbG: nutrition?.carbG ?? old.carbG,
            fatG: nutrition?.fatG ?? old.fatG,
            typicalPortionG: nutrition?.typicalPortionG ?? old.typicalPortionG,
            useCount: old.useCount, isPreset: old.isPreset, createdAt: old.createdAt
        )
        items[idx] = updated
        return updated
    }

    func deleteSticker(id: String) async throws {
        try? await Task.sleep(nanoseconds: 150_000_000)
        items.removeAll { $0.id == id }
    }

    func markUsed(id: String) async throws {
        guard let idx = items.firstIndex(where: { $0.id == $0.id }) else { return }
        let old = items[idx]
        items[idx] = StickerItem(
            id: old.id, name: old.name, imageURL: old.imageURL,
            imageData: old.imageData, thumbnailData: old.thumbnailData,
            kcalPer100g: old.kcalPer100g, proteinG: old.proteinG,
            carbG: old.carbG, fatG: old.fatG,
            typicalPortionG: old.typicalPortionG,
            useCount: old.useCount + 1, isPreset: old.isPreset, createdAt: old.createdAt
        )
    }

    enum StickerRepoError: Error { case notFound }
}

// MARK: - 模拟 PK 仓库

/// 返回与 PKMock 完全一致的数据，确保 PK 页面图表渲染不变。
final class MockPKRepository: PKRepository {

    // MARK: 绑定

    func sendBindRequest(opponentUID: String) async throws -> PKBindStatus {
        try? await Task.sleep(nanoseconds: 300_000_000)
        return PKBindStatus(state: .pending)
    }

    func getBindStatus() async throws -> PKBindStatus {
        try? await Task.sleep(nanoseconds: 100_000_000)
        return PKBindStatus(state: .bound(opponent: PKOpponentInfo(
            uid: "mock-rival-uid",
            nickname: MockDashboardRepository.rivalNickname,
            avatarURL: nil
        )))
    }

    func unbind() async throws {
        try? await Task.sleep(nanoseconds: 200_000_000)
    }

    // MARK: 周数据

    /// 与 PKMock.me / PKMock.rival 完全对齐
    func fetchWeeklyData() async throws -> PKWeeklyData {
        try? await Task.sleep(nanoseconds: 250_000_000)
        return Self.buildMockWeeklyData()
    }

    func submitDailyRecord() async throws {
        // Mock 实现无需实际提交
    }

    // MARK: 数据构造

    private static func buildMockWeeklyData() -> PKWeeklyData {
        let me = PKWeeklyData.Person(
            nickname: MockDashboardRepository.mockNickname,
            avatarURL: nil,
            dailyIntake: [1450, 1520, 1380, 1600, 1490, 1700, 1400],
            dailyBurned: [320, 280, 410, 350, 300, 460, 380],
            exerciseMinutes: [45, 38, 55, 47, 40, 65, 52],
            weights: [58.2, 58.0, 57.7, 57.9, 57.5, 57.3, 57.1],
            waterML: [1300, 1500, 1600, 1400, 1500, 1700, 1500],
            waterGoalML: 2000
        )

        let opponent = PKWeeklyData.Person(
            nickname: MockDashboardRepository.rivalNickname,
            avatarURL: nil,
            dailyIntake: [1280, 1350, 1420, 1300, 1450, 1250, 1380],
            dailyBurned: [260, 300, 240, 350, 280, 320, 290],
            exerciseMinutes: [35, 42, 33, 50, 40, 45, 39],
            weights: [55.6, 55.4, 55.5, 55.2, 55.0, 54.9, 54.7],
            waterML: [1100, 1300, 1400, 1200, 1300, 1450, 1300],
            waterGoalML: 1800
        )

        // 四个维度指标，与 PKMock.metrics 对齐
        let metrics: [PKWeeklyData.Metric] = {
            func avg(_ a: [Int]) -> Double { Double(a.reduce(0, +)) / Double(a.count) }
            func sum(_ a: [Int]) -> Double { Double(a.reduce(0, +)) }

            let meAvgIntake = avg(me.dailyIntake)    // ≈ 1506
            let opAvgIntake = avg(opponent.dailyIntake) // ≈ 1349
            let meTotalBurn = sum(me.dailyBurned)     // 2500
            let opTotalBurn = sum(opponent.dailyBurned) // 2040
            let meWeightLoss = ((me.weights[0] - me.weights[6]) * 10).rounded() / 10  // 1.1
            let opWeightLoss = ((opponent.weights[0] - opponent.weights[6]) * 10).rounded() / 10 // 0.9
            let meWaterPct = (Double(me.waterML.filter { $0 >= me.waterGoalML }.count) / 7 * 100).rounded() // 0
            let opWaterPct = (Double(opponent.waterML.filter { $0 >= opponent.waterGoalML }.count) / 7 * 100).rounded() // 0

            return [
                PKWeeklyData.Metric(label: "平均每日摄入",
                                     myValue: meAvgIntake, opponentValue: opAvgIntake,
                                     myWins: false, desc: "平均摄入越低越好"),
                PKWeeklyData.Metric(label: "总运动消耗",
                                     myValue: meTotalBurn, opponentValue: opTotalBurn,
                                     myWins: true, desc: "总消耗越高越好"),
                PKWeeklyData.Metric(label: "本周减重",
                                     myValue: meWeightLoss, opponentValue: opWeightLoss,
                                     myWins: true, desc: "本周减重越多越好"),
                PKWeeklyData.Metric(label: "饮水达标率",
                                     myValue: meWaterPct, opponentValue: opWaterPct,
                                     myWins: false, desc: "达标天数比例"),
            ]
        }()

        let meWins = metrics.filter { $0.myWins }.count  // 2
        let opWins  = metrics.count - meWins             // 2

        return PKWeeklyData(
            weekLabel: "本周          ",
            me: me,
            opponent: opponent,
            metrics: metrics,
            meWinsTotal: meWins,
            opponentWinsTotal: opWins,
            leaderIsMe: meWins >= opWins
        )
    }
}
