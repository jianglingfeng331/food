import UIKit

/// 拍照链路对接层（单例）。
///
/// 职责：对接现有拍照界面的拍照回调，串联「前置抠图 → 双任务并行（营养识别 + 卡通贴纸生成）→ 结果聚合」。
/// 不改动现有拍照 UI 与交互，仅扩展后续处理链路。
///
/// 业务链路：
/// ```
/// 拍照原图 → 【第一次抠图：秒级预览】
/// 任务A（并行）：原图 → 智谱 glm-4v-flash 多模态 → 营养信息
/// 任务B（并行）：原图 → 火山方舟图生图 → 白底卡通图（不再依赖食物名，独立运行，不被营养识别超时拖累）
/// 两者结果聚合后统一回调
/// ```
final class FoodStickerCaptureProcessor {

    static let shared = FoodStickerCaptureProcessor()

    private let helper = VisionSegmentationHelper.shared
    private let nutrition = FoodNutritionService.shared
    private let sticker = EmojiStickerGenerator.shared

    private init() {}

    // MARK: - 对外接口

    /// 处理拍照结果，启动全链路流程。
    /// - Parameters:
    ///   - originalImage: 拍照原图
    ///   - roiRect: 可选 ROI（相对坐标 0~1），复用拍照界面选框
    ///   - onPreviewReady: 前置抠图完成、预览图（带白边）就绪回调（秒级）
    ///   - onNutritionReady: 营养识别独立早期回调（不等待贴纸图生成，快速回显用）
    ///   - onFinalResult: 最终结果回调（透明底贴纸 + 营养信息 + 错误）
    func processCapture(originalImage: UIImage,
                       roiRect: CGRect? = nil,
                       onPreviewReady: @escaping (UIImage) -> Void,
                       onNutritionReady: ((FoodNutritionModel?) -> Void)? = nil,
                       onFinalResult: @escaping (UIImage?, FoodNutritionModel?, Error?) -> Void) {
        // 第一次（前置）抠图：秒级给用户展示贴纸效果
        helper.segmentForeground(from: originalImage, roiRect: roiRect) { [weak self] cutout in
            guard let self else { return }
            Log("[Pipeline] 首次抠图: \(cutout != nil ? "成功" : "失败")")

            // 渲染带白边的预览图立即回传
            let preview: UIImage
            if let cut = cutout {
                preview = self.helper.renderSticker(from: cut, borderWidth: 8, withWhiteBackground: false)
            } else {
                // iOS 16 等无原生抠图：用原图白底预览兜底
                preview = self.helper.renderSticker(from: originalImage, borderWidth: 8, withWhiteBackground: true)
            }
            DispatchQueue.main.async { onPreviewReady(preview) }

            // 后续任务使用抠好的透明底图（无则用原图）
            let workImage = cutout ?? originalImage

            // 双任务并行：营养识别 + 卡通贴纸生成（两者不再串行依赖）
            let group = DispatchGroup()
            var stickerImg: UIImage?
            var nutritionModel: FoodNutritionModel?
            var nutritionError: Error?

            // 营养识别
            group.enter()
            self.nutrition.recognize(image: originalImage) { model, error in
                nutritionModel = model
                nutritionError = error
                // 独立早期回调：营养一到位立即通知（详情页可快速回显，无需等待贴纸图生成）
                if let cb = onNutritionReady { DispatchQueue.main.async { cb(model) } }
                group.leave()
            }

            // 卡通贴纸：直接并行启动，不再等待营养识别结果。
            // 传入抠好的 workImage（只含食物），让模型聚焦食物本体、彻底去掉盘子/背景，
            // 即使营养识别超时/失败也不会拖慢贴纸生成。
            group.enter()
            self.sticker.generateSticker(foodName: "delicious food",
                                         originalPhoto: workImage,
                                         fallbackImage: workImage) { img, _ in
                stickerImg = img
                group.leave()
            }

            // 全部完成后统一回调
            group.notify(queue: .main) {
                Log("[Pipeline] ===== 拍照处理完成 =====")
                Log("[Pipeline] nutritionModel: \(nutritionModel != nil ? "有" : "nil"), error: \(nutritionError?.localizedDescription ?? "无")")
                Log("[Pipeline] stickerImg: \(stickerImg != nil ? "有" : "nil")")
                onFinalResult(stickerImg, nutritionModel, nutritionError)
            }
        }
    }
}
