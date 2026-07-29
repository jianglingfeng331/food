import UIKit

/// 贴纸样式。
enum StickerStyle {
    case emojiWhite   // iOS Emoji 白底款：纯白底 + 底部柔和投影
    case whiteBorder  // 白边贴纸款：透明底 + 白色描边（ die-cut 风格）
    case transparent  // 纯透明底
}

/// 贴纸渲染工具类：将透明底前景图合成为统一 1024×1024 正方形画布。
///
/// 规范：
/// - 统一输出正方形画布（默认 1024×1024）。
/// - 主体居中，占画布约 80%。
/// - iOS Emoji 样式：纯白纯色背景、底部柔和自然投影、边缘干净清晰无锯齿。
struct StickerRenderer {

    /// 统一输出画布边长（正方形）。
    static let canvasSize: CGFloat = 1024
    /// 主体在画布中占比（居中）。
    static let subjectFillRatio: CGFloat = 0.8

    /// 生成贴纸。
    /// - Parameters:
    ///   - foreground: 透明底前景图（通常来自 `RealTimeSegmentationEngine`）。
    ///   - style: 贴纸样式，默认 `.emojiWhite`。
    ///   - size: 输出边长，默认 1024。
    /// - Returns: 合成后的贴纸 `UIImage`。
    static func render(_ foreground: UIImage,
                       style: StickerStyle = .emojiWhite,
                       size: CGFloat = canvasSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext

            // 1) 背景
            if style == .emojiWhite {
                UIColor.white.setFill()
                cg.fill(CGRect(x: 0, y: 0, width: size, height: size))
            }
            // .whiteBorder / .transparent 保持透明

            guard let fgCG = foreground.cgImage else { return }
            let fgRatio = CGFloat(fgCG.width) / CGFloat(fgCG.height)

            // 2) 主体绘制区域（居中，占 80%）
            let drawSize = largestCenteredRect(within: CGSize(width: size, height: size),
                                              fillRatio: subjectFillRatio,
                                              aspect: fgRatio)
            let drawRect = CGRect(x: (size - drawSize.width) / 2,
                                  y: (size - drawSize.height) / 2,
                                  width: drawSize.width,
                                  height: drawSize.height)

            // 3) 白边款：先画放大后的白色剪影垫底
            if style == .whiteBorder,
               let white = makeWhiteSilhouette(foreground, scale: 1.06)?.cgImage {
                let padSize = CGSize(width: drawSize.width * 1.06, height: drawSize.height * 1.06)
                let padRect = CGRect(x: (size - padSize.width) / 2,
                                     y: (size - padSize.height) / 2,
                                     width: padSize.width, height: padSize.height)
                cg.draw(white, in: padRect)
            }

            // 4) 软阴影（仅 Emoji 白底款需要底部自然投影）
            if style == .emojiWhite {
                cg.saveGState()
                cg.setShadow(offset: CGSize(width: 0, height: size * 0.03),
                             blur: size * 0.05,
                             color: UIColor.black.withAlphaComponent(0.18).cgColor)
                cg.draw(fgCG, in: drawRect)
                cg.restoreGState()
            } else {
                cg.draw(fgCG, in: drawRect)
            }
        }
    }

    // MARK: - 内部工具

    /// 在正方形画布内，按主体宽高比，求得占 `fillRatio` 的最大居中矩形尺寸。
    private static func largestCenteredRect(within canvas: CGSize,
                                           fillRatio: CGFloat,
                                           aspect: CGFloat) -> CGSize {
        let maxW = canvas.width * fillRatio
        let maxH = canvas.height * fillRatio
        if aspect >= 1 {
            let w = min(maxW, maxH * aspect)
            return CGSize(width: w, height: w / aspect)
        } else {
            let h = min(maxH, maxW / aspect)
            return CGSize(width: h * aspect, height: h)
        }
    }

    /// 生成白色剪影：保留原图 alpha 形状，RGB 染成白色（用于白边款垫底）。
    private static func makeWhiteSilhouette(_ image: UIImage, scale: CGFloat) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let w = Int(CGFloat(cg.width) * scale)
        let h = Int(CGFloat(cg.height) * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: format)
        return renderer.image { ctx in
            let cx = ctx.cgContext
            cx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
            cx.setBlendMode(.sourceIn) // 仅保留原 alpha，颜色替换为下方填充色
            UIColor.white.setFill()
            cx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        }
    }
}
