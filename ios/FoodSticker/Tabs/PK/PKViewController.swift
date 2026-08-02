import UIKit
import SwiftUI

// MARK: - PK 标签页容器（UIKit 承载 SwiftUI）

final class PKViewController: UIViewController {

    private let store = AppDataStore.shared
    private var hosting: UIHostingController<AnyView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "PK"
        navigationController?.navigationBar.prefersLargeTitles = true
        renderPK()

        NotificationCenter.default.addObserver(self, selector: #selector(rerender),
                                               name: .authDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rerender),
                                               name: .pkRelationChanged, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func rerender() {
        renderPK()
    }

    private func renderPK() {
        let binding = PKBindingCoordinator.shared
        let page = PKPageView(
            store: store,
            binding: binding,
            onBind: { [weak self] in self?.presentBindSheet() },
            onScan: { [weak self] in self?.presentScanner() },
            onMyQR: { [weak self] in self?.presentMyQR() },
            onUnbind: { [weak self] in self?.confirmUnbind() },
            onProfile: { [weak self] in self?.openProfile() }
        )
        .environmentObject(binding)

        if let hosting = hosting {
            hosting.rootView = AnyView(page)
        } else {
            let h = UIHostingController(rootView: AnyView(page))
            hosting = h
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
        }
    }

    // MARK: 绑定流程

    private func presentBindSheet() {
        // 关键操作：游客先登录
        AuthCoordinator.shared.requireLogin(from: self) { [weak self] in
            self?.showBindOptions()
        }
    }

    private func showBindOptions() {
        let alert = UIAlertController(title: "绑定 PK 对手", message: "扫码或输入对方绑定码", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "扫码绑定", style: .default) { [weak self] _ in self?.presentScanner() })
        alert.addAction(UIAlertAction(title: "我的二维码", style: .default) { [weak self] _ in self?.presentMyQR() })
        alert.addAction(UIAlertAction(title: "手动输入绑定码", style: .default) { [weak self] _ in self?.presentCodeInput() })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func presentScanner() {
        let scanner = QRScannerViewController()
        scanner.onScanned = { [weak self] payload in
            self?.handleBindPayload(payload)
        }
        present(scanner, animated: true)
    }

    private func presentMyQR() {
        let qr = MyQRCodeViewController()
        let nav = UINavigationController(rootViewController: qr)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func presentCodeInput() {
        let alert = UIAlertController(title: "输入绑定码", message: "粘贴对方二维码对应的绑定码", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "绑定码" }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "绑定", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text else { return }
            self?.handleBindPayload(text)
        })
        present(alert, animated: true)
    }

    private func handleBindPayload(_ payload: String) {
        guard AuthService.shared.isLoggedIn else {
            AuthCoordinator.shared.presentLogin(from: self)
            return
        }
        if PKBindingCoordinator.shared.bind(payload: payload) {
            let ok = UIAlertController(title: "绑定成功", message: "已与对手建立 PK 关系", preferredStyle: .alert)
            ok.addAction(UIAlertAction(title: "好的", style: .default))
            present(ok, animated: true)
        } else {
            let fail = UIAlertController(title: "绑定失败", message: "绑定码无效，请确认后重试", preferredStyle: .alert)
            fail.addAction(UIAlertAction(title: "好的", style: .default))
            present(fail, animated: true)
        }
    }

    private func confirmUnbind() {
        let alert = UIAlertController(title: "解除 PK 绑定", message: "确定要与当前对手解绑吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "解绑", style: .destructive) { _ in
            PKBindingCoordinator.shared.unbind()
        })
        present(alert, animated: true)
    }

    // MARK: - 打开「我的」

    private func openProfile() {
        let nav = UINavigationController(rootViewController: ProfileViewController())
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}
