import UIKit

/// 卡通贴纸生成服务（单例）：通过服务端代理调用火山方舟图生图。
///
/// 流程：拍照原图 → CloudAPI 代理 → 服务端中转火山方舟 seedream → 返回卡通贴纸。
/// 客户端不再持有火山方舟 API Key，所有密钥仅存服务端环境变量。
final class EmojiStickerGenerator {

    static let shared = EmojiStickerGenerator()

    // MARK: - 兼容旧代码：FoodNutritionService 暂用的配置（待迁移到 CloudAPI）
    /// ⚠️ 已废弃：API Key 已迁移至服务端，此处仅为 FoodNutritionService 兼容保留。
    /// TODO: 将 FoodNutritionService 改为走 CloudAPI.shared.recognizeFood / queryNutrition
    @available(*, deprecated, message: "API Key 已迁移至服务端，请使用 CloudAPI.shared")
    struct Config {
        var apiKey: String = ""
        var baseURL: String = ""
        var modelName: String = ""
        var chatBaseURL: String = ""
        var visionModelName: String = ""
    }
    @available(*, deprecated, message: "API Key 已迁移至服务端，请使用 CloudAPI.shared")
    var config = Config()

    private init() {}

    // MARK: - 对外接口

    /// 生成卡通贴纸（通过服务端代理，客户端不再持有 API Key）。
    ///
    /// - Parameters:
    ///   - foodName: 识别出的食物名（驱动图生图 prompt）
    ///   - originalPhoto: 拍照原图（作为图生图参考图）
    ///   - fallbackImage: 兜底图（服务失败时直接返回）
    ///   - completion: 主线程回调（卡通贴纸 / 错误）
    func generateSticker(foodName: String,
                         originalPhoto: UIImage,
                         fallbackImage: UIImage,
                         completion: @escaping (UIImage?, Error?) -> Void) {

        Task {
            do {
                let sticker = try await CloudAPI.shared.generateSticker(
                    foodName: foodName,
                    originalPhoto: originalPhoto
                )
                DispatchQueue.main.async { completion(sticker, nil) }
            } catch {
                print("[EmojiSticker] ❌ 服务端代理失败: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(fallbackImage, nil) }
            }
        }
    }
}
