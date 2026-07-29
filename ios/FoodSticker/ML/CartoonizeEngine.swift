import CoreML
import CoreImage

enum CartoonizeError: Error {
    case modelNotFound(String)
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
        cfg.computeUnits = .all
        guard let url = Bundle.main.url(forResource: "AnimeGANv3", withExtension: "mlpackage") else {
            throw CartoonizeError.modelNotFound("AnimeGANv3.mlpackage")
        }
        let model = try await MLModel.load(contentsOf: url, configuration: cfg)
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
        let flatCG = ciContext.createCGImage(flattened, from: flattened.extent)!

        let pb = try flatCG.resizedPixelBuffer(width: inputSize, height: inputSize,
                                               contentWidth: inputSize, contentHeight: inputSize)
        let out = try model.prediction(from: MLDictionaryFeatureProvider(
            dictionary: ["image": MLFeatureValue(pixelBuffer: pb)]))
        let cartoon = out.featureValue(for: "cartoon")!.multiArrayValue!
        // [-1,1] → RGB CGImage
        return cartoon.tanhToRGBCGImage(width: inputSize, height: inputSize)
    }
}
