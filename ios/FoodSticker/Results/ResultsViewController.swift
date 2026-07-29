import UIKit
import SwiftUI
import Photos

/// 结果展示页：透明底贴纸预览 + 营养卡片 + 保存到相册 + 分享 + 高清导出 + 手动改食品名
final class ResultsViewController: UIViewController {

    private let result: PipelineResult
    private let original: UIImage
    private let pipeline: StickerPipeline
    private var currentFood: FoodInfo?
    private let composer = StickerComposer()

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let vStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 16
        s.alignment = .fill
        s.distribution = .fill
        return s
    }()

    private let stickerBox: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = true
        v.backgroundColor = UIColor(patternImage: ResultsViewController.checkerboard())
        return v
    }()
    private let stickerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 16
        return v
    }()
    private let cardStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 10
        s.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        s.isLayoutMarginsRelativeArrangement = true
        return s
    }()
    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = AppFont.ui(size: 22, weight: .bold)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()
    private let nutritionLabel: UILabel = {
        let l = UILabel()
        l.font = AppFont.ui(size: 15)
        l.numberOfLines = 0
        l.textColor = .secondaryLabel
        return l
    }()

    private let saveButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let hdButton = UIButton(type: .system)
    private let correctButton = UIButton(type: .system)

    // MARK: - Init

    init(result: PipelineResult, original: UIImage, pipeline: StickerPipeline) {
        self.result = result
        self.original = original
        self.pipeline = pipeline
        self.currentFood = result.food
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "生成结果"
        setupLayout()
        setupButtons()
        render()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(vStack)
        vStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            vStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            vStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            vStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            vStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])

        stickerBox.addSubview(stickerImageView)
        NSLayoutConstraint.activate([
            stickerImageView.centerXAnchor.constraint(equalTo: stickerBox.centerXAnchor),
            stickerImageView.centerYAnchor.constraint(equalTo: stickerBox.centerYAnchor),
            stickerImageView.leadingAnchor.constraint(greaterThanOrEqualTo: stickerBox.leadingAnchor, constant: 16),
            stickerImageView.trailingAnchor.constraint(lessThanOrEqualTo: stickerBox.trailingAnchor, constant: -16),
            stickerImageView.topAnchor.constraint(greaterThanOrEqualTo: stickerBox.topAnchor, constant: 16),
            stickerImageView.bottomAnchor.constraint(lessThanOrEqualTo: stickerBox.bottomAnchor, constant: -16),
            stickerImageView.widthAnchor.constraint(lessThanOrEqualTo: stickerBox.widthAnchor, constant: -32),
            stickerImageView.heightAnchor.constraint(lessThanOrEqualTo: stickerBox.heightAnchor, constant: -32),
        ])
        stickerBox.heightAnchor.constraint(equalToConstant: 320).isActive = true
        vStack.addArrangedSubview(stickerBox)

        cardView.addSubview(cardStack)
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: cardView.topAnchor),
            cardStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            cardStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            cardStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
        ])
        cardStack.addArrangedSubview(nameLabel)
        cardStack.addArrangedSubview(nutritionLabel)
        vStack.addArrangedSubview(cardView)

        vStack.addArrangedSubview(saveButton)
        vStack.addArrangedSubview(shareButton)
        vStack.addArrangedSubview(hdButton)
        vStack.addArrangedSubview(correctButton)
    }

    private func setupButtons() {
        let buttons = [saveButton, shareButton, hdButton, correctButton]
        buttons.forEach {
            $0.titleLabel?.font = AppFont.ui(size: 16, weight: .medium)
            $0.layer.cornerRadius = 12
            $0.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
            $0.setTitleColor(.systemBlue, for: .normal)
            $0.heightAnchor.constraint(equalToConstant: 48).isActive = true
        }
        saveButton.setTitle("保存到相册", for: .normal)
        shareButton.setTitle("分享", for: .normal)
        hdButton.setTitle("高清导出", for: .normal)
        correctButton.setTitle("修正食品名", for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        hdButton.addTarget(self, action: #selector(hdTapped), for: .touchUpInside)
        correctButton.addTarget(self, action: #selector(correctTapped), for: .touchUpInside)
    }

    // MARK: - Render

    private func render() {
        stickerImageView.image = result.sticker
        if let food = currentFood {
            nameLabel.text = food.nameCN + (food.fromCloud ? "  (云端识别)" : "")
            nutritionLabel.text = nutritionText(for: food)
        } else {
            nameLabel.text = "未能识别食品"
            nutritionLabel.text = "可点击下方「修正食品名」手动指定"
        }
    }

    private func nutritionText(for food: FoodInfo?) -> String {
        guard let f = food else { return "—" }
        var lines = [
            "热量：\(Int(f.kcal100g)) kcal / 100g",
            "蛋白质：\(String(format: "%.1f", f.proteinG)) g",
            "碳水：\(String(format: "%.1f", f.carbG)) g",
            "脂肪：\(String(format: "%.1f", f.fatG)) g",
            "典型份量：\(Int(f.typicalG)) g",
        ]
        if let p = f.portionG {
            lines.append("本次估算分量：\(Int(p)) g")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Actions

    @objc private func saveTapped() {
        composer.saveToAlbum(result.sticker) { [weak self] ok in
            self?.toast(ok ? "已保存到相册" : "保存失败，请检查相册权限")
        }
    }

    @objc private func shareTapped() {
        composer.share(result.sticker, nutrition: nutritionText(for: currentFood), from: self)
    }

    @objc private func hdTapped() {
        guard let cg = original.cgImage else {
            toast("无法读取原图"); return
        }
        hdButton.isEnabled = false
        hdButton.setTitle("导出中…", for: .normal)
        Task {
            do {
                let hd = try await pipeline.exportHD(original: cg, alphaPNG: result.alphaPNG)
                await MainActor.run {
                    self.stickerImageView.image = hd
                    self.hdButton.setTitle("高清导出", for: .normal)
                    self.hdButton.isEnabled = true
                    self.toast("高清贴纸已生成")
                }
            } catch {
                await MainActor.run {
                    self.hdButton.setTitle("高清导出", for: .normal)
                    self.hdButton.isEnabled = true
                    self.toast("高清导出失败：\(error.localizedDescription)")
                }
            }
        }
    }

    @objc private func correctTapped() {
        let alert = UIAlertController(title: "修正食品名",
                                      message: "输入食品名称以查询本地/云端营养数据",
                                      preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "如：白米饭" }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let self, let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            Task {
                if let info = await self.pipeline.correctFood(name: name) {
                    await MainActor.run {
                        self.currentFood = info
                        self.render()
                        self.toast("已更新为：\(info.nameCN)")
                    }
                } else {
                    await MainActor.run { self.toast("未找到「\(name)」的营养信息") }
                }
            }
        })
        present(alert, animated: true)
    }

    // MARK: - Helpers

    private func toast(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            alert.dismiss(animated: true)
        }
    }

    private static func checkerboard(cell: CGFloat = 16) -> UIImage {
        let size = cell * 2
        return UIGraphicsImageRenderer(size: CGSize(width: size, height: size)).image { ctx in
            UIColor.systemGray5.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
            UIColor.systemGray3.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: cell, height: cell))
            ctx.fill(CGRect(x: cell, y: cell, width: cell, height: cell))
        }
    }
}
