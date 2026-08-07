import Foundation

// MARK: - Mock 认证实现

/// 本期实现：全程端侧模拟，无任何真实网络/短信。
/// - 账号库持久化在 UserDefaults（JSON）。
/// - 验证码本地生成，通过 Toast + 控制台打印"模拟收到短信"。
final class MockAuthProvider: AuthProvider {

    // MARK: 本地存储
    private let accountKey = "mock_auth_accounts"
    private let codeKey    = "mock_auth_sms_codes"

    private var accounts: [String: MockAccount] {
        get { (UserDefaults.standard.dictionary(forKey: accountKey) as? [String: Data])?
                .compactMapValues { try? JSONDecoder().decode(MockAccount.self, from: $0) } ?? [:] }
        set {
            let data = newValue.compactMapValues { try? JSONEncoder().encode($0) }
            UserDefaults.standard.set(data, forKey: accountKey)
        }
    }

    private var codes: [String: CodeTicket] {
        get {
            guard let raw = UserDefaults.standard.dictionary(forKey: codeKey) as? [String: Data] else { return [:] }
            return raw.compactMapValues { try? JSONDecoder().decode(CodeTicket.self, from: $0) }
        }
        set {
            let data = newValue.compactMapValues { try? JSONEncoder().encode($0) }
            UserDefaults.standard.set(data, forKey: codeKey)
        }
    }

    // MARK: 验证码

    func sendSMSCode(phone: String) async throws -> String {
        guard isValidPhone(phone) else { throw AuthError.invalidPhone }
        let code = String(format: "%06d", Int.random(in: 0...999999))
        var c = codes
        c[phone] = CodeTicket(code: code, expireAt: Date().addingTimeInterval(5 * 60))
        codes = c
        // 模拟下发短信：控制台 + 通过通知让 UI 提示
        Log("📩 [Mock 短信] 验证码已发送至 \(phone)：\(code)（5 分钟内有效）")
        NotificationCenter.default.post(name: .mockSMSSent, object: nil,
                                        userInfo: ["phone": phone, "code": code])
        return code
    }

    func loginBySMS(phone: String, code: String) async throws -> AuthUser {
        guard isValidPhone(phone) else { throw AuthError.invalidPhone }
        guard let ticket = codes[phone], ticket.code == code else { throw AuthError.wrongCode }
        guard ticket.expireAt > Date() else {
            var c = codes; c.removeValue(forKey: phone); codes = c
            throw AuthError.codeExpired
        }
        // 登录成功即视为该号存在（验证码登录可免注册）
        let acc = accounts[phone] ?? MockAccount(phone: phone,
                                                 password: nil,
                                                 nickname: defaultNickname(phone),
                                                 avatar: randomAvatar())
        if accounts[phone] == nil { var a = accounts; a[phone] = acc; accounts = a }
        var c = codes; c.removeValue(forKey: phone); codes = c
        return acc.toUser(.sms)
    }

    // MARK: 密码

    func loginByPassword(phone: String, password: String) async throws -> AuthUser {
        guard isValidPhone(phone) else { throw AuthError.invalidPhone }
        guard let acc = accounts[phone] else { throw AuthError.userNotFound }
        guard acc.password == password else { throw AuthError.wrongPassword }
        return acc.toUser(.password)
    }

    func register(phone: String, code: String, password: String, nickname: String) async throws -> AuthUser {
        guard isValidPhone(phone) else { throw AuthError.invalidPhone }
        guard password.count >= 6 else { throw AuthError.weakPassword }
        // Mock 模式也校验验证码（与真实流程一致）
        guard let ticket = codes[phone], ticket.code == code else { throw AuthError.wrongCode }
        guard ticket.expireAt > Date() else {
            var c = codes; c.removeValue(forKey: phone); codes = c
            throw AuthError.codeExpired
        }
        guard accounts[phone] == nil else { throw AuthError.phoneAlreadyRegistered }
        let acc = MockAccount(phone: phone, password: password,
                              nickname: nickname.isEmpty ? defaultNickname(phone) : nickname,
                              avatar: randomAvatar())
        var a = accounts; a[phone] = acc; accounts = a
        return acc.toUser(.register)
    }

    // MARK: 账号密码注册（兜底，不依赖短信）

    func registerByUserID(userID: String, password: String, name: String) async throws -> AuthUser {
        guard password.count >= 6 else { throw AuthError.weakPassword }
        let key = userID
        guard accounts[key] == nil else { throw AuthError.userIDAlreadyRegistered }
        let acc = MockAccount(phone: userID, password: password,
                              nickname: name.isEmpty ? defaultNickname(userID) : name,
                              avatar: randomAvatar())
        var a = accounts; a[key] = acc; accounts = a
        return acc.toUser(.register)
    }

    // MARK: 工具

    private func isValidPhone(_ phone: String) -> Bool {
        let set = CharacterSet.decimalDigits.inverted
        let digits = phone.components(separatedBy: set).joined()
        return digits.count == 11 && digits.hasPrefix("1")
    }

    private func defaultNickname(_ phone: String) -> String {
        let tail = phone.suffix(4)
        return "用户\(tail)"
    }

    private func randomAvatar() -> String {
        ["🦊","🐼","🐯","🦁","🐨","🐸","🦄","🐧","🐱","🐶","🐰","🦉"].randomElement() ?? "🙂"
    }
}

// MARK: - 内部模型

private struct MockAccount: Codable {
    let phone: String
    var password: String?
    let nickname: String
    let avatar: String

    func toUser(_ type: AuthUser.LoginType) -> AuthUser {
        AuthUser(uid: "u_\(phone)", phone: phone, nickname: nickname,
                 avatar: avatar, loginType: type)
    }
}

private struct CodeTicket: Codable {
    let code: String
    let expireAt: Date
}

extension Notification.Name {
    static let mockSMSSent = Notification.Name("mockSMSSent")
}
