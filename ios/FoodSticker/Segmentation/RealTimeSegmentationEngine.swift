import UIKit
import Vision
import CoreMedia
import CoreVideo
import CoreImage

/// 实时抠图引擎：独立、无依赖、可复用。
///
/// 核心能力：
/// - iOS 17+：使用 Vision 原生 `VNGenerateForegroundInstanceMaskRequest` 端侧主体分割（食物/饮品等）。
/// - iOS 16：兼容降级为 ROI 矩形蒙版（无神经网络抠图，仅按框选区域裁剪）。
/// - 支持传入 `CGRect` 类型 ROI（归一化 0..1，UIKit 坐标系：原点左上），仅对框内内容做分割以提升速度。
/// - 提供两个核心接口：
///   1) `segmentPreviewFrame(_:maxSide:completion:)` —— 实时预览抠图回调（输入视频帧，输出透明前景）。
///   2) `segmentStill(image:roi:)` —— 高清抓拍抠图接口（输入原图，输出透明前景）。
final class RealTimeSegmentationEngine {

    /// 当前系统是否支持原生神经网络抠图（iOS 17+ 为 true）。
    static var isNativeSegmentationSupported: Bool {
        if #available(iOS 17.0, *) { return true }
        return false
    }

    /// 分割模式。
    enum Mode {
        case native      // iOS 17+ Vision 主体分割
        case roiFallback // iOS 16 降级：ROI 矩形蒙版
    }
    var mode: Mode { Self.isNativeSegmentationSupported ? .native : .roiFallback }

    /// ROI（归一化 0..1，坐标系同 UIKit：原点左上，x 向右，y 向下）。
    /// 仅对框内内容做分割，可显著提升运算速度；传 nil 表示整图。
    var roi: CGRect?

    // MARK: - 实时预览抠图回调

    /// 输入摄像头视频帧(`CMSampleBuffer`)，输出透明前景 `UIImage`。
    /// 内部会先将帧降采样至 `maxSide` 以提升速度，结果在主线程回调；失败时回调 `nil`。
    /// - Parameters:
    ///   - sampleBuffer: 摄像头视频帧。
    ///   - maxSide: 预处理最大边长（默认 512），越小越快。
    ///   - completion: 主线程回调，参数为透明前景图（失败为 nil）。
    func segmentPreviewFrame(_ sampleBuffer: CMSampleBuffer,
                             maxSide: CGFloat = 512,
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

    /// 输入原始 `UIImage`（建议先转正方向），输出透明前景 `UIImage`。
    /// - Parameters:
    ///   - image: 待抠图原图。
    ///   - roi: 可选 ROI，传入则覆盖引擎默认的 `roi`。
    /// - Returns: 透明底前景图；失败返回 nil。
    func segmentStill(image: UIImage, roi: CGRect? = nil) -> UIImage? {
        let region = roi ?? self.roi
        if #available(iOS 17.0, *), let cg = image.cgImage {
            return segmentNative(cgImage: cg, roi: region)
        }
        return segmentROIFallback(image: image, roi: region)
    }

    // MARK: iOS 17+ 原生主体分割

    @available(iOS 17.0, *)
    private func segmentNative(cgImage: CGImage, roi: CGRect?) -> UIImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        if let r = roi {
            // UIKit 左上原点 → Vision 左下原点，需要翻转 y。
            let converted = CGRect(x: r.minX, y: 1 - r.maxY, width: r.width, height: r.height)
            request.regionOfInterest = converted
        }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("⚠️ VNGenerateForegroundInstanceMaskRequest 执行失败：\(error)")
            return nil
        }
        guard let observation = request.results?.first as? VNInstanceMaskObservation else { return nil }

        // 取全部实例（即画面中的主体）生成蒙版。
        let instances = observation.allInstances
        guard !instances.isEmpty else { return nil }

        let maskBuffer: CVPixelBuffer
        do {
            // 该 API 接收 VNImageRequestHandler，生成高分辨率蒙版（CVPixelBuffer）。
            maskBuffer = try observation.generateScaledMaskForImage(forInstances: instances,
                                                                    from: handler)
        } catch {
            print("⚠️ 生成蒙版失败：\(error)")
            return nil
        }

        // 用 Core Image 把蒙版作为 alpha，合成透明前景（原图叠加在透明背景上）。
        let originalCI = CIImage(cgImage: cgImage)
        let maskCI = CIImage(cvImageBuffer: maskBuffer)
        let transparentBG = CIImage(color: CIColor.clear).cropped(to: originalCI.extent)
        let blended = originalCI.applyingFilter("CIBlendWithMask",
                                                parameters: [
                                                    "inputBackgroundImage": transparentBG,
                                                    "inputMaskImage": maskCI
                                                ])
        let ciCtx = CIContext()
        guard let outCG = ciCtx.createCGImage(blended, from: blended.extent) else { return nil }
        return UIImage(cgImage: outCG)
    }

    // MARK: iOS 16 降级：ROI 矩形蒙版

    /// iOS 16 无神经网络抠图，降级为 ROI 矩形蒙版：ROI 内不透明、外部透明。
    /// 未提供 ROI 时整图为前景（等同于不裁剪）。
    private func segmentROIFallback(image: UIImage, roi: CGRect?) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let size = CGSize(width: cg.width, height: cg.height)

        let rect: CGRect
        if let r = roi {
            rect = CGRect(x: r.minX * size.width,
                          y: r.minY * size.height,
                          width: r.width * size.width,
                          height: r.height * size.height)
        } else {
            rect = CGRect(origin: .zero, size: size)
        }

        let maskW = Int(size.width), maskH = Int(size.height)
        let gray = CGColorSpaceCreateDeviceGray()
        // 灰度蒙版：亮=不透明。copy(masking:) 以亮度作为透明度。
        guard let ctx = CGContext(data: nil,
                                  width: maskW, height: maskH,
                                  bitsPerComponent: 8, bytesPerRow: maskW,
                                  space: gray,
                                  bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return image }
        ctx.setFillColor(CGColor(colorSpace: gray, components: [0, 1])!) // 黑=透明
        ctx.fill(CGRect(origin: .zero, size: size))
        ctx.setFillColor(CGColor(colorSpace: gray, components: [1, 1])!) // 白=不透明
        ctx.fill(rect)

        guard let maskCG = ctx.makeImage(),
              let cutout = cg.masking(maskCG) else { return image }
        return UIImage(cgImage: cutout)
    }
}

// MARK: - CMSampleBuffer → UIImage（仅本文件使用）

extension CMSampleBuffer {
    /// 将视频帧转为 `UIImage`（方向按默认，预览用足够）。
    func toUIImage() -> UIImage? {
        guard let buffer = CMSampleBufferGetImageBuffer(self) else { return nil }
        let ci = CIImage(cvImageBuffer: buffer)
        let context = CIContext()
        guard let cg = context.createCGImage(ci, from: ci.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
