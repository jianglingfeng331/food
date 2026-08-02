import Foundation
import Combine

// MARK: - 认证服务（单例，全局登录态入口）

/// 统一对外暴露登录态。游客模式：currentUser == nil 即代表游客，可浏览全部内容。
/// 后期切换真实实现：将 provider 替换为 CloudAuthProvider 即可。
final class AuthService {

    static let shared = AuthService()

    /// 认证能力实现（Mock / 真实），一行切换。
    var provider: AuthProvider = MockAuthProvider()

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

    func loginByOneKey() async throws -> AuthUser {
        let user = try await provider.loginByOneKey()
        persist(user)
        return user
    }

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

    func register(phone: String, password: String, nickname: String) async throws -> AuthUser {
        let user = try await provider.register(phone: phone, password: password, nickname: nickname)
        persist(user)
        return user
    }

    // MARK: 登出 / 会话

    func logout() {
        currentUser = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: sessionKey)
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
    }

    // MARK: 游客态辅助

    /// 当前是否游客
    var isGuest: Bool { currentUser == nil }
}
