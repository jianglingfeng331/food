import UIKit
import SwiftUI

// MARK: - HomeViewController (SwiftUI 嵌入版)

final class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)

        let homeView = HomeView(onProfile: { [weak self] in
            self?.openProfile()
        })
        let hosting = UIHostingController(rootView: homeView)
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)
    }

    // MARK: - 打开「我的」

    private func openProfile() {
        let nav = UINavigationController(rootViewController: ProfileViewController())
        present(nav, animated: true)
    }
}
