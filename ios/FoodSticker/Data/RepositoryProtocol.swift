import UIKit

// MARK: - 首页仪表盘 DTO

/// 首页仪表盘聚合数据（对齐 GET /dashboard 响应结构）
/// 所有可选字段在游客态/无数据时为 nil，UI 层据此显示占位。
struct DashboardData: Sendable {
    // 本人
    let myNickname: String?
    let myAvatarURL: String?

    // 对手（无对手时为 nil）
    let opponentNickname: String?
    let opponentAvatarURL: String?
    let opponentScore: Int?
    let opponentIsLeader: Bool

    // PK 本周概要
    let hasOpponent: Bool
    let myScore: Int?
    let myWins: Int?
    let opponentWins: Int?

    // 今日数据（nil = 暂无记录）
    let todayCalorieIntake: Int?
    let todayCalorieGoal: Int
    let todayExerciseCalories: Int?
    let todayExerciseMinutes: Int?
    let todayWaterML: Int?
    let waterGoalML: Int
    let latestWeight: Double?
    let lastWeightTime: String?
}

// MARK: - 贴纸 DTO

/// 单个贴纸完整信息（对齐 GET /stickers 响应）
struct StickerItem: Identifiable, Sendable {
    let id: String
    let name: String
    let imageURL: String?            // 远端贴纸用 URL
    let imageData: Data?             // 本地预设/缓存用 Data
    let thumbnailData: Data?
    let kcalPer100g: Double
    let proteinG: Double
    let carbG: Double
    let fatG: Double
    let typicalPortionG: Double
    let useCount: Int
    let isPreset: Bool
    let createdAt: Date
}

// MARK: - PK 周数据 DTO

/// PK 双人本周完整对比数据（对齐 GET /pk/week 响应）
/// 比分计算由后端完成，前端仅渲染。
struct PKWeeklyData: Sendable {

    struct Person: Sendable {
        let nickname: String
        let avatarURL: String?
        /// 每日摄入 kcal（7 天数组）
        let dailyIntake: [Int]
        /// 每日运动消耗 kcal
        let dailyBurned: [Int]
        /// 每日运动时长 min
        let exerciseMinutes: [Int]
        /// 每日体重 kg
        let weights: [Double]
        /// 每日饮水 ml
        let waterML: [Int]
        let waterGoalML: Int
    }

    struct Metric: Sendable {
        let label: String           // e.g. "平均摄入", "总消耗", "本周减重", "饮水达标率"
        let myValue: Double
        let opponentValue: Double
        let myWins: Bool
        let desc: String            // e.g. "越低越好" / "越高越好"
    }

    let weekLabel: String           // e.g. "本周"
    let me: Person
    let opponent: Person
    let metrics: [Metric]
    let meWinsTotal: Int
    let opponentWinsTotal: Int
    let leaderIsMe: Bool
}

// MARK: - PK 绑定 DTO

/// 绑定关系状态
struct PKBindStatus: Sendable {
    enum State: Sendable {
        case unbound
        case pending         // 等待对方确认
        case bound(opponent: PKOpponentInfo)
    }
    let state: State
}

struct PKOpponentInfo: Sendable {
    let uid: String
    let nickname: String
    let avatarURL: String?
}

// MARK: - Repository 协议定义

/// 首页仪表盘数据仓库
protocol DashboardRepository: AnyObject {
    /// 获取首页聚合数据
    /// - 游客态返回所有字段为 nil 的空结构（仅含目标默认值）
    /// - 登录后返回真实数据
    func fetchDashboard() async throws -> DashboardData
}

/// 贴纸数据仓库
protocol StickerRepository: AnyObject {
    /// 获取当前用户贴纸列表（含系统预设 + 用户生成）
    func fetchStickers() async throws -> [StickerItem]
    /// 上传新贴纸（图片 + 营养元数据）
    func uploadSticker(image: UIImage, name: String, nutrition: StickerNutrition) async throws -> StickerItem
    /// 更新贴纸元数据（主要用于修正食品名/营养信息）
    func updateSticker(id: String, name: String?, nutrition: StickerNutrition?) async throws -> StickerItem
    /// 删除贴纸
    func deleteSticker(id: String) async throws
    /// 记录贴纸使用（增加计数器，用于统计分析）
    func markUsed(id: String) async throws
}

/// 贴纸营养元数据
struct StickerNutrition: Sendable {
    let kcalPer100g: Double
    let proteinG: Double
    let carbG: Double
    let fatG: Double
    let typicalPortionG: Double
}

/// PK 数据仓库
protocol PKRepository: AnyObject {
    // MARK: 绑定
    /// 向指定用户发送 PK 绑定请求
    func sendBindRequest(opponentUID: String) async throws -> PKBindStatus
    /// 查询当前绑定状态
    func getBindStatus() async throws -> PKBindStatus
    /// 解除绑定
    func unbind() async throws

    // MARK: 周数据
    /// 获取本周双方完整 PK 对比数据
    /// 服务端从双方记录中汇总计算，前端直接渲染
    func fetchWeeklyData() async throws -> PKWeeklyData
    /// 提交每日记录后通知服务端更新 PK 汇总
    func submitDailyRecord() async throws
}
