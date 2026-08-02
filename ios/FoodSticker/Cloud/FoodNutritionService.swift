import UIKit

/// 容错 CodingKey：允许模型字段名与 JSON key 之间做空格/下划线归一化
private struct FlexibleCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}

/// 食物营养识别服务（单例）：对接火山方舟多模态视觉模型（与图生图共用同一个 API Key / 域名）。
///
/// - 视觉识别接口：`POST {Config.chatBaseURL}`（OpenAI 兼容 chat/completions）
/// - 模型：`Config.visionModelName`（火山方舟视觉理解模型，需在控制台「模型推理」开通）
/// - 输入：原图压缩至 JPEG 0.7 质量后 base64 传入
/// - 输出：`response_format: json_object` 强制返回 JSON，解析为 `FoodNutritionModel`
///
/// ⚠️ 安全提示：客户端硬编码 Key 仅用于开发测试。生产环境务必改为后端代理转发，避免密钥泄露。
final class FoodNutritionService {

    static let shared = FoodNutritionService()

    /// 复用火山方舟配置（与图生图共用同一个 apiKey / 域名）。
    private var ark: EmojiStickerGenerator.Config { EmojiStickerGenerator.shared.config }

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 60
        return URLSession(configuration: cfg)
    }()

    /// 视觉模型候选列表：仅使用 Config.visionModelName（用户指定唯一模型，无兜底）。
    private var candidateVisionModels: [String] {
        [ark.visionModelName]
    }

    /// 已验证可用的模型下标，优先复用，避免每次都从头试
    private var preferredModelIndex: Int?

    /// 固定系统提示词（内置常量，不可修改）
    private let systemPrompt = """
    你是专业的食物营养分析师。请识别图片中的食物，严格按JSON格式返回结果，只输出JSON，不要任何额外文字、解释、markdown格式。
    字段要求：
    foodName：食物标准名称（中文）
    calories：每100克热量，单位千卡，纯数值
    protein：每100克蛋白质含量，单位g，纯数值
    fat：每100克脂肪含量，单位g，纯数值
    carbohydrate：每100克碳水化合物含量，单位g，纯数值
    dietaryFiber：每100克膳食纤维含量，单位g，纯数值
    sodium：每100克钠含量，单位mg，纯数值
    vitaminTips：单条字符串（注意必须是字符串，不是数组或列表），两句以内的健康小贴士，语气轻松幽默、像朋友间聊天，可带一点拟人化，别太严肃，控制在两行左右，不要 emoji、不要 markdown
    """

    /// 纯文本系统提示词（按名称估算营养，不依赖图片）
    private let namePrompt = """
    你是专业的食物营养分析师。请根据用户给出的食物名称，估算其每100克的营养成分，
    严格按JSON格式返回结果，只输出JSON，不要任何额外文字、解释、markdown格式。
    字段要求：
    foodName：食物标准名称（中文）
    calories：每100克热量，单位千卡，纯数值
    protein：每100克蛋白质含量，单位g，纯数值
    fat：每100克脂肪含量，单位g，纯数值
    carbohydrate：每100克碳水化合物含量，单位g，纯数值
    dietaryFiber：每100克膳食纤维含量，单位g，纯数值
    sodium：每100克钠含量，单位mg，纯数值
    vitaminTips：单条字符串（注意必须是字符串，不是数组或列表），两句以内的健康小贴士，语气轻松幽默、像朋友间聊天，可带一点拟人化，别太严肃，控制在两行左右，不要 emoji、不要 markdown
    """

    private init() {}

    // MARK: - 图片识别
    /// 识别食物营养信息（看图）。
    /// - Parameters:
    ///   - image: 拍照原图（内部自动压缩）
    ///   - completion: 主线程回调（模型 / 错误）
    func recognize(image: UIImage, completion: @escaping (FoodNutritionModel?, Error?) -> Void) {
        guard let jpeg = image.resized(maxSide: 1024).jpegData(compressionQuality: 0.7) else {
            completion(nil, NSError(domain: "FoodNutrition", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "图片编码失败"]))
            return
        }
        let b64 = jpeg.base64EncodedString()
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": [
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(b64)"]],
                ["type": "text", "text": "请识别这张食物图片的营养信息"]
            ]]
        ]
        performChat(messages: messages, attempt: 0, maxAttempts: 2,
                    modelIndex: preferredModelIndex ?? 0, completion: completion)
    }

    // MARK: - 名称识别
    /// 按食物名称重新分析营养（纯文本，无需图片）。
    /// - Parameters:
    ///   - name: 用户编辑后的食物名称
    ///   - completion: 主线程回调（模型 / 错误）
    func analyzeByName(_ name: String, completion: @escaping (FoodNutritionModel?, Error?) -> Void) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(nil, NSError(domain: "FoodNutrition", code: -2,
                                    userInfo: [NSLocalizedDescriptionKey: "名称不能为空"]))
            return
        }
        let messages: [[String: Any]] = [
            ["role": "system", "content": namePrompt],
            ["role": "user", "content": "请根据食物名称「\(trimmed)」估算其每100克的营养成分"]
        ]
        performChat(messages: messages, attempt: 0, maxAttempts: 2,
                    modelIndex: preferredModelIndex ?? 0, completion: completion)
    }

    // MARK: - 公共请求（火山方舟 chat/completions，带超时/5xx 重试 + 多模型兜底）
    private func performChat(messages: [[String: Any]],
                             attempt: Int,
                             maxAttempts: Int,
                             modelIndex: Int,
                             completion: @escaping (FoodNutritionModel?, Error?) -> Void) {
        let cfg = ark
        guard let url = URL(string: cfg.chatBaseURL), !cfg.apiKey.isEmpty else {
            DispatchQueue.main.async {
                completion(nil, NSError(domain: "FoodNutrition", code: -4,
                                        userInfo: [NSLocalizedDescriptionKey: "火山方舟配置缺失（apiKey / chatBaseURL）"]))
            }
            return
        }
        guard modelIndex < candidateVisionModels.count else {
            print("[Nutrition] ❌ 已尝试全部候选视觉模型，均不可用")
            DispatchQueue.main.async {
                completion(nil, NSError(domain: "FoodNutrition", code: -5,
                                        userInfo: [NSLocalizedDescriptionKey: "未找到可用的火山视觉模型"]))
            }
            return
        }

        let model = candidateVisionModels[modelIndex]
        print("[Nutrition] → 尝试视觉模型[\(modelIndex)]: \(model)")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(cfg.apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "response_format": ["type": "json_object"],
            "temperature": 0.1
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = session.dataTask(with: req) { [weak self] data, response, err in
            // ═══ 调试日志 ═══
            if let httpResp = response as? HTTPURLResponse {
                print("[Nutrition] ← HTTP \(httpResp.statusCode) (模型[\(modelIndex)] \(model))")
            }
            if let d = data, let respBody = String(data: d, encoding: .utf8) {
                print("[Nutrition] ← 响应体: \(respBody.prefix(500))")
            }

            if let err {
                let isRetriable = (err as? URLError)?.code == .timedOut ||
                                  (err as? URLError)?.code == .networkConnectionLost
                if isRetriable, attempt + 1 < maxAttempts {
                    print("[Nutrition] ⚠️ 网络错误(\(err.localizedDescription))，重试 (\(attempt + 1)/\(maxAttempts - 1))")
                    self?.performChat(messages: messages, attempt: attempt + 1, maxAttempts: maxAttempts, modelIndex: modelIndex, completion: completion)
                    return
                }
                print("[Nutrition] ❌ 网络错误: \(err.localizedDescription)")
                DispatchQueue.main.async { completion(nil, err) }
                return
            }

            // 服务端临时错误（5xx，如 502 Bad Gateway 网关抖动）：重试一次
            if let httpResp = response as? HTTPURLResponse,
               (500...599).contains(httpResp.statusCode) {
                if attempt + 1 < maxAttempts {
                    print("[Nutrition] ⚠️ HTTP \(httpResp.statusCode) 服务端错误，重试 (\(attempt + 1)/\(maxAttempts - 1))")
                    self?.performChat(messages: messages, attempt: attempt + 1, maxAttempts: maxAttempts, modelIndex: modelIndex, completion: completion)
                    return
                }
                print("[Nutrition] ❌ HTTP \(httpResp.statusCode) 最终失败")
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "FoodNutrition", code: httpResp.statusCode,
                                            userInfo: [NSLocalizedDescriptionKey: "服务端错误 \(httpResp.statusCode)"]))
                }
                return
            }

            // 模型不存在 / 无权限（404 InvalidEndpointOrModel.NotFound）：自动切换到下一个候选模型
            if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 404,
               let data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errInfo = json["error"] as? [String: Any],
               let errMsg = errInfo["message"] as? String,
               (errInfo["code"] as? String == "InvalidEndpointOrModel.NotFound" || errMsg.contains("does not exist")) {
                print("[Nutrition] ⚠️ 模型[\(modelIndex)] \(model) 不可用（\(errMsg)），尝试下一个候选")
                self?.performChat(messages: messages, attempt: 0, maxAttempts: maxAttempts, modelIndex: modelIndex + 1, completion: completion)
                return
            }

            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let msg = choices.first?["message"] as? [String: Any],
                  let content = msg["content"] as? String else {
                if let data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errInfo = json["error"] as? [String: Any],
                   let errMsg = errInfo["message"] as? String {
                    print("[Nutrition] ❌ 火山错误: \(errMsg)")
                } else {
                    print("[Nutrition] ❌ 返回格式异常")
                }
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "FoodNutrition", code: -3,
                                            userInfo: [NSLocalizedDescriptionKey: "返回格式异常"]))
                }
                return
            }
            // 命中可用模型，记住它，后续请求优先复用
            self?.preferredModelIndex = modelIndex
            print("[Nutrition] ✅ 命中可用视觉模型[\(modelIndex)]: \(model)")
            print("[Nutrition] ✅ 识别成功: \(content.prefix(200))")
            let cleaned = FoodNutritionService.stripCodeFence(content)
            self?.parseAndComplete(cleaned, completion)
        }
        task.resume()
    }

    /// 去掉模型偶发返回的 ```json ... ``` 代码块包裹，避免 JSON 解析失败。
    private static func stripCodeFence(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("```") {
            if let nl = t.firstIndex(of: "\n") {
                t = String(t[t.index(after: nl)...])
            }
            if t.hasSuffix("```") {
                t = String(t.dropLast(3))
            }
            t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return t
    }

    /// 解析火山方舟返回的 JSON 内容并回调（图片 / 名称两条路径共用）
    private func parseAndComplete(_ content: String, _ completion: @escaping (FoodNutritionModel?, Error?) -> Void) {
        // 容错：模型偶发会把 vitaminTips 返回成字符串数组 ["...","..."]。
        // FoodNutritionModel.vitaminTips 是 String，数组会触发解码失败。
        // 这里先做一次归一化：把任意形式（含空格/下划线变体 key）的数组值 join 成单条字符串。
        let data = normalizeVitaminTips(content)

        let decoder = JSONDecoder()
        // 容错：火山偶发会返回 "dietary Fiber"（带空格）/ "dietary_fiber"（下划线）等变体 key，
        // 统一归一化为 camelCase 再匹配模型属性。
        decoder.keyDecodingStrategy = .custom { keys in
            let raw = keys.last!.stringValue
            let noSpace = raw.replacingOccurrences(of: " ", with: "")
            let parts = noSpace.components(separatedBy: "_")
            let camel: String
            if parts.count > 1 {
                camel = parts.enumerated().map { i, p in
                    i == 0 ? p.lowercased() : p.prefix(1).uppercased() + p.dropFirst().lowercased()
                }.joined()
            } else {
                camel = noSpace
            }
            return FlexibleCodingKey(stringValue: camel) ?? keys.last!
        }
        do {
            let model = try decoder.decode(FoodNutritionModel.self, from: data)
            print("[Nutrition] ✅ 解析成功: \(model.foodName), \(model.calories)kcal, 碳水\(model.carbohydrate)g")
            DispatchQueue.main.async { completion(model, nil) }
        } catch {
            print("[Nutrition] ❌ JSON解析失败: \(error.localizedDescription), 原始内容: \(content.prefix(300))")
            DispatchQueue.main.async { completion(nil, error) }
        }
    }

    /// 把模型中可能以「字符串数组」形式返回的 vitaminTips 规整为单条字符串。
    /// 兼容各种 key 变体（vitaminTips / vitamin_tips / vitamin tips 等）。
    private func normalizeVitaminTips(_ content: String) -> Data {
        guard let obj = try? JSONSerialization.jsonObject(with: Data(content.utf8)) as? [String: Any] else {
            return Data(content.utf8)
        }
        var dict = obj
        for (key, value) in dict {
            let normalized = key.replacingOccurrences(of: " ", with: "")
                              .replacingOccurrences(of: "_", with: "")
                              .lowercased()
            if normalized == "vitamintips", let arr = value as? [String] {
                dict[key] = arr.joined(separator: " ")
            }
        }
        return (try? JSONSerialization.data(withJSONObject: dict)) ?? Data(content.utf8)
    }
}
