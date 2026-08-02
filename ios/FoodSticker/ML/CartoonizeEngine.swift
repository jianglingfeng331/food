import CoreML
import CoreImage

enum CartoonizeError: Error {
    case modelNotFound(String)
    case featureNotFound(name: String)
    case renderFailed
}

/// 端侧卡通风格化引擎：AnimeGANv3-Lite（食品贴纸风微调版, FP16）
/// 输入透明底食品主体图（先平铺白底再推理，避免透明区干扰）→ 输出卡通化RGB
final class CartoonizeEngine {
    private let model: MLModel
    private let ciContext = CIContext(options: [.cacheIntermediates: false])
    private let inputSize: Int   // 512（低端机 384）

    private init(model: MLModel, inputSize: Int) {
        self.model = model
        self.inputSize = inputSize
    }

    /// 后台异步加载模型（编译 + 加载均在后台线程，避免主线程阻塞警告）
    static func load(tier: DeviceTier) async throws -> CartoonizeEngine {
        let cfg = MLModelConfiguration()
        cfg.computeUnits = .cpuAndGPU   // 避免 ANE 不兼容导致模型加载失败
        guard let url = Bundle.main.url(forResource: "AnimeGANv3", withExtension: "mlpackage") else {
            throw CartoonizeError.modelNotFound("AnimeGANv3.mlpackage")
        }
        let compiledURL = try await MLModel.compileModel(at: url)
        let model = try await MLModel.load(contentsOf: compiledURL, configuration: cfg)
        let inputSize = tier == .low ? 384 : 512
        return CartoonizeEngine(model: model, inputSize: inputSize)
    }

    /// - Parameter subject: 透明背景的食品主体图
    /// - Returns: 卡通化后的 RGB 图（inputSize²，由调用方映射回原分辨率并复用Alpha裁剪）
    func cartoonize(subject: CGImage) throws -> CGImage {
        // 透明区填白（模型训练时A域即白底主体，保持分布一致）
        let white = CIImage(color: .white)
            .cropped(to: CGRect(x: 0, y: 0, width: subject.width, height: subject.height))
        let flattened = CIImage(cgImage: subject).composited(over: white)
        guard let flatCG = ciContext.createCGImage(flattened, from: flattened.extent) else {
            throw CartoonizeError.renderFailed
        }

        let pb = try flatCG.resizedPixelBuffer(width: inputSize, height: inputSize,
                                               contentWidth: inputSize, contentHeight: inputSize)
        let out = try model.prediction(from: MLDictionaryFeatureProvider(
            dictionary: ["image": MLFeatureValue(pixelBuffer: pb)]))
        // 选出“图像类”输出：4维且通道数为3（AnimeGAN 输出为 NCHW: [1,3,H,W]）。
        // 不能按名字猜（如 var_14 / var_13_cast_fp16 可能是中间特征图而非成品图），
        // 误取会拿到噪声张量 → 整屏雪花。
        var cartoon: MLMultiArray?
        for name in out.featureNames {
            guard let arr = out.featureValue(for: name)?.multiArrayValue,
                  arr.shape.count == 4,
                  arr.shape[1].intValue == 3 else { continue }
            cartoon = arr
            break
        }
        if cartoon == nil, let first = out.featureNames.first {
            cartoon = out.featureValue(for: first)?.multiArrayValue
        }
        guard let cartoon else {
            throw CartoonizeError.featureNotFound(name: "no-3channel-output-in-\(out.featureNames)")
        }
        // [-1,1] → RGB CGImage
        return cartoon.tanhToRGBCGImage(width: inputSize, height: inputSize)
    }
}
