import SwiftUI
import Combine

// MARK: - 本人头像 / 昵称 数据中枢
//
// 统一管理「当前用户」的头像图片与昵称，写入 UserDefaults，
// 通过 @Published 驱动全站（首页 / PK / 我的）实时同步更新。
// 头像以 JPEG/PNG Data 形式存储；昵称为字符串。
// 未设置头像时，UI 使用 DefaultAvatarView（规范图标）兜底。

@MainActor
final class AvatarStore: ObservableObject {
    static let shared = AvatarStore()

    @Published private(set) var avatarImage: UIImage?
    @Published var nickname: String

    private let imageKey = "me.avatar.image.data"
    private let nickKey = "me.nickname"

    private init() {
        if let data = UserDefaults.standard.data(forKey: imageKey),
           let img = UIImage(data: data) {
            self.avatarImage = img
        }
        self.nickname = UserDefaults.standard.string(forKey: nickKey) ?? "游客"
    }

    // MARK: - 写

    /// 保存头像图片（自动压缩为 JPEG）。nil 表示清除自定义头像（回退默认）。
    /// 同步上传到后端，确保对方刷新后能看到最新头像。
    func saveAvatar(_ image: UIImage?) {
        guard let image = image else {
            avatarImage = nil
            UserDefaults.standard.removeObject(forKey: imageKey)
            // 清除后端头像
            Task { try? await CloudAPI.shared.updateProfile(avatarB64: "") }
            return
        }
        let resized = AvatarStore.resize(image, to: 512)
        let data = resized.jpegData(compressionQuality: 0.85)
        avatarImage = resized
        if let data = data {
            UserDefaults.standard.set(data, forKey: imageKey)
            // 上传 base64 头像到后端，供对方 sync 时拉取
            let b64 = data.base64EncodedString()
            Task { try? await CloudAPI.shared.updateProfile(avatarB64: b64) }
        }
    }

    /// 保存昵称（同步更新全站数据源：AvatarStore / AppDataStore / 后端）
    func saveNickname(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        nickname = trimmed.isEmpty ? "游客" : trimmed
        UserDefaults.standard.set(nickname, forKey: nickKey)
        // 同步到 AppDataStore，保证首页/Card/PK页实时联动
        AppDataStore.shared.profile.name = nickname
        // 上传到后端，确保对方刷新后能看到最新昵称
        Task { try? await CloudAPI.shared.updateProfile(name: nickname) }
    }

    // MARK: - 从云端恢复（登录后 sync 调用，不触发上传，避免循环）

    /// 从云端恢复头像图片。仅写内存 + UserDefaults，不上传后端。
    /// 与 saveAvatar 的区别：saveAvatar 会触发上传，restoreFromCloud 不会。
    func restoreFromCloud(_ image: UIImage?) {
        avatarImage = image
        if let image = image {
            let data = image.jpegData(compressionQuality: 0.85)
            if let data = data {
                UserDefaults.standard.set(data, forKey: imageKey)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: imageKey)
        }
    }

    // MARK: - 重置（退出登录时调用）

    /// 退出登录时重置头像与昵称到初始状态（不写 UserDefaults，仅清内存）
    func reset() {
        avatarImage = nil
        UserDefaults.standard.removeObject(forKey: imageKey)
        nickname = "游客"
        UserDefaults.standard.removeObject(forKey: nickKey)
    }

    // MARK: - 工具

    private static func resize(_ image: UIImage, to maxSide: CGFloat) -> UIImage {
        let size = image.size
        let longer = max(size.width, size.height)
        guard longer > maxSide else { return image }
        let scale = maxSide / longer
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let result = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return result
    }
}
