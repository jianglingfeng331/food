import UIKit
import Vision
import CoreImage

/// 通用抠图引擎（单例）。
///
/// 职责：
/// 1. 端侧 Vision 前景分割（iOS 17+ 原生 `VNGenerateForegroundInstanceMaskRequest`，iOS 16 预留降级）。
/// 2. 蒙版后处理：1px 高斯羽化，消除锯齿。
/// 3. 贴纸渲染：白边 / 白底等样式。
///
/// 设计：单例 + 内部串行后台队列，对外回调统一回到主线程。可同时服务「前置抠图」与「后置抠图」（双次抠图复用同一套能力）。
final class VisionSegmentationHelper {

    /// 单例入口
    static let shared = VisionSegmentationHelper()

    /// 高清图处理上限边长：超过则降采样后再分割，避免 Vision mask buffer 触发 OOM（mach_vm_allocate）。
    /// iPhone 原相机照片可达 4032×3024，1024 对 280×280 展示足够，且能安全跑过 Vision + CIImage 链。
    private static let maxSegmentationSide: CGFloat = 1024

    private let ciContext = CIContext()
    private let workQueue = DispatchQueue(label: "foodsticker.segmentation")

    /// MobileSAM 端侧抠图引擎（懒加载，首次使用时同步加载一次）
    private var mattingEngine: MattingEngine?

    private init() {}

    // MARK: - 对外接口

    /// 通用前景抠图（异步）。
    /// 优先 Vision 原生（iOS 17+），失败自动回退 MobileSAM 端侧模型（iOS 16+ 可用），
    /// 保证任意系统版本都能拿到透明底抠图。
    /// - Parameters:
    ///   - image: 输入原图
    ///   - roiRect: 可选，限定识别区域（相对坐标 0~1，UIKit 原点左上）。仅框内内容参与分割。
    ///   - completion: 主线程回调透明底结果图；均失败时回调 `nil`。
    func segmentForeground(from image: UIImage,
                           roiRect: CGRect?,
                           completion: @escaping (UIImage?) -> Void) {
        workQueue.async { [weak self] in
            guard let self else { DispatchQueue.main.async { completion(nil) }; return }

            // ① Vision 原生（iOS 17+）
            if let visionCut = self._segmentVision(image, roi: roiRect) {
                print("[Segment] ✅ Vision 原生抠图成功")
                DispatchQueue.main.async { completion(visionCut) }
                return
            }

            // ② MobileSAM 端侧兜底（iOS 16+）
            if let samCut = self._segmentWithMobileSAM(image) {
                print("[Segment] ✅ MobileSAM 抠图成功（Vision 不可用）")
                DispatchQueue.main.async { completion(samCut) }
                return
            }

            print("[Segment] ⚠️ Vision 与 MobileSAM 均失败")
            DispatchQueue.main.async { completion(nil) }
        }
    }

    /// 贴纸效果渲染（同步，主线程调用即可）。
    /// - Parameters:
    ///   - transparentImage: 透明底原图
    ///   - borderWidth: 白边宽度（默认 8pt）
    ///   - withWhiteBackground: 是否填充纯白底（默认 false = 透明底）
    /// - Returns: 处理后的贴纸图
    func renderSticker(from transparentImage: UIImage,
                       borderWidth: CGFloat = 8,
                       withWhiteBackground: Bool = false) -> UIImage {
        guard let cg = transparentImage.cgImage else { return transparentImage }
        let ci = CIImage(cgImage: cg)
        let extent = ci.extent
        let clear = CIImage(color: CIColor.clear).cropped(to: extent)
        let white = CIImage(color: CIColor.white).cropped(to: extent)

        // 提取 alpha 通道，同时写入 R/G/B/A 四通道，
        // 确保无论 CIBlendWithMask 使用哪个通道做混合因子都能正确工作。
        let alphaMask = ci.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 1),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 1),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 1),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
        ])

        // 形态学膨胀：向外扩 borderWidth，得到包含主体的更大区域
        let dilated = alphaMask.applyingFilter("CIMorphologyRectangleMaximum", parameters: [
            "inputWidth": borderWidth,
            "inputHeight": borderWidth
        ])

        // 外扩区域 − 原主体 = 仅白边环
        let border = dilated.applyingFilter("CISubtractBlendMode", parameters: [
            "inputBackgroundImage": alphaMask
        ])

        // 用环作为蒙版，把白色填充到环位置
        let borderWhite = white.applyingFilter("CIBlendWithMask", parameters: [
            "inputBackgroundImage": clear,
            "inputMaskImage": border
        ])

        // 主体叠加在白边之上
        let subjectOverBorder = ci.applyingFilter("CISourceOverCompositing",
                                                  parameters: ["inputBackgroundImage": borderWhite])

        // 如需白底，再在最下层铺一层白色
        let finalCI: CIImage = withWhiteBackground
            ? subjectOverBorder.applyingFilter("CISourceOverCompositing",
                                               parameters: ["inputBackgroundImage": white])
            : subjectOverBorder

        guard let outCG = ciContext.createCGImage(finalCI, from: extent) else { return transparentImage }
        return UIImage(cgImage: outCG)
    }

    // MARK: - 内部实现

    // MARK: - Vision 原生（iOS 17+）

    private func _segmentVision(_ image: UIImage, roi: CGRect?) -> UIImage? {
        guard let cg = image.cgImage else { return nil }

        // 分辨率守卫
        let maxDim = max(CGFloat(cg.width), CGFloat(cg.height))
        let workCG: CGImage
        if maxDim > Self.maxSegmentationSide {
            guard let down = image.resized(maxSide: Self.maxSegmentationSide).cgImage else { return nil }
            workCG = down
        } else {
            workCG = cg
        }

        if #available(iOS 17.0, *) {
            print("[Vision] 进入原生分割分支，系统版本 \(UIDevice.current.systemVersion)，输入 \(workCG.width)×\(workCG.height)")
            return segmentNative(workCG, roi: roi)
        }
        print("[Vision] 系统 < iOS 17.0（当前 \(UIDevice.current.systemVersion)），跳过原生分割，将回退 MobileSAM")
        return nil
    }

    // MARK: - MobileSAM 端侧兜底

    /// 懒加载 MobileSAM（首次调用时同步阻塞当前后台队列加载一次）
    private func ensureMatting() -> MattingEngine? {
        if let e = mattingEngine { return e }
        let semaphore = DispatchSemaphore(value: 0)
        var loaded: MattingEngine?
        Task.detached {
            do {
                let tier = DeviceTier.detect()
                loaded = try await MattingEngine.load(tier: tier)
            } catch {
                print("⚠️ MobileSAM 加载失败：\(error.localizedDescription)")
            }
            semaphore.signal()
        }
        semaphore.wait()
        mattingEngine = loaded
        return mattingEngine
    }

    /// 用 MobileSAM 端侧模型抠图（不依赖系统版本），返回透明底前景。
    private func _segmentWithMobileSAM(_ image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        guard let matting = ensureMatting() else { return nil }
        do {
            let alpha = try matting.segment(image: cg)
            // 将 alpha 遮罩应用到原图，得到透明底抠图
            let ctx = CIContext()
            let out = CIImage(cgImage: cg).applyingFilter("CIBlendWithMask", parameters: [
                kCIInputBackgroundImageKey: CIImage.empty()
                    .cropped(to: CGRect(x: 0, y: 0, width: cg.width, height: cg.height)),
                // CIBlendWithMask 使用遮罩的 alpha 通道：灰度图本身无 alpha，需先转成 alpha 遮罩
                kCIInputMaskImageKey: CIImage(cgImage: alpha).applyingFilter("CIMaskToAlpha")])
            guard let cutoutCG = ctx.createCGImage(out, from: out.extent) else { return nil }
            return UIImage(cgImage: cutoutCG)
        } catch {
            print("⚠️ MobileSAM 分割失败：\(error.localizedDescription)")
            return nil
        }
    }

    @available(iOS 17.0, *)
    private func segmentNative(_ cg: CGImage, roi: CGRect?) -> UIImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        if let r = roi {
            // UIKit（左上原点）→ Vision（左下原点），翻转 y
            request.regionOfInterest = CGRect(x: r.minX, y: 1 - r.maxY,
                                              width: r.width, height: r.height)
        }
        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        do { try handler.perform([request]) } catch {
            print("⚠️ [Vision] perform 抛错（设备可能无 Neural Engine 支持）：\(error)")
            return nil
        }

        let results = request.results ?? []
        print("[Vision] request.results.count = \(results.count)")
        guard let obs = results.first else {
            print("⚠️ [Vision] 未取到 VNInstanceMaskObservation（Vision 认为图像中无明显前景实例，返回空）")
            return nil
        }

        // 取全部前景实例生成蒙版（ROI 已限定主体区域，避免连带背景/餐具）。
        // 注：当前 SDK 未暴露按面积排序的实例框接口，故直接合并所有实例；
        // 如需「仅最大主体」，可在支持 instanceBoundingBoxes 的 SDK 中按面积筛选后传入 forInstances。
        let instances = obs.allInstances
        print("[Vision] 前景实例数 = \(instances.count)")
        guard !instances.isEmpty else {
            print("⚠️ [Vision] allInstances 为空，无可用前景实例")
            return nil
        }

        let maskBuffer: CVPixelBuffer
        do {
            maskBuffer = try obs.generateScaledMaskForImage(forInstances: instances, from: handler)
        } catch {
            print("⚠️ [Vision] 生成蒙版失败：\(error)")
            return nil
        }
        return composite(cg, maskBuffer: maskBuffer)
    }

    /// 蒙版羽化（1px 高斯）+ 合成透明前景
    /// 用 Core Image（CIBlendWithMask + CIMaskToAlpha）合成，避免 `cg.masking` 因尺寸/格式不兼容而静默失败。
    private func composite(_ cg: CGImage, maskBuffer: CVPixelBuffer) -> UIImage? {
        let fg = CIImage(cgImage: cg)
        let mask = CIImage(cvImageBuffer: maskBuffer)
        // 1px 高斯羽化，消除边缘锯齿，贴合贴纸质感
        let feathered = mask.clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 1.0])
            .cropped(to: mask.extent)
        // 把 mask 的灰度亮度转为 alpha 通道，作为遮罩
        let maskAlpha = feathered.applyingFilter("CIMaskToAlpha")
        // 按 mask 合成：前景=原图，背景=透明 → 透明底抠图
        let out = fg.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: CIImage(color: CIColor.clear).cropped(to: fg.extent),
            kCIInputMaskImageKey: maskAlpha
        ])
        guard let outCG = ciContext.createCGImage(out, from: fg.extent) else {
            print("⚠️ [Vision] composite 生成 CGImage 失败")
            return nil
        }
        return UIImage(cgImage: outCG)
    }
}
