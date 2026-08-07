import UIKit

// MARK: - 设计常量（Auth 模块共享）
let AppPrimary   = UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1)
let AppBg        = UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1)
let AppBackground = AppBg   // 兼容 RegisterViewController 旧引用
let AppText      = UIColor(red: 26/255,  green: 26/255,  blue: 26/255,  alpha: 1)
let AppGray      = UIColor(red: 238/255, green: 238/255, blue: 238/255, alpha: 1)
let AppTextLight = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1)

// MARK: - 登录入口（欢迎页 → 手机号 → 验证码 三页式流程）
//
// 设计参考：
//   页0：App Logo + 协议勾选 + "手机账号登录" 主按钮
//   页1：返回箭头 + "输入手机号" + +86/手机号输入框 + "发送验证码" 主按钮
//   页2：返回箭头 + "输入验证码" + 6位方框 + 倒计时重发 + "下一步" 主按钮
//
final class AuthGateViewController: UIViewController {

    var onLogin: (() -> Void)?

    // MARK: - State
    private var currentPhone: String = ""
    private var currentCode:  String = ""
    private var countdown = 0
    private var timer: Timer?
    private var isAgreed = false
    private var isVerifying = false

    // MARK: - 页0：欢迎
    private let welcomePage = UIView()
    private let logoLbl     = UILabel()
    private let agreeBtn    = UIButton(type: .custom)
    private let agreeLbl    = UILabel()
    private let loginBtn    = UIButton(type: .system)
    private let accountLoginBtn = UIButton(type: .system)
    private let registerBtn = UIButton(type: .system)

    // MARK: - 页1：手机号
    private let phonePage   = UIView()
    private let backBtn     = UIButton(type: .system)
    private let phoneTitle  = UILabel()
    private let countryBox  = UIView()
    private let countryLbl  = UILabel()
    private let phoneBox    = UIView()
    private let phoneField  = UITextField()
    private let sendBtn     = UIButton(type: .system)

    // MARK: - 页2：验证码
    private let codePage    = UIView()
    private let codeBackBtn = UIButton(type: .system)
    private let codeTitle   = UILabel()
    private let codeStack   = UIStackView()
    private var codeBoxes: [UILabel] = []
    private let hiddenField = UITextField()
    private let resendBtn   = UIButton(type: .system)
    private let nextBtn     = UIButton(type: .system)

    // MARK: - 页3：账号密码登录（短信平台未就绪时的兜底登录方式）
    private let pwdPage      = UIView()
    private let pwdBackBtn   = UIButton(type: .system)
    private let pwdTitle     = UILabel()
    private let pwdPhoneBox  = UIView()
    private let pwdPhoneField = UITextField()
    private let pwdBox       = UIView()
    private let pwdField     = UITextField()
    private let pwdLoginBtn  = UIButton(type: .system)
    private var pwdLoginBottomConstraint: NSLayoutConstraint?

    // 页1 上的「使用密码登录」入口（独立于上方主按钮，避免复用同一实例导致约束/点击异常）
    private let pwdEntryBtn  = UIButton(type: .system)

    // MARK: - 键盘适配
    private var sendBtnBottomConstraint: NSLayoutConstraint?
    private var nextBtnBottomConstraint: NSLayoutConstraint?
    private var keyboardHeight: CGFloat = 0

    // MARK: - 通用
    private let toastLbl = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppBg
        // 强制浅色：Auth 模块整套视觉（背景、占位、键盘）
        // 都按浅色设计的，避免 Dark Mode 下出现黑框/灰字等异常。
        view.overrideUserInterfaceStyle = .light
        setupWelcomePage()
        setupPhonePage()
        setupCodePage()
        setupPwdPage()
        setupToast()
        observeKeyboard()
        observeMockCode()
        navigationController?.setNavigationBarHidden(true, animated: false)
        showWelcomePage()
    }

    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 页0 布局（欢迎页）
    private func setupWelcomePage() {
        welcomePage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(welcomePage)
        NSLayoutConstraint.activate([
            welcomePage.topAnchor.constraint(equalTo: view.topAnchor),
            welcomePage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            welcomePage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            welcomePage.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Logo / App 名称
        logoLbl.text = "FitFood PK"
        logoLbl.font = .systemFont(ofSize: 42, weight: .black)
        logoLbl.textColor = AppText
        logoLbl.textAlignment = .center

        // 勾选按钮
        agreeBtn.setImage(UIImage(systemName: "circle"), for: .normal)
        agreeBtn.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        agreeBtn.tintColor = AppTextLight
        agreeBtn.addTarget(self, action: #selector(didTapAgree), for: .touchUpInside)

        // 协议文字（富文本，带可点击链接）
        let fullText = "我已阅读并同意 用户协议 和 隐私政策"
        let attributed = NSMutableAttributedString(string: fullText)
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: AppTextLight
        ]
        let linkAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.systemBlue
        ]
        attributed.addAttributes(normalAttrs, range: NSRange(location: 0, length: fullText.utf16.count))
        if let range1 = fullText.range(of: "用户协议") {
            let nsRange1 = NSRange(range1, in: fullText)
            attributed.addAttributes(linkAttrs, range: nsRange1)
        }
        if let range2 = fullText.range(of: "隐私政策") {
            let nsRange2 = NSRange(range2, in: fullText)
            attributed.addAttributes(linkAttrs, range: nsRange2)
        }
        agreeLbl.attributedText = attributed
        agreeLbl.isUserInteractionEnabled = true
        let tapAgree = UITapGestureRecognizer(target: self, action: #selector(didTapAgreeLabel(_:)))
        agreeLbl.addGestureRecognizer(tapAgree)

        // 登录按钮（主）：手机账号登录（短信验证码）
        loginBtn.setTitle("手机账号登录", for: .normal)
        loginBtn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        loginBtn.setTitleColor(.white, for: .normal)
        loginBtn.backgroundColor = AppText
        loginBtn.layer.cornerRadius = 28
        loginBtn.addTarget(self, action: #selector(didTapLoginEntry), for: .touchUpInside)

        // 账号登录（次）：短信平台未就绪时的兜底登录方式
        accountLoginBtn.setTitle("账号登录", for: .normal)
        accountLoginBtn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        accountLoginBtn.setTitleColor(AppText, for: .normal)
        accountLoginBtn.backgroundColor = .clear
        accountLoginBtn.layer.cornerRadius = 28
        accountLoginBtn.layer.borderWidth = 1.5
        accountLoginBtn.layer.borderColor = AppText.cgColor
        accountLoginBtn.addTarget(self, action: #selector(didTapPwdLogin), for: .touchUpInside)

        // 马上注册（底部）
        registerBtn.setTitle("马上注册", for: .normal)
        registerBtn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        registerBtn.setTitleColor(AppText, for: .normal)
        registerBtn.backgroundColor = .clear
        registerBtn.layer.cornerRadius = 28
        registerBtn.layer.borderWidth = 1.5
        registerBtn.layer.borderColor = AppText.cgColor
        registerBtn.addTarget(self, action: #selector(didTapRegisterEntry), for: .touchUpInside)

        [logoLbl, agreeBtn, agreeLbl, loginBtn, accountLoginBtn, registerBtn].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            welcomePage.addSubview($0)
        }

        NSLayoutConstraint.activate([
            logoLbl.centerXAnchor.constraint(equalTo: welcomePage.centerXAnchor),
            logoLbl.centerYAnchor.constraint(equalTo: welcomePage.centerYAnchor, constant: -60),

            agreeBtn.leadingAnchor.constraint(equalTo: welcomePage.leadingAnchor, constant: 24),
            agreeBtn.bottomAnchor.constraint(equalTo: loginBtn.topAnchor, constant: -16),
            agreeBtn.widthAnchor.constraint(equalToConstant: 22),
            agreeBtn.heightAnchor.constraint(equalToConstant: 22),

            agreeLbl.leadingAnchor.constraint(equalTo: agreeBtn.trailingAnchor, constant: 8),
            agreeLbl.centerYAnchor.constraint(equalTo: agreeBtn.centerYAnchor),
            agreeLbl.trailingAnchor.constraint(lessThanOrEqualTo: welcomePage.trailingAnchor, constant: -24),

            loginBtn.bottomAnchor.constraint(equalTo: accountLoginBtn.topAnchor, constant: -12),
            loginBtn.leadingAnchor.constraint(equalTo: welcomePage.leadingAnchor, constant: 24),
            loginBtn.trailingAnchor.constraint(equalTo: welcomePage.trailingAnchor, constant: -24),
            loginBtn.heightAnchor.constraint(equalToConstant: 56),

            accountLoginBtn.bottomAnchor.constraint(equalTo: registerBtn.topAnchor, constant: -12),
            accountLoginBtn.leadingAnchor.constraint(equalTo: welcomePage.leadingAnchor, constant: 24),
            accountLoginBtn.trailingAnchor.constraint(equalTo: welcomePage.trailingAnchor, constant: -24),
            accountLoginBtn.heightAnchor.constraint(equalToConstant: 56),

            registerBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -48),
            registerBtn.leadingAnchor.constraint(equalTo: welcomePage.leadingAnchor, constant: 24),
            registerBtn.trailingAnchor.constraint(equalTo: welcomePage.trailingAnchor, constant: -24),
            registerBtn.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: - 页1 布局
    private func setupPhonePage() {
        phonePage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(phonePage)
        NSLayoutConstraint.activate([
            phonePage.topAnchor.constraint(equalTo: view.topAnchor),
            phonePage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            phonePage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            phonePage.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // 返回
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        backBtn.setImage(UIImage(systemName: "chevron.left", withConfiguration: cfg), for: .normal)
        backBtn.tintColor = AppText
        backBtn.addTarget(self, action: #selector(didTapPhoneBack), for: .touchUpInside)

        // 标题
        phoneTitle.text = "输入手机号"
        phoneTitle.font = .systemFont(ofSize: 28, weight: .bold)
        phoneTitle.textColor = AppText

        // +86 区号框
        countryBox.backgroundColor = AppGray
        countryBox.layer.cornerRadius = 14
        countryLbl.text = "+86"
        countryLbl.font = .systemFont(ofSize: 18, weight: .medium)
        countryLbl.textColor = AppText

        // 手机号输入框
        phoneBox.backgroundColor = AppGray
        phoneBox.layer.cornerRadius = 14
        phoneField.font = .systemFont(ofSize: 20)
        phoneField.textColor = AppText
        phoneField.keyboardType = .phonePad
        phoneField.delegate = self
        phoneField.addTarget(self, action: #selector(phoneChanged), for: .editingChanged)
        phoneField.placeholder = "请输入手机号"
        phoneField.tintColor = AppPrimary

        // 发送验证码按钮
        sendBtn.setTitle("发送验证码", for: .normal)
        sendBtn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        sendBtn.setTitleColor(.white, for: .normal)
        sendBtn.backgroundColor = AppText          // 接近黑色，与图片一致
        sendBtn.layer.cornerRadius = 28
        sendBtn.isEnabled = false
        sendBtn.alpha = 0.35
        sendBtn.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)

        // 使用密码登录（短信平台未就绪时的兜底登录方式）
        pwdEntryBtn.setTitle("使用密码登录", for: .normal)
        pwdEntryBtn.titleLabel?.font = .systemFont(ofSize: 15)
        pwdEntryBtn.setTitleColor(AppTextLight, for: .normal)
        pwdEntryBtn.addTarget(self, action: #selector(didTapPwdLogin), for: .touchUpInside)

        // Add subviews
        [backBtn, phoneTitle, countryBox, phoneBox, sendBtn, pwdEntryBtn].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            phonePage.addSubview($0)
        }
        countryBox.addSubview(countryLbl)
        phoneBox.addSubview(phoneField)
        countryLbl.translatesAutoresizingMaskIntoConstraints = false
        phoneField.translatesAutoresizingMaskIntoConstraints = false

        let sendBottom = sendBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -48)
        sendBtnBottomConstraint = sendBottom

        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            backBtn.widthAnchor.constraint(equalToConstant: 44),
            backBtn.heightAnchor.constraint(equalToConstant: 44),

            phoneTitle.topAnchor.constraint(equalTo: backBtn.bottomAnchor, constant: 24),
            phoneTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            countryBox.topAnchor.constraint(equalTo: phoneTitle.bottomAnchor, constant: 36),
            countryBox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            countryBox.widthAnchor.constraint(equalToConstant: 82),
            countryBox.heightAnchor.constraint(equalToConstant: 58),

            countryLbl.centerXAnchor.constraint(equalTo: countryBox.centerXAnchor),
            countryLbl.centerYAnchor.constraint(equalTo: countryBox.centerYAnchor),

            phoneBox.topAnchor.constraint(equalTo: countryBox.topAnchor),
            phoneBox.leadingAnchor.constraint(equalTo: countryBox.trailingAnchor, constant: 12),
            phoneBox.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            phoneBox.heightAnchor.constraint(equalToConstant: 58),

            phoneField.leadingAnchor.constraint(equalTo: phoneBox.leadingAnchor, constant: 16),
            phoneField.trailingAnchor.constraint(equalTo: phoneBox.trailingAnchor, constant: -16),
            phoneField.centerYAnchor.constraint(equalTo: phoneBox.centerYAnchor),

            sendBottom,
            sendBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            sendBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            sendBtn.heightAnchor.constraint(equalToConstant: 56),

            pwdEntryBtn.topAnchor.constraint(equalTo: sendBtn.bottomAnchor, constant: 16),
            pwdEntryBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pwdEntryBtn.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    // MARK: - 页3 布局（账号密码登录）
    private func setupPwdPage() {
        pwdPage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pwdPage)
        NSLayoutConstraint.activate([
            pwdPage.topAnchor.constraint(equalTo: view.topAnchor),
            pwdPage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pwdPage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pwdPage.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        pwdPage.isHidden = true
        pwdPage.backgroundColor = AppBg

        // 返回
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        pwdBackBtn.setImage(UIImage(systemName: "chevron.left", withConfiguration: cfg), for: .normal)
        pwdBackBtn.tintColor = AppText
        pwdBackBtn.addTarget(self, action: #selector(didTapPwdBack), for: .touchUpInside)

        pwdTitle.text = "账号密码登录"
        pwdTitle.font = .systemFont(ofSize: 28, weight: .bold)
        pwdTitle.textColor = AppText

        // 手机号框
        pwdPhoneBox.backgroundColor = AppGray
        pwdPhoneBox.layer.cornerRadius = 14
        pwdPhoneField.font = .systemFont(ofSize: 20)
        pwdPhoneField.textColor = AppText
        pwdPhoneField.keyboardType = .default
        pwdPhoneField.delegate = self
        pwdPhoneField.addTarget(self, action: #selector(pwdPhoneChanged), for: .editingChanged)
        pwdPhoneField.placeholder = "请输入账号或手机号"
        pwdPhoneField.tintColor = AppPrimary

        // 密码框
        pwdBox.backgroundColor = AppGray
        pwdBox.layer.cornerRadius = 14
        pwdField.font = .systemFont(ofSize: 20)
        pwdField.textColor = AppText
        pwdField.isSecureTextEntry = true
        pwdField.placeholder = "请输入密码"
        pwdField.tintColor = AppPrimary
        pwdField.returnKeyType = .go
        pwdField.delegate = self
        pwdField.addTarget(self, action: #selector(pwdFieldChanged), for: .editingChanged)

        // 登录按钮
        pwdLoginBtn.setTitle("登 录", for: .normal)
        pwdLoginBtn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        pwdLoginBtn.setTitleColor(.white, for: .normal)
        pwdLoginBtn.backgroundColor = AppText
        pwdLoginBtn.layer.cornerRadius = 28
        pwdLoginBtn.isEnabled = false
        pwdLoginBtn.alpha = 0.35
        pwdLoginBtn.addTarget(self, action: #selector(didTapPwdLoginSubmit), for: .touchUpInside)

        [pwdBackBtn, pwdTitle, pwdPhoneBox, pwdBox, pwdLoginBtn].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            pwdPage.addSubview($0)
        }
        pwdPhoneBox.addSubview(pwdPhoneField)
        pwdBox.addSubview(pwdField)
        pwdPhoneField.translatesAutoresizingMaskIntoConstraints = false
        pwdField.translatesAutoresizingMaskIntoConstraints = false

        let bottom = pwdLoginBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -48)
        pwdLoginBottomConstraint = bottom

        NSLayoutConstraint.activate([
            pwdBackBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            pwdBackBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            pwdBackBtn.widthAnchor.constraint(equalToConstant: 44),
            pwdBackBtn.heightAnchor.constraint(equalToConstant: 44),

            pwdTitle.topAnchor.constraint(equalTo: pwdBackBtn.bottomAnchor, constant: 24),
            pwdTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            pwdPhoneBox.topAnchor.constraint(equalTo: pwdTitle.bottomAnchor, constant: 36),
            pwdPhoneBox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            pwdPhoneBox.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            pwdPhoneBox.heightAnchor.constraint(equalToConstant: 58),

            pwdPhoneField.leadingAnchor.constraint(equalTo: pwdPhoneBox.leadingAnchor, constant: 16),
            pwdPhoneField.trailingAnchor.constraint(equalTo: pwdPhoneBox.trailingAnchor, constant: -16),
            pwdPhoneField.centerYAnchor.constraint(equalTo: pwdPhoneBox.centerYAnchor),

            pwdBox.topAnchor.constraint(equalTo: pwdPhoneBox.bottomAnchor, constant: 12),
            pwdBox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            pwdBox.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            pwdBox.heightAnchor.constraint(equalToConstant: 58),

            pwdField.leadingAnchor.constraint(equalTo: pwdBox.leadingAnchor, constant: 16),
            pwdField.trailingAnchor.constraint(equalTo: pwdBox.trailingAnchor, constant: -16),
            pwdField.centerYAnchor.constraint(equalTo: pwdBox.centerYAnchor),

            bottom,
            pwdLoginBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            pwdLoginBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            pwdLoginBtn.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: - 页2 布局
    private func setupCodePage() {
        codePage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(codePage)
        NSLayoutConstraint.activate([
            codePage.topAnchor.constraint(equalTo: view.topAnchor),
            codePage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            codePage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            codePage.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        codePage.isHidden = true

        // 返回
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        codeBackBtn.setImage(UIImage(systemName: "chevron.left", withConfiguration: cfg), for: .normal)
        codeBackBtn.tintColor = AppText
        codeBackBtn.addTarget(self, action: #selector(didTapCodeBack), for: .touchUpInside)

        // 标题
        codeTitle.text = "输入验证码"
        codeTitle.font = .systemFont(ofSize: 28, weight: .bold)
        codeTitle.textColor = AppText

        // 6 位验证码框
        codeStack.axis = .horizontal
        codeStack.distribution = .fillEqually
        codeStack.spacing = 10
        for i in 0..<6 {
            let box = UILabel()
            box.backgroundColor = AppGray
            box.layer.cornerRadius = 14
            box.clipsToBounds = true
            box.textAlignment = .center
            box.font = .systemFont(ofSize: 26, weight: .medium)
            box.textColor = AppText
            box.isUserInteractionEnabled = true
            box.tag = i
            let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCodeBox(_:)))
            box.addGestureRecognizer(tap)
            codeBoxes.append(box)
            codeStack.addArrangedSubview(box)
        }
        codeStack.translatesAutoresizingMaskIntoConstraints = false

        // 隐藏的输入框（接收系统键盘 + 短信自动填充）
        hiddenField.keyboardType = .numberPad
        hiddenField.textContentType = .oneTimeCode
        hiddenField.delegate = self
        hiddenField.addTarget(self, action: #selector(codeChanged), for: .editingChanged)
        hiddenField.isHidden = true

        // 重新发送
        resendBtn.titleLabel?.font = .systemFont(ofSize: 14)
        resendBtn.setTitleColor(AppTextLight, for: .normal)
        resendBtn.contentHorizontalAlignment = .left
        resendBtn.addTarget(self, action: #selector(didTapResend), for: .touchUpInside)

        // 下一步按钮
        nextBtn.setTitle("下一步  →", for: .normal)
        nextBtn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        nextBtn.setTitleColor(.white, for: .normal)
        nextBtn.backgroundColor = AppText
        nextBtn.layer.cornerRadius = 28
        nextBtn.isEnabled = false
        nextBtn.alpha = 0.35
        nextBtn.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)

        // Add
        [codeBackBtn, codeTitle, codeStack, resendBtn, nextBtn, hiddenField].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            codePage.addSubview($0)
        }

        let nextBottom = nextBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -48)
        nextBtnBottomConstraint = nextBottom

        NSLayoutConstraint.activate([
            codeBackBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            codeBackBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            codeBackBtn.widthAnchor.constraint(equalToConstant: 44),
            codeBackBtn.heightAnchor.constraint(equalToConstant: 44),

            codeTitle.topAnchor.constraint(equalTo: codeBackBtn.bottomAnchor, constant: 24),
            codeTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            codeStack.topAnchor.constraint(equalTo: codeTitle.bottomAnchor, constant: 36),
            codeStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            codeStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            codeStack.heightAnchor.constraint(equalToConstant: 58),

            resendBtn.topAnchor.constraint(equalTo: codeStack.bottomAnchor, constant: 20),
            resendBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            nextBottom,
            nextBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            nextBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            nextBtn.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    // MARK: - Toast
    private func setupToast() {
        toastLbl.textAlignment = .center
        toastLbl.textColor = .systemRed
        toastLbl.font = .systemFont(ofSize: 14, weight: .medium)
        toastLbl.numberOfLines = 0
        toastLbl.isHidden = true
        toastLbl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toastLbl)
        NSLayoutConstraint.activate([
            toastLbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLbl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            toastLbl.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            toastLbl.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])
    }

    // MARK: - 页面切换
    private func showWelcomePage() {
        welcomePage.isHidden = false
        phonePage.isHidden = true
        codePage.isHidden = true
        pwdPage.isHidden = true
    }

    private func showPhonePage() {
        welcomePage.isHidden = true
        phonePage.isHidden = false
        codePage.isHidden = true
        pwdPage.isHidden = true
        phoneField.becomeFirstResponder()
    }

    private func showCodePage() {
        welcomePage.isHidden = true
        phonePage.isHidden = true
        codePage.isHidden = false
        pwdPage.isHidden = true
        isVerifying = false
        hiddenField.becomeFirstResponder()
        updateCodeBoxes()
        updateResendTitle()
    }

    // MARK: - 键盘适配
    private func observeKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo,
              let endFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }
        keyboardHeight = endFrame.height
        let bottomOffset = -(keyboardHeight + 16) // 键盘顶部上方 16pt

        UIView.animate(withDuration: duration) {
            self.sendBtnBottomConstraint?.constant = bottomOffset
            self.nextBtnBottomConstraint?.constant = bottomOffset
            self.pwdLoginBottomConstraint?.constant = bottomOffset
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let info = notification.userInfo,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }
        keyboardHeight = 0

        UIView.animate(withDuration: duration) {
            self.sendBtnBottomConstraint?.constant = -48
            self.nextBtnBottomConstraint?.constant = -48
            self.pwdLoginBottomConstraint?.constant = -48
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Mock 验证码提示
    private func observeMockCode() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onMockCodeSent(_:)),
            name: .mockSMSSent,
            object: nil
        )
    }

    @objc private func onMockCodeSent(_ notification: Notification) {
        if let code = notification.userInfo?["code"] as? String {
            DispatchQueue.main.async {
                self.showToast("验证码（Mock）：\(code)")
            }
        }
    }

    // MARK: - 页1 交互
    @objc private func phoneChanged() {
        let raw = phoneField.text ?? ""
        let digits = raw.filter { $0.isNumber }
        if digits.count > 11 {
            phoneField.text = String(digits.prefix(11))
        } else {
            phoneField.text = digits
        }
        let valid = digits.count == 11
        sendBtn.isEnabled = valid
        sendBtn.alpha = valid ? 1.0 : 0.35
    }

    @objc private func didTapSend() {
        let phone = phoneField.text ?? ""
        guard phone.count == 11 else { return }
        currentPhone = phone
        currentCode = ""
        hiddenField.text = ""
        phoneField.resignFirstResponder()

        Task {
            do {
                _ = try await AuthService.shared.provider.sendSMSCode(phone: phone)
                await MainActor.run {
                    self.showCodePage()
                    self.startCountdown()
                }
            } catch {
                await MainActor.run {
                    self.showToast((error as? AuthError)?.errorDescription ?? "发送失败")
                }
            }
        }
    }

    @objc private func didTapPhoneBack() {
        phoneField.resignFirstResponder()
        showWelcomePage()
    }

    // MARK: - 页0 交互
    @objc private func didTapAgree() {
        isAgreed.toggle()
        agreeBtn.isSelected = isAgreed
        agreeBtn.tintColor = isAgreed ? AppPrimary : AppTextLight
    }

    @objc private func didTapAgreeLabel(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: agreeLbl)
        let textStorage = NSTextStorage(attributedString: agreeLbl.attributedText ?? NSAttributedString())
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: agreeLbl.bounds.size)
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        layoutManager.ensureLayout(for: textContainer)

        let index = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        let fullText = agreeLbl.text ?? ""
        if let range1 = fullText.range(of: "用户协议"), NSRange(range1, in: fullText).contains(index) {
            showToast("用户协议页面（待接入）")
            return
        }
        if let range2 = fullText.range(of: "隐私政策"), NSRange(range2, in: fullText).contains(index) {
            showToast("隐私政策页面（待接入）")
            return
        }
        didTapAgree()
    }

    @objc private func didTapLoginEntry() {
        guard isAgreed else {
            showToast("请先阅读并同意用户协议和隐私政策")
            return
        }
        showPhonePage()
    }

    @objc private func didTapPwdLogin() {
        showPwdPage()
    }

    private func showPwdPage() {
        welcomePage.isHidden = true
        phonePage.isHidden = true
        codePage.isHidden = true
        pwdPage.isHidden = false
        pwdPhoneField.becomeFirstResponder()
    }

    @objc private func didTapPwdBack() {
        pwdPhoneField.resignFirstResponder()
        pwdField.resignFirstResponder()
        showWelcomePage()
    }

    @objc private func pwdPhoneChanged() {
        updatePwdLoginEnabled()
    }

    @objc private func pwdFieldChanged() {
        updatePwdLoginEnabled()
    }

    private func updatePwdLoginEnabled() {
        let valid = !(pwdPhoneField.text ?? "").isEmpty && !(pwdField.text ?? "").isEmpty
        pwdLoginBtn.isEnabled = valid
        pwdLoginBtn.alpha = valid ? 1.0 : 0.35
    }

    @objc private func didTapPwdLoginSubmit() {
        let phone = pwdPhoneField.text ?? ""
        let pwd = pwdField.text ?? ""
        guard !phone.isEmpty, !pwd.isEmpty else { return }
        pwdLoginBtn.isEnabled = false
        pwdField.resignFirstResponder()

        Task {
            do {
                let user = try await AuthService.shared.loginByPassword(phone: phone, password: pwd)
                await MainActor.run {
                    self.pwdLoginBtn.isEnabled = true
                    self.finishLogin(user)
                }
                Log("密码登录成功 uid=\(user.uid) name=\(user.nickname)")
            } catch {
                let msg = (error as? AuthError)?.errorDescription ?? error.localizedDescription
                await MainActor.run {
                    self.pwdLoginBtn.isEnabled = true
                    self.showToast(msg)
                }
            }
        }
    }

    @objc private func didTapRegisterEntry() {
        guard isAgreed else {
            showToast("请先阅读并同意用户协议和隐私政策")
            return
        }
        let vc = RegisterByPasswordViewController()
        vc.onRegistered = { [weak self] in
            // 注册页已 push 进 loginNav，直接让登录流程整体退出即可，
            // 由 finishLogin 统一 dismiss 整个 loginNav（含注册页）。
            self?.finishLogin()
        }
        vc.onCancel = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - 页2 交互
    @objc private func didTapCodeBack() {
        hiddenField.resignFirstResponder()
        timer?.invalidate()
        countdown = 0
        showPhonePage()
    }

    @objc private func didTapCodeBox(_ gesture: UITapGestureRecognizer) {
        hiddenField.becomeFirstResponder()
    }

    @objc private func codeChanged() {
        let raw = hiddenField.text ?? ""
        let digits = raw.filter { $0.isNumber }

        if digits.count > 6 {
            currentCode = String(digits.prefix(6))
        } else {
            currentCode = digits
        }
        hiddenField.text = currentCode

        updateCodeBoxes()

        let complete = currentCode.count == 6
        nextBtn.isEnabled = complete
        nextBtn.alpha = complete ? 1.0 : 0.35

        if complete && !isVerifying {
            verifyCode()
        }
    }

    private func updateCodeBoxes() {
        for (i, box) in codeBoxes.enumerated() {
            if i < currentCode.count {
                let idx = currentCode.index(currentCode.startIndex, offsetBy: i)
                box.text = String(currentCode[idx])
                box.layer.borderWidth = 0
            } else {
                box.text = ""
                if i == currentCode.count {
                    // 当前聚焦位：主色边框
                    box.layer.borderWidth = 2
                    box.layer.borderColor = AppPrimary.cgColor
                } else {
                    box.layer.borderWidth = 0
                }
            }
        }
    }

    @objc private func didTapResend() {
        guard countdown <= 0 else { return }
        Task {
            do {
                _ = try await AuthService.shared.provider.sendSMSCode(phone: currentPhone)
                await MainActor.run { self.startCountdown() }
            } catch {
                await MainActor.run {
                    self.showToast((error as? AuthError)?.errorDescription ?? "发送失败")
                }
            }
        }
    }

    @objc private func didTapNext() {
        verifyCode()
    }

    private func verifyCode() {
        guard currentCode.count == 6, !isVerifying else { return }
        isVerifying = true
        nextBtn.isEnabled = false

        Task {
            do {
                let user = try await AuthService.shared.loginBySMS(phone: currentPhone, code: currentCode)
                await MainActor.run { self.finishLogin(user) }
            } catch {
                await MainActor.run {
                    self.isVerifying = false
                    self.nextBtn.isEnabled = true
                    self.nextBtn.alpha = 1.0
                    self.showToast((error as? AuthError)?.errorDescription ?? "验证失败")
                }
            }
        }
    }

    // MARK: - 倒计时
    private func startCountdown() {
        countdown = 60
        timer?.invalidate()
        updateResendTitle()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            self.countdown -= 1
            if self.countdown <= 0 { t.invalidate() }
            self.updateResendTitle()
        }
    }

    private func updateResendTitle() {
        if countdown > 0 {
            resendBtn.setTitle("重新发送 \(countdown)s", for: .normal)
            resendBtn.setTitleColor(AppTextLight, for: .normal)
            resendBtn.isEnabled = false
        } else {
            resendBtn.setTitle("重新发送", for: .normal)
            resendBtn.setTitleColor(AppPrimary, for: .normal)
            resendBtn.isEnabled = true
        }
    }

    // MARK: - 完成登录
    private func finishLogin(_ user: AuthUser? = nil) {
        // 先 dismiss 登录界面（释放主线程）
        AuthCoordinator.shared.dismissLogin { [weak self] in
            NotificationCenter.default.post(name: .authDidChange, object: nil)
            self?.onLogin?()
            // dismiss 完成后再启动数据同步（避免 bootstrap @MainActor 阻塞 dismiss 动画）
            Task { await AppDataStore.shared.bootstrap() }
        }
    }

    // MARK: - Toast
    private func showToast(_ text: String) {
        toastLbl.text = text
        toastLbl.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.toastLbl.isHidden = true
        }
    }
}

// MARK: - UITextFieldDelegate
extension AuthGateViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if textField == phoneField {
            // 手机号只允许数字
            return string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
        }
        if textField == hiddenField {
            // 验证码也只做数字过滤（6位限制在 codeChanged 中处理）
            return string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
        }
        return true
    }
}

extension Notification.Name {
    static let authDidChange = Notification.Name("authDidChange")
}
