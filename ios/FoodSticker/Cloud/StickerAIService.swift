import UIKit

/// AI 风格化生成网络层：对接「图生图(img2img)」API。
///
/// - 默认 `isStub = true`：直接返回输入图，保证无后端时演示链路可跑通。
/// - 配置 `baseURL` / `apiKey` 后可发起真实 multipart 请求（占位端点，参数可配置）。
/// - 内置固定的 iOS Emoji 风格正向 / 负面提示词模板。
/// - 支持「还原度」参数：越高越贴近原图造型（重绘幅度越小）。
struct StickerAIService {

    /// 服务基础地址（占位，自行替换为真实 img2img 端点）。
    var baseURL: URL? = nil
    /// API 路径。
    var apiPath: String = "/v1/img2img"
    /// 鉴权 Token（Bearer）。
    var apiKey: String? = nil
    /// 占位开关：true 时直接返回原图（无需后端），默认 true。
    var isStub: Bool = true

    /// 还原度 0...1：越高越贴近原图造型（重绘幅度越小）。默认 0.85。
    var fidelity: Double = 0.85

    /// iOS Emoji 风格正向提示词（固定模板）。
    let positivePrompt = """
    iOS emoji style 3D sticker, pure white background, clean vector outline, \
    soft ambient occlusion, glossy plastic material, centered, high detail, \
    official Apple memoji aesthetic, subject faithfully preserved
    """
    /// 负面提示词（固定模板）。
    let negativePrompt = """
    photo, realistic, blurry, lowres, deformed, extra limbs, \
    text, watermark, messy background, dark shadows, cropped
    """

    /// 触发生成。
    /// - Parameters:
    ///   - foreground: 抠好的透明底前景图。
    ///   - description: 主体描述文本（用于增强提示词，可空）。
    ///   - fidelity: 还原度 0...1，不传则用 `self.fidelity`。
    ///   - completion: 主线程回调结果（成功为成品贴纸图）。
    func generate(foreground: UIImage,
                  description: String = "",
                  fidelity: Double? = nil,
                  completion: @escaping (Result<UIImage, Error>) -> Void) {
        let fid = min(max(fidelity ?? self.fidelity, 0), 1)

        // 占位模式：直接返回原图，保证演示可用。
        if isStub || baseURL == nil {
            DispatchQueue.main.async { completion(.success(foreground)) }
            return
        }

        guard let url = baseURL?.appendingPathComponent(apiPath),
              let png = foreground.pngData() else {
            completion(.failure(NSError(domain: "StickerAIService", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "参数缺失或无法编码 PNG"])))
            return
        }

        // 还原度 → 重绘强度：还原度越高，重绘越小（更贴近原图）。
        let strength = 1.0 - fid

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        if let key = apiKey {
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        let boundary = "Boundary-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func append(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        append("prompt", positivePrompt + (description.isEmpty ? "" : ", \(description)"))
        append("negative_prompt", negativePrompt)
        append("strength", String(format: "%.2f", strength))
        append("image_strength", String(format: "%.2f", fid))

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"fg.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(png)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data, let img = UIImage(data: data) else {
                completion(.failure(NSError(domain: "StickerAIService", code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "响应解析失败"])))
                return
            }
            completion(.success(img))
        }.resume()
    }
}
