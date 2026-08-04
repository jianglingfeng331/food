import UIKit

// MARK: - 登录入口（首屏：本机号码一键登录为主）
//
// 设计规范：主色 #10B981；背景 #F8F8F8；文字深色；图标使用 SF Symbol（非 emoji）。

/// 项目主色（与 SwiftUI 端 CardTokens.Color.primary 一致）
let AppPrimary = UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1)
let AppBackground = UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1)
let AppText = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1)

final class AuthGateViewController: UIViewController {

    var onLogin: (() -> Void)?

    private let logoView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    // 一键登录主按钮
    private let oneKeyButton = UIButton(type: .system)
    private let oneKeyTitleLabel = UILabel()
    private let maskedPhoneLabel = UILabel()

    // 其他登录方式
    private let otherToggle = UIButton(type: .system)
    private let otherContainer = UIView()
    private let phoneField = UITextField()
    private let smsField = UITextField()
    private let passwordField = UITextField()
    private let getCodeButton = UIButton(type: .system)
    private let segment = UISegmentedControl(items: ["验证码登录", "密码登录"])
    private let otherLoginButton = UIButton(type: .system)
    private let otherTip = UILabel()

    private let registerButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    private let toastLabel = UILabel()

    private var showingOther = false
    private var countdown = 0
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppBackground
        setupUI()
        refreshMaskedPhone()
    }

    deinit { timer?.invalidate() }

    // MARK: UI

    private func setupUI() {
        // 品牌图标（SF Symbol，非 emoji）
        let cfg = UIImage.SymbolConfiguration(pointSize: 52, weight: .medium)
        logoView.image = UIImage(systemName: "fork.knife", withConfiguration: cfg)
        logoView.tintColor = AppPrimary
        logoView.contentMode = .scaleAspectFit

        titleLabel.text = "FoodSticker"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = AppText
        titleLabel.textAlignment = .center
        subtitleLabel.text = "记录每一餐，和朋友来一场贴纸 PK"
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = AppText
        subtitleLabel.textAlignment = .center

        // 一键登录主按钮（突出）
        oneKeyButton.backgroundColor = AppPrimary
        oneKeyButton.layer.cornerRadius = 14
        oneKeyButton.setTitleColor(.white, for: .normal)
        // 不通过 setTitle 设置文字，避免和内部自定义 stack 重叠
        oneKeyButton.setTitle("", for: .normal)
        oneKeyButton.addTarget(self, action: #selector(oneKeyTapped), for: .touchUpInside)

        oneKeyTitleLabel.text = "本机号码一键登录"
        oneKeyTitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        oneKeyTitleLabel.textColor = .white
        oneKeyTitleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [oneKeyTitleLabel, maskedPhoneLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .center
        oneKeyButton.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: oneKeyButton.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: oneKeyButton.centerYAnchor)
        ])

        // 其他登录方式切换
        otherToggle.setTitle("其他登录方式 ▾", for: .normal)
        otherToggle.setTitleColor(AppText, for: .normal)
        otherToggle.addTarget(self, action: #selector(toggleOther), for: .touchUpInside)

        buildOtherContainer()

        registerButton.setTitle("注册新账号", for: .normal)
        registerButton.setTitleColor(AppPrimary, for: .normal)
        registerButton.addTarget(self, action: #selector(goRegister), for: .touchUpInside)

        closeButton.setTitle("稍后再说", for: .normal)
        closeButton.setTitleColor(AppText, for: .normal)
        closeButton.addTarget(self, action: #selector(skip), for: .touchUpInside)

        toastLabel.textAlignment = .center
        toastLabel.textColor = .systemRed
        toastLabel.font = .systemFont(ofSize: 13)
        toastLabel.isHidden = true

        let vstack = UIStackView(arrangedSubviews: [logoView, titleLabel, subtitleLabel,
                                                     oneKeyButton, otherToggle, otherContainer,
                                                     registerButton, toastLabel])
        vstack.axis = .vertical
        vstack.spacing = 24
        vstack.alignment = .fill
        vstack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vstack)
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            vstack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            vstack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])

        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        // 一键登录按钮高度
        oneKeyButton.heightAnchor.constraint(equalToConstant: 84).isActive = true
        otherContainer.isHidden = true
    }

    private func buildOtherContainer() {
        phoneField.placeholder = "手机号"
        phoneField.keyboardType = .phonePad
        phoneField.borderStyle = .roundedRect
        passwordField.placeholder = "密码"
        passwordField.isSecureTextEntry = true
        passwordField.borderStyle = .roundedRect
        smsField.placeholder = "验证码"
        smsField.keyboardType = .numberPad
        smsField.borderStyle = .roundedRect

        getCodeButton.setTitle("获取验证码", for: .normal)
        getCodeButton.setTitleColor(AppPrimary, for: .normal)
        getCodeButton.addTarget(self, action: #selector(getCode), for: .touchUpInside)

        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        otherLoginButton.backgroundColor = UIColor(white: 0.94, alpha: 1)
        otherLoginButton.layer.cornerRadius = 12
        otherLoginButton.setTitleColor(AppText, for: .normal)
        otherLoginButton.setTitle("登录", for: .normal)
        otherLoginButton.addTarget(self, action: #selector(otherLoginTapped), for: .touchUpInside)

        otherTip.text = "未注册的手机号，验证码登录将自动创建账号"
        otherTip.font = .systemFont(ofSize: 12)
        otherTip.textColor = .tertiaryLabel
        otherTip.numberOfLines = 0

        let codeRow = UIStackView(arrangedSubviews: [smsField, getCodeButton])
        codeRow.spacing = 8
        codeRow.axis = .horizontal
        getCodeButton.setContentHuggingPriority(.required, for: .horizontal)

        let inner = UIStackView(arrangedSubviews: [segment, phoneField, codeRow, passwordField, otherLoginButton, otherTip])
        inner.axis = .vertical
        inner.spacing = 12
        inner.translatesAutoresizingMaskIntoConstraints = false
        otherContainer.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: otherContainer.topAnchor),
            inner.leadingAnchor.constraint(equalTo: otherContainer.leadingAnchor),
            inner.trailingAnchor.constraint(equalTo: otherContainer.trailingAnchor),
            inner.bottomAnchor.constraint(equalTo: otherContainer.bottomAnchor)
        ])
        segmentChanged()
    }

    // MARK: 交互

    private func refreshMaskedPhone() {
        let masked = (AuthService.shared.provider as? MockAuthProvider)?.oneKeyMaskedPhone ?? "138****8000"
        maskedPhoneLabel.text = masked
        maskedPhoneLabel.textColor = .white.withAlphaComponent(0.85)
        maskedPhoneLabel.font = .systemFont(ofSize: 13)
    }

    @objc private func toggleOther() {
        showingOther.toggle()
        UIView.animate(withDuration: 0.25) {
            self.otherContainer.isHidden = !self.showingOther
            self.otherToggle.setTitle(self.showingOther ? "其他登录方式 ▴" : "其他登录方式 ▾", for: .normal)
        }
    }

    @objc private func segmentChanged() {
        let isSMS = segment.selectedSegmentIndex == 0
        smsField.isHidden = !isSMS
        getCodeButton.isHidden = !isSMS
        passwordField.isHidden = isSMS
        otherLoginButton.setTitle(isSMS ? "验证码登录" : "密码登录", for: .normal)
    }

    @objc private func oneKeyTapped() {
        showLoading(on: oneKeyButton, text: "本机号码一键登录")
        Task {
            do {
                let user = try await AuthService.shared.loginByOneKey()
                await MainActor.run { self.finishLogin(user) }
            } catch {
                await MainActor.run { self.hideLoading(self.oneKeyButton); self.showToast("一键登录失败，请重试") }
            }
        }
    }

    @objc private func getCode() {
        guard let phone = phoneField.text, !phone.isEmpty else {
            showToast("请输入手机号"); return
        }
        Task {
            do {
                _ = try await AuthService.shared.provider.sendSMSCode(phone: phone)
                await MainActor.run { self.startCountdown() }
            } catch {
                await MainActor.run { self.showToast((error as? AuthError)?.errorDescription ?? "发送失败") }
            }
        }
    }

    private func startCountdown() {
        countdown = 60
        getCodeButton.isEnabled = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            self.countdown -= 1
            if self.countdown <= 0 {
                t.invalidate()
                self.getCodeButton.isEnabled = true
                self.getCodeButton.setTitle("获取验证码", for: .normal)
            } else {
                self.getCodeButton.setTitle("\(self.countdown)s 后重发", for: .normal)
            }
        }
    }

    @objc private func otherLoginTapped() {
        guard let phone = phoneField.text, !phone.isEmpty else { showToast("请输入手机号"); return }
        let isSMS = segment.selectedSegmentIndex == 0
        showLoading(on: otherLoginButton, text: "登录中")
        Task {
            do {
                let user: AuthUser
                if isSMS {
                    guard let code = smsField.text, !code.isEmpty else {
                        await MainActor.run { self.hideLoading(self.otherLoginButton); self.showToast("请输入验证码") }; return
                    }
                    user = try await AuthService.shared.loginBySMS(phone: phone, code: code)
                } else {
                    guard let pwd = passwordField.text, !pwd.isEmpty else {
                        await MainActor.run { self.hideLoading(self.otherLoginButton); self.showToast("请输入密码") }; return
                    }
                    user = try await AuthService.shared.loginByPassword(phone: phone, password: pwd)
                }
                await MainActor.run { self.hideLoading(self.otherLoginButton); self.finishLogin(user) }
            } catch {
                await MainActor.run { self.hideLoading(self.otherLoginButton); self.showToast((error as? AuthError)?.errorDescription ?? "登录失败") }
            }
        }
    }

    @objc private func goRegister() {
        let reg = RegisterViewController()
        navigationController?.pushViewController(reg, animated: true)
    }

    @objc private func skip() {
        // 游客：关闭登录，回到原浏览态
        AuthCoordinator.shared.dismissLogin()
    }

    // MARK: 完成

    private func finishLogin(_ user: AuthUser) {
        NotificationCenter.default.post(name: .authDidChange, object: nil)
        AuthCoordinator.shared.dismissLogin()
        onLogin?()
    }

    // MARK: 工具

    private func showToast(_ text: String) {
        toastLabel.text = text
        toastLabel.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.toastLabel.isHidden = true }
    }

    private func showLoading(on button: UIButton, text: String) {
        button.isEnabled = false
        if button === oneKeyButton {
            oneKeyTitleLabel.text = text + "…"
            maskedPhoneLabel.isHidden = true
        } else {
            button.setTitle(text + "…", for: .normal)
        }
    }

    private func hideLoading(_ button: UIButton) {
        button.isEnabled = true
        if button === oneKeyButton {
            oneKeyTitleLabel.text = "本机号码一键登录"
            maskedPhoneLabel.isHidden = false
        } else {
            button.setTitle("登录", for: .normal)
        }
    }
}

extension Notification.Name {
    static let authDidChange = Notification.Name("authDidChange")
}
