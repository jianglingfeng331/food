import UIKit
import SwiftUI

/// 自定义浮动 TabBar：白色胶囊（左侧 3 Tab）+ 绿色圆形相机按钮（右侧）
/// 视觉规范与 Web 首页一致：#FFFFFF 卡片、#10B981 主色、圆角/阴影精确对齐
/// 图标：从 Web 端 lucide-react 自动提取 → LucideIcons.swift (SwiftUI Shape)
final class MainTabBarController: UIViewController {

    // MARK: - Child VCs
    private let homeVC    = UINavigationController(rootViewController: HomeViewController())
    private let cardVC    = UINavigationController(rootViewController: CardViewController())
    private let pkVC      = UINavigationController(rootViewController: PKViewController())
    private let profileVC = UINavigationController(rootViewController: ProfileViewController())

    private lazy var pages: [UIViewController] = [homeVC, cardVC, pkVC]
    private var currentIndex = 0

    // MARK: - UI
    private let containerView = UIView()

    /// 底部浮动容器（白色胶囊 + 相机按钮）
    private let floatBar  = UIView()
    private let capsule   = UIView()
    private let cameraBtn = UIButton(type: .system)

    private var tabButtons: [UIButton] = []
    private var tabBgs: [UIView] = []

    // MARK: - 设计令牌 (对照 Web 端)
    private let accentGreen  = UIColor(hex: 0x10B981)
    private let cardBg       = UIColor(hex: 0xFFFFFF)
    private let inactiveGray = UIColor(hex: 0x999999)
    private let borderColor  = UIColor.black.withAlphaComponent(0.05)
    private let cardShadow   = UIColor.black.withAlphaComponent(0.03)

    // lucide 图标尺寸 (24x24 viewBox，stroke-width: 2)
    private let iconSize: CGFloat = 22
    private let iconLineWidth: CGFloat = 1.8

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupContainer()
        setupChildVCs()
        setupFloatBar()
        selectTab(index: 0, animated: false)
    }

    // MARK: - Shape → UIImage 渲染
    /// 将 lucide SwiftUI Shape 渲染为指定颜色的 UIImage (outline 风格)
    /// 使用 SwiftUI 原生 ImageRenderer 确保 arc/curve 等路径元素精确还原，避免 CGPath 中间转换偏差
    private func imageFromShape<S: Shape>(_ shape: S) -> UIImage {
        let styled = shape
            .stroke(style: StrokeStyle(lineWidth: iconLineWidth, lineCap: .round, lineJoin: .round))
            .foregroundColor(.black) // 占位色，实际通过 tintColor 控制
            .frame(width: iconSize, height: iconSize)

        let renderer = ImageRenderer(content: styled)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage ?? UIImage()
    }

    // MARK: - Setup
    private func setupContainer() {
        view.backgroundColor = UIColor(hex: 0xF8F8F8)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupChildVCs() {
        for vc in pages {
            addChild(vc)
            vc.view.translatesAutoresizingMaskIntoConstraints = false
            vc.view.isHidden = true
            containerView.addSubview(vc.view)
            NSLayoutConstraint.activate([
                vc.view.topAnchor.constraint(equalTo: containerView.topAnchor),
                vc.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                vc.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                vc.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            vc.didMove(toParent: self)
        }
    }

    private func setupFloatBar() {
        floatBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(floatBar)
        NSLayoutConstraint.activate([
            floatBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            floatBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            floatBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            floatBar.heightAnchor.constraint(equalToConstant: 56)
        ])

        // 白色胶囊（左侧 3 Tab）
        capsule.backgroundColor = cardBg
        capsule.layer.cornerRadius = 28
        capsule.layer.borderWidth = 1
        capsule.layer.borderColor = borderColor.cgColor
        capsule.layer.shadowColor   = cardShadow.cgColor
        capsule.layer.shadowOffset  = CGSize(width: 0, height: 2)
        capsule.layer.shadowOpacity = 1
        capsule.layer.shadowRadius  = 8
        capsule.translatesAutoresizingMaskIntoConstraints = false
        floatBar.addSubview(capsule)

        // lucide 图标：从 Web 端自动提取 → 1:1 还原 Web 视觉效果
        // 顺序：首页(餐饮) / 贴纸(文档) / PK(对战)
        let iconShapes: [AnyShape] = [
            AnyShape(UtensilsCrossedIcon()),
            AnyShape(StickerIcon()),
            AnyShape(SwordsIcon())
        ]

        for (i, shape) in iconShapes.enumerated() {
            // 选中背景 (primary/10)
            let bg = UIView()
            bg.backgroundColor = accentGreen.withAlphaComponent(0.10)
            bg.layer.cornerRadius = 22
            bg.isHidden = true
            bg.translatesAutoresizingMaskIntoConstraints = false
            capsule.addSubview(bg)
            tabBgs.append(bg)

            let btn = UIButton(type: .system)
            btn.tag = i
            // 渲染 Shape → UIImage (用黑色作为模板色，通过 tintColor 变色)
            let rawImg = imageFromShape(shape)
            btn.setImage(rawImg.withRenderingMode(.alwaysTemplate), for: .normal)
            btn.tintColor = inactiveGray
            btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            btn.addTarget(self, action: #selector(btnTouchDown(_:)), for: .touchDown)
            btn.addTarget(self, action: #selector(btnTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
            btn.translatesAutoresizingMaskIntoConstraints = false
            capsule.addSubview(btn)
            tabButtons.append(btn)

            NSLayoutConstraint.activate([
                bg.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
                bg.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
                bg.widthAnchor.constraint(equalToConstant: 44),
                bg.heightAnchor.constraint(equalToConstant: 44)
            ])
        }

        // 胶囊布局：仅靠左，宽度由内部 3 个按钮自适应
        NSLayoutConstraint.activate([
            capsule.leadingAnchor.constraint(equalTo: floatBar.leadingAnchor),
            capsule.topAnchor.constraint(equalTo: floatBar.topAnchor),
            capsule.bottomAnchor.constraint(equalTo: floatBar.bottomAnchor)
        ])

        // Tab 按钮在胶囊内排列
        let btnSize: CGFloat = 44
        let gap: CGFloat = 4
        let sidePad: CGFloat = 8
        for (i, btn) in tabButtons.enumerated() {
            NSLayoutConstraint.activate([
                btn.topAnchor.constraint(equalTo: capsule.topAnchor, constant: 6),
                btn.bottomAnchor.constraint(equalTo: capsule.bottomAnchor, constant: -6),
                btn.widthAnchor.constraint(equalToConstant: btnSize),
                btn.heightAnchor.constraint(equalToConstant: btnSize)
            ])
            if i == 0 {
                btn.leadingAnchor.constraint(equalTo: capsule.leadingAnchor, constant: sidePad).isActive = true
            } else {
                btn.leadingAnchor.constraint(equalTo: tabButtons[i-1].trailingAnchor, constant: gap).isActive = true
            }
            if i == tabButtons.count - 1 {
                btn.trailingAnchor.constraint(equalTo: capsule.trailingAnchor, constant: -sidePad).isActive = true
            }
        }

        // 绿色圆形相机按钮（右侧，使用 lucide CameraIcon）
        cameraBtn.backgroundColor = accentGreen
        cameraBtn.layer.cornerRadius = 28
        cameraBtn.setImage(imageFromShape(CameraIcon()).withRenderingMode(.alwaysTemplate),
                           for: .normal)
        cameraBtn.tintColor = .white
        cameraBtn.layer.shadowColor   = accentGreen.cgColor
        cameraBtn.layer.shadowOffset  = CGSize(width: 0, height: 4)
        cameraBtn.layer.shadowOpacity = 0.35
        cameraBtn.layer.shadowRadius  = 8
        cameraBtn.addTarget(self, action: #selector(cameraTapped), for: .touchUpInside)
        cameraBtn.addTarget(self, action: #selector(btnTouchDown(_:)), for: .touchDown)
        cameraBtn.addTarget(self, action: #selector(btnTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        cameraBtn.translatesAutoresizingMaskIntoConstraints = false
        floatBar.addSubview(cameraBtn)

        NSLayoutConstraint.activate([
            cameraBtn.centerYAnchor.constraint(equalTo: capsule.centerYAnchor),
            cameraBtn.widthAnchor.constraint(equalToConstant: 56),
            cameraBtn.heightAnchor.constraint(equalToConstant: 56),
            cameraBtn.trailingAnchor.constraint(equalTo: floatBar.trailingAnchor)
        ])
    }

    // MARK: - Actions
    @objc private func tabTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index != currentIndex else { return }
        selectTab(index: index, animated: true)
    }

    @objc private func cameraTapped() {
        let sheet = UIAlertController(title: "选择相机模式", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "食物相机", style: .default) { [weak self] _ in
            guard let self else { return }
            let nav = UINavigationController()
            let root = UIHostingController(rootView: CameraPage(nav: nav))
            nav.viewControllers = [root]
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true)
        })
        sheet.addAction(UIAlertAction(title: "实时抠图贴纸工坊", style: .default) { [weak self] _ in
            guard let self else { return }
            let flow = StickerFlowViewController()
            let nav = UINavigationController(rootViewController: flow)
            self.present(nav, animated: true)
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(sheet, animated: true)
    }

    // MARK: - 点击状态反馈 (缩放动画)
    @objc private func btnTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12, delay: 0, options: [.beginFromCurrentState, .curveEaseOut]) {
            sender.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        }
    }

    @objc private func btnTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.18, delay: 0, options: [.beginFromCurrentState, .curveEaseOut]) {
            sender.transform = .identity
        }
    }

    private func selectTab(index: Int, animated: Bool) {
        pages[currentIndex].view.isHidden = true
        currentIndex = index
        pages[currentIndex].view.isHidden = false

        for (i, btn) in tabButtons.enumerated() {
            let selected = (i == index)
            tabBgs[i].isHidden = !selected
            btn.tintColor = selected ? accentGreen : inactiveGray

            if animated && selected {
                btn.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.6, options: [.beginFromCurrentState]) {
                    btn.transform = .identity
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
}

// MARK: - UIColor Hex 扩展
extension UIColor {
    convenience init(hex: UInt) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
