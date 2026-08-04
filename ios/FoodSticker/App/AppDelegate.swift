import UIKit

/// 标准 UIKit App 入口（iOS 13+ Scene 生命周期）
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    // Scene-based app：window 由 SceneDelegate 管理，此处不保留

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 启动时预初始化营养库连接（首次运行会从 Bundle 拷贝 nutrition.db 到 Documents）
        _ = NutritionDB.shared

#if DEBUG
        // 开发调试：UserDefaults 中 fs_debug_clear_on_launch = true 时清空全部数据
        if UserDefaults.standard.bool(forKey: "fs_debug_clear_on_launch") {
            AppDataStore.shared.clearAllData()
            UserDefaults.standard.removeObject(forKey: "fs_debug_clear_on_launch")
            print("[AppDelegate] 已清空全部数据")
        }
#endif

        return true
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // 与 project.yml 中 UISceneConfigurations 的 UISceneConfigurationName 保持一致
        return UISceneConfiguration(name: "Default Configuration",
                                    sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}
