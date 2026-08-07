import Foundation
import SwiftUI

extension Notification.Name {
    static let pkBindingDidChange = Notification.Name("pkBindingDidChange")
}

// MARK: - PK 绑定协调器（SwiftUI ↔ 关系服务桥接）

/// 当前对手（已绑定伙伴）的展示模型。
struct PKOpponent: Identifiable, Equatable {
    let id: String        // uid
    let nickname: String
    let avatar: String    // emoji
}

/// 持有当前 PK 关系状态，供 PKPageView 订阅刷新；
/// 并提供绑定/解绑动作（游客需先登录）。
@MainActor
final class PKBindingCoordinator: ObservableObject {
    static let shared = PKBindingCoordinator()

    @Published private(set) var opponent: PKOpponent?
    @Published private(set) var isBusy = false
    @Published private(set) var lastError: String?

    private init() {
        syncFromService()
    }

    /// 启动时 / 登录后调用，从云端拉取最新关系。
    func refresh() async {
        await PKRelationService.shared.refresh()
        syncFromService()
    }

    private func syncFromService() {
        let oldOpponent = opponent
        guard let p = PKRelationService.shared.partner else {
            opponent = nil
            if oldOpponent != nil { notifyChange() }
            return
        }
        let newOpponent = PKOpponent(id: p.id, nickname: p.nickname, avatar: p.avatar)
        if newOpponent != oldOpponent {
            opponent = newOpponent
            notifyChange()
        }
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: .pkBindingDidChange, object: nil)
    }

    /// 发起绑定（来自扫码/输码解析出的 PKCode）。需先登录。
    @MainActor
    @discardableResult
    func bind(_ code: PKCode) async -> Bool {
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        do {
            try await PKRelationService.shared.bind(code)
            syncFromService()
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    @MainActor
    func unbind() async {
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        do {
            try await PKRelationService.shared.unbind()
            opponent = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    var isBound: Bool { opponent != nil }
}
