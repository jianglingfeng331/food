import SwiftUI

// MARK: - 账户设置
//
// 头像：支持「拍摄 / 相册上传 / 系统裁剪」并即时保存，
//      存至 AvatarStore，自动同步到首页 / PK / 我的。
// 昵称：点击进入独立编辑页填写并保存。
// 图标全部使用项目规范 LucideIcons，禁用 emoji 与系统图标。

struct AccountSettingsView: View {
    @StateObject private var store = ProfileStore.shared
    @ObservedObject private var avatarStore = AvatarStore.shared
    @ObservedObject private var appStore = AppDataStore.shared
    @Environment(\.dismiss) private var dismiss

    /// 点击"登录以同步账号"时触发（由 ProfileViewController 注入）
    var onLogin: (() -> Void)? = nil
    /// 点击"昵称"进入编辑页（由 ProfileViewController 注入，push NicknameEditView）
    var onEditNickname: (() -> Void)? = nil

    var onUpdateCalorieTarget: ((Int) -> Void)? = nil

    @State private var showPicker: ImagePickerSource? = nil
    @State private var showLogout = false
    @State private var showDeleteAccount = false
    @State private var isDeletingAccount = false
    @State private var deleteError: String?
    @State private var showCalorieEditor = false
    @State private var showPasswordEditor = false

    private var isGuest: Bool { AuthService.shared.currentUser == nil }
    /// 昵称显示：直接从 avatarStore 读取，修改后自动刷新
    private var displayName: String {
        let n = avatarStore.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? "我" : n
    }
    /// 热量预算：直接从 appStore 读取，修改后自动刷新
    private var calorieTarget: Int { appStore.calorieTarget }
    /// 应用版本号：从主 Bundle 读取，显示用
    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(v)"
    }

    init(onLogin: (() -> Void)? = nil,
         onEditNickname: (() -> Void)? = nil,
         calorieTarget: Int = 0,
         onUpdateCalorieTarget: ((Int) -> Void)? = nil) {
        self.onLogin = onLogin
        self.onEditNickname = onEditNickname
        self.onUpdateCalorieTarget = onUpdateCalorieTarget
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 头像
                VStack(spacing: 14) {
                    AvatarView(avatarStore.avatarImage, size: 96)
                    Text("点击下方按钮更换头像")
                        .font(.app(size: 13))
                        .foregroundColor(CardTokens.Color.foregroundSubtle)

                    HStack(spacing: 12) {
                        actionButton(icon: { CameraIcon()
                            .stroke(CardTokens.Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .frame(width: 18, height: 18) },
                            title: "拍摄") { showPicker = .camera }

                        actionButton(icon: { ImagesIcon()
                            .stroke(CardTokens.Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .frame(width: 18, height: 18) },
                            title: "相册") { showPicker = .photoLibrary }
                    }
                }
                .padding(16)
                .profileCard()

                // 昵称（点击进入新页面）
                Button(action: { onEditNickname?() }) {
                    HStack {
                        Text("昵称")
                            .font(.app(size: 15))
                            .foregroundColor(CardTokens.Color.foreground)
                        Spacer()
                        Text(displayName)
                            .font(.app(size: 16, weight: .semibold))
                            .foregroundColor(CardTokens.Color.foreground)
                        ChevronRightIcon()
                            .stroke(CardTokens.Color.foregroundSubtle, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .frame(width: 18, height: 18)
                            .padding(.leading, 4)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .profileCard()
                }
                .buttonStyle(.plain)

                // 每日热量预算
                Button(action: { showCalorieEditor = true }) {
                    HStack {
                        Text("每日热量预算")
                            .font(.app(size: 15))
                            .foregroundColor(CardTokens.Color.foreground)
                        Spacer()
                        Text("\(calorieTarget) kcal")
                            .font(.app(size: 16, weight: .semibold))
                            .foregroundColor(CardTokens.Color.foreground)
                        ChevronRightIcon()
                            .stroke(CardTokens.Color.foregroundSubtle, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            .frame(width: 18, height: 18)
                            .padding(.leading, 4)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .profileCard()
                }
                .buttonStyle(.plain)

                // 登录密码（仅登录用户可见）
                if !isGuest {
                    Button(action: { showPasswordEditor = true }) {
                        HStack {
                            Text("登录密码")
                                .font(.app(size: 15))
                                .foregroundColor(CardTokens.Color.foreground)
                            Spacer()
                            Text("设置 / 修改")
                                .font(.app(size: 14))
                                .foregroundColor(CardTokens.Color.foregroundSubtle)
                            ChevronRightIcon()
                                .stroke(CardTokens.Color.foregroundSubtle, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                .frame(width: 18, height: 18)
                                .padding(.leading, 4)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .profileCard()
                    }
                    .buttonStyle(.plain)
                }

                // 账号信息 / 游客登录提示
                if isGuest {
                    Button(action: { onLogin?() }) {
                        HStack(spacing: 12) {
                            LogInIcon()
                                .stroke(CardTokens.Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                .frame(width: 22, height: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("登录以同步账号")
                                    .font(.app(size: 15, weight: .semibold))
                                    .foregroundColor(CardTokens.Color.foreground)
                                Text("登录后可同步昵称、头像与云端数据")
                                    .font(.app(size: 12))
                                    .foregroundColor(CardTokens.Color.foregroundSubtle)
                            }
                            Spacer()
                            ChevronRightIcon()
                                .stroke(CardTokens.Color.foregroundSubtle, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                .frame(width: 18, height: 18)
                        }
                        .padding(16)
                        .profileCard()
                    }
                    .buttonStyle(.plain)
                } else {
                    VStack(spacing: 0) {
                        infoRow(title: "登录方式", value: loginTypeText)
                        Rectangle()
                            .fill(CardTokens.Color.foreground.opacity(0.06))
                            .frame(height: 0.5)
                        infoRow(title: "账号", value: AuthService.shared.currentUser?.phone ?? "—")
                    }
                    .padding(.horizontal, 16)
                    .profileCard()

                    Button(action: { showLogout = true }) {
                        Text("退出登录")
                            .font(.app(size: 15, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.08)))
                    }
                    .buttonStyle(.plain)

                    // 删除账号（Apple 审核 5.1.1(v) 强制要求）
                    Button(action: { showDeleteAccount = true }) {
                        Text("删除账号")
                            .font(.app(size: 13))
                            .foregroundColor(CardTokens.Color.foregroundSubtle)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .disabled(isDeletingAccount)
                }

                Text("FitFood PK \(appVersion)")
                    .font(.app(size: 12))
                    .foregroundColor(CardTokens.Color.foregroundSubtle)
            }
            .padding(20)
        }
        .background(CardTokens.Color.background.ignoresSafeArea())
        .navigationTitle("账户设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") { dismiss() }
                    .font(.app(size: 15, weight: .semibold))
                    .foregroundColor(CardTokens.Color.primary)
            }
        }
        .sheet(item: $showPicker) { source in
            ImagePicker(source: source.type) { image in
                avatarStore.saveAvatar(image)
            }
        }
        .sheet(isPresented: $showCalorieEditor) {
            CalorieTargetEditView(current: calorieTarget) { newTarget in
                onUpdateCalorieTarget?(newTarget)
            }
        }
        .sheet(isPresented: $showPasswordEditor) {
            PasswordEditView()
        }
        .alert("退出登录", isPresented: $showLogout) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive) {
                avatarStore.reset()
                Task { await AppDataStore.shared.bootstrap() }
                AuthService.shared.logout()
                dismiss()
            }
        } message: {
            Text("确定要退出当前账号吗？")
        }
        .alert("删除账号", isPresented: $showDeleteAccount) {
            Button("取消", role: .cancel) {}
            Button("永久删除", role: .destructive) {
                isDeletingAccount = true
                Task {
                    do {
                        try await CloudAPI.shared.deleteAccount()
                        await MainActor.run {
                            isDeletingAccount = false
                            avatarStore.reset()
                            Task { await AppDataStore.shared.bootstrap() }
                            AuthService.shared.logout()
                            dismiss()
                        }
                    } catch {
                        await MainActor.run {
                            isDeletingAccount = false
                            deleteError = error.localizedDescription
                        }
                    }
                }
            }
        } message: {
            Text("删除后你的账号、打卡记录、贴纸等全部数据将永久清除且无法恢复。确定要删除吗？")
        }
        .alert("删除失败", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("好的") { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
    }

    // MARK: 视图碎片

    private func actionButton<Icon: View>(@ViewBuilder icon: () -> Icon,
                                           title: String,
                                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                icon()
                Text(title)
                    .font(.app(size: 14, weight: .semibold))
                    .foregroundColor(CardTokens.Color.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(CardTokens.Color.primaryBg10))
        }
        .buttonStyle(.plain)
    }

    private var loginTypeText: String {
        switch AuthService.shared.currentUser?.loginType {
        case .sms:      return "短信验证码"
        case .password: return "账号密码"
        case .register: return "注册账号"
        default:        return "游客"
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title).font(.app(size: 14)).foregroundColor(CardTokens.Color.foregroundMuted)
            Spacer()
            Text(value).font(.app(size: 14)).foregroundColor(CardTokens.Color.foreground)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - 每日热量预算编辑页

struct CalorieTargetEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String

    private let current: Int
    private let onSave: (Int) -> Void

    init(current: Int, onSave: @escaping (Int) -> Void) {
        self.current = current
        self.onSave = onSave
        _text = State(initialValue: current > 0 ? "\(current)" : "")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("每日热量预算（kcal）")
                        .font(.app(size: 13))
                        .foregroundColor(CardTokens.Color.foregroundSubtle)

                    TextField("例如 1500", text: $text)
                        .keyboardType(.numberPad)
                        .font(.app(size: 28, weight: .bold))
                        .foregroundColor(CardTokens.Color.foreground)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.04)))

                    Text("设定后，首页热量概览将以该值为预算基准")
                        .font(.app(size: 12))
                        .foregroundColor(CardTokens.Color.foregroundSubtle)
                }
                .padding(20)
            }
            .background(CardTokens.Color.background.ignoresSafeArea())
            .navigationTitle("每日热量预算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .font(.app(size: 15))
                        .foregroundColor(CardTokens.Color.foregroundMuted)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save(); dismiss() }
                        .font(.app(size: 15, weight: .semibold))
                        .foregroundColor(CardTokens.Color.primary)
                }
            }
            .tint(CardTokens.Color.primary)
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = Int(trimmed) ?? 0
        onSave(max(0, min(value, 9999)))
    }
}

// MARK: - 登录密码设置页

struct PasswordEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    private var canSubmit: Bool {
        password.count >= 6 && password == confirmPassword && !isLoading
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 密码
                    VStack(alignment: .leading, spacing: 8) {
                        Text("新密码")
                            .font(.app(size: 13))
                            .foregroundColor(CardTokens.Color.foregroundSubtle)
                        SecureField("请输入新密码（至少 6 位）", text: $password)
                            .font(.app(size: 16))
                            .foregroundColor(CardTokens.Color.foreground)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.04)))
                    }

                    // 确认密码
                    VStack(alignment: .leading, spacing: 8) {
                        Text("确认密码")
                            .font(.app(size: 13))
                            .foregroundColor(CardTokens.Color.foregroundSubtle)
                        SecureField("请再次输入新密码", text: $confirmPassword)
                            .font(.app(size: 16))
                            .foregroundColor(CardTokens.Color.foreground)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.04)))
                    }

                    // 错误提示
                    if let err = errorMessage {
                        Text(err)
                            .font(.app(size: 12))
                            .foregroundColor(CardTokens.Color.error)
                    }

                    // 提交按钮
                Button(action: submit) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.9)
                                .tint(canSubmit ? .white : CardTokens.Color.foregroundSubtle)
                        }
                        Text(isLoading ? "提交中…" : "提交")
                            .font(.app(size: 16, weight: .semibold))
                            .foregroundColor(canSubmit ? .white : CardTokens.Color.foregroundSubtle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canSubmit ? CardTokens.Color.primary : Color.black.opacity(0.06))
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)

                Text("密码用于账号密码登录，修改后即时生效。")
                    .font(.app(size: 12))
                    .foregroundColor(CardTokens.Color.foregroundSubtle)
                }
                .padding(20)
            }
            .background(CardTokens.Color.background.ignoresSafeArea())
            .navigationTitle("登录密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .font(.app(size: 15))
                        .foregroundColor(CardTokens.Color.foregroundMuted)
                }
            }
            .tint(CardTokens.Color.primary)
            .alert("修改成功", isPresented: $showSuccess) {
                Button("好的") { dismiss() }
            } message: {
                Text("登录密码已更新，下次请使用新密码登录。")
            }
        }
    }

    private func submit() {
        guard password.count >= 6 else {
            errorMessage = "密码至少 6 位"
            return
        }
        guard password == confirmPassword else {
            errorMessage = "两次输入的密码不一致"
            return
        }
        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await CloudAPI.shared.changePassword(newPassword: password)
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}



struct NicknameEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    private let onSave: (String) -> Void

    init(initial: String, onSave: @escaping (String) -> Void) {
        _text = State(initialValue: initial)
        self.onSave = onSave
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("昵称")
                    .font(.app(size: 13))
                    .foregroundColor(CardTokens.Color.foregroundSubtle)
                TextField("请输入昵称", text: $text)
                    .font(.app(size: 16))
                    .foregroundColor(CardTokens.Color.foreground)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.04)))
                Text("最多 20 个字符")
                    .font(.app(size: 12))
                    .foregroundColor(CardTokens.Color.foregroundSubtle)
            }
            .padding(20)
        }
        .background(CardTokens.Color.background.ignoresSafeArea())
        .navigationTitle("编辑昵称")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") { save() }
                    .font(.app(size: 15, weight: .semibold))
                    .foregroundColor(CardTokens.Color.primary)
            }
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(trimmed.isEmpty ? "我" : String(trimmed.prefix(20)))
        dismiss()
    }
}

// MARK: - 意见反馈

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @State private var contact = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    private var canSubmit: Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 1000 && !isLoading
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("请写下你的意见或建议，我们会认真对待每一条反馈。")
                    .font(.app(size: 13))
                    .foregroundColor(CardTokens.Color.foregroundSubtle)

                // 反馈内容
                VStack(alignment: .leading, spacing: 8) {
                    Text("反馈内容")
                        .font(.app(size: 13))
                        .foregroundColor(CardTokens.Color.foregroundSubtle)
                    TextEditor(text: $content)
                        .font(.app(size: 15))
                        .foregroundColor(CardTokens.Color.foreground)
                        .scrollContentBackground(.hidden)
                        .frame(height: 140)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.04)))
                        .overlay(alignment: .bottomTrailing) {
                            Text("\(content.count)/1000")
                                .font(.app(size: 11))
                                .foregroundColor(CardTokens.Color.foregroundSubtle)
                                .padding(8)
                        }
                }

                // 联系方式（可选）
                VStack(alignment: .leading, spacing: 8) {
                    Text("联系方式（选填）")
                        .font(.app(size: 13))
                        .foregroundColor(CardTokens.Color.foregroundSubtle)
                    TextField("便于我们回复你", text: $contact)
                        .font(.app(size: 15))
                        .foregroundColor(CardTokens.Color.foreground)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.04)))
                }

                // 错误提示
                if let err = errorMessage {
                    Text(err)
                        .font(.app(size: 12))
                        .foregroundColor(CardTokens.Color.error)
                }

                // 提交按钮
                Button(action: submit) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.9)
                                .tint(canSubmit ? .white : CardTokens.Color.foregroundSubtle)
                        }
                        Text(isLoading ? "提交中…" : "提交")
                            .font(.app(size: 16, weight: .semibold))
                            .foregroundColor(canSubmit ? .white : CardTokens.Color.foregroundSubtle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canSubmit ? CardTokens.Color.primary : Color.black.opacity(0.06))
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
            }
            .padding(20)
        }
        .background(CardTokens.Color.background.ignoresSafeArea())
        .navigationTitle("意见反馈")
        .navigationBarTitleDisplayMode(.inline)
        .alert("提交成功", isPresented: $showSuccess) {
            Button("好的") { dismiss() }
        } message: {
            Text("感谢你的反馈，我们会尽快处理。")
        }
    }

    private func submit() {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "反馈内容不能为空"
            return
        }
        guard trimmed.count <= 1000 else {
            errorMessage = "反馈内容不能超过 1000 字"
            return
        }
        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await CloudAPI.shared.sendFeedback(
                    content: trimmed,
                    contact: contact.isEmpty ? nil : contact
                )
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - 关于我们

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 应用图标（使用 AppIcon 资源）
                Image("AppIconDisplay")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(CardTokens.Color.foreground.opacity(0.06), lineWidth: 1)
                    )

                VStack(spacing: 4) {
                    Text("FitFood PK")
                        .font(.app(size: 20, weight: .bold))
                        .foregroundColor(CardTokens.Color.foreground)
                    Text("版本 1.0")
                        .font(.app(size: 13))
                        .foregroundColor(CardTokens.Color.foregroundSubtle)
                }

                // 简介
                VStack(spacing: 12) {
                    infoCard(title: "应用简介",
                             body: "FitFood PK 是一款专注饮食记录与健康管理的轻量级应用，通过拍照识别食物贴纸、PK 对赌机制，帮助你轻松坚持健康饮食。")

                    infoCard(title: "核心功能",
                             body: "· 拍照识别食物，自动生成贴纸\n· 每日热量 / 饮水 / 体重记录\n· 胃壁贴纸可视化展示\n· 好友 PK 对赌，互相督促\n· 减脂目标与体重趋势追踪")

                    infoCard(title: "联系我们",
                             body: "如有任何问题或建议，请通过「意见反馈」告诉我们。")
                }
            }
            .padding(20)
        }
        .background(CardTokens.Color.background.ignoresSafeArea())
        .navigationTitle("关于我们")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.app(size: 15, weight: .semibold))
                .foregroundColor(CardTokens.Color.foreground)
            Text(body)
                .font(.app(size: 13))
                .foregroundColor(CardTokens.Color.foregroundMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(CardTokens.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CardTokens.Color.foreground.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - 图片选择器（拍摄 / 相册，含系统方形裁剪）

enum ImagePickerSource: Identifiable {
    case camera, photoLibrary
    var id: Int { hashValue }
    var type: UIImagePickerController.SourceType {
        switch self {
        case .camera:       return .camera
        case .photoLibrary: return .photoLibrary
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    let source: UIImagePickerController.SourceType
    let onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            if let image = image { parent.onImage(image) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
