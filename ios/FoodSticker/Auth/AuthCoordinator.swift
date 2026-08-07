import UIKit

// MARK: - 全局登录协调器

/// 游客模式下，任何"关键操作"都可调用 presentLogin(from:) 弹起登录流程。
/// 登录成功后通过 onLogin 回调继续原操作。
final class AuthCoordinator {

    static let shared = AuthCoordinator()

    private var loginNav: UINavigationController?

    /// 若已登录直接执行 completion；否则弹登录流程，成功后执行。
    func requireLogin(from vc: UIViewController, then completion: @escaping () -> Void) {
        if AuthService.shared.isLoggedIn {
            completion()
            return
        }
        let gate = AuthGateViewController()
        gate.onLogin = completion
        let nav = UINavigationController(rootViewController: gate)
        nav.modalPresentationStyle = .fullScreen
        loginNav = nav
        vc.present(nav, animated: true)
    }

    /// 直接弹出登录流程（不判断登录态），用于"我的"页主动登录。
    func presentLogin(from vc: UIViewController, onLogin: (() -> Void)? = nil) {
        let gate = AuthGateViewController()
        gate.onLogin = onLogin ?? {}
        let nav = UINavigationController(rootViewController: gate)
        nav.modalPresentationStyle = .fullScreen
        loginNav = nav
        vc.present(nav, animated: true)
    }

    func dismissLogin(completion: (() -> Void)? = nil) {
        // 不依赖单例 loginNav（易失配），直接从窗口根控制器找到当前最顶层的 modal 来关闭
        // 这样无论 loginNav 是否被覆盖，都能正确关闭登录弹窗
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first else {
            // 取不到窗口（极端情况），回退到 loginNav 兜底
            if let nav = loginNav {
                nav.dismiss(animated: true) { [weak self] in
                    self?.loginNav = nil
                    completion?()
                }
            } else {
                completion?()
            }
            return
        }
        var top = window.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        top?.dismiss(animated: true) { [weak self] in
            self?.loginNav = nil
            completion?()
        }
    }
}
