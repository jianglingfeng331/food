import Foundation

/// PK 绑定关系服务。
/// 改造后：绑定关系以云端为准（数据库落地，跨设备实时同步），
/// 同时在本地 UserDefaults 缓存一份，断网时也能展示上次状态。
@MainActor
final class PKRelationService {
    static let shared = PKRelationService()

    @Published private(set) var partner: BindingPartner?
    private let cacheKey = "pk_relation_partner"

    struct BindingPartner: Identifiable, Equatable {
        let id: String        // uid
        let nickname: String
        let avatar: String    // emoji
    }

    private init() {
        // 不再在初始化时加载旧缓存，避免 PK 页打开时闪现旧对手
        // 缓存仅在断网时兜底使用，refresh() 失败时会自动保留旧状态
    }

    // MARK: - 本地缓存（断网兜底）

    private func loadCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let d = try? JSONDecoder().decode(CacheModel.self, from: data) else { return }
        partner = BindingPartner(id: d.uid, nickname: d.nickname, avatar: d.avatar)
    }

    private func saveCache(_ p: BindingPartner?) {
        if let p {
            let m = CacheModel(uid: p.id, nickname: p.nickname, avatar: p.avatar)
            UserDefaults.standard.set(try? JSONEncoder().encode(m), forKey: cacheKey)
        } else {
            UserDefaults.standard.removeObject(forKey: cacheKey)
        }
    }

    private struct CacheModel: Codable {
        let uid: String; let nickname: String; let avatar: String
    }

    // MARK: - 云端操作

    /// 从云端拉取当前绑定关系并刷新本地状态。
    @MainActor
    func refresh() async {
        guard CloudAPI.shared.isLoggedIn else { return }
        do {
            let rel = try await CloudAPI.shared.pkRelation()
            let p = rel.partner.map {
                BindingPartner(id: $0.uid, nickname: $0.nickname, avatar: $0.avatar)
            }
            partner = p
            saveCache(p)
        } catch {
            // 网络失败：保留本地缓存状态，不报错打扰用户
            Log("[PKRelation] refresh failed: \(error.localizedDescription)")
        }
    }

    /// 绑定对方（传入 PKCode 解析出的 uid）。
    @MainActor
    func bind(_ code: PKCode) async throws {
        let partnerInfo = try await CloudAPI.shared.pkBind(targetUID: code.uid)
        let p = BindingPartner(id: partnerInfo.uid,
                               nickname: partnerInfo.nickname,
                               avatar: partnerInfo.avatar)
        partner = p
        saveCache(p)
    }

    /// 解绑。
    @MainActor
    func unbind() async throws {
        try await CloudAPI.shared.pkUnbind()
        partner = nil
        saveCache(nil)
    }

    var isBound: Bool { partner != nil }
}
