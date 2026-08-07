import Foundation

// MARK: - 认证用户模型

/// 表示一个已登录（或本机）用户。
/// Mock 阶段全部字段本地生成，后期对接运营商/短信网关时只需补充真实字段。
struct AuthUser: Identifiable, Codable, Equatable {
    var id: String { uid }
    let uid: String
    var phone: String          // 脱敏展示用，如 "138****8000"；密码/验证码登录时为真实号
    var nickname: String
    var avatar: String         // emoji 头像，Mock 阶段随机分配
    var loginType: LoginType

    enum LoginType: String, Codable {
        case sms       = "sms"        // 短信验证码登录
        case password  = "password"   // 账号密码登录
        case register  = "register"   // 注册新账号
    }

    var isGuest: Bool { false }

    static let guest = AuthUser(
        uid: "guest", phone: "", nickname: "游客", avatar: "🚶", loginType: .password)
}

// MARK: - 认证能力抽象（可插拔：Mock ↔ 真实运营商/短信）

/// 所有登录/注册能力统一收敛到协议层，UI 完全不感知实现。
/// 后期接入真实运营商 SDK / 短信平台时，仅需新增一个 CloudAuthProvider
/// 实现本协议，并替换 AuthService.shared.provider，UI 与业务流程零改动。
protocol AuthProvider {

    /// 发送短信验证码（Mock：本地生成 + 控制台/Toast 告知；真实：对接短信网关）
    /// - Parameter phone: 手机号
    func sendSMSCode(phone: String) async throws -> String   // 返回本次验证码（Mock 用于回显/调试）

    /// 短信验证码登录
    func loginBySMS(phone: String, code: String) async throws -> AuthUser

    /// 账号密码登录
    func loginByPassword(phone: String, password: String) async throws -> AuthUser

    /// 注册新账号（需短信验证码校验）
    func register(phone: String, code: String, password: String, nickname: String) async throws -> AuthUser

    /// 账号密码注册（短信平台未就绪时的兜底注册方式）：
    /// 用 user_id（手机号或其他账号）+ 自设密码 + 昵称直接建号，不经过短信。
    func registerByUserID(userID: String, password: String, name: String) async throws -> AuthUser
}

// MARK: - 认证错误

enum AuthError: LocalizedError {
    case invalidPhone
    case codeExpired
    case wrongCode
    case userNotFound
    case wrongPassword
    case phoneAlreadyRegistered
    case weakPassword
    case userIDAlreadyRegistered
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidPhone:            return "手机号格式不正确"
        case .codeExpired:             return "验证码已过期，请重新获取"
        case .wrongCode:               return "验证码错误，请重试"
        case .userNotFound:            return "该手机号尚未注册"
        case .wrongPassword:           return "密码错误，请重试"
        case .phoneAlreadyRegistered:  return "该手机号已注册，请直接登录"
        case .weakPassword:            return "密码至少 6 位"
        case .userIDAlreadyRegistered: return "该账号已被注册，请直接登录或更换账号"
        case .unknown(let m):          return m
        }
    }
}
