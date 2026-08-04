import UIKit
import SwiftUI

// MARK: - 贴纸日记（承载 SwiftUI 版 CardPageView，1:1 还原 Web 端 CardPage）

final class CardViewController: UIViewController {

    private var hosting: UIHostingController<CardPageView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1)

        mountHosting()

        NotificationCenter.default.addObserver(
            self, selector: #selector(rerender),
            name: .authDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .authDidChange, object: nil)
    }

    private func mountHosting() {
        let h = UIHostingController(rootView: CardPageView(onProfile: { [weak self] in
            self?.openProfile()
        }, onAddTap: { [weak self] in
            self?.openCamera()
        }))
        addChild(h)
        h.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(h.view)
        NSLayoutConstraint.activate([
            h.view.topAnchor.constraint(equalTo: view.topAnchor),
            h.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            h.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            h.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        h.didMove(toParent: self)
        self.hosting = h
    }

    @objc private func rerender() {
        hosting?.rootView = CardPageView(onProfile: { [weak self] in
            self?.openProfile()
        }, onAddTap: { [weak self] in
            self?.openCamera()
        })
    }

    // MARK: - 打开「我的」

    private func openProfile() {
        let nav = UINavigationController(rootViewController: ProfileViewController())
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    // MARK: - 打开拍摄

    private func openCamera() {
        AuthCoordinator.shared.requireLogin(from: self) { [weak self] in
            guard let self else { return }
            let nav = UINavigationController()
            var page = CameraPage()
            page.nav = nav
            let root = UIHostingController(rootView: page)
            nav.viewControllers = [root]
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
