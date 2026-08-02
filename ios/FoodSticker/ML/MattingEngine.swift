import CoreML
import CoreImage
import Accelerate

enum MattingError: Error {
    case modelNotFound(String)
    case featureNotFound(name: String)
    case renderFailed
}

/// 端侧抠图引擎：MobileSAM (FP16, ANE/Metal)
/// 输入拍摄原图 → 输出原图分辨率 Alpha 遮罩（已做1.5px高斯模糊消锯齿）
final class MattingEngine {
    private let encoder: MLModel
    private let decoder: MLModel
    private let ciContext = CIContext(options: [.cacheIntermediates: false])
    private let inputSize: Int   // 1024（低端机降级 512）

    private init(encoder: MLModel, decoder: MLModel, inputSize: Int) {
        self.encoder = encoder
        self.decoder = decoder
        self.inputSize = inputSize
    }

    /// 后台异步加载编码器/解码器（并行编译加载，避免主线程阻塞警告）
    static func load(tier: DeviceTier) async throws -> MattingEngine {
        let cfg = MLModelConfiguration()
        cfg.computeUnits = .cpuAndGPU   // ANE 不支持 MobileSAM 的某些 op，强制走 GPU/CPU
        guard let encURL = Bundle.main.url(forResource: "MobileSAMEncoder", withExtension: "mlpackage"),
              let decURL = Bundle.main.url(forResource: "MobileSAMDecoder", withExtension: "mlpackage") else {
            throw MattingError.modelNotFound("MobileSAMEncoder/Decoder.mlpackage")
        }
        let compiledEncURL = try await MLModel.compileModel(at: encURL)
        let compiledDecURL = try await MLModel.compileModel(at: decURL)
        async let enc = MLModel.load(contentsOf: compiledEncURL, configuration: cfg)
        async let dec = MLModel.load(contentsOf: compiledDecURL, configuration: cfg)
        let inputSize = tier == .low ? 512 : 1024
        return try MattingEngine(encoder: await enc, decoder: await dec, inputSize: inputSize)
    }

    /// - Returns: 原图分辨率的单通道 Alpha（CGImage, 灰度即alpha值）
    func segment(image: CGImage) throws -> CGImage {
        // 1. 等比缩放 + pad 到 inputSize²
        let scale = CGFloat(inputSize) / CGFloat(max(image.width, image.height))
        let sw = Int(CGFloat(image.width) * scale), sh = Int(CGFloat(image.height) * scale)
        let pixelBuffer = try image.resizedPixelBuffer(width: inputSize, height: inputSize,
                                                       contentWidth: sw, contentHeight: sh)

        // 2. 编码器：image → embeddings (1,256,64,64)
        let encOut = try encoder.prediction(from: MLDictionaryFeatureProvider(
            dictionary: ["image": MLFeatureValue(pixelBuffer: pixelBuffer)]))
        // 注意：coremltools mlprogram 模式下，输出名是 PyTorch JIT trace 的变量名 var_11
        guard let embFeature = encOut.featureValue(for: "var_11"),
              let embeddings = embFeature.multiArrayValue else {
            throw MattingError.featureNotFound(name: "var_11")
        }

        // 3. 解码器：中心正点提示（取景框引导主体居中），四角负点抑制背景
        let coords = try MLMultiArray(shape: [1, 5, 2], dataType: .float32)
        let labels = try MLMultiArray(shape: [1, 5], dataType: .float32)
        let pts: [(Float, Float, Float)] = [   // (x, y, label)
            (Float(sw) / 2, Float(sh) / 2, 1),
            (8, 8, 0), (Float(sw) - 8, 8, 0),
            (8, Float(sh) - 8, 0), (Float(sw) - 8, Float(sh) - 8, 0)]
        for (i, p) in pts.enumerated() {
            coords[[0, i, 0] as [NSNumber]] = NSNumber(value: p.0)
            coords[[0, i, 1] as [NSNumber]] = NSNumber(value: p.1)
            labels[[0, i] as [NSNumber]] = NSNumber(value: p.2)
        }
        let maskInput = try MLMultiArray(shape: [1, 1, 256, 256], dataType: .float32)
        let hasMask = try MLMultiArray(shape: [1], dataType: .float32)
        let origSize = try MLMultiArray(shape: [2], dataType: .float32)
        origSize[0] = NSNumber(value: inputSize); origSize[1] = NSNumber(value: inputSize)

        let decOut = try decoder.prediction(from: MLDictionaryFeatureProvider(dictionary: [
            "image_embeddings": MLFeatureValue(multiArray: embeddings),
            "point_coords": MLFeatureValue(multiArray: coords),
            "point_labels": MLFeatureValue(multiArray: labels),
            "mask_input": MLFeatureValue(multiArray: maskInput),
            "has_mask_input": MLFeatureValue(multiArray: hasMask),
            "orig_im_size": MLFeatureValue(multiArray: origSize)]))
        guard let maskFeature = decOut.featureValue(for: "masks"),
              let mask = maskFeature.multiArrayValue else {
            throw MattingError.featureNotFound(name: "masks")
        }

        // 4. logits → 二值alpha → 裁掉pad → 放大回原图 → 1.5px高斯模糊平滑边缘
        // mask 实际尺寸从 shape 推导（解码器通常输出 256×256，避免按 inputSize 越界读内存崩溃）
        let mh = Int(mask.shape[mask.shape.count - 2].intValue)
        let mw = Int(mask.shape[mask.shape.count - 1].intValue)
        let maskImage = mask.toAlphaCGImage(width: mw, height: mh, threshold: 0)
        // mask 对应 inputSize×inputSize 的带 pad 输入：有效内容位于顶部 sh 行，底部为 pad(0)
        let cropH = max(1, Int(round(CGFloat(sh) * CGFloat(mh) / CGFloat(inputSize))))
        let cropW = max(1, Int(round(CGFloat(sw) * CGFloat(mw) / CGFloat(inputSize))))
        let cropped = CIImage(cgImage: maskImage)
            .cropped(to: CGRect(x: 0, y: 0, width: cropW, height: cropH))
        let upscaled = cropped.transformed(by: .init(scaleX: CGFloat(image.width) / CGFloat(cropW),
                                                     y: CGFloat(image.height) / CGFloat(cropH)))
        let smoothed = upscaled
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 1.5])
            .cropped(to: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let final = ciContext.createCGImage(smoothed, from: smoothed.extent) else {
            throw MattingError.renderFailed
        }
        return final
    }
}
