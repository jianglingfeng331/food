import UIKit

// MARK: - 我的二维码页

/// 展示当前用户的 PK 绑定二维码，可保存相册 / 复制绑定码。
/// 游客态时提示需先登录。
final class MyQRCodeViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let card = UIView()
    private let avatarLabel = UILabel()
    private let nameLabel = UILabel()
    private let qrImageView = UIImageView()
    private let hintLabel = UILabel()
    private let saveButton = UIButton(type: .system)
    private let copyButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
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

        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 20
        card.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(card)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            card.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24)
        ])

        avatarLabel.font = .systemFont(ofSize: 64)
        avatarLabel.textAlignment = .center
        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textAlignment = .center
        nameLabel.textColor = .label

        qrImageView.contentMode = .scaleAspectFit
        qrImageView.layer.cornerRadius = 12
        qrImageView.clipsToBounds = true

        hintLabel.font = .systemFont(ofSize: 13)
        hintLabel.textColor = .secondaryLabel
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 0

        saveButton.setTitle("保存到相册", for: .normal)
        saveButton.backgroundColor = .systemGreen
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 12
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)

        copyButton.setTitle("复制绑定码", for: .normal)
        copyButton.backgroundColor = .secondarySystemFill
        copyButton.setTitleColor(.label, for: .normal)
        copyButton.layer.cornerRadius = 12
        copyButton.addTarget(self, action: #selector(copyCode), for: .touchUpInside)

        closeButton.setTitle("关闭", for: .normal)
        closeButton.setTitleColor(.secondaryLabel, for: .normal)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [avatarLabel, nameLabel, qrImageView, hintLabel, saveButton, copyButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24)
        ])
        qrImageView.widthAnchor.constraint(equalToConstant: 220).isActive = true
        qrImageView.heightAnchor.constraint(equalToConstant: 220).isActive = true
        saveButton.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        copyButton.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true

        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
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
        qrImageView.image = QRCoder.generate(code.payload, size: 220, tint: .label)
        hintLabel.text = "让好友扫描此码即可与此账号 PK 绑定"
    }

    @objc private func save() {
        guard let img = qrImageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(img, self, #selector(saveDone(_:didFinish:ctx:)), nil)
    }

    @objc private func saveDone(_ image: UIImage, didFinish saving: Bool, ctx: UnsafeRawPointer?) {
        let msg = saving ? "已保存到相册" : "保存失败"
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
