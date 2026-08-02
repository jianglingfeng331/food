import UIKit

/// 云端接口：高清贴纸生成（SD+ControlNet）+ 冷门食品识别兜底（多模态大模型）
/// + 业务数据（登录 / 仪表盘 / 记录 / PK / 贴纸墙 / 资料）
final class CloudAPI {
    static let shared = CloudAPI()

    /// 本地联调地址：
    /// - 通过 pymobiledevice3 usbmux forward 将 iPhone localhost:8000 经 USB 线转接到 Mac。
    /// - 模拟器同样用 127.0.0.1，直接映射到 Mac 本地，无需额外配置。
    #if DEBUG
    private var base: URL {
        return URL(string: "http://127.0.0.1:8000")!
    }
    #else
    private var base = URL(string: "https://api.yourserver.com")!
    #endif

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 8    // 超时快速失败，避免阻塞 UI
        return URLSession(configuration: cfg)
    }()

    // MARK: - Token
    private(set) var token: String? {
        didSet { UserDefaults.standard.set(token, forKey: "fs_token") }
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
        let currentWeight: Double; let targetWeight: Double; let height: Double
        enum CodingKeys: String, CodingKey {
            case id, name, avatar, height
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
    struct CkSticker: Decodable {
        let id: String; let name: String; let image_b64: String
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
        return data
    }

    enum CloudError: Error { case unauthorized, server(String) }

    // MARK: - 业务接口
    /// 登录：默认演示账号 user-1 / 123456
    func login(userID: String, password: String = "123456") async throws -> CkUser {
        struct Req: Encodable { let user_id: String; let password: String }
        let data = try await authed("auth/login", method: "POST",
                                    body: Req(user_id: userID, password: password))
        let r = try JSONDecoder().decode(CkLogin.self, from: data)
        self.token = r.token
        return r.user
    }

    func userMe() async throws -> CkUser {
        try JSONDecoder().decode(CkUser.self, from: try await authed("user/me"))
    }

    func dashboard() async throws -> CkDashboard {
        try JSONDecoder().decode(CkDashboard.self, from: try await authed("dashboard"))
    }

    func pkWeek() async throws -> CkPKWeek {
        try JSONDecoder().decode(CkPKWeek.self, from: try await authed("pk/week"))
    }

    func stickers() async throws -> [CkSticker] {
        try JSONDecoder().decode([CkSticker].self, from: try await authed("stickers"))
    }

    func addSticker(name: String, imageB64: String) async throws {
        struct Req: Encodable { let name: String; let image_b64: String }
        _ = try await authed("stickers", method: "POST", body: Req(name: name, image_b64: imageB64))
    }

    func addRecord(type: String, name: String, calories: Double,
                   amount: Double, unit: String, time: String) async throws {
        struct Req: Encodable {
            let type: String; let name: String; let calories: Double
            let amount: Double; let unit: String; let time: String
        }
        _ = try await authed("records", method: "POST",
                             body: Req(type: type, name: name, calories: calories,
                                      amount: amount, unit: unit, time: time))
    }

    func deleteRecord(id: String) async throws {
        _ = try await authed("records/\(id)", method: "DELETE")
    }

    func updateProfile(name: String? = nil, avatar: String? = nil,
                       currentWeight: Double? = nil, targetWeight: Double? = nil,
                       height: Double? = nil) async throws -> CkUser {
        struct Req: Encodable {
            let name: String?; let avatar: String?
            let currentWeight: Double?; let targetWeight: Double?; let height: Double?
        }
        let data = try await authed("profile", method: "PUT",
            body: Req(name: name, avatar: avatar, currentWeight: currentWeight,
                      targetWeight: targetWeight, height: height))
        return try JSONDecoder().decode(CkUser.self, from: data)
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

    /// 高清贴纸：上传原图+端侧Alpha → SD img2img + ControlNet Canny → 服务端复用Alpha抠白底
    func generateHDSticker(image: CGImage, alphaPNG: Data) async throws -> UIImage {
        let jpeg = UIImage(cgImage: image).resized(maxSide: 1536).jpegData(compressionQuality: 0.9)!
        var req = URLRequest(url: base.appendingPathComponent("/sticker/hd"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode([
            "image_b64": jpeg.base64EncodedString(),
            "alpha_b64": alphaPNG.base64EncodedString()])
        let (data, _) = try await session.data(for: req)
        struct R: Decodable { let sticker_png_b64: String }
        let r = try JSONDecoder().decode(R.self, from: data)
        guard let d = Data(base64Encoded: r.sticker_png_b64), let img = UIImage(data: d)
        else { throw URLError(.cannotDecodeContentData) }
        return img
    }
}

extension UIImage {
    func resized(maxSide: CGFloat) -> UIImage {
        let s = min(1, maxSide / max(size.width, size.height))
        if s >= 1 { return self }
        let newSize = CGSize(width: size.width * s, height: size.height * s)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
