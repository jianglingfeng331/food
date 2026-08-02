import Foundation
import SwiftUI

// MARK: - PK 绑定协调器（SwiftUI ↔ 关系服务桥接）

/// 持有当前 PK 关系状态，供 PKPageView 订阅刷新；
/// 并提供绑定/解绑动作（游客需先登录）。
final class PKBindingCoordinator: ObservableObject {
    static let shared = PKBindingCoordinator()

    @Published private(set) var opponent: PKOpponent?

    private var bag: NSObjectProtocol?

    private init() {
        opponent = PKRelationService.shared.opponent
        bag = NotificationCenter.default.addObserver(forName: .pkRelationChanged, object: nil,
                                                     queue: .main) { [weak self] _ in
            self?.opponent = PKRelationService.shared.opponent
        }
    }

    deinit { if let b = bag { NotificationCenter.default.removeObserver(b) } }

    /// 发起绑定（来自扫码/输码得到的 payload）。需先登录。
    func bind(payload: String) -> Bool {
        PKRelationService.shared.bind(rawPayload: payload)
    }

    func unbind() {
        PKRelationService.shared.unbind()
    }
}

extension Notification.Name {
    static let pkRelationChanged = Notification.Name("pkRelationChanged")
}
