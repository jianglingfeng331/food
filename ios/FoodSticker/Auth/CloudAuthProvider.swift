import Foundation

// MARK: - 真实后端认证实现（短信验证码 + 手机号注册/登录）

/// 对接 FastAPI 后端的认证流程：
/// - 发送验证码：POST /auth/send-code {phone}
/// - 短信登录：   POST /auth/login-by-phone {phone, code}（号须已注册）
/// - 手机号注册： POST /auth/register-by-phone {phone, code, password?, nickname?}
///
/// 验证码由服务端下发（Mock 模式打到服务端日志），客户端不持有原文，符合安全规范。
/// 成功后写入 CloudAPI.shared.token，使后续业务接口（仪表盘/记录/PK/贴纸）自动带鉴权。
final class CloudAuthProvider: AuthProvider {

    private let api = CloudAPI.shared

    // MARK: - 发送验证码

    /// 调后端发码。Mock 模式验证码打印在服务端日志，客户端无从获取，UI 仅显示 60s 倒计时。
    /// 返回空串（与协议签名保持一致，但不回传真实验证码）。
    func sendSMSCode(phone: String) async throws -> String {
        guard isValidPhone(phone) else { throw AuthError.invalidPhone }
        do {
            let req = SendCodeRequest(phone: phone)
            _ = try await api.postNoAuthData("auth/send-code", body: req)
            return ""
        } catch let e as CloudAPI.CloudError {
            throw mapError(e)
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }

    // MARK: - 短信验证码登录

    func loginBySMS(phone: String, code: String) async throws -> AuthUser {
        guard isValidPhone(phone) else { throw AuthError.invalidPhone }
        do {
            let req = PhoneCodeRequest(phone: phone, code: code)
            let res: LoginResponse = try await api.postNoAuth("auth/login-by-phone", body: req)
            return try toAuthUser(res, loginType: .sms, phone: phone)
        } catch let e as CloudAPI.CloudError {
            throw mapError(e)
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }

    // MARK: - 账号密码登录（手机号 + 密码）

    func loginByPassword(phone: String, password: String) async throws -> AuthUser {
        // 后端按 username（账号密码体系）或 phone（手机号体系）查找，
        // 与不可预测的随机 id 解耦，直接传用户输入即可，无需猜测前缀。
        do {
            let u: CloudAPI.CkUser = try await retryOnNetwork {
                try await api.login(userID: phone, password: password)
            }
            return AuthUser(uid: u.id, phone: phone, nickname: u.name,
                            avatar: u.avatar, loginType: .password)
        } catch let e as CloudAPI.CloudError {
            throw mapError(e)
        }
    }

    // MARK: - 账号密码注册（兜底，不依赖短信）

    func registerByUserID(userID: String, password: String, name: String) async throws -> AuthUser {
        guard password.count >= 6 else { throw AuthError.weakPassword }
        do {
            // 网络层偶发超时/连不上时自动重试，避免「互联网」提示；
            // 409 等业务错误不是 URLError，不会重试，直接走 mapError → 自动登录回退。
            let u: CloudAPI.CkUser = try await retryOnNetwork {
                try await api.register(userID: userID, password: password, name: name)
            }
            return AuthUser(uid: u.id, phone: userID, nickname: u.name,
                            avatar: u.avatar, loginType: .register)
        } catch let e as CloudAPI.CloudError {
            throw mapError(e)
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }

    // MARK: - 手机号注册

    func register(phone: String, code: String, password: String, nickname: String) async throws -> AuthUser {
        guard isValidPhone(phone) else { throw AuthError.invalidPhone }
        guard password.count >= 6 else { throw AuthError.weakPassword }
        do {
            let req = PhoneRegisterRequest(phone: phone, code: code, password: password,
                                           nickname: nickname.isEmpty ? nil : nickname)
            let res: LoginResponse = try await api.postNoAuth("auth/register-by-phone", body: req)
            return try toAuthUser(res, loginType: .register, phone: phone)
        } catch let e as CloudAPI.CloudError {
            throw mapError(e)
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }

    // MARK: - 映射

    private func toAuthUser(_ res: LoginResponse, loginType: AuthUser.LoginType, phone: String) throws -> AuthUser {
        // 写入 CloudAPI token，使后续业务请求自动鉴权
        api.setToken(res.token)
        let u = res.user
        return AuthUser(
            uid: u.id,
            phone: phone,
            nickname: u.name,
            avatar: u.avatar,
            loginType: loginType
        )
    }

    private func mapError(_ e: CloudAPI.CloudError) -> AuthError {
        switch e {
        case .unauthorized:
            return .wrongPassword
        case .server(let msg):
            if msg.contains("过期") { return .codeExpired }
            if msg.contains("错误") { return .wrongCode }
            if msg.contains("尚未注册") { return .userNotFound }
            if msg.contains("已注册") { return .userIDAlreadyRegistered }
            if msg.contains("格式") { return .invalidPhone }
            if msg.contains("6 位") { return .weakPassword }
            return .unknown(msg)
        }
    }

    /// 仅对瞬时网络错误（超时 / 无法连接 / 连接丢失 / 无网络等）自动重试，
    /// 业务错误（CloudError，含 409 已注册、401 密码错）不重试，直接上抛。
    private func retryOnNetwork<T>(_ op: () async throws -> T) async throws -> T {
        do { return try await op() }
        catch let urlErr as URLError {
            Log("[CloudAuth] retryOnNetwork caught URLError code=\(urlErr.code.rawValue) desc=\(urlErr.localizedDescription)")
            let transient: [URLError.Code] = [
                .timedOut, .cannotConnectToHost, .networkConnectionLost,
                .notConnectedToInternet, .dnsLookupFailed, .callIsActive,
                .internationalRoamingOff, .cannotFindHost
            ]
            guard transient.contains(urlErr.code) else { throw urlErr }
            for i in 0..<2 {
                try? await Task.sleep(nanoseconds: 800_000_000)
                do { return try await op() }
                catch let retryErr as URLError {
                    Log("[CloudAuth] retry #\(i+1) URLError code=\(retryErr.code.rawValue)")
                }
            }
            throw urlErr
        }
    }

    private func isValidPhone(_ phone: String) -> Bool {
        let set = CharacterSet.decimalDigits.inverted
        let digits = phone.components(separatedBy: set).joined()
        return digits.count == 11 && digits.hasPrefix("1")
    }

    // MARK: - 请求/响应模型

    private struct SendCodeRequest: Encodable { let phone: String }
    private struct PhoneCodeRequest: Encodable { let phone: String; let code: String }
    private struct PhoneRegisterRequest: Encodable {
        let phone: String; let code: String
        let password: String?; let nickname: String?
    }
    private struct LoginResponse: Decodable {
        let token: String
        let user: CkAuthUser
    }
    private struct CkAuthUser: Decodable {
        let id: String; let name: String; let avatar: String
    }
}
