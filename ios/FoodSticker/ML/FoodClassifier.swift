import CoreML

struct ClassifyResult {
    let classId: Int        // = nutrition.db food.class_id
    let labelEn: String
    let confidence: Float
}

enum ClassifierError: Error {
    case cropFailed
    case outputNotFound(name: String)
    case outputTypeMismatch(name: String)
    case modelNotFound(String)
}

/// 端侧食品分类：EfficientNet-Lite4（1000类, FP16）
/// 注意：模型输出特征名由 coremltools 自动命名为 "var_12"（shape [1,1000] FP16）
final class FoodClassifier {
    static let confidenceThreshold: Float = 0.85   // 低于此值走云端兜底

    private let model: MLModel
    private let labels: [String]
    private let inputSize = 300

    private init(model: MLModel, labels: [String]) {
        self.model = model
        self.labels = labels
    }

    /// 后台异步加载模型（编译 + 加载均在后台线程，避免主线程阻塞警告）
    static func load() async throws -> FoodClassifier {
        let cfg = MLModelConfiguration()
        cfg.computeUnits = .all
        guard let modelURL = Bundle.main.url(forResource: "FoodClassifierModel", withExtension: "mlpackage") else {
            throw ClassifierError.modelNotFound("FoodClassifierModel.mlpackage")
        }
        let model = try await MLModel.load(contentsOf: modelURL, configuration: cfg)
        guard let url = Bundle.main.url(forResource: "labels_1000", withExtension: "txt") else {
            throw ClassifierError.modelNotFound("labels_1000.txt")
        }
        let labels = try String(contentsOf: url, encoding: .utf8).split(separator: "\n").map(String.init)
        return FoodClassifier(model: model, labels: labels)
    }

    func classify(image: CGImage) throws -> ClassifyResult {
        // 中心裁方形 + 缩放到 300²（与训练 CenterCrop 一致）
        let side = min(image.width, image.height)
        guard let crop = image.cropping(to: CGRect(x: (image.width - side) / 2,
                                                    y: (image.height - side) / 2,
                                                    width: side, height: side)) else {
            throw ClassifierError.cropFailed
        }
        let pb = try crop.resizedPixelBuffer(width: inputSize, height: inputSize,
                                             contentWidth: inputSize, contentHeight: inputSize)
        let out = try model.prediction(from: MLDictionaryFeatureProvider(
            dictionary: ["image": MLFeatureValue(pixelBuffer: pb)]))

        // 输出特征名是 "var_12"（而非直观的 "probs"）
        guard let feature = out.featureValue(for: "var_12") else {
            throw ClassifierError.outputNotFound(name: "var_12")
        }
        guard let probs = feature.multiArrayValue else {
            throw ClassifierError.outputTypeMismatch(name: "var_12")
        }

        var bestId = 0
        var bestP: Float = 0
        for i in 0..<labels.count {
            let p = probs[i].floatValue
            if p > bestP { bestP = p; bestId = i }
        }
        return ClassifyResult(classId: bestId, labelEn: labels[bestId], confidence: bestP)
    }
}
