import UIKit

/// 流程协调器：相机采集 → StickerPipeline 处理 → push 结果页（含 Loading 转场）
enum Router {

    /// 由 CameraViewController.onCapture 调用
    static func handleCapture(_ full: UIImage, from nav: UINavigationController) {
        let loading = makeLoading()
        nav.present(loading, animated: true)

        Task {
            do {
                guard let cg = full.cgImage else {
                    throw NSError(domain: "FoodSticker", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "无法读取图像数据"])
                }
                let pipeline = try await StickerPipeline.build()
                let result = try await pipeline.process(image: cg)
                await MainActor.run {
                    let vc = ResultsViewController(result: result, original: full, pipeline: pipeline)
                    loading.dismiss(animated: false)
                    nav.pushViewController(vc, animated: true)
                }
            } catch {
                await MainActor.run {
                    loading.dismiss(animated: true)
                    let alert = UIAlertController(title: "处理失败",
                                                  message: error.localizedDescription,
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "确定", style: .default))
                    nav.present(alert, animated: true)
                }
            }
        }
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
