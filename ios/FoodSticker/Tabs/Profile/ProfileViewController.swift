import UIKit
import SwiftUI

// MARK: - 个人中心（UIKit 壳，承载 SwiftUI ProfileView）

final class ProfileViewController: UIViewController {

    private var hosting: UIHostingController<ProfileView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1)

        let profileView = ProfileView(
            onClose: { [weak self] in self?.dismiss(animated: true) },
            onNavigate: { [weak self] dest in self?.navigate(dest) },
            onLogin: { [weak self] in self?.loginTapped() }
        )
        let h = UIHostingController(rootView: profileView)
        hosting = h
        addChild(h)
        h.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(h.view)
        NSLayoutConstraint.activate([
            h.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            h.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            h.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            h.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        h.didMove(toParent: self)

        NotificationCenter.default.addObserver(self,
            selector: #selector(rerender), name: .authDidChange, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func rerender() {
        let profileView = ProfileView(
            onClose: { [weak self] in self?.dismiss(animated: true) },
            onNavigate: { [weak self] dest in self?.navigate(dest) },
            onLogin: { [weak self] in self?.loginTapped() }
        )
        hosting?.rootView = profileView
    }

    // MARK: 跳转功能页

    private func navigate(_ dest: ProfileDestination) {
        switch dest {
        case .goal:      pushSwiftUI(GoalView(), title: "减脂目标")
        case .trend:     pushSwiftUI(WeightTrendView(), title: "体重趋势")
        case .reminder:  pushSwiftUI(ReminderView(), title: "提醒设置")
        case .account:
            let accountView = AccountSettingsView(
                onLogin: { [weak self] in self?.loginTapped() },
                onEditNickname: { [weak self] in
                    let editor = NicknameEditView(initial: AvatarStore.shared.nickname) { newName in
                        AvatarStore.shared.saveNickname(newName)
                        if var u = AuthService.shared.currentUser {
                            u.nickname = newName
                            AuthService.shared.updateCurrentUser(u)
                        }
                    }
                    self?.pushSwiftUI(editor, title: "编辑昵称")
                },
                calorieTarget: AppDataStore.shared.calorieTarget,
                onUpdateCalorieTarget: { newTarget in
                    AppDataStore.shared.calorieTarget = newTarget
                })
            pushSwiftUI(accountView, title: "账户设置")
        }
    }

    private func pushSwiftUI<V: View>(_ view: V, title: String) {
        let vc = UIHostingController(rootView: view)
        vc.title = title
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: 动作

    @objc private func loginTapped() {
        AuthCoordinator.shared.presentLogin(from: self)
    }
}
