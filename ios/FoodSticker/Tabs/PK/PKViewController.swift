import UIKit
import SwiftUI

// MARK: - PK 标签页容器（UIKit 承载 SwiftUI）

final class PKViewController: UIViewController {

    private let store = AppDataStore.shared
    private var hosting: UIHostingController<AnyView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        // 推迟到首帧布局完成后才渲染 PKPageView，避免 zero-bounds 导致
        // SwiftUI GeometryReader/Canvas 报 Invalid frame dimension
        DispatchQueue.main.async { [weak self] in self?.renderPK() }
        // 进入即按云端最新关系刷新绑定状态（跨设备同步）
        Task { @MainActor in await PKBindingCoordinator.shared.refresh() }

        NotificationCenter.default.addObserver(self, selector: #selector(rerender),
                                               name: .authDidChange, object: nil)

        // 绑定状态变化（扫码绑定、对手绑定我）时刷新
        NotificationCenter.default.addObserver(self, selector: #selector(rerender),
                                               name: .pkBindingDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .authDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .pkBindingDidChange, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 每次进入 PK 标签页时刷新绑定关系（跨设备同步）。
        // 注意：不再在此处调用 store.sync() —— 那会用网络快照覆盖首页用户刚保存的体重/饮水等数据。
        // PK 全量数据刷新由用户下拉刷新触发。
        Task { @MainActor in
            await PKBindingCoordinator.shared.refresh()
        }
    }

    @objc private func rerender() {
        // 同样推迟，确保在 dismiss 动画结束后布局稳定再渲染
        DispatchQueue.main.async { [weak self] in self?.renderPK() }
        Task { @MainActor in
            await PKBindingCoordinator.shared.refresh()
        }
    }

    private func renderPK() {
        // 游客态：不渲染 PK 页面，直接弹出登录
        guard AuthService.shared.isLoggedIn else {
            if hosting == nil {
                // 首次挂载一个空 view 防止 UI 闪白
                let emptyBox = UIHostingController(rootView: AnyView(Color(.systemGroupedBackground).ignoresSafeArea()))
                hosting = emptyBox
                addChild(emptyBox)
                emptyBox.view.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(emptyBox.view)
                NSLayoutConstraint.activate([
                    emptyBox.view.topAnchor.constraint(equalTo: view.topAnchor),
                    emptyBox.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                    emptyBox.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    emptyBox.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
                ])
                emptyBox.didMove(toParent: self)
            }
            AuthCoordinator.shared.requireLogin(from: self) {}
            return
        }
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
        guard let code = PKCode.parse(payload) else {
            let fail = UIAlertController(title: "绑定失败", message: "绑定码无效，请确认后重试", preferredStyle: .alert)
            fail.addAction(UIAlertAction(title: "好的", style: .default))
            present(fail, animated: true)
            return
        }
        let hud = UIAlertController(title: "绑定中…", message: nil, preferredStyle: .alert)
        present(hud, animated: true)
        Task { @MainActor in
            let ok = await PKBindingCoordinator.shared.bind(code)
            await MainActor.run {
                hud.dismiss(animated: true) {
                    if ok {
                        // 绑定成功后从云端刷新 PK 对战数据
                        Task { @MainActor in try? await AppDataStore.shared.sync() }
                        let a = UIAlertController(title: "绑定成功", message: "已与对手建立 PK 关系", preferredStyle: .alert)
                        a.addAction(UIAlertAction(title: "好的", style: .default))
                        self.present(a, animated: true)
                    } else {
                        let a = UIAlertController(title: "绑定失败",
                                                  message: PKBindingCoordinator.shared.lastError ?? "绑定码无效，请确认后重试",
                                                  preferredStyle: .alert)
                        a.addAction(UIAlertAction(title: "好的", style: .default))
                        self.present(a, animated: true)
                    }
                }
            }
        }
    }

    private func confirmUnbind() {
        let alert = UIAlertController(title: "解除 PK 绑定", message: "确定要与当前对手解绑吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "解绑", style: .destructive) { _ in
            Task { @MainActor in
                await PKBindingCoordinator.shared.unbind()
                // coordinator.opponent 已置空，PKPageView 通过 @ObservedObject 自动刷新
            }
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
