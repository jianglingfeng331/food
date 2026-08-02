import SwiftUI

// MARK: - 默认头像（规范图标兜底）
//
// 用户未设置/上传头像时显示：规范 UserIcon 于柔和底圈中，
// 不使用任何 emoji。

struct DefaultAvatarView: View {
    var size: CGFloat = 40
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#F1F3F6"))
            UserIcon()
                .stroke(Color(hex: "#9AA3AF"), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.58, height: size * 0.58)
                .aspectRatio(contentMode: .fit)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 统一头像组件
//
// 有自定义头像图片时显示图片（圆形裁切），
// 否则回退 DefaultAvatarView。昵称首字作为图片加载前的占位提示（可选）。

struct AvatarView: View {
    let image: UIImage?
    var size: CGFloat = 40

    init(_ image: UIImage?, size: CGFloat = 40) {
        self.image = image
        self.size = size
    }

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                DefaultAvatarView(size: size)
            }
        }
        .frame(width: size, height: size)
    }
}
