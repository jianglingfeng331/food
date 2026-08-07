import Foundation
import CoreImage
import UIKit

// MARK: - 绑定码模型（PK 关系用）

/// 二维码 / 输码 统一承载的结构。
/// Mock 阶段纯端侧，真实上线可加密签名防止伪造。
struct PKCode: Codable, Equatable {
    var v: Int = 1
    var t: String = "pk"          // type = pk 绑定
    let uid: String               // 对方 uid
    let nick: String              // 昵称
    let av: String                // emoji 头像

    var payload: String {
        (try? JSONEncoder().encode(self)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }

    static func parse(_ string: String) -> PKCode? {
        guard let data = string.data(using: .utf8),
              let code = try? JSONDecoder().decode(PKCode.self, from: data),
              code.t == "pk", !code.uid.isEmpty else { return nil }
    return code
    }
}

// MARK: - 二维码生成 / 识别

enum QRCoder {

    /// 生成二维码 UIImage（无第三方库，使用 CoreImage 内置 filter）。
    /// - Parameters:
    ///   - string: 编码内容（一般来自 PKCode.payload）
    ///   - size: 输出边长（pt）
    ///   - tint: 前景模块颜色；背景固定白色
    /// - Note: 用 CIFalseColor 着色（替换黑/白通道），避免手写 bitmap 时 alpha/字节序错位
    ///         导致 UIImageView 渲染为漆黑方块；输出统一是不透明白底，避免 UI 层透明像素合并异常。
    static func generate(_ string: String, size: CGFloat = 220, tint: UIColor? = nil) -> UIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(string.data(using: .utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let qr = filter.outputImage else { return nil }
        let scale = size / qr.extent.width
        let scaled = qr.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // 1) 合成不透明白底：CIQRCodeGenerator 输出是 alpha-only 黑模块，
        //    composited(over:) 之后所有像素 alpha=255，UIImageView 显示稳定。
        let extent = scaled.extent
        let whiteBg = CIImage(color: CIColor.white).cropped(to: extent)
        let opaque = scaled.composited(over: whiteBg)

        // 2) 着色：用 CIFalseColor 把黑→tint、白→白；不需要则原样输出。
        let outImage: CIImage?
        if let tint = tint { let ciColor = CIColor(color: tint)
            guard let fc = CIFilter(name: "CIFalseColor") else { return nil }
            fc.setValue(opaque, forKey: kCIInputImageKey)
            fc.setValue(ciColor, forKey: "inputColor0")     // 黑模块 → tint
            fc.setValue(CIColor.white, forKey: "inputColor1") // 白底 → 白
            outImage = fc.outputImage
        } else {
            outImage = opaque
        }

        guard let final = outImage else { return nil }
        let context = CIContext()
        guard let cg = context.createCGImage(final, from: final.extent) else { return nil }
        return UIImage(cgImage: cg)
    }

    /// 从相册图片识别二维码（兜底入口，便于单机演示）。
    static func detect(from image: UIImage) -> String? {
        guard let cg = image.cgImage else { return nil }
        let ci = CIImage(cgImage: cg)
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                        context: nil,
                                        options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]) else { return nil }
        let features = detector.features(in: ci) as? [CIQRCodeFeature]
        return features?.first?.messageString
    }
}
