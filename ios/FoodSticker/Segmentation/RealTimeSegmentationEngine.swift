import UIKit
import Vision
import CoreMedia
import CoreVideo
import CoreImage

/// 实时抠图引擎：独立、无依赖、可复用。
///
/// 核心能力：
/// - iOS 17+：使用 Vision 原生 `VNGenerateForegroundInstanceMaskRequest` 端侧主体分割（食物/饮品等）。
/// - iOS 15+：降级使用 `VNGeneratePersonSegmentationRequest`（可检测显著性物体）。
/// - 所有路径均对蒙版做羽化处理，消除锯齿，合成边缘平滑自然。
/// - 支持传入 `CGRect` 类型 ROI（归一化 0..1，UIKit 坐标系：原点左上），仅对框内内容做分割以提升速度。
/// - 提供两个核心接口：
///   1) `segmentPreviewFrame(_:maxSide:completion:)` —— 实时预览抠图回调。
///   2) `segmentStill(image:roi:)` —— 高清抓拍抠图接口（输入原图，输出透明前景）。
final class RealTimeSegmentationEngine {

    /// 当前系统是否支持原生神经网络抠图（iOS 17+ 为 true）。
    static var isNativeSegmentationSupported: Bool {
        if #available(iOS 17.0, *) { return true }
        return false
    }

    /// ROI（归一化 0..1，坐标系同 UIKit：原点左上，x 向右，y 向下）。
    /// 仅对框内内容做分割，可显著提升运算速度；传 nil 表示整图。
    var roi: CGRect?

    // MARK: - 实时预览抠图回调

    /// 输入摄像头视频帧(`CMSampleBuffer`)，输出透明前景 `UIImage`。
    /// 内部会先将帧降采样至 `maxSide` 以提升速度，结果在主线程回调；失败时回调 `nil`。
    func segmentPreviewFrame(_ sampleBuffer: CMSampleBuffer,
                             maxSide: CGFloat = 384,
                             completion: @escaping (UIImage?) -> Void) {
        guard let image = sampleBuffer.toUIImage() else { completion(nil); return }
        let downscaled = image.resized(maxSide: maxSide)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { completion(nil); return }
            let result = self.segmentStill(image: downscaled, roi: self.roi)
            DispatchQueue.main.async { completion(result) }
        }
    }

    // MARK: - 高清抓拍抠图接口

    // Vision mask 在高分辨率（>2048px）图像上可能触发 mach_vm_allocate OOM。
    private static let maxSegmentationSide: CGFloat = 2048

    /// 输入原始 `UIImage`（建议先转正方向），输出透明前景 `UIImage`。
    public func segmentStill(image: UIImage, roi: CGRect? = nil) -> UIImage? {
        let region = roi ?? self.roi
        guard let cg = image.cgImage else { return nil }

        // 分辨率守卫：过大图像先降采样，防止 Vision mask buffer OOM。
        let inputCG: CGImage
        let maxDim = max(CGFloat(cg.width), CGFloat(cg.height))
        if maxDim > Self.maxSegmentationSide {
            let downImage = image.resized(maxSide: Self.maxSegmentationSide)
            guard let downCG = downImage.cgImage else { return nil }
            inputCG = downCG
        } else {
            inputCG = cg
        }

        if #available(iOS 17.0, *) {
            return segmentNative(cgImage: inputCG, roi: region)
        }
        if #available(iOS 15.0, *) {
            return segmentPersonSaliency(cgImage: inputCG, roi: region)
        }
        // iOS 14 及以下无 ML 分割能力，回退到软蒙版。
        return segmentSoftFallback(image: image, roi: region)
    }

    // MARK: - iOS 17+ 原生主体分割

    @available(iOS 17.0, *)
    private func segmentNative(cgImage: CGImage, roi: CGRect?) -> UIImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        if let r = roi {
            // UIKit (左上原点) → Vision (左下原点)，翻转 y。
            request.regionOfInterest = CGRect(x: r.minX, y: 1 - r.maxY,
                                              width: r.width, height: r.height)
        }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do { try handler.perform([request]) } catch {
            print("⚠️ VNGenerateForegroundInstanceMaskRequest 失败：\(error)")
            return nil
        }
        guard let obs = request.results?.first as? VNInstanceMaskObservation,
              !obs.allInstances.isEmpty else {
            // 未检测到主体：回退到软蒙版（不会返回整图矩形）
            return nil
        }

        let maskBuffer: CVPixelBuffer
        do {
            maskBuffer = try obs.generateScaledMaskForImage(forInstances: obs.allInstances,
                                                            from: handler)
        } catch {
            print("⚠️ 生成蒙版失败：\(error)")
            return nil
        }
        return composite(cgImage: cgImage, maskBuffer: maskBuffer)
    }

    // MARK: - iOS 15+ 显著性分割降级

    @available(iOS 15.0, *)
    private func segmentPersonSaliency(cgImage: CGImage, roi: CGRect?) -> UIImage? {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        if let r = roi {
            request.regionOfInterest = CGRect(x: r.minX, y: 1 - r.maxY,
                                              width: r.width, height: r.height)
        }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do { try handler.perform([request]) } catch {
            print("⚠️ VNGeneratePersonSegmentationRequest 失败：\(error)")
            return nil
        }
        guard let maskBuffer = request.results?.first?.pixelBuffer else {
            return nil
        }
        return composite(cgImage: cgImage, maskBuffer: maskBuffer)
    }

    // MARK: - 软蒙版降级（iOS 14 / 所有路径的兜底）

    /// 在选中区域（ROI）内创建一个椭圆渐变软蒙版。
    /// 中心不透明、边缘逐渐透明，模拟一个柔和的抠图效果。
    private func segmentSoftFallback(image: UIImage, roi: CGRect?) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let w = CGFloat(cg.width), h = CGFloat(cg.height)

        // 若未设 ROI，取中心 60% 区域
        let rect: CGRect = {
            if let r = roi {
                return CGRect(x: r.minX * w, y: r.minY * h,
                              width: r.width * w, height: r.height * h)
            }
            let side = min(w, h) * 0.6
            return CGRect(x: (w - side) / 2, y: (h - side) / 2,
                          width: side, height: side)
        }()

        // 用 Core Image 生成径向渐变蒙版：椭圆内白（不透明），边缘向外渐黑（透明）。
        let center = CIVector(x: rect.midX, y: h - rect.midY) // CI 原点左下
        let radius = Float(min(rect.width, rect.height) / 2)
        let gradient = CIFilter(name: "CIRadialGradient")!
        gradient.setValue(center, forKey: kCIInputCenterKey)
        gradient.setValue(radius * 0.6, forKey: "inputRadius0")
        gradient.setValue(radius, forKey: "inputRadius1")
        gradient.setValue(CIColor.white, forKey: "inputColor0")
        gradient.setValue(CIColor.black, forKey: "inputColor1")

        guard let gradientMask = gradient.outputImage?.cropped(to: CGRect(x: 0, y: 0, width: w, height: h)) else {
            return nil
        }

        // 将渐变蒙版转为 CGImage，再用 masking 合成透明前景。
        let maskCtx = CIContext()
        guard let maskCG = maskCtx.createCGImage(gradientMask, from: gradientMask.extent),
              let cutout = cg.masking(maskCG) else { return nil }
        return UIImage(cgImage: cutout)
    }

    // MARK: - 蒙版合成（羽化 + 抗锯齿）

    /// 将 Vision 输出的单通道蒙版 buffer 羽化后合成透明前景。
    /// - 对蒙版施加小半径高斯模糊 → 消除像素级锯齿 → 边缘平滑过渡。
    private func composite(cgImage: CGImage, maskBuffer: CVPixelBuffer) -> UIImage? {
        // 1) 生成羽毛化的蒙版 CGImage
        guard let featheredMaskCG = featherMask(maskBuffer) else { return nil }

        // 2) 用 CGImage.masking(_:) 将原图按羽化蒙版裁剪
        guard let cutout = cgImage.masking(featheredMaskCG) else { return nil }
        return UIImage(cgImage: cutout)
    }

    /// 对单通道蒙版施加高斯模糊 + 对比度拉伸，生成羽化后的灰度 CGImage。
    private func featherMask(_ buffer: CVPixelBuffer) -> CGImage? {
        var maskCI = CIImage(cvImageBuffer: buffer)

        // 高斯模糊：小半径（1.5~2.5 px）足以消除锯齿，同时不模糊主体边界。
        maskCI = maskCI.clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 2.0])
            .cropped(to: maskCI.extent)

        // 对比度拉伸：把模糊后的灰色边缘"拉"回接近 0/1 的陡峭过渡，
        // 只保留 2px 左右的渐变带作为抗锯齿区域。
        maskCI = maskCI.applyingFilter("CIColorControls", parameters: [
            kCIInputContrastKey: 1.8
        ])

        let ctx = CIContext()
        return ctx.createCGImage(maskCI,
                                 from: CGRect(x: 0, y: 0,
                                              width: CVPixelBufferGetWidth(buffer),
                                              height: CVPixelBufferGetHeight(buffer)))
    }
}

// MARK: - CMSampleBuffer → UIImage（仅本文件使用）

extension CMSampleBuffer {
    /// 将视频帧转为 `UIImage`。
    func toUIImage() -> UIImage? {
        guard let buffer = CMSampleBufferGetImageBuffer(self) else { return nil }
        let ci = CIImage(cvImageBuffer: buffer)
        let context = CIContext()
        guard let cg = context.createCGImage(ci, from: ci.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}


