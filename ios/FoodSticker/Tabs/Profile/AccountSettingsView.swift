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
    @Environment(\.dismiss) private var dismiss

    /// 点击"登录以同步账号"时触发（由 ProfileViewController 注入）
    var onLogin: (() -> Void)? = nil
    /// 点击"昵称"进入编辑页（由 ProfileViewController 注入，push NicknameEditView）
    var onEditNickname: (() -> Void)? = nil

    @State private var showPicker: ImagePickerSource? = nil
    @State private var showLogout = false
    @State private var nickname: String

    private var isGuest: Bool { AuthService.shared.currentUser == nil }
    private var displayName: String {
        let n = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? "小鹿" : n
    }

    init(onLogin: (() -> Void)? = nil, onEditNickname: (() -> Void)? = nil) {
        self.onLogin = onLogin
        self.onEditNickname = onEditNickname
        _nickname = State(initialValue: AuthService.shared.currentUser?.nickname ?? AvatarStore.shared.nickname)
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
                        infoRow(title: "手机号", value: AuthService.shared.currentUser?.phone ?? "—")
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
                }

                Text("FoodSticker v1.0 · Mock 演示版")
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
        .alert("退出登录", isPresented: $showLogout) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive) {
                AuthService.shared.logout()
                Task { await AppDataStore.shared.bootstrap() }
                NotificationCenter.default.post(name: .authDidChange, object: nil)
                dismiss()
            }
        } message: {
            Text("确定要退出当前账号吗？")
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
        case .oneKey:   return "本机一键登录"
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

// MARK: - 昵称编辑页

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
        onSave(trimmed.isEmpty ? "小鹿" : String(trimmed.prefix(20)))
        dismiss()
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
