import UIKit

/// 标准 SceneDelegate：构建 UIWindow + MainTabBarController，启动默认选中首页（Home）
final public class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    public var window: UIWindow?

    public func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {
            print("❌ SceneDelegate: windowScene 转换失败")
            return
        }
        print("✅ SceneDelegate: willConnectTo 已触发")

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainTabBarController()
        self.window = window
        window.makeKeyAndVisible()
        print("✅ SceneDelegate: MainTabBarController 已设置，window 已可见")

        // 启动即登录演示账号并拉取首页/PK 真实数据（替代硬编码 mock）
        Task { await AppDataStore.shared.bootstrap() }
    }
}
