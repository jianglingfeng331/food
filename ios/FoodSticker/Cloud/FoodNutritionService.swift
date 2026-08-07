import UIKit

/// 食物营养识别服务（单例）。
///
/// 所有 AI 调用经 `CloudAPI` 走**服务端代理**（密钥仅存服务端环境变量），
/// 客户端不再持有任何火山方舟 / 大模型 API Key，杜绝密钥随 App 包泄露。
final class FoodNutritionService {

    static let shared = FoodNutritionService()

    private init() {}

    // MARK: - 图片识别
    /// 识别食物营养信息（看图）。经服务端 VLM 代理，返回完整 `FoodNutritionModel`。
    /// - Parameters:
    ///   - image: 拍照原图（内部自动压缩）
    ///   - completion: 主线程回调（模型 / 错误）
    func recognize(image: UIImage, completion: @escaping (FoodNutritionModel?, Error?) -> Void) {
        Task {
            do {
                let model = try await CloudAPI.shared.recognizeNutrition(image: image)
                DispatchQueue.main.async { completion(model, nil) }
            } catch {
                Log("[Nutrition] ❌ 服务端识别失败: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil, error) }
            }
        }
    }

    // MARK: - 名称识别
    /// 按食物名称重新分析营养（纯文本，无需图片）。经服务端 VLM 代理。
    /// - Parameters:
    ///   - name: 用户编辑后的食物名称
    ///   - completion: 主线程回调（模型 / 错误）
    func analyzeByName(_ name: String, completion: @escaping (FoodNutritionModel?, Error?) -> Void) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(nil, NSError(domain: "FoodNutrition", code: -2,
                                    userInfo: [NSLocalizedDescriptionKey: "名称不能为空"]))
            return
        }
        Task {
            do {
                let model = try await CloudAPI.shared.queryNutritionByName(trimmed)
                DispatchQueue.main.async { completion(model, nil) }
            } catch {
                Log("[Nutrition] ❌ 服务端查询失败: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil, error) }
            }
        }
    }
}
