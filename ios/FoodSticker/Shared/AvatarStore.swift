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
        self.nickname = UserDefaults.standard.string(forKey: nickKey) ?? "未登录"
    }

    // MARK: - 写

    /// 保存头像图片（自动压缩为 JPEG）。nil 表示清除自定义头像（回退默认）。
    func saveAvatar(_ image: UIImage?) {
        guard let image = image else {
            avatarImage = nil
            UserDefaults.standard.removeObject(forKey: imageKey)
            return
        }
        let resized = AvatarStore.resize(image, to: 512)
        let data = resized.jpegData(compressionQuality: 0.85)
        avatarImage = resized
        if let data = data {
            UserDefaults.standard.set(data, forKey: imageKey)
        }
    }

    /// 保存昵称
    func saveNickname(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        nickname = trimmed.isEmpty ? "未登录" : trimmed
        UserDefaults.standard.set(nickname, forKey: nickKey)
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
