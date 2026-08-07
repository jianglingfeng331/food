import UIKit
import SwiftUI

// MARK: - HomeViewController (SwiftUI 嵌入版)

final class HomeViewController: UIViewController {

    private var hosting: UIHostingController<HomeView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)

        mountHosting()

        NotificationCenter.default.addObserver(
            self, selector: #selector(rerender),
            name: .authDidChange, object: nil)

        // 绑定/解绑状态变化时刷新首页（PK 卡片显隐、对手数据）
        NotificationCenter.default.addObserver(
            self, selector: #selector(rerender),
            name: .pkBindingDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .authDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .pkBindingDidChange, object: nil)
    }

    private func mountHosting() {
        let homeView = HomeView(onProfile: { [weak self] in
            self?.openProfile()
        })
        let h = UIHostingController(rootView: homeView)
        addChild(h)
        h.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(h.view)
        NSLayoutConstraint.activate([
            h.view.topAnchor.constraint(equalTo: view.topAnchor),
            h.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            h.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            h.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        h.didMove(toParent: self)
        self.hosting = h
    }

    @objc private func rerender() {
        let homeView = HomeView(onProfile: { [weak self] in
            self?.openProfile()
        })
        hosting?.rootView = homeView
    }

    // MARK: - 打开「我的」

    private func openProfile() {
        let nav = UINavigationController(rootViewController: ProfileViewController())
        present(nav, animated: true)
    }
}
