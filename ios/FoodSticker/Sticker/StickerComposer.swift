import CoreImage
import UIKit

/// 贴纸合成器：白色模切描边 + 图层合成 + 透明PNG导出
/// 强约束：白描边只由抠图Alpha形态学膨胀生成（禁止重新分割），与主体零错位
final class StickerComposer {
    private let ciContext = CIContext(options: [.cacheIntermediates: false])

    /// - Parameters:
    ///   - cartoon: 卡通化RGB图（模型输出，含黑内轮廓/平涂）
    ///   - alpha:   原始Alpha遮罩（已高斯模糊，原图分辨率）
    ///   - outlinePx: 白色模切描边宽度 3~5px（相对输出分辨率）
    ///   - maxSide: 输出上限（低端机 1080，普通 2048，高清导出走云端）
    func compose(cartoon: CGImage, alpha: CGImage, outlinePx: CGFloat = 4,
                 maxSide: CGFloat = 2048) -> UIImage {
        let alphaCI = CIImage(cgImage: alpha)
        let targetScale = min(1, maxSide / max(alphaCI.extent.width, alphaCI.extent.height))
        let alphaS = alphaCI.transformed(by: .init(scaleX: targetScale, y: targetScale))
        // 卡通图（512²）放大到目标分辨率
        let cartoonCI = CIImage(cgImage: cartoon).transformed(by: .init(
            scaleX: alphaS.extent.width / CGFloat(cartoon.width),
            y: alphaS.extent.height / CGFloat(cartoon.height)))

        // ① 原始Alpha做形态学膨胀（3~5px）
        let dilated = alphaS.applyingFilter("CIMorphologyMaximum",
                                            parameters: [kCIInputRadiusKey: outlinePx])
        // ② 膨胀Alpha即白描边层的形状（含主体+描边环）；
        //    白层置底、主体层置上，视觉上露出的就是"膨胀−原始"的描边环
        let whiteLayer = CIImage(color: .white).cropped(to: alphaS.extent)
            .applyingFilter("CIBlendWithMask", parameters: [
                kCIInputBackgroundImageKey: CIImage.empty().cropped(to: alphaS.extent),
                kCIInputMaskImageKey: dilated])
        // ③ 卡通主体 × 原始Alpha（透明底），叠在白层之上 → 描边与主体绝对对齐
        let subjectLayer = cartoonCI.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: CIImage.empty().cropped(to: alphaS.extent),
            kCIInputMaskImageKey: alphaS])
        let final = subjectLayer.composited(over: whiteLayer)

        let cg = ciContext.createCGImage(final, from: final.extent,
                                         format: .RGBA8,
                                         colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)!
        return UIImage(cgImage: cg)
    }

    /// 保存到相册（保留透明通道PNG）
    func saveToAlbum(_ sticker: UIImage, completion: @escaping (Bool) -> Void) {
        guard let png = sticker.pngData() else { return completion(false) }
        PHPhotoLibrary.shared().performChanges({
            let req = PHAssetCreationRequest.forAsset()
            req.addResource(with: .photo, data: png, options: nil)
        }) { ok, _ in DispatchQueue.main.async { completion(ok) } }
    }

    /// 分享（贴纸PNG + 营养文本）
    func share(_ sticker: UIImage, nutrition: String, from vc: UIViewController) {
        let items: [Any] = [sticker.pngData() as Any, nutrition]
        vc.present(UIActivityViewController(activityItems: items, applicationActivities: nil),
                   animated: true)
    }
}

import Photos
