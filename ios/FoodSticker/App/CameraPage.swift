//
//  CameraPage.swift
//  FoodSticker
//
//  相机流程页（拍摄 / 选择已有）— 1:1 还原 Web 端 CameraPage.tsx 控件
//  颜色 / 圆角 / 字号 / 间距 / 阴影 全部使用 Web 版精确数值（index.css @theme）
//  布局分区顺序、排列方式、对齐方式完全对齐 Web 版
//  组件优先使用 SwiftUI 原生实现：原生相机 AVCaptureSession，相册 PHPicker
//

import SwiftUI
import AVFoundation
import PhotosUI

// MARK: - Color Hex 扩展（Web 色值精确还原）

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - 设计令牌（与 Web 端 index.css @theme 完全一致，便于批量修改）

struct CameraPageTokens {

    // ---------- 颜色 ----------
    static let background        = Color(hex: "#F8F8F8")
    static let primary           = Color(hex: "#10B981")
    static let primaryLight      = Color(hex: "#34D399")
    static let primaryDark       = Color(hex: "#059669")
    static let primaryGlow       = Color(hex: "#10B981").opacity(0.12)
    static let card              = Color(hex: "#FFFFFF")
    static let surface           = Color.white.opacity(0.95)   // --color-surface
    static let surfaceBorder     = Color.black.opacity(0.05)  // --color-surface-border
    static let foreground        = Color(hex: "#1A1A1A")
    static let foregroundMuted   = Color(hex: "#666666")
    static let foregroundSubtle  = Color(hex: "#999999")
    static let success           = Color(hex: "#10B981")
    static let warning           = Color(hex: "#F59E0B")
    static let error             = Color(hex: "#EF4444")
    static let divider           = Color.black.opacity(0.05)

    // ---------- 圆角 ----------
    static let rXl: CGFloat = 24
    static let rLg: CGFloat = 16
    static let rMd: CGFloat = 12
    static let rSm: CGFloat = 10
    static let rXs: CGFloat = 8
    static let rFull: CGFloat = 9999
    static let previewRadius: CGFloat = 28   // rounded-[28px]

    // ---------- 阴影 ----------
    struct CamShadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        let opacity: Double
    }
    static let shadowCard    = CamShadow(color: .black,                 radius: 8,  x: 0, y: 2,  opacity: 0.03)
    static let shadowButton  = CamShadow(color: primary,                radius: 12, x: 0, y: 4,  opacity: 0.15)
    static let shadowButtonA = CamShadow(color: primary,                radius: 6,  x: 0, y: 2,  opacity: 0.10)
    static let shadowCamera  = CamShadow(color: .black,                 radius: 24, x: 0, y: 8,  opacity: 0.18)

    // ---------- 间距 ----------
    static let content: CGFloat  = 20   // --spacing-content (px-5)
    static let section: CGFloat  = 24   // space-y-6
    static let cardPad: CGFloat  = 16   // --spacing-card
    static let headerGap: CGFloat = 4   // mt-1
    static let tabGap: CGFloat    = 12  // gap-3

    // ---------- 字号 ----------
    static let fsXs: CGFloat  = 11
    static let fsSm: CGFloat  = 13
    static let fsBase: CGFloat = 14
    static let fsLg: CGFloat  = 16
    static let fsXl: CGFloat  = 20
    static let fs2xl: CGFloat = 24

    // ---------- 字重（Web 使用系统字体，按精确 px + weight 1:1 还原）----------
    static let wRegular:  Font.Weight = .regular
    static let wMedium:   Font.Weight = .medium
    static let wSemibold: Font.Weight = .semibold
    static let wBold:     Font.Weight = .bold

    static func font(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .system(size: size, weight: weight)
    }

    // ---------- 几何尺寸 ----------
    static let previewAspect: CGFloat = 3.0 / 4.0   // aspect-[3/4]
    static let guideSize: CGFloat = 192              // h-48 w-48
    static let shutterOuter: CGFloat = 72            // w-[72px] h-[72px]
    static let shutterInner: CGFloat = 64            // 内圈（仅装饰，此处渐变圆为整体）
    static let badgeFont: CGFloat = 11               // text-xs
    static let tabHeight: CGFloat = 44               // h-[44px]
    static let actionHeight: CGFloat = 48
    static let closeBtn: CGFloat = 56                // h-14 w-14
    static let albumBtn: CGFloat = 56                // h-14 w-14
    static let buttonGap: CGFloat = 28               // gap-7
    static let gridGap: CGFloat = 12                 // gap-12 / gap-3
    static let pendingThumb: CGFloat = 40            // w-10 h-10
}

extension View {
    func camShadow(_ s: CameraPageTokens.CamShadow) -> some View {
        self.shadow(color: s.color.opacity(s.opacity), radius: s.radius, x: s.x, y: s.y)
    }
}

// MARK: - 图标（lucide alert-circle / circle-check，与 CameraIcon 同规范）

private struct AlertCircleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var p = Path()
        p.addEllipse(in: CGRect(x: 2, y: 2, width: 20, height: 20)) // circle r=10
        p.move(to: CGPoint(x: 12, y: 8))
        p.addLine(to: CGPoint(x: 12, y: 12))
        p.move(to: CGPoint(x: 12, y: 16))
        p.addLine(to: CGPoint(x: 12, y: 16))
        return p.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

private struct CircleCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var p = Path()
        p.addEllipse(in: CGRect(x: 2, y: 2, width: 20, height: 20)) // circle r=10
        p.move(to: CGPoint(x: 8, y: 12))
        p.addLine(to: CGPoint(x: 11, y: 15))
        p.addLine(to: CGPoint(x: 16, y: 9))
        return p.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - 原生相机采集（AVCaptureSession + 预览层，对应 Web 的 react-camera-pro）

final class CameraModel: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    let previewView = PreviewView()
    private let queue = DispatchQueue(label: "foodsticker.camera.session")
    private var completion: ((UIImage?) -> Void)?
    @Published var isAuthorized = false

    override init() {
        super.init()
        session.sessionPreset = .photo
        previewView.videoPreviewLayer.session = session
        previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        requestAccess()
    }

    private func requestAccess() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted { self?.configureAndStart() }
            }
        default:
            break
        }
    }

    private func configureAndStart() {
        queue.async { [weak self] in
            guard let self else { return }
            self.configureSession()
            self.session.startRunning()
            DispatchQueue.main.async { self.isAuthorized = true }
        }
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        session.beginConfiguration()
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        session.commitConfiguration()
    }

    func start() { queue.async { [weak self] in self?.session.startRunning() } }
    func stop()  { queue.async { [weak self] in self?.session.stopRunning() } }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion?(nil); return
        }
        completion?(image)
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

struct CameraPreview: UIViewRepresentable {
    let model: CameraModel
    func makeUIView(context: Context) -> UIView { model.previewView }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - 相册选择（PHPicker，对应 Web 的 <input type="file">）

struct AlbumPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onPick: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var cfg = PHPickerConfiguration()
        cfg.selectionLimit = 1
        cfg.filter = .images
        let vc = PHPickerViewController(configuration: cfg)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: AlbumPicker
        init(_ parent: AlbumPicker) { self.parent = parent }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            guard let item = results.first?.itemProvider,
                  item.canLoadObject(ofClass: UIImage.self) else { return }
            item.loadObject(ofClass: UIImage.self) { obj, _ in
                if let img = obj as? UIImage {
                    DispatchQueue.main.async { self.parent.onPick(img) }
                }
            }
        }
    }
}

// MARK: - 待登记项（对应 Web pending）

struct PendingItem: Identifiable {
    let id = UUID()
    let sticker: FoodSticker
    var portion: Double
}

// MARK: - 相机流程主页面

struct CameraPage: View {

    enum Mode: String, CaseIterable {
        case camera  = "相机"
        case library = "选择已有"
    }

    var nav: UINavigationController?
    var onClose: (() -> Void)? = nil

    @StateObject private var camera = CameraModel()
    @State private var mode: Mode = .camera
    @State private var analyzing = false
    @State private var fallbackImage: UIImage? = nil
    @State private var showAlbumPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var successMessage = ""
    @State private var showPortion: FoodSticker? = nil
    @State private var pending: [PendingItem] = []
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        ZStack {
            CameraPageTokens.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: CameraPageTokens.section) {
                    modeToggle
                    if mode == .camera {
                        cameraSection
                    } else {
                        librarySection
                    }
                    if showError   { errorAlert }
                    if showSuccess && !analyzing { successAlert }
                }
                .padding(.horizontal, CameraPageTokens.content)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }

            if analyzing { analyzingOverlay }

            if showToast { toastView }

            // 份数选择面板（对应 Web PortionSheet，底部弹出）
            if let sticker = showPortion {
                ZStack(alignment: .bottom) {
                    Color.black.opacity(0.35).ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { showPortion = nil }
                    PortionSheet(sticker: sticker) { st, p in
                        addPending(st, p)
                        showPortion = nil
                    }
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showAlbumPicker) {
            AlbumPicker { img in runGenerate(img) }
        }
    }

    // MARK: 模式切换 Tab（相机 / 选择已有）—— 顶部居中，两种 mode 共用
    // 严格对齐 Web：容器 gap 2px / padding 3px / rounded 20px / 黑底 4%；
    // 按钮带图标、圆角 16px、px16 py8、文字 13px medium，激活态主色白字。
    private var modeToggle: some View {
        HStack(spacing: 2) {
            ForEach(Mode.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { mode = tab }
                } label: {
                    HStack(spacing: 4) {
                        modeIcon(tab, active: mode == tab)
                            .frame(width: 14, height: 14)
                        Text(tab.rawValue)
                            .font(CameraPageTokens.font(13, .medium))
                            .foregroundColor(mode == tab ? .white : CameraPageTokens.foregroundMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(mode == tab ? CameraPageTokens.primary : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: mode == tab ? .black.opacity(0.10) : .clear,
                            radius: 2, x: 0, y: 1)
                }
            }
        }
        .padding(3)
        .background(Color.black.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func modeIcon(_ tab: Mode, active: Bool) -> some View {
        let c = active ? Color.white : CameraPageTokens.foregroundMuted
        let s = StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        switch tab {
        case .camera:   CameraIcon().stroke(c, style: s)
        case .library:  ImagesIcon().stroke(c, style: s)
        }
    }

    // MARK: 拍摄界面
    @ViewBuilder
    private var cameraSection: some View {
        if let img = fallbackImage {
            previewCard(image: img)
        } else {
            cameraPreviewCard
            captureButtons
        }
    }

    // MARK: 拍摄区：实时预览 + 取景框
    private var cameraPreviewCard: some View {
        ZStack {
            CameraPreview(model: camera)
                .frame(maxWidth: .infinity)
                .aspectRatio(CameraPageTokens.previewAspect, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.previewRadius))
                .camShadow(CameraPageTokens.shadowCamera)
                .onAppear { camera.start() }
                .onDisappear { camera.stop() }

            if !camera.isAuthorized {
                Color.black.opacity(0.55)
                    .aspectRatio(CameraPageTokens.previewAspect, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.previewRadius))
                    .overlay(
                        Text("请在系统设置中允许使用相机")
                            .font(CameraPageTokens.font(CameraPageTokens.fsSm, .regular))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    )
            }

            // 中心虚线取景框（Web 同款，无四角方框装饰）
            RoundedRectangle(cornerRadius: CameraPageTokens.rLg)
                .stroke(Color.white.opacity(0.4),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .frame(width: CameraPageTokens.guideSize, height: CameraPageTokens.guideSize)
        }
        .aspectRatio(CameraPageTokens.previewAspect, contentMode: .fill)
    }

    // MARK: 底部三按钮：关闭 / 快门 / 相册（选照片）  —— 对应 Web 拍摄界面底部
    private var captureButtons: some View {
        HStack(spacing: CameraPageTokens.buttonGap) {
            // 关闭
            Button {
                if let onClose { onClose() } else { nav?.dismiss(animated: true) }
            } label: {
                ZStack {
                    Circle()
                        .fill(CameraPageTokens.card)
                        .frame(width: CameraPageTokens.closeBtn, height: CameraPageTokens.closeBtn)
                        .camShadow(CameraPageTokens.shadowButtonA)
                    XIcon()
                        .stroke(CameraPageTokens.foregroundMuted,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .frame(width: 22, height: 22)
                }
            }
            .scaleButton()
            .disabled(analyzing)

            // 快门（仅在已授权时启用）
            Button { capture() } label: {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [CameraPageTokens.primaryLight, CameraPageTokens.primary],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: CameraPageTokens.shutterOuter, height: CameraPageTokens.shutterOuter)
                        .camShadow(CameraPageTokens.shadowButton)
                    CameraIcon()
                        .stroke(Color.white,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .frame(width: 30, height: 30)
                }
            }
            .scaleButton()
            .disabled(analyzing || !camera.isAuthorized)

            // 相册（选择照片生成贴纸）
            Button { showAlbumPicker = true } label: {
                ZStack {
                    Circle()
                        .fill(CameraPageTokens.card)
                        .frame(width: CameraPageTokens.albumBtn, height: CameraPageTokens.albumBtn)
                        .camShadow(CameraPageTokens.shadowButtonA)
                    ImagesIcon()
                        .stroke(CameraPageTokens.primary,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .frame(width: 24, height: 24)
                }
            }
            .scaleButton()
            .disabled(analyzing)
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity)
        .opacity(analyzing ? 0 : 1)
    }

    // MARK: 失败回退：已拍/已选预览 + 重新拍摄 / 生成贴纸
    private func previewCard(image: UIImage) -> some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(CameraPageTokens.previewAspect, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.previewRadius))
                .camShadow(CameraPageTokens.shadowCamera)

            Text("已拍摄")
                .font(CameraPageTokens.font(CameraPageTokens.badgeFont, .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(CameraPageTokens.primary.opacity(0.9))
                .clipShape(Capsule())
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            HStack(spacing: CameraPageTokens.tabGap) {
                secondaryButton("重新拍摄") {
                    fallbackImage = nil
                    camera.start()
                }
                primaryButton("生成贴纸") {
                    if let img = fallbackImage { runGenerate(img) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .aspectRatio(CameraPageTokens.previewAspect, contentMode: .fill)
    }

    // MARK: 选择已有：食物预设网格 + 待登记 + 确认登记
    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            foodGrid
            if !pending.isEmpty { pendingList }
            confirmButton
            // 关闭（底部居中）
            Button {
                if let onClose { onClose() } else { nav?.dismiss(animated: true) }
            } label: {
                ZStack {
                    Circle()
                        .fill(CameraPageTokens.card)
                        .frame(width: 40, height: 40)
                        .camShadow(CameraPageTokens.shadowButtonA)
                    XIcon()
                        .stroke(CameraPageTokens.foregroundMuted,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .frame(width: 18, height: 18)
                }
            }
            .scaleButton()
            .frame(maxWidth: .infinity, alignment: .center)
            Spacer(minLength: 8)
        }
    }

    private var foodGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                  spacing: CameraPageTokens.gridGap) {
            ForEach(CardMock.stickers(for: .me)) { s in
                foodCell(s)
            }
        }
    }

    private func foodCell(_ s: FoodSticker) -> some View {
        Button { showPortion = s } label: {
            VStack(spacing: 6) {
                Image(s.imageName)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Text(s.name)
                    .font(CameraPageTokens.font(CameraPageTokens.fsSm, .medium))
                    .foregroundColor(CameraPageTokens.foreground)
                    .lineLimit(1)
                Text("\(s.cal) kcal")
                    .font(CameraPageTokens.font(CameraPageTokens.fsXs, .medium))
                    .foregroundColor(CameraPageTokens.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var pendingList: some View {
        VStack(spacing: 10) {
            ForEach(pending) { item in pendingRow(item) }
        }
    }

    private func pendingRow(_ item: PendingItem) -> some View {
        HStack(spacing: 12) {
            Image(item.sticker.imageName)
                .resizable()
                .frame(width: CameraPageTokens.pendingThumb, height: CameraPageTokens.pendingThumb)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.sticker.name)
                    .font(CameraPageTokens.font(CameraPageTokens.fsBase, .medium))
                    .foregroundColor(CameraPageTokens.foreground)
                Text("\(item.portion, specifier: "%.1f") 份 · \(Int(round(Double(item.sticker.cal) * item.portion))) kcal")
                    .font(CameraPageTokens.font(CameraPageTokens.fsSm, .regular))
                    .foregroundColor(CameraPageTokens.foregroundMuted)
            }
            Spacer()
            Button { removePending(item) } label: {
                XIcon()
                    .stroke(CameraPageTokens.foregroundSubtle,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 18, height: 18)
            }
        }
        .padding(12)
        .background(CameraPageTokens.card)
        .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rMd))
        .camShadow(CameraPageTokens.shadowCard)
    }

    private var confirmButton: some View {
        let total = pending.reduce(0) { $0 + Int(round(Double($1.sticker.cal) * $1.portion)) }
        return Button { registerPending() } label: {
            Text("确认登记 · \(total) kcal")
                .font(CameraPageTokens.font(CameraPageTokens.fsBase, .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: CameraPageTokens.actionHeight)
                .background(pending.isEmpty ? CameraPageTokens.foregroundSubtle : CameraPageTokens.primary)
                .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rMd))
                .camShadow(CameraPageTokens.shadowButton)
        }
        .disabled(pending.isEmpty)
        .scaleButton()
    }

    // MARK: 通用按钮
    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(CameraPageTokens.font(CameraPageTokens.fsBase, .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: CameraPageTokens.actionHeight)
                .background(CameraPageTokens.primary)
                .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rMd))
                .camShadow(CameraPageTokens.shadowButton)
        }
        .scaleButton()
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(CameraPageTokens.font(CameraPageTokens.fsBase, .semibold))
                .foregroundColor(CameraPageTokens.primary)
                .frame(maxWidth: .infinity)
                .frame(height: CameraPageTokens.actionHeight)
                .background(CameraPageTokens.background)
                .overlay(
                    RoundedRectangle(cornerRadius: CameraPageTokens.rMd)
                        .stroke(CameraPageTokens.primary, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rMd))
        }
        .scaleButton()
    }

    // MARK: 错误提示
    private var errorAlert: some View {
        HStack(spacing: 8) {
            AlertCircleShape()
                .stroke(CameraPageTokens.error, lineWidth: 2)
                .frame(width: 16, height: 16)
            Text(errorMessage)
                .font(CameraPageTokens.font(CameraPageTokens.fsBase, .regular))
                .foregroundColor(CameraPageTokens.error)
            Spacer()
        }
        .padding(12)
        .background(CameraPageTokens.error.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: CameraPageTokens.rLg)
                .stroke(CameraPageTokens.error.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rLg))
    }

    // MARK: 成功提示
    private var successAlert: some View {
        HStack(spacing: 8) {
            CircleCheckShape()
                .stroke(CameraPageTokens.success, lineWidth: 2)
                .frame(width: 16, height: 16)
            Text(successMessage)
                .font(CameraPageTokens.font(CameraPageTokens.fsBase, .regular))
                .foregroundColor(CameraPageTokens.success)
            Spacer()
        }
        .padding(12)
        .background(CameraPageTokens.success.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: CameraPageTokens.rLg)
                .stroke(CameraPageTokens.success.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rLg))
    }

    // MARK: 分析中遮罩（对应 Web analyzing overlay）
    private var analyzingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                AnalyzingSpinner()
                Text("正在分析食物...")
                    .font(CameraPageTokens.font(CameraPageTokens.fsLg, .medium))
                    .foregroundColor(CameraPageTokens.foreground)
            }
            .padding(24)
            .background(CameraPageTokens.card)
            .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rLg))
        }
        .ignoresSafeArea()
    }

    // MARK: Toast（对应 Web react-hot-toast）
    private var toastView: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                CircleCheckShape()
                    .stroke(CameraPageTokens.success, lineWidth: 2)
                    .frame(width: 18, height: 18)
                Text(toastMessage)
                    .font(CameraPageTokens.font(CameraPageTokens.fsBase, .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rMd))
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: 生成贴纸（衔接现有 StickerPipeline + ResultsViewController）
    private func capture() {
        camera.capturePhoto { img in
            if let img = img { runGenerate(img) }
        }
    }

    private func runGenerate(_ image: UIImage) {
        analyzing = true
        showError = false
        fallbackImage = nil
        Task {
            do {
                guard let cg = image.cgImage else {
                    throw NSError(domain: "FoodSticker", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "无法读取图像数据"])
                }
                let pipeline = try await StickerPipeline.build()
                let result = try await pipeline.process(image: cg)
                await MainActor.run {
                    analyzing = false
                    showSuccess = true
                    successMessage = "贴纸生成成功！"
                    // 对齐 Web：成功提示展示 800ms 后跳转结果页
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        let vc = ResultsViewController(result: result,
                                                       original: image,
                                                       pipeline: pipeline)
                        nav?.pushViewController(vc, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    analyzing = false
                    fallbackImage = image
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    // MARK: 选择已有：份数登记逻辑
    private func addPending(_ sticker: FoodSticker, _ portion: Double) {
        if let idx = pending.firstIndex(where: { $0.sticker.name == sticker.name }) {
            pending[idx].portion = portion
        } else {
            pending.append(PendingItem(sticker: sticker, portion: portion))
        }
    }

    private func removePending(_ item: PendingItem) {
        pending.removeAll { $0.id == item.id }
    }

    private func registerPending() {
        let count = pending.count
        var total = 0
        for item in pending {
            let cal = Int(round(Double(item.sticker.cal) * item.portion))
            total += cal
            AppDataStore.shared.addRecord(DailyRecord(type: .food,
                                                      name: item.sticker.name,
                                                      calories: cal,
                                                      amount: item.portion))
        }
        pending.removeAll()
        toastMessage = "已登记 \(count) 项 · 共 \(total) kcal"
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showToast = false }
        }
    }
}

// MARK: - 份数选择面板（对应 Web PortionSheet，底部弹出）

private struct PortionSheet: View {
    let sticker: FoodSticker
    let onConfirm: (FoodSticker, Double) -> Void
    @State private var portion: Double = 1.0

    var body: some View {
        VStack(spacing: 20) {
            // 拖动手柄
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.15))
                .frame(width: 40, height: 5)

            // 食物信息
            HStack(spacing: 12) {
                Image(sticker.imageName)
                    .resizable()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(sticker.name)
                        .font(CameraPageTokens.font(CameraPageTokens.fsLg, .semibold))
                        .foregroundColor(CameraPageTokens.foreground)
                    Text("\(sticker.cal) kcal/份")
                        .font(CameraPageTokens.font(CameraPageTokens.fsSm, .regular))
                        .foregroundColor(CameraPageTokens.foregroundMuted)
                }
                Spacer()
            }

            // 大号份数
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", portion))
                    .font(CameraPageTokens.font(32, .bold))
                    .foregroundColor(CameraPageTokens.primary)
                Text("份")
                    .font(CameraPageTokens.font(CameraPageTokens.fsLg, .medium))
                    .foregroundColor(CameraPageTokens.primary)
            }

            // 份数滑块（0.5 ~ 3，6 档）
            Slider(value: $portion, in: 0.5...3, step: 0.5)
                .accentColor(CameraPageTokens.primary)

            // 确定
            Button {
                onConfirm(sticker, portion)
            } label: {
                Text("确定")
                    .font(CameraPageTokens.font(CameraPageTokens.fsBase, .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: CameraPageTokens.actionHeight)
                    .background(CameraPageTokens.primary)
                    .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rMd))
            }
            .scaleButton()
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(CameraPageTokens.card)
        .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rXl, style: .continuous))
    }
}

// MARK: - 分析中旋转指示器

private struct AnalyzingSpinner: View {
    @State private var angle: Double = 0
    var body: some View {
        Circle()
            .trim(from: 0.15, to: 1)
            .stroke(CameraPageTokens.primary, lineWidth: 4)
            .frame(width: 32, height: 32)
            .rotationEffect(.degrees(angle))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
    }
}

// MARK: - 点击缩放反馈（适配 iOS 原生交互手感）

private struct ScaleButtonModifier: ViewModifier {
    @State private var pressed = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: pressed)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
                                pressing: { p in pressed = p }, perform: {})
    }
}

private extension View {
    func scaleButton() -> some View { self.modifier(ScaleButtonModifier()) }
}
