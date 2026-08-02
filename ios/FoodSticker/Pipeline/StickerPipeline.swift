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
    private let cartoonizer: CartoonizeEngine?   // 可选：卡通模型缺失时自动跳过卡通化
    private let classifier: FoodClassifier
    private let nutritionDB = NutritionDB.shared
    private let cloud = CloudAPI.shared
    let tier: DeviceTier
    /// 卡通模型是否可用（true=已加载并会卡通化；false=缺失，结果直接用抠图主体）
    let cartoonAvailable: Bool

    private init(matting: MattingEngine, cartoonizer: CartoonizeEngine?,
                 classifier: FoodClassifier, tier: DeviceTier) {
        self.matting = matting
        self.cartoonizer = cartoonizer
        self.classifier = classifier
        self.tier = tier
        self.cartoonAvailable = cartoonizer != nil
    }

    /// 后台并行加载全部模型（使用 MLModel.load 异步 API，避免主线程编译/加载警告）
    /// 注意：卡通模型为可选，加载失败不致命，仅跳过卡通化，抠图+识别照常工作
    static func build() async throws -> StickerPipeline {
        let tier = Self.detectTier()
        async let matting = MattingEngine.load(tier: tier)
        async let classifier = FoodClassifier.load()
        // 卡通模型可选：加载失败仅跳过卡通化，不让整个 build 抛错
        let cartoonizer: CartoonizeEngine?
        do {
            cartoonizer = try await CartoonizeEngine.load(tier: tier)
        } catch {
            cartoonizer = nil
            print("⚠️ [StickerPipeline] 卡通模型加载失败，已跳过卡通化（抠图+识别仍可用）：\(error.localizedDescription)")
        }
        return try StickerPipeline(
            matting: await matting,
            cartoonizer: cartoonizer,
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
    /// - Parameter onCutout: 抠图完成（拿到透明底主体、尚未卡通化）时的回调，
    ///   供 UI 先显示「已抠图」中间帧，复刻「先抠图后卡通」的逐帧过渡动效。
    func process(image: CGImage,
                 onCutout: ((CGImage) -> Void)? = nil) async throws -> PipelineResult {
        // ── 并行：分类（独立分支）与 抠图→风格化（串行依赖链）同时跑 ──
        async let classifyTask: FoodInfo? = recognizeFood(image: image)

        // 串行推理链：SAM → 主体裁剪 → AnimeGAN → 合成
        let alpha = try matting.segment(image: image)                    // ~400ms
        print("✅ [StickerPipeline] 抠图成功 alpha: \(alpha.width)×\(alpha.height)")
        let subject = Self.applyAlpha(image: image, alpha: alpha)        // 透明底主体
        // 抠图完成：先回传主体，让缩略图从「原图灰显」过渡到「抠出主体灰显」
        onCutout?(subject)
        // 卡通化：模型可用则卡通化；缺失或运行时失败则直接用主体（自动回退，不致命）
        let cartoon: CGImage
        if let cz = cartoonizer {
            do {
                cartoon = try cz.cartoonize(subject: subject)            // ~180ms
                print("✅ [StickerPipeline] 卡通化成功 cartoon: \(cartoon.width)×\(cartoon.height)")
            } catch {
                print("⚠️ [StickerPipeline] 卡通化运行时失败，回退到抠图主体：\(error.localizedDescription)")
                cartoon = subject
            }
        } else {
            print("⚠️ [StickerPipeline] 卡通模型不可用，直接使用抠图主体")
            cartoon = subject
        }
        let maxSide: CGFloat = tier == .low ? 1080 : 2048
        // 去除合成贴纸环节：卡通结果与原始Alpha对齐，生成透明底主体（无白边/黑描边）
        let sticker = Self.makeSticker(cartoon: cartoon, alpha: alpha, maxSide: maxSide)

        let food = await classifyTask
        let alphaPNG = UIImage(cgImage: alpha).pngData()!
        return PipelineResult(sticker: sticker, alphaPNG: alphaPNG,
                              food: food, usedCloud: food?.fromCloud ?? false)
    }

    /// 识别：仅走端侧分类 + 本地营养库。
    /// 说明：此前这里有一层「云端兜底」指向 127.0.0.1:8000（Mac 联调后端），
    /// 真机/模拟器永远连不到，会刷一堆 Connection refused 且无意义。
    /// 详情页的完整营养（含贴士/膳食纤维/钠）统一由老模块云端源
    /// （FoodNutritionService / 火山方舟）在「点开详情」时提供，故此处不再兜底。
    private func recognizeFood(image: CGImage) async -> FoodInfo? {
        if let r = try? classifier.classify(image: image),
           let info = nutritionDB.query(classId: r.classId) {
            return info
        }
        return nil
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
    /// 使用 Core Graphics 直接带遮罩绘制，确保输出 CGImage 一定携带 Alpha 通道，
    /// 避免 CIImage.empty + createCGImage 在部分情况下丢失 Alpha、透明像素显为黑色。
    static func applyAlpha(image: CGImage, alpha: CGImage) -> CGImage {
        let w = image.width
        let h = image.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(data: nil, width: w, height: h,
                                      bitsPerComponent: 8, bytesPerRow: 0,
                                      space: colorSpace, bitmapInfo: bitmapInfo.rawValue),
              let dataProvider = alpha.dataProvider,
              let mask = CGImage(maskWidth: alpha.width, height: alpha.height,
                                 bitsPerComponent: alpha.bitsPerComponent,
                                 bitsPerPixel: alpha.bitsPerPixel,
                                 bytesPerRow: alpha.bytesPerRow,
                                 provider: dataProvider,
                                 decode: nil, shouldInterpolate: false) else {
            // 兜底：若无法建 mask，回退到原图
            return image
        }
        context.clip(to: CGRect(x: 0, y: 0, width: w, height: h), mask: mask)
        context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return context.makeImage() ?? image
    }

    /// 去除合成贴纸后：卡通结果按原始Alpha对齐，仅做透明遮罩（无白边/黑描边），生成成品贴纸
    /// 同样使用 Core Graphics 带遮罩绘制，避免 CIImage.empty 丢失 Alpha 通道导致黑雪花。
    private static func makeSticker(cartoon: CGImage, alpha: CGImage, maxSide: CGFloat) -> UIImage {
        // 1) 用 Core Image 把 alpha 缩放到 maxSide 以内
        let alphaCI = CIImage(cgImage: alpha)
        let scale = min(1, maxSide / max(alphaCI.extent.width, alphaCI.extent.height))
        let alphaS: CGImage
        if scale < 1 {
            let scaled = alphaCI.transformed(by: .init(scaleX: scale, y: scale))
            let ctx = CIContext()
            alphaS = ctx.createCGImage(scaled, from: scaled.extent) ?? alpha
        } else {
            alphaS = alpha
        }

        // 2) 把 cartoon 缩放到与 alphaS 同分辨率
        let cartoonCI = CIImage(cgImage: cartoon)
        let sx = CGFloat(alphaS.width) / CGFloat(cartoon.width)
        let sy = CGFloat(alphaS.height) / CGFloat(cartoon.height)
        let cartoonS: CGImage
        if abs(sx - 1) > 0.001 || abs(sy - 1) > 0.001 {
            let scaled = cartoonCI.transformed(by: .init(scaleX: sx, y: sy))
            let ctx = CIContext()
            cartoonS = ctx.createCGImage(scaled, from: scaled.extent) ?? cartoon
        } else {
            cartoonS = cartoon
        }

        // 3) Core Graphics 带遮罩绘制，确保 Alpha 通道正确
        let w = alphaS.width
        let h = alphaS.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(data: nil, width: w, height: h,
                                      bitsPerComponent: 8, bytesPerRow: 0,
                                      space: colorSpace, bitmapInfo: bitmapInfo.rawValue),
              let dataProvider = alphaS.dataProvider,
              let mask = CGImage(maskWidth: alphaS.width, height: alphaS.height,
                                 bitsPerComponent: alphaS.bitsPerComponent,
                                 bitsPerPixel: alphaS.bitsPerPixel,
                                 bytesPerRow: alphaS.bytesPerRow,
                                 provider: dataProvider,
                                 decode: nil, shouldInterpolate: false) else {
            // 兜底：无遮罩直接返回缩放后的 cartoon
            return UIImage(cgImage: cartoonS)
        }
        context.clip(to: CGRect(x: 0, y: 0, width: w, height: h), mask: mask)
        context.draw(cartoonS, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let result = context.makeImage() else {
            return UIImage(cgImage: cartoonS)
        }
        return UIImage(cgImage: result)
    }
}
