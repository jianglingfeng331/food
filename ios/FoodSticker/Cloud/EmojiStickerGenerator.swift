import UIKit

/// 卡通贴纸生成服务（单例）：火山引擎图生图。
///
/// 流程：拍照原图 → 火山方舟 image-to-image（Q 版白底卡通）→ 直接返回卡通贴纸（不做二次抠图/合成）。
///
/// 配置项（可修改）：`config.apiKey` / `config.baseURL` / `config.modelName`。
/// 模型名需与火山方舟控制台「模型推理」中已开通的图生图模型精确一致。
/// 已知可用模型：`doubao-seedream-5-0-260128`(5.0-lite) / `doubao-seedream-4-5-251128`(4.5) / `doubao-seedream-4-0-250828`(4.0)。
final class EmojiStickerGenerator {

    static let shared = EmojiStickerGenerator()

    /// 火山方舟服务配置（图生图 + 营养识别共用同一个 API Key / 域名）
    struct Config {
        /// 火山方舟 API Key（图生图与营养识别共用）
        var apiKey: String = "__ARK_API_KEY_PLACEHOLDER__"
        /// 火山方舟图片生成接口地址（图生图，seedream）
        var baseURL: String = "https://ark.cn-beijing.volces.com/api/v3/images/generations"
        /// 火山方舟图生图模型（请在控制台「模型推理」核对精确名称，参考上方的已知可用列表）
        /// 官方文档示例 ID：doubao-seedream-5-0-260128（5.0-lite，注意命名中不含 "lite" 字样）
        /// 备选稳定款：doubao-seedream-4-0-250828（价格更低，兼容性更好）
        var modelName: String = "doubao-seedream-5-0-260128"
        /// 火山方舟多模态对话接口地址（营养识别 / 名称分析共用，OpenAI 兼容 chat/completions）
        var chatBaseURL: String = "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
        /// 火山方舟视觉理解模型（营养识别用，需在控制台「模型推理」开通）。
        /// 用户指定：doubao-seed-2-0-lite-260428（Seed 2.0 轻量版，带日期后缀 260428）。
        var visionModelName: String = "doubao-seed-2-0-lite-260428"
    }

    var config = Config()

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 90  // 图生图较慢，给充足时间
        return URLSession(configuration: cfg)
    }()

    /// 构造图生图正面提示词（iOS 官方表情符号风格轻量 3D 贴纸）。
    /// 注意：Seedream 图生图 API 不支持 negative_prompt，所有"不要…"约束需以正面/确定性措辞写进 prompt。
    private func buildCartoonPrompt(_ foodName: String) -> String {
        """
        独立食物，软萌3D卡通，哑光材质，细腻环境光，柔和明暗过渡，一圈柔和白色外描边，emoji风格，单独物件，无环境、无桌面，透明背景，画面居中，8k高清，边缘干净，贴纸成品效果。
        """
    }

    private init() {}

    /// 将参考图绘制到纯白画布上：透明背景的抠图会变白底，普通照片不受影响。
    /// 避免透明 PNG 转 JPEG 时透明区域变黑底，从而让模型拿到干净的"白底食物"参考图。
    private func flattenOnWhite(_ image: UIImage) -> UIImage {
        let size = image.size
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.scale = image.scale
        return UIGraphicsImageRenderer(size: size, format: fmt).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - 对外接口

    /// 生成卡通贴纸（图生图）。
    ///
    /// 将拍照原图作为参考图上传火山方舟，由模型根据原图内容生成 Q 版卡通变体，
    /// 直接返回火山方舟产出的卡通贴纸（白底），不做二次抠图。
    ///
    /// - Parameters:
    ///   - foodName: 识别出的食物名（驱动图生图 prompt）
    ///   - originalPhoto: 拍照原图（作为图生图参考图）
    ///   - fallbackImage: 兜底图（服务失败时直接返回）
    ///   - completion: 主线程回调（卡通贴纸 / 错误）
    func generateSticker(foodName: String,
                         originalPhoto: UIImage,
                         fallbackImage: UIImage,
                         completion: @escaping (UIImage?, Error?) -> Void) {
        // 服务未配置：直接 fallback，保证基础功能可用
        guard let url = URL(string: config.baseURL), !config.apiKey.isEmpty else {
            completion(fallbackImage, nil)
            return
        }

        // 将原图（抠好的食物白底图）转为 base64 JPEG 作为图生图参考输入
        let refImage = flattenOnWhite(originalPhoto.resized(maxSide: 1024))
        guard let jpeg = refImage.jpegData(compressionQuality: 0.8) else {
            completion(fallbackImage, nil)
            return
        }
        let imageB64 = jpeg.base64EncodedString()
        let prompt = buildCartoonPrompt(foodName)

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        // 火山方舟图生图请求体：
        // image 字段传 base64 参考图（单图用 string）；Seedream 图生图不支持 strength / negative_prompt，
        // 编辑强度由模型按 prompt 自行决定，风格控制全部写进 prompt。
        let body: [String: Any] = [
            "model": config.modelName,
            "prompt": prompt,
            "image": "data:image/jpeg;base64,\(imageB64)",
            "size": "2K",
            "output_format": "png",
            "watermark": false,
            "sequential_image_generation": "disabled"
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        if let bodyData = req.httpBody {
            print("[EmojiSticker] → 请求体: \(String(data: bodyData, encoding: .utf8)?.prefix(200) ?? "nil")...")
        }

        let task = session.dataTask(with: req) { [weak self] data, response, err in
            guard let self else { return }
            
            // ═══ 调试日志：打印原始响应 ═══
            var responseBody: String?
            if let d = data { responseBody = String(data: d, encoding: .utf8) }
            if let httpResp = response as? HTTPURLResponse {
                print("[EmojiSticker] ← HTTP \(httpResp.statusCode)")
            }
            if let body = responseBody {
                print("[EmojiSticker] ← 响应体: \(body.prefix(500))")
            }
            
            // 网络/解析失败：兜底实拍抠图贴纸
            guard err == nil, let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let arr = json["data"] as? [[String: Any]],
                  let first = arr.first else {
                // 火山返回错误信息时打印 error.message
                if let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errInfo = json["error"] as? [String: Any],
                   let msg = errInfo["message"] as? String {
                    print("[EmojiSticker] ❌ 火山错误: \(msg)")
                } else if let err {
                    print("[EmojiSticker] ❌ 网络错误: \(err.localizedDescription)")
                }
                DispatchQueue.main.async { completion(fallbackImage, nil) }
                return
            }

            // 火山方舟返回 url 或 b64_json，统一取出 UIImage
            var aiImage: UIImage?
            if let urlStr = first["url"] as? String, let imgURL = URL(string: urlStr) {
                if let ddata = try? Data(contentsOf: imgURL), let img = UIImage(data: ddata) {
                    aiImage = img
                }
            } else if let b64 = first["b64_json"] as? String,
                      let imgData = Data(base64Encoded: b64),
                      let img = UIImage(data: imgData) {
                aiImage = img
            }

            guard let gen = aiImage else {
                DispatchQueue.main.async { completion(fallbackImage, nil) }
                return
            }

            // 直接返回火山方舟生成的卡通贴纸（白底），不再做二次抠图/合成
            DispatchQueue.main.async { completion(gen, nil) }
        }
        task.resume()
    }
}
