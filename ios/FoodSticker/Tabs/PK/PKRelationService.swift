import Foundation
import Combine

// MARK: - PK 对手模型

struct PKOpponent: Codable, Equatable {
    let uid: String
    var nickname: String
    var avatar: String
    var boundAt: Date
}

// MARK: - PK 绑定状态

@available(iOS 13.0, *)
enum PKRelationState {
    case none                                  // 未绑定
    case bound(PKOpponent)                     // 已绑定对手
}

// MARK: - PK 关系服务（Mock 持久化）

/// 负责 PK 绑定 / 解绑 / 状态查询。
/// Mock 阶段用 UserDefaults 持久化；真实上线可改为云端关系。
/// 与当前登录用户绑定：游客态无绑定关系（需先登录）。
final class PKRelationService {

    static let shared = PKRelationService()

    @Published private(set) var opponent: PKOpponent?

    private let key = "pk_relation_opponent"

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let op = try? JSONDecoder().decode(PKOpponent.self, from: data) {
            opponent = op
        }
    }

    @available(iOS 13.0, *)
    var state: PKRelationState { opponent.map { .bound($0) } ?? .none }

    /// 通过扫到的绑定码发起绑定。 Mock：直接建立本地关系。
    /// 真实场景：将 code.uid 上报云端，云端确认双方互绑。
    func bind(by code: PKCode) {
        let op = PKOpponent(uid: code.uid, nickname: code.nick,
                            avatar: code.av.isEmpty ? "🙂" : code.av,
                            boundAt: Date())
        opponent = op
        persist(op)
        NotificationCenter.default.post(name: .pkRelationChanged, object: nil)
    }

    /// 手动输入绑定码绑定（兜底入口）。
    func bind(rawPayload: String) -> Bool {
        guard let code = PKCode.parse(rawPayload) else { return false }
        bind(by: code)
        return true
    }

    func unbind() {
        opponent = nil
        UserDefaults.standard.removeObject(forKey: key)
        NotificationCenter.default.post(name: .pkRelationChanged, object: nil)
    }

    private func persist(_ op: PKOpponent) {
        if let data = try? JSONEncoder().encode(op) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
