import UIKit

// MARK: - 我的二维码页

/// 展示当前用户的 PK 绑定二维码，可保存相册 / 复制绑定码。
/// 游客态时提示需先登录。
/// UI 规范与 PK 页（PKTokens / CardTokens）保持一致：主色 #10B981、白卡圆角、浅灰背景。
final class MyQRCodeViewController: UIViewController {

    // MARK: 设计令牌（对齐 PKTokens.Color / CardTokens.Color）
    private enum C {
        static let background = UIColor(hex: 0xF8F8F8)
        static let card       = UIColor(hex: 0xFFFFFF)
        static let primary    = UIColor(hex: 0x10B981)
        static let primaryBg  = UIColor(hex: 0x10B981).withAlphaComponent(0.10)
        static let foreground = UIColor(hex: 0x1A1A1A)
        static let subtle     = UIColor(hex: 0x999999)
        static let border     = UIColor.black.withAlphaComponent(0.05)
    }

    private let scrollView = UIScrollView()
    private let card = UIView()
    private let avatarLabel = UILabel()
    private let nameLabel = UILabel()
    private let qrImageView = UIImageView()
    private let hintLabel = UILabel()
    private let saveButton = UIButton(type: .system)
    private let copyButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = C.background
        setupUI()
        render()
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // 顶部返回（与全站一致：左上角箭头）
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = C.foreground
        backButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "我的 PK 码"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = C.foreground
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        card.backgroundColor = C.card
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.04
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 64),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            card.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24)
        ])

        avatarLabel.font = .systemFont(ofSize: 64)
        avatarLabel.textAlignment = .center

        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textAlignment = .center
        nameLabel.textColor = C.foreground

        qrImageView.contentMode = .scaleAspectFit
        qrImageView.layer.cornerRadius = 12
        qrImageView.clipsToBounds = true
        qrImageView.widthAnchor.constraint(equalToConstant: 240).isActive = true
        qrImageView.heightAnchor.constraint(equalToConstant: 240).isActive = true

        hintLabel.font = .systemFont(ofSize: 13)
        hintLabel.textColor = C.subtle
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 0

        saveButton.setTitle("保存到相册", for: .normal)
        saveButton.backgroundColor = C.primary
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        saveButton.layer.cornerRadius = 12
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)

        copyButton.setTitle("复制绑定码", for: .normal)
        copyButton.backgroundColor = C.primaryBg
        copyButton.setTitleColor(C.primary, for: .normal)
        copyButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        copyButton.layer.cornerRadius = 12
        copyButton.addTarget(self, action: #selector(copyCode), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [avatarLabel, nameLabel, qrImageView, hintLabel, saveButton, copyButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -28)
        ])
        saveButton.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        saveButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        copyButton.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        copyButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

    private func render() {
        guard let user = AuthService.shared.currentUser else {
            avatarLabel.text = "🚶"
            nameLabel.text = "游客"
            qrImageView.image = nil
            hintLabel.text = "登录后可生成你的 PK 绑定二维码"
            saveButton.isEnabled = false
            copyButton.isEnabled = false
            return
        }
        let code = PKCode(uid: user.uid, nick: user.nickname, av: user.avatar)
        avatarLabel.text = user.avatar
        nameLabel.text = user.nickname
        qrImageView.image = QRCoder.generate(code.payload, size: 240, tint: C.foreground)
        hintLabel.text = "让好友扫描此码即可与此账号 PK 绑定"
    }

    @objc private func save() {
        guard let img = qrImageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(img, self, #selector(saveDone(_:didFinish:ctx:)), nil)
    }

    @objc private func saveDone(_ image: UIImage, didFinish saving: Bool, ctx: UnsafeRawPointer?) {
        let msg = saving ? "已保存到相册" : "保存失败，请检查相册权限"
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
    }

    @objc private func copyCode() {
        guard let user = AuthService.shared.currentUser else { return }
        let code = PKCode(uid: user.uid, nick: user.nickname, av: user.avatar)
        UIPasteboard.general.string = code.payload
        let alert = UIAlertController(title: nil, message: "绑定码已复制", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}
