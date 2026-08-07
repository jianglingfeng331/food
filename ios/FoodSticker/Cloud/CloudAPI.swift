import UIKit

/// 云端接口：高清贴纸生成（SD+ControlNet）+ 冷门食品识别兜底（多模态大模型）
/// + 业务数据（登录 / 仪表盘 / 记录 / PK / 贴纸墙 / 资料）
final class CloudAPI {
    static let shared = CloudAPI()

    /// 无字段请求体（如解绑接口）。
    private struct EmptyBody: Encodable {}

    /// 生产环境（Release）走公网 HTTPS，由 Nginx 转发到后端。
    /// 联调时（DEBUG）连本机/局域网后端：
    /// - 模拟器：localhost:8000 直接映射到 Mac 本地。
    /// - 真机 WiFi 联调：必须用 Mac 当前局域网 IP（查询：ifconfig en0 | grep inet）。
    /// - 真机 USB 联调：用 pymobiledevice3 usbmux forward 转发后改回 localhost:8000。
    /// - ⚠️ 内测期间临时指向生产服务器，内测结束后改回局域网 IP。
    #if DEBUG
    private var base: URL {
        #if targetEnvironment(simulator)
        // 模拟器直接访问 Mac 本地后端
        return URL(string: "http://127.0.0.1:8000")!
        #else
        // 真机内测：临时指向生产服务器
        return URL(string: "https://www.rubyace.love")!
        #endif
    }
    #else
    private var base = URL(string: "https://www.rubyace.love")!
    #endif

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 15
        cfg.timeoutIntervalForResource = 30
        cfg.allowsConstrainedNetworkAccess = true
        #if DEBUG
        cfg.waitsForConnectivity = false      // 本地联调：无需等待网络
        #else
        cfg.waitsForConnectivity = true       // 生产：等待网络恢复（切 WiFi/蜂窝）
        #endif
        return URLSession(configuration: cfg)
    }()

    // MARK: - 长超时 Session（AI/VLM 识别需要更长处理时间）
    private let aiSession: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 60   // AI 识别需要足够时间
        cfg.timeoutIntervalForResource = 120
        cfg.waitsForConnectivity = false
        cfg.allowsConstrainedNetworkAccess = true
        return URLSession(configuration: cfg)
    }()

    // MARK: - Token
    private(set) var token: String? {
        didSet { UserDefaults.standard.set(token, forKey: "fs_token") }
    }

    /// 供 AuthProvider 在短信登录/注册成功后写入 token（内部 login/register 已自行写入）。
    func setToken(_ t: String?) {
        token = t
    }

    private init() {
        self.token = UserDefaults.standard.string(forKey: "fs_token")
    }

    /// 是否已登录（有可发送的 token）
    var isLoggedIn: Bool { token != nil }

    func logout() { token = nil }

    // MARK: - 解码模型（对齐后端 JSON）
    struct CkUser: Decodable {
        let id: String; let name: String; let avatar: String
        let avatarB64: String?
        let currentWeight: Double; let targetWeight: Double; let height: Double
        enum CodingKeys: String, CodingKey {
            case id, name, avatar, height
            case avatarB64 = "avatar_b64"
            case currentWeight = "currentWeight"
            case targetWeight = "targetWeight"
        }
    }
    struct CkStats: Decodable {
        let intake: Double; let burned: Double; let remaining: Double; let target: Double
    }
    struct CkRecord: Decodable {
        let id: String; let type: String; let name: String
        let calories: Double; let amount: Double; let unit: String; let time: String
        let imageB64: String?
        let date: String?   // "2026-08-06"，用于 PK 按天分组
        // 营养成分与小贴士（食物记录携带，供对方查看详情）
        let proteinG: Double?
        let carbG: Double?
        let fatG: Double?
        let dietaryFiberG: Double?
        let sugarG: Double?
        let sodiumMg: Double?
        let vitaminTips: String?
        enum CodingKeys: String, CodingKey {
            case id, type, name, calories, amount, unit, time, date
            case imageB64 = "image_b64"
            case proteinG = "protein_g"
            case carbG = "carb_g"
            case fatG = "fat_g"
            case dietaryFiberG = "dietary_fiber_g"
            case sugarG = "sugar_g"
            case sodiumMg = "sodium_mg"
            case vitaminTips = "vitamin_tips"
        }
    }
    struct CkPerson: Decodable {
        let user: CkUser; let dailyStats: CkStats; let todayRecords: [CkRecord]
    }
    struct CkDashboard: Decodable {
        let user: CkUser; let dailyStats: CkStats; let todayRecords: [CkRecord]
    }
    struct CkPKWeek: Decodable {
        let startDate: String; let days: Int
        let me: CkPerson; let partner: CkPerson?
    }
    struct CkPKPartner: Decodable {
        let uid: String; let nickname: String; let avatar: String
    }
    struct CkPKRelation: Decodable {
        let bound: Bool
        let partner: CkPKPartner?
    }
    struct CkSticker: Decodable {
        let id: String; let name: String; let image_b64: String
        let kcalPer100g: Double; let proteinG: Double; let carbG: Double; let fatG: Double
        let dietaryFiberG: Double; let sodiumMg: Double; let typicalPortionG: Double
        let vitaminTips: String
        enum CodingKeys: String, CodingKey {
            case id, name, image_b64
            case kcalPer100g = "kcal_per_100g"
            case proteinG = "protein_g"
            case carbG = "carb_g"
            case fatG = "fat_g"
            case dietaryFiberG = "dietary_fiber_g"
            case sodiumMg = "sodium_mg"
            case typicalPortionG = "typical_portion_g"
            case vitaminTips = "vitamin_tips"
        }
    }
    struct CkLogin: Decodable { let token: String; let user: CkUser }

    // MARK: - 鉴权请求封装
    private func authed(_ path: String, method: String = "GET", body: Encodable? = nil) async throws -> Data {
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = token { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        if let body { req.httpBody = try JSONEncoder().encode(body) }
        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode == 401 {
            throw CloudError.unauthorized
        }
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"] ?? "请求失败"
            throw CloudError.server(msg)
        }
        return data
    }

    /// 长超时版本的 authed（用于 AI/VLM 识别等耗时请求）
    private func authedAI(_ path: String, method: String = "GET", body: Encodable? = nil) async throws -> Data {
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = token { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        if let body { req.httpBody = try JSONEncoder().encode(body) }
        let (data, resp) = try await aiSession.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode == 401 {
            throw CloudError.unauthorized
        }
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"] ?? "请求失败"
            throw CloudError.server(msg)
        }
        return data
    }

    enum CloudError: LocalizedError {
        case unauthorized, server(String)
        var errorDescription: String? {
            switch self {
            case .unauthorized: return "登录已过期，请重新登录"
            case .server(let msg): return msg
            }
        }
    }

    // MARK: - 非鉴权请求封装（注册/发码/登录等无需 token 的接口）

    /// 发送不需要鉴权的请求，返回解码后的模型。
    func postNoAuth<T: Decodable>(_ path: String, body: Encodable) async throws -> T {
        try JSONDecoder().decode(T.self, from: try await postNoAuthData(path, body: body))
    }

    /// 发送不需要鉴权的请求，直接返回原始 Data（调用方自行解码）。
    func postNoAuthData(_ path: String, body: Encodable) async throws -> Data {
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"] ?? "请求失败"
            throw CloudError.server(msg)
        }
        return data
    }

    // MARK: - 业务接口
    /// 登录：账号/手机号 + 密码
    func login(userID: String, password: String) async throws -> CkUser {
        struct Req: Encodable { let user_id: String; let password: String }
        let data = try await authed("auth/login", method: "POST",
                                    body: Req(user_id: userID, password: password))
        let r = try JSONDecoder().decode(CkLogin.self, from: data)
        self.token = r.token
        return r.user
    }

    /// 账号密码注册（短信平台未就绪时的兜底注册方式）：user_id + password + name
    /// 调用后端 /auth/register，成功后自动写入 token 并回传用户。
    func register(userID: String, password: String, name: String) async throws -> CkUser {
        struct Req: Encodable {
            let user_id: String; let password: String; let name: String
        }
        let data = try await postNoAuthData("auth/register",
                                        body: Req(user_id: userID, password: password, name: name))
        let r = try JSONDecoder().decode(CkLogin.self, from: data)
        self.token = r.token
        return r.user
    }

    func userMe() async throws -> CkUser {
        try JSONDecoder().decode(CkUser.self, from: try await authed("user/me"))
    }

    /// 修改当前登录用户的登录密码（需鉴权）
    func changePassword(newPassword: String) async throws {
        struct Req: Encodable { let new_password: String }
        _ = try await authed("auth/change-password", method: "POST",
                             body: Req(new_password: newPassword))
    }

    /// 删除当前登录用户账号及全部数据（需鉴权）
    func deleteAccount() async throws {
        _ = try await authed("auth/account", method: "DELETE")
        logout()
    }

    /// 提交意见反馈（需鉴权）
    func sendFeedback(content: String, contact: String?) async throws {
        struct Req: Encodable { let content: String; let contact: String? }
        _ = try await authed("feedback", method: "POST",
                             body: Req(content: content, contact: contact))
    }

    func dashboard() async throws -> CkDashboard {
        let t0 = CFAbsoluteTimeGetCurrent()
        defer { Log("[CloudAPI] dashboard took \(String(format:"%.2f", (CFAbsoluteTimeGetCurrent()-t0)*1000))ms") }
        return try JSONDecoder().decode(CkDashboard.self, from: try await authed("dashboard"))
    }

    func pkWeek() async throws -> CkPKWeek {
        let t0 = CFAbsoluteTimeGetCurrent()
        defer { Log("[CloudAPI] pkWeek took \(String(format:"%.2f", (CFAbsoluteTimeGetCurrent()-t0)*1000))ms") }
        return try JSONDecoder().decode(CkPKWeek.self, from: try await authed("pk/week"))
    }

    func pkBind(targetUID: String) async throws -> CkPKPartner {
        struct Body: Encodable { let target_uid: String }
        let data = try await authed("pk/bind", method: "POST", body: Body(target_uid: targetUID))
        struct Resp: Decodable { let ok: Bool; let partner: CkPKPartner }
        return try JSONDecoder().decode(Resp.self, from: data).partner
    }

    func pkUnbind() async throws {
        _ = try await authed("pk/unbind", method: "POST", body: EmptyBody())
    }

    func pkRelation() async throws -> CkPKRelation {
        try JSONDecoder().decode(CkPKRelation.self, from: try await authed("pk/relation"))
    }

    func stickers() async throws -> [CkSticker] {
        try JSONDecoder().decode([CkSticker].self, from: try await authed("stickers"))
    }

    func addSticker(name: String, imageB64: String, nutrition: StickerNutrition? = nil) async throws {
        struct Req: Encodable {
            let name: String; let image_b64: String
            let kcal_per_100g: Double; let protein_g: Double; let carb_g: Double; let fat_g: Double
            let dietary_fiber_g: Double; let sodium_mg: Double; let typical_portion_g: Double
            let vitamin_tips: String
        }
        let n = nutrition ?? StickerNutrition()
        _ = try await authed("stickers", method: "POST", body: Req(
            name: name, image_b64: imageB64,
            kcal_per_100g: n.kcalPer100g, protein_g: n.proteinG,
            carb_g: n.carbG, fat_g: n.fatG,
            dietary_fiber_g: n.dietaryFiberG, sodium_mg: n.sodiumMg,
            typical_portion_g: n.typicalPortionG, vitamin_tips: n.vitaminTips))
    }

    func addRecord(type: String, name: String, calories: Double,
                   amount: Double, unit: String, time: String,
                   imageFileName: String? = nil,
                   proteinG: Double = 0, carbG: Double = 0, fatG: Double = 0,
                   dietaryFiberG: Double = 0, sugarG: Double = 0,
                   sodiumMg: Double = 0, vitaminTips: String = "",
                   createdAt: String = "") async throws -> String {
        struct Req: Encodable {
            let type: String; let name: String; let calories: Double
            let amount: Double; let unit: String; let time: String
            let image_b64: String; let created_at: String
            let protein_g: Double; let carb_g: Double; let fat_g: Double
            let dietary_fiber_g: Double; let sugar_g: Double
            let sodium_mg: Double; let vitamin_tips: String
        }
        // 读取本地图片并 base64 编码
        var imageB64 = ""
        if let fn = imageFileName {
            let url = AppDataStore.stickerImagesDir.appendingPathComponent(fn)
            if let data = try? Data(contentsOf: url) {
                imageB64 = data.base64EncodedString()
            }
        }
        struct Resp: Decodable { let id: String }
        let data = try await authed("records", method: "POST",
                             body: Req(type: type, name: name, calories: calories,
                                      amount: amount, unit: unit, time: time,
                                      image_b64: imageB64, created_at: createdAt,
                                      protein_g: proteinG, carb_g: carbG, fat_g: fatG,
                                      dietary_fiber_g: dietaryFiberG, sugar_g: sugarG,
                                      sodium_mg: sodiumMg, vitamin_tips: vitaminTips))
        let resp = try JSONDecoder().decode(Resp.self, from: data)
        return resp.id
    }

    func deleteRecord(id: String) async throws {
        _ = try await authed("records/\(id)", method: "DELETE")
    }

    /// 更新已有记录（用于饮水覆盖式更新等场景）
    func updateRecord(id: String, type: String, name: String, calories: Double,
                      amount: Double, unit: String, time: String,
                      proteinG: Double = 0, carbG: Double = 0, fatG: Double = 0,
                      dietaryFiberG: Double = 0, sugarG: Double = 0,
                      sodiumMg: Double = 0, vitaminTips: String = "") async throws {
        struct Req: Encodable {
            let type: String; let name: String; let calories: Double
            let amount: Double; let unit: String; let time: String
            let protein_g: Double; let carb_g: Double; let fat_g: Double
            let dietary_fiber_g: Double; let sugar_g: Double
            let sodium_mg: Double; let vitamin_tips: String
        }
        _ = try await authed("records/\(id)", method: "PUT",
                             body: Req(type: type, name: name, calories: calories,
                                       amount: amount, unit: unit, time: time,
                                       protein_g: proteinG, carb_g: carbG, fat_g: fatG,
                                       dietary_fiber_g: dietaryFiberG, sugar_g: sugarG,
                                       sodium_mg: sodiumMg, vitamin_tips: vitaminTips))
    }

    func updateProfile(name: String? = nil, avatar: String? = nil, avatarB64: String? = nil,
                       currentWeight: Double? = nil, targetWeight: Double? = nil,
                       height: Double? = nil) async throws -> CkUser {
        struct Req: Encodable {
            let name: String?; let avatar: String?; let avatarB64: String?
            let currentWeight: Double?; let targetWeight: Double?; let height: Double?
            enum CodingKeys: String, CodingKey {
                case name, avatar, height
                case avatarB64 = "avatar_b64"
                case currentWeight = "currentWeight"
                case targetWeight = "targetWeight"
            }
        }
        let data = try await authed("profile", method: "PUT",
            body: Req(name: name, avatar: avatar, avatarB64: avatarB64,
                      currentWeight: currentWeight,
                      targetWeight: targetWeight, height: height))
        return try JSONDecoder().decode(CkUser.self, from: data)
    }

    // MARK: - 火山方舟代理接口（密钥仅存服务端，客户端不持有 Key）

    /// 图生图卡通贴纸（通过服务端代理调用火山方舟 seedream）。使用长超时（60s）。
    func generateSticker(foodName: String, originalPhoto: UIImage) async throws -> UIImage {
        let ref = originalPhoto.resized(maxSide: 1024)
        guard let jpeg = ref.jpegData(compressionQuality: 0.8) else {
            throw URLError(.cannotDecodeContentData)
        }
        let b64 = jpeg.base64EncodedString()
        struct Req: Encodable { let food_name: String; let image_b64: String }
        struct Res: Decodable { let sticker_png_b64: String }
        let data = try await authedAI("/sticker/seedream", method: "POST",
                                       body: Req(food_name: foodName, image_b64: b64))
        let r = try JSONDecoder().decode(Res.self, from: data)
        guard let d = Data(base64Encoded: r.sticker_png_b64),
              let img = UIImage(data: d) else {
            throw URLError(.cannotDecodeContentData)
        }
        return img
    }

    // MARK: - 原有 ML 接口（保持不变）
    /// 冷门食品识别兜底：上传原图（压缩到1024长边省流量）→ 名称+分量+营养
    func recognizeFood(image: CGImage) async throws -> FoodInfo {
        let jpeg = UIImage(cgImage: image).resized(maxSide: 1024).jpegData(compressionQuality: 0.8)!
        var req = URLRequest(url: base.appendingPathComponent("/food/recognize"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["image_b64": jpeg.base64EncodedString()])
        let (data, _) = try await session.data(for: req)
        struct R: Decodable {
            let name_cn: String; let portion_g: Double
            let kcal_100g, protein_g, carb_g, fat_g: Double
        }
        let r = try JSONDecoder().decode(R.self, from: data)
        return FoodInfo(nameCN: r.name_cn, kcal100g: r.kcal_100g, proteinG: r.protein_g,
                        carbG: r.carb_g, fatG: r.fat_g, typicalG: r.portion_g,
                        fromCloud: true, portionG: r.portion_g)
    }

    /// 手动修正后名称查营养（本地未命中时）
    func queryNutrition(name: String) async throws -> FoodInfo {
        var req = URLRequest(url: base.appendingPathComponent("/food/nutrition"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["name": name])
        let (data, _) = try await session.data(for: req)
        struct R: Decodable { let name_cn: String; let kcal_100g, protein_g, carb_g, fat_g: Double }
        let r = try JSONDecoder().decode(R.self, from: data)
        return FoodInfo(nameCN: r.name_cn, kcal100g: r.kcal_100g, proteinG: r.protein_g,
                        carbG: r.carb_g, fatG: r.fat_g, typicalG: 100, fromCloud: true)
    }

    /// 高清贴纸：上传原图+端侧Alpha → SD img2img + ControlNet Canny → 服务端复用Alpha抠白底。使用长超时（60s）。
    func generateHDSticker(image: CGImage, alphaPNG: Data) async throws -> UIImage {
        let jpeg = UIImage(cgImage: image).resized(maxSide: 1536).jpegData(compressionQuality: 0.9)!
        var req = URLRequest(url: base.appendingPathComponent("/sticker/hd"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode([
            "image_b64": jpeg.base64EncodedString(),
            "alpha_b64": alphaPNG.base64EncodedString()])
        let (data, _) = try await aiSession.data(for: req)
        struct R: Decodable { let sticker_png_b64: String }
        let r = try JSONDecoder().decode(R.self, from: data)
        guard let d = Data(base64Encoded: r.sticker_png_b64), let img = UIImage(data: d)
        else { throw URLError(.cannotDecodeContentData) }
        return img
    }

    // MARK: - 完整营养识别（返回 FoodNutritionModel，对齐 iOS 端模型）

    /// 看图识别完整营养（服务端 VLM 代理，密钥仅存服务端）。使用长超时（60s）。
    func recognizeNutrition(image: UIImage) async throws -> FoodNutritionModel {
        guard let jpeg = image.resized(maxSide: 1024).jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "CloudAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "图片格式无效，无法识别"])
        }
        struct Req: Encodable { let image_b64: String }
        let data = try await authedAI("/food/recognize", method: "POST",
                                       body: Req(image_b64: jpeg.base64EncodedString()))
        return try Self.decodeNutrition(data)
    }

    /// 按名称查完整营养（服务端 VLM 代理，密钥仅存服务端）。使用长超时（60s）。
    func queryNutritionByName(_ name: String) async throws -> FoodNutritionModel {
        struct Req: Encodable { let name: String }
        let data = try await authedAI("/food/nutrition", method: "POST", body: Req(name: name))
        return try Self.decodeNutrition(data)
    }

    /// 容错解析服务端返回的营养 JSON → FoodNutritionModel。
    /// 服务端字段为下划线命名（name_cn/kcal_100g/protein_g/.../sodium_mg/vitamin_tips），
    /// 此处统一重命名为 iOS 模型字段名后解码，并兼容 vitamin_tips 为字符串数组的情况。
    private static func decodeNutrition(_ data: Data) throws -> FoodNutritionModel {
        var dict = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]

        // vitamin_tips 可能为字符串数组 → 合并为单条
        if let arr = dict["vitamin_tips"] as? [String] {
            dict["vitamin_tips"] = arr.joined(separator: " ")
        }

        // 服务端字段 → FoodNutritionModel 字段名映射（驼峰命名）
        let rename: [String: String] = [
            "name_cn": "foodName",
            "kcal_100g": "calories",
            "protein_g": "protein",
            "carb_g": "carbohydrate",
            "fat_g": "fat",
            "dietary_fiber": "dietaryFiber",
            "sodium_mg": "sodium",
            "vitamin_tips": "vitaminTips",
        ]
        var modelDict: [String: Any] = [:]
        for (k, v) in dict {
            let target = rename[k] ?? k
            modelDict[target] = v
        }
        let normalized = try JSONSerialization.data(withJSONObject: modelDict)
        do {
            return try JSONDecoder().decode(FoodNutritionModel.self, from: normalized)
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "nil"
            Log("[decodeNutrition] decode failed. raw JSON: \(raw)")
            Log("[decodeNutrition] mapped dict: \(modelDict)")
            throw error
        }
    }
}

extension UIImage {
    func resized(maxSide: CGFloat) -> UIImage {
        let s = min(1, maxSide / max(size.width, size.height))
        let newSize = CGSize(width: size.width * s, height: size.height * s)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true           // JPEG 不需要 alpha，用不透明位图确保 jpegData 兼容
        format.scale = 1.0
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: newSize, format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: newSize))
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
