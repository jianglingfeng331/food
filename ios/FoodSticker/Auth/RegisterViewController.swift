import UIKit

// MARK: - 注册页
//
// 设计规范：主色 #10B981；背景 #F8F8F8；文字深色；图标使用 SF Symbol（非 emoji）。

final class RegisterViewController: UIViewController {

    private let titleLabel = UILabel()
    private let phoneField = UITextField()
    private let nicknameField = UITextField()
    private let passwordField = UITextField()
    private let confirmField = UITextField()
    private let agreeButton = UIButton(type: .system)
    private let registerButton = UIButton(type: .system)
    private let toastLabel = UILabel()
    private var agreed = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppBackground
        title = "注册"
        setupUI()
    }

    private func setupUI() {
        titleLabel.text = "创建账号"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = AppText

        phoneField.placeholder = "手机号"; phoneField.keyboardType = .phonePad; phoneField.borderStyle = .roundedRect
        nicknameField.placeholder = "昵称（选填）"; nicknameField.borderStyle = .roundedRect
        passwordField.placeholder = "密码（至少 6 位）"; passwordField.isSecureTextEntry = true; passwordField.borderStyle = .roundedRect
        confirmField.placeholder = "确认密码"; confirmField.isSecureTextEntry = true; confirmField.borderStyle = .roundedRect

        agreeButton.setImage(UIImage(systemName: "square"), for: .normal)
        agreeButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        agreeButton.tintColor = AppPrimary
        agreeButton.setTitle(" 我已阅读并同意《用户协议》", for: .normal)
        agreeButton.setTitleColor(.secondaryLabel, for: .normal)
        agreeButton.contentHorizontalAlignment = .left
        agreeButton.addTarget(self, action: #selector(toggleAgree), for: .touchUpInside)

        registerButton.backgroundColor = AppPrimary
        registerButton.layer.cornerRadius = 12
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.setTitle("注册并登录", for: .normal)
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)

        toastLabel.textColor = .systemRed
        toastLabel.font = .systemFont(ofSize: 13)
        toastLabel.isHidden = true
        toastLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, phoneField, nicknameField,
                                                   passwordField, confirmField, agreeButton,
                                                   registerButton, toastLabel])
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    @objc private func toggleAgree() {
        agreed.toggle()
        agreeButton.isSelected = agreed
    }

    @objc private func registerTapped() {
        guard let phone = phoneField.text, !phone.isEmpty else { showToast("请输入手机号"); return }
        guard let pwd = passwordField.text, pwd.count >= 6 else { showToast("密码至少 6 位"); return }
        guard pwd == confirmField.text else { showToast("两次密码不一致"); return }
        guard agreed else { showToast("请先同意用户协议"); return }

        registerButton.isEnabled = false
        registerButton.setTitle("注册中…", for: .normal)
        Task {
            do {
                let nick = nicknameField.text ?? ""
                _ = try await AuthService.shared.register(phone: phone, password: pwd, nickname: nick)
                await MainActor.run {
                    NotificationCenter.default.post(name: .authDidChange, object: nil)
                    AuthCoordinator.shared.dismissLogin()
                }
            } catch {
                await MainActor.run {
                    self.registerButton.isEnabled = true
                    self.registerButton.setTitle("注册并登录", for: .normal)
                    self.showToast((error as? AuthError)?.errorDescription ?? "注册失败")
                }
            }
        }
    }

    private func showToast(_ text: String) {
        toastLabel.text = text
        toastLabel.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.toastLabel.isHidden = true }
    }
}
