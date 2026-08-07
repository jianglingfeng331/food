import UIKit

/// 标准 SceneDelegate：构建 UIWindow + MainTabBarController，启动默认选中首页（Home）
final public class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    public var window: UIWindow?

    public func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {
            Log("❌ SceneDelegate: windowScene 转换失败")
            return
        }
        Log("✅ SceneDelegate: willConnectTo 已触发")

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainTabBarController()
        self.window = window
        window.makeKeyAndVisible()
        Log("✅ SceneDelegate: MainTabBarController 已设置，window 已可见")

        // 游客模式：默认以本地数据进入，无需强制登录。
        // 若已存在持久化会话（上次登录过），则尝试同步云端数据。
        Task { await AppDataStore.shared.bootstrap() }

        // 未登录时弹出登录流程（欢迎页 → 注册/登录）。
        // AuthGateViewController 内的协议勾选通过后展示对应登录/注册入口。
        if !AuthService.shared.isLoggedIn {
            AuthCoordinator.shared.requireLogin(from: window.rootViewController!) { [weak self] in
                Log("✅ SceneDelegate: 登录完成，进入主流程")
            }
        }
    }

    // App 进入前台时检查日期变化（跨天后自动更新缓存）
    public func sceneWillEnterForeground(_ scene: UIScene) {
        AppDataStore.shared.checkDayChangeAndUpdate()
    }
}
