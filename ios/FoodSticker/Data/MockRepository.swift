import UIKit

// MARK: - 模拟 Dashboard 仓库

/// 返回与当前 HomeView 结构一致的 mock 数据，但昵称跟随 AppDataStore 的真实资料，
/// 避免首页/贴纸页出现硬编码的「小鹿/小宇」。
final class MockDashboardRepository: DashboardRepository {

    func fetchDashboard() async throws -> DashboardData {
        // 模拟 200ms 网络延迟，让 UI 感知数据加载过程
        try? await Task.sleep(nanoseconds: 200_000_000)

        let store = AppDataStore.shared
        let myName = store.profile.name.isEmpty ? nil : store.profile.name
        let rivalName = store.partnerProfile.name.isEmpty ? nil : store.partnerProfile.name

        // 检查 PK 绑定状态：PKBindingCoordinator 是 @MainActor，通过 MainActor.run 读取
        let (hasOpponent, opponentNick, opponentAvatar) = await MainActor.run {
            let c = PKBindingCoordinator.shared
            let bound = c.isBound
            let nick = bound ? (c.opponent?.nickname ?? rivalName) : rivalName
            let avatar = bound ? c.opponent?.avatar : nil
            return (bound, nick, avatar)
        }

        // 已清零所有假数据，用户无真实记录时全部为 0/nil，方便测试
        return DashboardData(
            myNickname: myName,
            myAvatarURL: nil,

            opponentNickname: opponentNick,
            opponentAvatarURL: opponentAvatar,
            opponentScore: nil,
            opponentCalorieGoal: nil,
            opponentIsLeader: false,

            // PK 概要：依据 PKBindingCoordinator 实时状态
            hasOpponent: hasOpponent,
            myScore: nil,
            myWins: nil,
            opponentWins: nil,

            // 今日数据全清零，仅当用户真有本地记录时才会被 store 数据覆盖
            todayCalorieIntake: nil,
            todayCalorieGoal: 0,
            todayExerciseCalories: nil,
            todayExerciseMinutes: nil,
            todayWaterML: nil,
            waterGoalML: 2000,
            latestWeight: nil,
            lastWeightTime: nil
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
            opponentCalorieGoal: nil,
            opponentIsLeader: false,
            hasOpponent: false,
            myScore: nil,
            myWins: nil,
            opponentWins: nil,
            todayCalorieIntake: nil,
            todayCalorieGoal: 0,                 // 游客态目标也清零，UI 显示 0
            todayExerciseCalories: nil,
            todayExerciseMinutes: nil,
            todayWaterML: nil,
            waterGoalML: 0,
            latestWeight: nil,
            lastWeightTime: nil
        )
    }
}

// MARK: - 模拟 Sticker 仓库

final class MockStickerRepository: StickerRepository {
    /// 默认无任何预设贴纸（游客态数据全为 0）；上传后才有数据
    private var items: [StickerItem] = []

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
            dietaryFiberG: nutrition.dietaryFiberG,
            sodiumMg: nutrition.sodiumMg,
            vitaminTips: nutrition.vitaminTips,
            typicalPortionG: nutrition.typicalPortionG,
            useCount: 0,
            isPreset: false,
            createdAt: Date()
        )
        items.removeAll { $0.name == name }
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
            dietaryFiberG: nutrition?.dietaryFiberG ?? old.dietaryFiberG,
            sodiumMg: nutrition?.sodiumMg ?? old.sodiumMg,
            vitaminTips: nutrition?.vitaminTips ?? old.vitaminTips,
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
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let old = items[idx]
        items[idx] = StickerItem(
            id: old.id, name: old.name, imageURL: old.imageURL,
            imageData: old.imageData, thumbnailData: old.thumbnailData,
            kcalPer100g: old.kcalPer100g, proteinG: old.proteinG,
            carbG: old.carbG, fatG: old.fatG,
            dietaryFiberG: old.dietaryFiberG,
            sodiumMg: old.sodiumMg,
            vitaminTips: old.vitaminTips,
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
        // 已清零：无对手绑定状态，方便测试
        return PKBindStatus(state: .unbound)
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
        let store = AppDataStore.shared
        let myName = store.profile.name.isEmpty ? "我" : store.profile.name
        let rivalName = store.partnerProfile.name.isEmpty ? "对手" : store.partnerProfile.name

        // 已清零：所有周数据为 0，方便测试
        let zeroIntake   = [0, 0, 0, 0, 0, 0, 0]
        let zeroBurned   = [0, 0, 0, 0, 0, 0, 0]
        let zeroExMin    = [0, 0, 0, 0, 0, 0, 0]
        let zeroWeights  = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        let zeroWater    = [0, 0, 0, 0, 0, 0, 0]

        let me = PKWeeklyData.Person(
            nickname: myName,
            avatarURL: nil,
            dailyIntake: zeroIntake,
            dailyBurned: zeroBurned,
            exerciseMinutes: zeroExMin,
            weights: zeroWeights,
            waterML: zeroWater,
            waterGoalML: 0
        )

        let opponent = PKWeeklyData.Person(
            nickname: rivalName,
            avatarURL: nil,
            dailyIntake: zeroIntake,
            dailyBurned: zeroBurned,
            exerciseMinutes: zeroExMin,
            weights: zeroWeights,
            waterML: zeroWater,
            waterGoalML: 0
        )

        // 指标全部归零，无输赢
        let metrics: [PKWeeklyData.Metric] = [
            PKWeeklyData.Metric(label: "平均每日摄入",
                                 myValue: 0, opponentValue: 0,
                                 myWins: false, desc: "平均摄入越低越好"),
            PKWeeklyData.Metric(label: "总运动消耗",
                                 myValue: 0, opponentValue: 0,
                                 myWins: false, desc: "总消耗越高越好"),
            PKWeeklyData.Metric(label: "本周减重",
                                 myValue: 0, opponentValue: 0,
                                 myWins: false, desc: "本周减重越多越好"),
            PKWeeklyData.Metric(label: "饮水达标率",
                                 myValue: 0, opponentValue: 0,
                                 myWins: false, desc: "达标天数比例"),
        ]

        return PKWeeklyData(
            weekLabel: "本周          ",
            me: me,
            opponent: opponent,
            metrics: metrics,
            meWinsTotal: 0,
            opponentWinsTotal: 0,
            leaderIsMe: false
        )
    }
}
