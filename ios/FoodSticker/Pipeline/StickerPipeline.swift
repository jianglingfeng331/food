import UIKit
import CoreImage

enum DeviceTier { case high, mid, low }

struct PipelineResult {
    let sticker: UIImage          // 透明底贴纸PNG（黑内轮廓+白外描边）
    let alphaPNG: Data            // 原始Alpha（供云端高清导出复用）
    let food: FoodInfo?           // 识别+营养结果
    let usedCloud: Bool
}

/// 端侧主流水线：并行预处理 → 串行推理（SAM → AnimeGAN → 合成），分类并行跑
/// 中高端机全流程 ≤1s
final class StickerPipeline {
    private let matting: MattingEngine
    private let cartoonizer: CartoonizeEngine
    private let classifier: FoodClassifier
    private let composer = StickerComposer()
    private let nutritionDB = NutritionDB.shared
    private let cloud = CloudAPI.shared
    let tier: DeviceTier

    private init(matting: MattingEngine, cartoonizer: CartoonizeEngine,
                 classifier: FoodClassifier, tier: DeviceTier) {
        self.matting = matting
        self.cartoonizer = cartoonizer
        self.classifier = classifier
        self.tier = tier
    }

    /// 后台并行加载全部模型（使用 MLModel.load 异步 API，避免主线程编译/加载警告）
    static func build() async throws -> StickerPipeline {
        let tier = Self.detectTier()
        async let matting = MattingEngine.load(tier: tier)
        async let cartoonizer = CartoonizeEngine.load(tier: tier)
        async let classifier = FoodClassifier.load()
        return try StickerPipeline(
            matting: await matting,
            cartoonizer: await cartoonizer,
            classifier: await classifier,
            tier: tier
        )
    }

    static func detectTier() -> DeviceTier {
        let ram = ProcessInfo.processInfo.physicalMemory / (1 << 30)
        if ram >= 6 { return .high }
        return ram >= 4 ? .mid : .low
    }

    /// 主入口：拍照原图 → 贴纸 + 营养
    func process(image: CGImage) async throws -> PipelineResult {
        // ── 并行：分类（独立分支）与 抠图→风格化（串行依赖链）同时跑 ──
        async let classifyTask: FoodInfo? = recognizeFood(image: image)

        // 串行推理链：SAM → 主体裁剪 → AnimeGAN → 合成
        let alpha = try matting.segment(image: image)                    // ~400ms
        let subject = Self.applyAlpha(image: image, alpha: alpha)        // 透明底主体
        let cartoon = try cartoonizer.cartoonize(subject: subject)       // ~180ms
        let maxSide: CGFloat = tier == .low ? 1080 : 2048
        let sticker = composer.compose(cartoon: cartoon, alpha: alpha,
                                       outlinePx: 4, maxSide: maxSide)   // ~80ms

        let food = await classifyTask
        let alphaPNG = UIImage(cgImage: alpha).pngData()!
        return PipelineResult(sticker: sticker, alphaPNG: alphaPNG,
                              food: food, usedCloud: food?.fromCloud ?? false)
    }

    /// 识别：端侧优先，置信度<85% 自动云端兜底
    private func recognizeFood(image: CGImage) async -> FoodInfo? {
        if let r = try? classifier.classify(image: image),
           r.confidence >= FoodClassifier.confidenceThreshold,
           let info = nutritionDB.query(classId: r.classId) {
            return info
        }
        return try? await cloud.recognizeFood(image: image)  // 冷门食品兜底 ≤3s
    }

    /// 手动修正食品名：本地别名模糊搜索 → 命中即返回；未命中走云端
    func correctFood(name: String) async -> FoodInfo? {
        if let info = nutritionDB.search(name: name) { return info }
        return try? await cloud.queryNutrition(name: name)
    }

    /// 高清导出：云端SD+ControlNet，复用端侧Alpha抠白底
    func exportHD(original: CGImage, alphaPNG: Data) async throws -> UIImage {
        try await cloud.generateHDSticker(image: original, alphaPNG: alphaPNG)
    }

    /// 原图 × Alpha → 透明底主体
    static func applyAlpha(image: CGImage, alpha: CGImage) -> CGImage {
        let ctx = CIContext()
        let out = CIImage(cgImage: image).applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: CIImage.empty()
                .cropped(to: CGRect(x: 0, y: 0, width: image.width, height: image.height)),
            kCIInputMaskImageKey: CIImage(cgImage: alpha)])
        return ctx.createCGImage(out, from: out.extent)!
    }
}
