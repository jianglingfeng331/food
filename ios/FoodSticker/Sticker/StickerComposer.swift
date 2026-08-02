import UIKit
import Photos

/// 贴纸导出器：相册保存 + 系统分享
/// 注：原「合成贴纸」（白色模切描边 + 黑色轮廓）环节已移除，此类型仅负责成品导出
final class StickerExporter {
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
