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
    static func generate(_ string: String, size: CGFloat = 220, tint: UIColor? = nil) -> UIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(string.data(using: .utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return nil }
        let scale = size / ciImage.extent.width
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let context = CIContext()
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }

        // 着色：默认深色前景
        if let tint = tint {
            let colored = tintQR(cgImage: cg, tint: tint)
            return UIImage(cgImage: colored)
        }
        return UIImage(cgImage: cg)
    }

    private static func tintQR(cgImage: CGImage, tint: UIColor) -> CGImage {
        let width = cgImage.width, height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: width * 4,
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return cgImage
        }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = ctx.data else { return cgImage }
        let ptr = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        tint.getRed(&r, green: &g, blue: &b, alpha: &a)
        for i in 0..<width * height {
            let o = i * 4
            // 原图中黑点（alpha 高且亮度低）替换为 tint
            let alpha = ptr[o + 3]
            if alpha > 128 {
                ptr[o]     = UInt8(r * 255)
                ptr[o + 1] = UInt8(g * 255)
                ptr[o + 2] = UInt8(b * 255)
                ptr[o + 3] = 255
            } else {
                ptr[o] = 255; ptr[o + 1] = 255; ptr[o + 2] = 255; ptr[o + 3] = 0
            }
        }
        return ctx.makeImage() ?? cgImage
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
