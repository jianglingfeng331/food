import UIKit

/// 流程协调器：相机采集 → 新链路（前置抠图 + 营养识别 + 卡通贴纸生成）→ push 结果页
enum Router {

    /// 由 CameraViewController.onCapture 调用（复用现有拍照 UI，仅替换后续处理链路）
    static func handleCapture(_ full: UIImage, from nav: UINavigationController) {
        let loading = makeLoading()
        nav.present(loading, animated: true)

        // ① 前置抠图：秒级拿到预览贴纸，立即 push 结果页
        FoodStickerCaptureProcessor.shared.processCapture(
            originalImage: full,
            onPreviewReady: { preview in
                DispatchQueue.main.async {
                    loading.dismiss(animated: false)
                    let vc = FoodStickerResultViewController(previewSticker: preview, original: full)
                    nav.pushViewController(vc, animated: true)
                }
            },
            onFinalResult: { sticker, nutrition, error in
                DispatchQueue.main.async {
                    // 找到栈内结果页，动态刷新最终贴纸与营养信息
                    if let vc = nav.viewControllers.compactMap({ $0 as? FoodStickerResultViewController }).last {
                        vc.update(with: sticker, nutrition: nutrition, error: error)
                    }
                }
            }
        )
    }

    private static func makeLoading() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor(white: 0, alpha: 0.4)
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        vc.view.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor),
        ])
        return vc
    }
}
