//
//  RegisterByPasswordViewController.swift
//  账号密码注册（短信平台未就绪时的兜底注册方式）
//

import UIKit

final class RegisterByPasswordViewController: UIViewController {

    var onRegistered: (() -> Void)?
    var onCancel: (() -> Void)?

    private let scrollView = UIScrollView()
    private let stack      = UIStackView()
    private let titleLbl   = UILabel()
    private let tipLbl     = UILabel()

    private let uidField   = UITextField()
    private let nameField  = UITextField()
    private let pwdField   = UITextField()
    private let pwd2Field  = UITextField()
    private let submitBtn  = UIButton(type: .system)
    private let loading    = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppBackground
        // 强制浅色：避免 iOS Dark Mode 下系统动态色（placeholder / secondarySystemBackground）
        // 反转成黑底灰字、看不清。Auth 模块页面背景/控件全部走固定色。
        view.overrideUserInterfaceStyle = .light
        setupNav()
        setupUI()
    }

    private func setupNav() {
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = AppText
        back.addTarget(self, action: #selector(close), for: .touchUpInside)
        back.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(back)
        NSLayoutConstraint.activate([
            back.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            back.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            back.widthAnchor.constraint(equalToConstant: 44),
            back.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupUI() {
        titleLbl.text = "创建账号"
        titleLbl.font = .systemFont(ofSize: 26, weight: .bold)
        titleLbl.textColor = AppText

        tipLbl.text = "短信验证码通道暂未开放，可用手机号或自定义账号 + 密码注册。"
        tipLbl.font = .systemFont(ofSize: 13)
        tipLbl.textColor = .secondaryLabel
        tipLbl.numberOfLines = 0

        configure(uidField,  "账号（手机号或其他唯一 ID）", contentType: .username)
        configure(nameField, "昵称（可选）")
        configure(pwdField,  "密码（至少 6 位）", secure: true)
        configure(pwd2Field, "确认密码", secure: true)

        submitBtn.setTitle("注 册", for: .normal)
        submitBtn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        submitBtn.setTitleColor(.white, for: .normal)
        submitBtn.backgroundColor = AppText
        submitBtn.layer.cornerRadius = 14
        submitBtn.addTarget(self, action: #selector(submit), for: .touchUpInside)

        loading.color = .white
        submitBtn.addSubview(loading)
        loading.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loading.centerXAnchor.constraint(equalTo: submitBtn.centerXAnchor),
            loading.centerYAnchor.constraint(equalTo: submitBtn.centerYAnchor)
        ])

        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(titleLbl)
        stack.addArrangedSubview(tipLbl)
        stack.addArrangedSubview(uidField)
        stack.addArrangedSubview(nameField)
        stack.addArrangedSubview(pwdField)
        stack.addArrangedSubview(pwd2Field)
        stack.addArrangedSubview(submitBtn)
        stack.setCustomSpacing(8, after: tipLbl)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48),

            submitBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func configure(_ tf: UITextField, _ placeholder: String,
                           secure: Bool = false,
                           contentType: UITextContentType? = nil) {
        tf.placeholder = placeholder
        tf.borderStyle = .roundedRect
        tf.font = .systemFont(ofSize: 15)
        tf.isSecureTextEntry = secure
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        tf.smartDashesType = .no
        tf.smartQuotesType = .no
        if let ct = contentType { tf.textContentType = ct }
        tf.heightAnchor.constraint(equalToConstant: 48).isActive = true
        // 固定浅灰色，不跟随系统 Dark Mode 切换
        tf.backgroundColor = AppGray
        // placeholder 也用显式固定色，避免 Dark Mode 下黑底白字看不清
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: AppTextLight,
                .font: UIFont.systemFont(ofSize: 15)
            ]
        )
        tf.textColor = AppText
        if secure {
            // 不引导 Strong Password Suggestions，让用户自己设置密码；
            // 空规则表示允许任意字符，关闭 iOS 自带的密码复杂度校验与建议气泡。
            tf.passwordRules = UITextInputPasswordRules(descriptor: "")
        }
    }

    @objc private func close() {
        if let onCancel { onCancel() }
        else { navigationController?.popViewController(animated: true) }
    }

    private func showToast(_ text: String) {
        let toast = UILabel()
        toast.text = text
        toast.textColor = .white
        toast.font = .systemFont(ofSize: 14)
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toast.layer.cornerRadius = 10
        toast.clipsToBounds = true
        toast.numberOfLines = 0
        toast.textAlignment = .center
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)

        let maxW = view.frame.width - 80
        let size = toast.sizeThatFits(CGSize(width: maxW, height: .greatestFiniteMagnitude))
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            toast.widthAnchor.constraint(lessThanOrEqualToConstant: maxW),
            toast.heightAnchor.constraint(equalToConstant: max(size.height + 20, 40))
        ])
        toast.alpha = 0
        UIView.animate(withDuration: 0.25) { toast.alpha = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            UIView.animate(withDuration: 0.25, animations: { toast.alpha = 0 }) { _ in
                toast.removeFromSuperview()
            }
        }
    }

    @objc private func submit() {
        view.endEditing(true)
        let uid  = (uidField.text ?? "").trimmingCharacters(in: .whitespaces)
        var name = (nameField.text ?? "").trimmingCharacters(in: .whitespaces)
        if name.isEmpty {
            // 昵称留空时自动生成友好昵称，绝不把账号直接当昵称显示
            let tail = uid.count >= 4 ? String(uid.suffix(4)) : uid
            name = "用户" + tail
        }
        let pwd  = pwdField.text ?? ""
        let pwd2 = pwd2Field.text ?? ""

        guard !uid.isEmpty else { showToast("请填写账号"); return }
        guard !pwd.isEmpty else  { showToast("请填写密码"); return }
        guard pwd.count >= 6 else { showToast("密码至少 6 位"); return }
        guard pwd == pwd2 else { showToast("两次密码不一致"); return }

        submitBtn.isEnabled = false
        loading.startAnimating()

        Task { [weak self] in
            do {
                let user = try await AuthService.shared.registerByUserID(
                    userID: uid, password: pwd, name: name)
                await MainActor.run {
                    self?.loading.stopAnimating()
                    self?.submitBtn.isEnabled = true
                    Log("注册成功 uid=\(user.uid) name=\(user.nickname)")
                    // 注册页已 push 进 loginNav 导航栈，由 onRegistered 触发
                    // finishLogin 统一 dismiss 整个 loginNav（含注册页），
                    // 避免多层 modal 各自 dismiss 导致登录流程未关闭。
                    self?.onRegistered?()
                }
            } catch {
                let msg = (error as? AuthError)?.errorDescription
                    ?? error.localizedDescription
                await MainActor.run {
                    self?.loading.stopAnimating()
                    self?.submitBtn.isEnabled = true
                    self?.showToast(msg)
                }
            }
        }
    }
}
