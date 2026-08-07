import Foundation
import Combine

// MARK: - 认证服务（单例，全局登录态入口）

/// 统一对外暴露登录态。游客模式：currentUser == nil 即代表游客，可浏览全部内容。
/// 后期切换真实实现：将 provider 替换为 CloudAuthProvider 即可。
final class AuthService {

    static let shared = AuthService()

    /// 认证能力实现（Mock / 真实），一行切换。
    var provider: AuthProvider = CloudAuthProvider()

    @Published private(set) var currentUser: AuthUser?   // nil = 游客
    @Published private(set) var isLoggedIn: Bool = false

    private let sessionKey = "auth_session_user"

    private init() {
        // 启动时恢复持久化会话（游客默认不写入，即 currentUser == nil）
        if let data = UserDefaults.standard.data(forKey: sessionKey),
           let user = try? JSONDecoder().decode(AuthUser.self, from: data) {
            currentUser = user
            isLoggedIn = true
        }
    }

    // MARK: 登录入口（供 UI 调用）

    func loginBySMS(phone: String, code: String) async throws -> AuthUser {
        let user = try await provider.loginBySMS(phone: phone, code: code)
        persist(user)
        return user
    }

    func loginByPassword(phone: String, password: String) async throws -> AuthUser {
        let user = try await provider.loginByPassword(phone: phone, password: password)
        persist(user)
        return user
    }

    /// 发送短信验证码（短信平台就绪后启用）。返回验证码：Cloud 模式返回空串，Mock 模式返回真实验证码用于调试。
    func sendSMSCode(phone: String) async throws -> String {
        try await provider.sendSMSCode(phone: phone)
    }

    /// 短信验证码注册（短信平台就绪后启用）
    func register(phone: String, code: String, password: String, nickname: String) async throws -> AuthUser {
        let user = try await provider.register(phone: phone, code: code,
                                                password: password, nickname: nickname)
        persist(user)
        return user
    }

    /// 账号密码注册（短信平台未就绪时的兜底注册方式）
    /// 若账号已存在（首次注册时网络抖动导致客户端未收到成功响应，重试即 409），
    /// 自动用同一账号密码登录，避免用户卡在「已注册」提示进不去。
    func registerByUserID(userID: String, password: String, name: String) async throws -> AuthUser {
        do {
            let user = try await provider.registerByUserID(userID: userID, password: password, name: name)
            persist(user)
            return user
        } catch AuthError.userIDAlreadyRegistered {
            // 账号已存在：直接尝试登录（密码一致即可进）
            let user = try await provider.loginByPassword(phone: userID, password: password)
            persist(user)
            return user
        }
    }

    // MARK: 登出 / 会话

    func logout() {
        currentUser = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: sessionKey)
        // 清空业务数据，防止退出后下一用户看到残留数据
        DispatchQueue.main.async {
            AppDataStore.shared.clearAllData()
        }
        NotificationCenter.default.post(name: .authDidChange, object: nil)
    }

    /// 登录态下更新当前用户资料（昵称/头像），并刷新持久化与通知。
    func updateCurrentUser(_ user: AuthUser) {
        currentUser = user
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
        NotificationCenter.default.post(name: .authDidChange, object: nil)
    }

    private func persist(_ user: AuthUser) {
        currentUser = user
        isLoggedIn = true
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
        // 同步昵称到全站数据源（「我的」/「账户设置」读 AvatarStore，
        // ProfileStore 用于个人中心派生数据），避免登录后仍是「游客」。
        let name = Self.effectiveNickname(user)
        Task { @MainActor in
            AvatarStore.shared.saveNickname(name)
            ProfileStore.shared.setLoggedInNickname(name)
        }
    }

    /// 昵称为空时生成友好昵称（用户 + uid/手机号后 4 位），绝不暴露完整账号。
    private static func effectiveNickname(_ user: AuthUser) -> String {
        let n = user.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !n.isEmpty { return n }
        let tail = (user.phone.count >= 4 ? String(user.phone.suffix(4))
                    : (user.uid.count >= 4 ? String(user.uid.suffix(4)) : user.uid))
        return "用户" + tail
    }

    // MARK: 游客态辅助

    /// 当前是否游客
    var isGuest: Bool { currentUser == nil }
}
