import UIKit

// MARK: - 注册页（手机号 + 短信验证码）

final class RegisterViewController: UIViewController {

    private let titleLabel = UILabel()
    private let phoneField = UITextField()
    private let codeField = UITextField()
    private let codeButton = UIButton(type: .system)
    private let nicknameField = UITextField()
    private let passwordField = UITextField()
    private let confirmField = UITextField()
    private let agreeButton = UIButton(type: .system)
    private let registerButton = UIButton(type: .system)
    private let toastLabel = UILabel()
    private var agreed = false
    private var countdown = 0
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppBackground
        title = "注册"
        setupUI()
    }

    deinit { timer?.invalidate() }

    private func setupUI() {
        titleLabel.text = "创建账号"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = AppText

        phoneField.placeholder = "手机号"; phoneField.keyboardType = .phonePad; phoneField.borderStyle = .roundedRect

        // 验证码行：输入框 + 获取验证码按钮
        codeField.placeholder = "短信验证码"; codeField.keyboardType = .numberPad; codeField.borderStyle = .roundedRect
        codeButton.setTitle("获取验证码", for: .normal)
        codeButton.setTitleColor(AppPrimary, for: .normal)
        codeButton.titleLabel?.font = .systemFont(ofSize: 14)
        codeButton.contentHorizontalAlignment = .right
        codeButton.addTarget(self, action: #selector(sendCodeTapped), for: .touchUpInside)

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

        // 验证码行容器
        let codeRow = UIStackView(arrangedSubviews: [codeField, codeButton])
        codeRow.axis = .horizontal
        codeRow.spacing = 12
        codeRow.distribution = .fill
        codeField.widthAnchor.constraint(equalTo: codeRow.widthAnchor, multiplier: 0.62).isActive = true

        let stack = UIStackView(arrangedSubviews: [titleLabel, phoneField, codeRow, nicknameField,
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

    @objc private func sendCodeTapped() {
        guard let phone = phoneField.text, isValidPhone(phone) else {
            showToast("请输入正确的手机号"); return
        }
        codeButton.isEnabled = false
        Task {
            do {
                _ = try await AuthService.shared.sendSMSCode(phone: phone)
                await MainActor.run {
                    self.startCountdown()
                    self.showToast("验证码已发送，请查看手机短信")
                }
            } catch {
                await MainActor.run {
                    self.codeButton.isEnabled = true
                    self.showToast((error as? AuthError)?.errorDescription ?? "发送失败")
                }
            }
        }
    }

    private func startCountdown() {
        countdown = 60
        updateCodeButton()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            self.countdown -= 1
            if self.countdown <= 0 {
                t.invalidate()
                self.codeButton.isEnabled = true
                self.codeButton.setTitle("获取验证码", for: .normal)
            } else {
                self.updateCodeButton()
            }
        }
    }

    private func updateCodeButton() {
        codeButton.setTitle("\(countdown)s 后重发", for: .normal)
    }

    @objc private func registerTapped() {
        guard let phone = phoneField.text, isValidPhone(phone) else { showToast("请输入正确的手机号"); return }
        guard let code = codeField.text, code.count == 6 else { showToast("请输入 6 位验证码"); return }
        guard let pwd = passwordField.text, pwd.count >= 6 else { showToast("密码至少 6 位"); return }
        guard pwd == confirmField.text else { showToast("两次密码不一致"); return }
        guard agreed else { showToast("请先同意用户协议"); return }

        registerButton.isEnabled = false
        registerButton.setTitle("注册中…", for: .normal)
        Task {
            do {
                let nick = nicknameField.text ?? ""
                _ = try await AuthService.shared.register(phone: phone, code: code, password: pwd, nickname: nick)
                await MainActor.run {
                    AuthCoordinator.shared.dismissLogin {
                        NotificationCenter.default.post(name: .authDidChange, object: nil)
                    }
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

    private func isValidPhone(_ phone: String) -> Bool {
        let digits = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return digits.count == 11 && digits.hasPrefix("1")
    }

    private func showToast(_ text: String) {
        toastLabel.text = text
        toastLabel.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.toastLabel.isHidden = true }
    }
}
