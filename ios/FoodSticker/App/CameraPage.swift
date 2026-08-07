//
//  CameraPage.swift
//  FoodSticker
//
//  相机流程页（拍摄 / 选择已有）—— 后台任务队列版
//  行为对齐 Web 端 CameraPage.tsx 的「连续拍摄 + 后台异步任务队列」逻辑：
//   · 点击快门 → 来源页白光闪烁动效 → 主体自动抠出并缩小到顶部队列（相机/选择已有上方、居左）
//   · 任务生成中灰显并标注「识别中」，完成后自动恢复彩色
//   · 抠图/识别/生成全部入后台队列异步执行，不阻塞界面，可连续拍摄
//   · 任意状态下点击缩略图即可查看详情
//   · 最多同时 5 个任务，超出弹窗提醒
//   · 任务排队等待用户确认下一步操作，系统不主动删除任何任务
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

// MARK: - 设计令牌（与 Web 端 index.css @theme 完全一致）

struct CameraPageTokens {

    // ---------- 颜色 ----------
    static let background        = Color(hex: "#F8F8F8")
    static let primary           = Color(hex: "#10B981")
    static let primaryLight      = Color(hex: "#34D399")
    static let primaryDark       = Color(hex: "#059669")
    static let primaryGlow       = Color(hex: "#10B981").opacity(0.12)
    static let card              = Color(hex: "#FFFFFF")
    static let surface           = Color.white.opacity(0.95)
    static let surfaceBorder     = Color.black.opacity(0.05)
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
    static let previewRadius: CGFloat = 28

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
    static let content: CGFloat  = 20
    static let section: CGFloat  = 24
    static let cardPad: CGFloat  = 16
    static let headerGap: CGFloat = 4
    static let tabGap: CGFloat    = 12

    // ---------- 字号 ----------
    static let fsXs: CGFloat  = 11
    static let fsSm: CGFloat  = 13
    static let fsBase: CGFloat = 14
    static let fsLg: CGFloat  = 16
    static let fsXl: CGFloat  = 20
    static let fs2xl: CGFloat = 24

    // ---------- 字重 ----------
    static let wRegular:  Font.Weight = .regular
    static let wMedium:   Font.Weight = .medium
    static let wSemibold: Font.Weight = .semibold
    static let wBold:     Font.Weight = .bold

    static func font(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .system(size: size, weight: weight)
    }

    // ---------- 几何尺寸 ----------
    static let previewAspect: CGFloat = 3.0 / 4.0
    static let guideSize: CGFloat = 192
    static let shutterOuter: CGFloat = 72
    static let shutterInner: CGFloat = 64
    static let tabHeight: CGFloat = 44
    static let actionHeight: CGFloat = 48
    static let closeBtn: CGFloat = 56
    static let albumBtn: CGFloat = 56
    static let buttonGap: CGFloat = 28
    static let pendingThumb: CGFloat = 40
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
        p.addEllipse(in: CGRect(x: 2, y: 2, width: 20, height: 20))
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
        p.addEllipse(in: CGRect(x: 2, y: 2, width: 20, height: 20))
        p.move(to: CGPoint(x: 8, y: 12))
        p.addLine(to: CGPoint(x: 11, y: 15))
        p.addLine(to: CGPoint(x: 16, y: 9))
        return p.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - 原生相机采集（AVCaptureSession + 预览层）

final class CameraModel: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    let previewView = PreviewView()
    private let queue = DispatchQueue(label: "foodsticker.camera.session")
    private var completion: ((UIImage?) -> Void)?
    @Published var isAuthorized = false
    @Published var isSimulator = false

    override init() {
        super.init()
#if targetEnvironment(simulator)
        isSimulator = true
        return
#endif
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
            let ok = self.configureSession()
            guard ok else {
                Log("[CameraModel] 摄像头配置失败，可能无可用后置摄像头")
                return
            }
            self.session.startRunning()
            DispatchQueue.main.async { self.isAuthorized = true }
        }
    }

    @discardableResult
    private func configureSession() -> Bool {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video, position: .back)
        else {
            Log("[CameraModel] 未找到后置广角摄像头")
            return false
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            Log("[CameraModel] 无法创建 AVCaptureDeviceInput")
            return false
        }
        session.beginConfiguration()
        session.sessionPreset = .photo
        var ok = true
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            Log("[CameraModel] 无法添加摄像输入")
            ok = false
        }
        if session.canAddOutput(photoOutput) {
            photoOutput.isHighResolutionCaptureEnabled = true
            session.addOutput(photoOutput)
        } else {
            Log("[CameraModel] 无法添加照片输出")
            ok = false
        }
        session.commitConfiguration()
        return ok
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

// MARK: - 相册选择（PHPicker）

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

// MARK: - 拍摄任务模型

enum TaskStatus: Equatable {
    case processing
    case done
    case logged
}

struct CaptureTask: Identifiable {
    let id: Int
    var sourceImage: UIImage
    var preview: UIImage          // 队列缩略图（处理中即显示原图/抠图结果）
    var status: TaskStatus
    var name: String
    var kcal100g: Double
    var proteinG: Double
    var carbG: Double
    var fatG: Double
    var typicalG: Double
    var portionG: Double?         // 云端估算分量
    var grams: Double             // 用户当前份数（g）
    var stickerImage: UIImage?
    var isPreset: Bool
    var error: String?
    var createdAt: Date = Date()   // 拍摄时间，详情页用于展示「日期时间」

    // 云端（火山方舟）完整营养结果缓存：拍摄时只请求一次，详情页直接复用，避免重复请求模型
    var cloudNutrition: FoodNutritionModel? = nil
    var cloudError: Error? = nil
    var cloudDone: Bool = false
    var cloudRequested: Bool = false

    var caloriesNow: Int { Int(round(kcal100g * grams / 100)) }
}

// MARK: - 拍摄任务仓库（全局单例，不主动删除）

final class CaptureStore: ObservableObject {
    static let shared = CaptureStore()
    static let maxTasks = 5

    @Published private(set) var tasks: [CaptureTask] = []

    private init() {}

    func add(_ task: CaptureTask) { tasks.insert(task, at: 0) }
    func remove(_ id: Int) { tasks.removeAll { $0.id == id } }
    func update(_ id: Int, _ mutate: (inout CaptureTask) -> Void) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        var t = tasks[idx]
        mutate(&t)
        tasks[idx] = t
    }
    var count: Int { tasks.count }
    func canAddMore() -> Bool { tasks.count < CaptureStore.maxTasks }
}

// MARK: - 选择已有：待提交项

struct LibraryPendingItem: Identifiable {
    let id = UUID()
    let sticker: FoodSticker
    let servings: Int
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
    @StateObject private var store = CaptureStore.shared

    @State private var mode: Mode = .camera
    @State private var showAlbumPicker = false
    @State private var showLimit = false
    @State private var flashKey = 0
    @State private var toast: String? = nil
    @State private var toastWork: DispatchWorkItem? = nil

    // 选择已有：份数选择 & 待提交列表
    @State private var servingTarget: FoodSticker? = nil
    @State private var selectedServings: Int = 1
    @State private var pendingItems: [LibraryPendingItem] = []

    // 从贴纸仓库异步加载的贴纸列表（用于合并到本地 savedStickers，不直接参与显示）
    @State private var repoStickers: [FoodSticker] = []

    // 待删除的自定义贴纸（长按触发，仅自定义贴纸可删，内置 CardMock 不可删）
    @State private var stickerToDelete: FoodSticker? = nil

    var body: some View {
        ZStack {
            CameraPageTokens.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // 顶部：任务队列（固定 80pt 高度，避免 GeometryReader 撑开布局）
                taskQueue
                    .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 80, alignment: .leading)
                    .padding(.top, 10)
                    .padding(.horizontal, 16)

                modeToggle
                    .padding(.top, 14)
                    .padding(.horizontal, 16)

                Group {
                    if mode == .camera {
                        cameraSection
                            .padding(.horizontal, CameraPageTokens.content)
                            .padding(.top, 16)
                    } else {
                        // 选择已有：上方滚动区域 + 底部固定关闭按钮
                        VStack(spacing: 0) {
                            ScrollView {
                                librarySection
                                    .padding(.horizontal, CameraPageTokens.content)
                                    .padding(.top, 16)
                                    .padding(.bottom, 16)
                            }
                            libraryCloseBar
                                .padding(.horizontal, CameraPageTokens.content)
                                .padding(.top, 8)
                                .padding(.bottom, 24)
                                .background(CameraPageTokens.background)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showAlbumPicker) {
            AlbumPicker { img in runPipelineForImage(img) }
        }
        .alert("任务已达上限", isPresented: $showLimit) {
            Button("我知道了", role: .cancel) {}
        } message: {
            Text("最多同时处理 \(CaptureStore.maxTasks) 个拍摄任务，请先完成或删除现有任务后再继续拍摄。")
        }
        .overlay(alignment: .bottom) {
            if let msg = toast {
                Text(msg)
                    .font(CameraPageTokens.font(CameraPageTokens.fsSm, .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rFull))
                    .padding(.bottom, 90)
                    .transition(.opacity)
            }
        }
        .task {
            // 从贴纸仓库异步加载云端贴纸，并合并到本地 savedStickers（跨设备同步）
            // 不直接用于显示：显示层始终 = CardMock 内置预设 + savedStickers 自定义贴纸
            repoStickers = await AppDataStore.shared.fetchStickersAsFoodStickers()
            AppDataStore.shared.mergeCloudStickers(repoStickers)
        }
    }

    // MARK: 模式切换 Tab（相机 / 选择已有）
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
    private var cameraSection: some View {
        VStack(spacing: 0) {
            cameraPreviewCard
                .frame(maxHeight: .infinity)
            Spacer().frame(height: 32)
            captureButtons
        }
    }

    // MARK: 拍摄区：实时预览 + 取景框 + 快门动效
    private var cameraPreviewCard: some View {
        ZStack {
            CameraPreview(model: camera)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.previewRadius))
                .camShadow(CameraPageTokens.shadowCamera)
                .onAppear { camera.start() }
                .onDisappear { camera.stop() }

            if camera.isSimulator {
                Color.black.opacity(0.55)
                    .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.previewRadius))
                    .overlay(
                        VStack(spacing: 8) {
                            Text("模拟器不支持摄像头\n请在真机上运行")
                                .multilineTextAlignment(.center)
                                .font(CameraPageTokens.font(CameraPageTokens.fsSm, .regular))
                                .foregroundColor(.white)
                        }
                    )
            } else if !camera.isAuthorized {
                Color.black.opacity(0.55)
                    .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.previewRadius))
                    .overlay(
                        VStack(spacing: 8) {
                            Text("请在「设置」中允许访问相机")
                                .font(CameraPageTokens.font(CameraPageTokens.fsSm, .regular))
                                .foregroundColor(.white)
                            Button("重试") { camera.start() }
                                .font(CameraPageTokens.font(CameraPageTokens.fsBase, .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(Color.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rFull))
                        }
                    )
            }

            // 取景引导框（始终显示，提示主体居中）
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.4),
                        style: StrokeStyle(lineWidth: 4, dash: [10, 8]))
                .frame(width: 200, height: 200)
                .allowsHitTesting(false)

            // 快门动效：每次拍摄白光闪烁
            if flashKey > 0 {
                FlashOverlay().id(flashKey).allowsHitTesting(false)
            }
        }
    }

    // MARK: 底部控制条：关闭 / 快门 / 相册
    private var captureButtons: some View {
        HStack(alignment: .center, spacing: CameraPageTokens.buttonGap) {
            Button {
                closeAction()
            } label: {
                XIcon()
                    .stroke(CameraPageTokens.foreground,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 22, height: 22)
                    .padding(17)
                    .background(CameraPageTokens.card.opacity(0.9))
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }

            Button { capture() } label: {
                ZStack {
                    Circle()
                        .fill(CameraPageTokens.primary)
                        .frame(width: CameraPageTokens.shutterOuter, height: CameraPageTokens.shutterOuter)
                        .shadow(color: CameraPageTokens.primary.opacity(0.3), radius: 12, x: 0, y: 4)
                    Circle()
                        .fill(Color.white)
                        .frame(width: CameraPageTokens.shutterInner - 8,
                               height: CameraPageTokens.shutterInner - 8)
                }
            }
            .scaleButton()

            Button { showAlbumPicker = true } label: {
                ImagesIcon()
                    .stroke(CameraPageTokens.foreground,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 22, height: 22)
                    .padding(17)
                    .background(CameraPageTokens.card.opacity(0.9))
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 20)
        .padding(.bottom, 36)
    }

    // MARK: 选择已有：预设食物网格 → 份数选择 → 待提交列表 → 统一提交
    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("选择已有食物")
                .font(CameraPageTokens.font(CameraPageTokens.fsLg, .semibold))
                .foregroundColor(CameraPageTokens.foreground)
            // 显示数据源 = CardMock 内置预设 + savedStickers 用户自定义（按名称去重）
            // 内置预设始终保留，不被云端贴纸替换；自定义贴纸可在云端跨设备同步
            let builtIn = CardMock.stickers(for: .me)
            let userItems = AppDataStore.shared.savedStickers.filter { u in
                !builtIn.contains { $0.name == u.name }
            }
            let items = builtIn + userItems
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
            ForEach(items) { st in
                // 自定义贴纸（recordId 非空）：右上角有删除按钮 + 长按菜单
                // 内置预设（recordId 空）：不可删除
                let isCustom = !st.recordId.isEmpty
                Button { servingTarget = st; selectedServings = 1 } label: {
                    VStack(spacing: 6) {
                        ZStack(alignment: .topTrailing) {
                            StickerImageView(sticker: st, contentMode: .fill)
                                .frame(height: 96).frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rMd))
                            if isCustom {
                                // 显式删除按钮（×），无需长按
                                Button {
                                    stickerToDelete = st
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.red.opacity(0.9))
                                        .background(Circle().fill(Color.white))
                                        .padding(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Text(st.name)
                            .font(CameraPageTokens.font(CameraPageTokens.fsSm, .medium))
                            .foregroundColor(CameraPageTokens.foreground)
                        Text("\(st.cal) kcal")
                            .font(CameraPageTokens.font(CameraPageTokens.fsXs, .regular))
                            .foregroundColor(CameraPageTokens.foregroundMuted)
                    }
                }
                .buttonStyle(.plain)
                .contextMenu { if isCustom {
                    Button(role: .destructive) {
                        stickerToDelete = st
                    } label: {
                        Label("删除该预设", systemImage: "trash")
                    }
                } }
            }
            }

            // 份数选择条（横向滚动）
            if let target = servingTarget {
                servingPicker(for: target)
            }

            // 待提交列表 + 统一提交
            if !pendingItems.isEmpty {
                pendingList
            }
        }
        .alert("删除预设", isPresented: Binding(
            get: { stickerToDelete != nil },
            set: { if !$0 { stickerToDelete = nil } }
        )) {
            Button("取消", role: .cancel) { stickerToDelete = nil }
            Button("删除", role: .destructive) {
                if let st = stickerToDelete {
                    AppDataStore.shared.deleteCustomSticker(recordId: st.recordId)
                    // 若当前选中的贴纸被删除，清除选中状态
                    if servingTarget?.recordId == st.recordId {
                        servingTarget = nil
                    }
                    stickerToDelete = nil
                }
            }
        } message: {
            if let st = stickerToDelete {
                Text("确定要删除「\(st.name)」吗？删除后可在拍摄后重新预设。")
            }
        }
    }

    // MARK: 选择已有 - 底部固定关闭按钮
    private var libraryCloseBar: some View {
        Button {
            closeAction()
        } label: {
            HStack(spacing: 8) {
                XIcon()
                    .stroke(CameraPageTokens.foregroundMuted,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 18, height: 18)
                Text("关闭")
                    .font(CameraPageTokens.font(CameraPageTokens.fsBase, .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.systemGray5))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.systemGray4), lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: 横向滚动份数选择条（1~5 份）
    @ViewBuilder
    private func servingPicker(for sticker: FoodSticker) -> some View {
        VStack(spacing: 10) {
            Text("「\(sticker.name)」选择份数")
                .font(CameraPageTokens.font(CameraPageTokens.fsSm, .medium))
                .foregroundColor(CameraPageTokens.foreground)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(1...5, id: \.self) { n in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { selectedServings = n }
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(n)份")
                                    .font(CameraPageTokens.font(16, .semibold))
                                Text("\(sticker.cal * n) kcal")
                                    .font(CameraPageTokens.font(CameraPageTokens.fsXs, .regular))
                                    .foregroundColor(CameraPageTokens.foregroundMuted)
                            }
                            .frame(width: 64, height: 56)
                            .background(selectedServings == n
                                        ? CameraPageTokens.primary.opacity(0.15)
                                        : Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                     .stroke(selectedServings == n
                                             ? CameraPageTokens.primary
                                             : Color.clear, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { servingTarget = nil }
                } label: {
                    Text("取消")
                        .font(CameraPageTokens.font(CameraPageTokens.fsSm, .medium))
                        .foregroundColor(CameraPageTokens.foregroundMuted)
                        .padding(.horizontal, 24).padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Button {
                    let item = LibraryPendingItem(sticker: sticker, servings: selectedServings)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pendingItems.append(item)
                        servingTarget = nil
                    }
                } label: {
                    Text("确认添加")
                        .font(CameraPageTokens.font(CameraPageTokens.fsSm, .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24).padding(.vertical, 10)
                        .background(CameraPageTokens.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: 待提交列表 + 统一提交按钮
    private var pendingList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("待提交（\(pendingItems.count)项）")
                .font(CameraPageTokens.font(CameraPageTokens.fsSm, .semibold))
                .foregroundColor(CameraPageTokens.foreground)
            ForEach(Array(pendingItems.enumerated()), id: \.element.id) { idx, item in
                HStack(spacing: 10) {
                    StickerImageView(sticker: item.sticker, contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.sticker.name)
                            .font(CameraPageTokens.font(CameraPageTokens.fsSm, .medium))
                            .foregroundColor(CameraPageTokens.foreground)
                        Text("×\(item.servings)份  \(item.sticker.cal * item.servings) kcal")
                            .font(CameraPageTokens.font(CameraPageTokens.fsXs, .regular))
                            .foregroundColor(CameraPageTokens.foregroundMuted)
                    }
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            pendingItems.remove(atOffsets: IndexSet(integer: idx))
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(.systemGray3))
                            .font(.title3)
                    }
                }
            }
            Button {
                submitLibraryItems()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("统一提交")
                }
                .font(CameraPageTokens.font(CameraPageTokens.fsBase, .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(CameraPageTokens.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    /// 统一提交：将待提交项逐条写入胃袋记录，并清空列表
    private func submitLibraryItems() {
        let count = pendingItems.count
        for item in pendingItems {
            let s = item.sticker
            // 图片数据：优先用 uiImage（拍照/抠图结果），否则从 bundle 加载预设图片
            let imgData: Data? = {
                if let ui = s.uiImage { return ui.pngData() }
                if !s.imageName.isEmpty { return UIImage(named: s.imageName)?.pngData() }
                return nil
            }()
            AppDataStore.shared.addRecord(DailyRecord(
                type: .food,
                name: s.name,
                calories: s.cal * item.servings,
                amount: Double(item.servings),
                imageData: imgData,
                protein: s.protein,
                carbs: s.carbs,
                fat: s.fat,
                fiber: s.fiber,
                sugar: s.sugar,
                salt: s.salt,
                tip: s.tip))
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            pendingItems.removeAll()
        }
        showToast("已记录 \(count) 项")
    }

    // MARK: 顶部任务队列缩略图
    private var taskQueue: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 10
            let maxCount = 5
            let total = geo.size.width
            // 最多 5 个：按当前可用宽度平均分配单格宽度（上限 64，留 16pt 给白边+阴影）
            let cell = min((total - spacing * CGFloat(maxCount - 1)) / CGFloat(maxCount), 64)
            HStack(spacing: spacing) {
                ForEach(store.tasks) { task in
                    Button { openFoodStickerResult(task: task) } label: {
                        thumbnailCell(task: task, size: cell)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale(scale: 1.6).combined(with: .opacity))
                }
            }
            .frame(width: total, height: 80, alignment: .leading)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: store.tasks.count)
        }
    }

    /// 缩略方块：正方形 + 圆角 + 边框 + 阴影
    /// - 处理中：白透明蒙版（不灰显、无文字），边框为白色；
    /// - 完成：蒙版消失，图片即为卡通贴纸，边框转为绿色（与快门同款）。
    @ViewBuilder
    private func thumbnailCell(task: CaptureTask, size: CGFloat) -> some View {
        let r: CGFloat = 16
        let border: CGFloat = 4
        let done = task.status != .processing
        Image(uiImage: task.preview)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: r))
            .overlay(RoundedRectangle(cornerRadius: r)
                     .stroke(done ? CameraPageTokens.primary : Color.white, lineWidth: border))
            // 处理中：白透明蒙版；完成后 opacity=0 自动消失
            .overlay(RoundedRectangle(cornerRadius: r)
                     .fill(Color.white.opacity(task.status == .processing ? 0.5 : 0)))
            .overlay(alignment: .topTrailing) {
                if task.status == .logged {
                    Text("胃袋")
                        .font(CameraPageTokens.font(8, .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4).padding(.vertical, 2)
                        .background(CameraPageTokens.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(2)
                }
            }
            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }

    // MARK: - 业务逻辑

    private func closeAction() {
        if let onClose { onClose() } else { nav?.dismiss(animated: true) }
    }

    private func triggerFlash() {
        flashKey = (flashKey == Int.max) ? 1 : flashKey + 1
    }

    private func showToast(_ msg: String) {
        toast = msg
        toastWork?.cancel()
        let work = DispatchWorkItem { toast = nil }
        toastWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: work)
    }

    /// 拍摄：立即入队（灰显+识别中），再异步执行后台流水线
    private func capture() {
        guard store.canAddMore() else { showLimit = true; return }
        guard !camera.isSimulator else {
            showToast("模拟器不支持拍摄，请在真机上使用"); return
        }
        guard camera.isAuthorized else {
            showToast("请先在「设置」中允许访问相机"); return
        }
        let id = Int(Date().timeIntervalSince1970 * 1000)
        let task = CaptureTask(
            id: id, sourceImage: UIImage(), preview: UIImage(), status: .processing,
            name: "识别中…", kcal100g: 0, proteinG: 0, carbG: 0, fatG: 0,
            typicalG: 100, portionG: nil, grams: 100,
            stickerImage: nil, isPreset: false, error: nil)
        store.add(task)
        triggerFlash()
        camera.capturePhoto { image in
            DispatchQueue.main.async {
                guard let image else {
                    self.store.update(id) { $0.status = .done; $0.error = "拍摄失败，请重试" }
                    return
                }
                self.store.update(id) { $0.sourceImage = image; $0.preview = image }
                self.runPipeline(id: id, image: image)
            }
        }
    }

    /// 相册选图：同样入队异步处理
    private func runPipelineForImage(_ img: UIImage) {
        guard store.canAddMore() else { showLimit = true; return }
        let id = Int(Date().timeIntervalSince1970 * 1000)
        let task = CaptureTask(
            id: id, sourceImage: img, preview: img, status: .processing,
            name: "识别中…", kcal100g: 0, proteinG: 0, carbG: 0, fatG: 0,
            typicalG: 100, portionG: nil, grams: 100,
            stickerImage: nil, isPreset: false, error: nil)
        store.add(task)
        runPipeline(id: id, image: img)
    }

    /// 后台流水线：复用「老模块」FoodStickerCaptureProcessor
    /// （VisionSegmentationHelper 抠图 + EmojiStickerGenerator 火山方舟图生图生成卡通贴纸
    ///  + FoodNutritionService 云端营养），一次完成贴纸与完整营养识别并写入 CaptureTask 缓存，
    ///  详情页直接复用缓存，避免重复请求模型。
    private func runPipeline(id: Int, image: UIImage) {
        guard let _ = image.cgImage else {
            store.update(id) { $0.status = .done; $0.error = "图片无效" }
            return
        }
        let store = self.store
        Task.detached(priority: .userInitiated) {
            FoodStickerCaptureProcessor.shared.processCapture(
                originalImage: image,
                onPreviewReady: { preview in
                    Task { @MainActor in
                        store.update(id) { $0.preview = preview; $0.stickerImage = preview }
                    }
                },
                onNutritionReady: { nutrition in
                    // 营养识别完成即写回，独立于贴纸图生成，确保详情页快速回显
                    Task { @MainActor in
                        store.update(id) { t in
                            if let n = nutrition {
                                t.name = n.foodName
                                t.kcal100g = n.calories
                                t.proteinG = n.protein
                                t.carbG = n.carbohydrate
                                t.fatG = n.fat
                                t.cloudNutrition = n
                            }
                        }
                    }
                },
                onFinalResult: { sticker, nutrition, error in
                    Task { @MainActor in
                        store.update(id) { t in
                            if let s = sticker { t.preview = s; t.stickerImage = s }
                            // cloudNutrition 已由 onNutritionReady 写入，这里兜底补写
                            if let n = nutrition, t.cloudNutrition == nil {
                                t.cloudNutrition = n
                            }
                            t.cloudError = error
                            t.cloudDone = true
                            t.status = .done
                            if t.name.isEmpty && t.cloudError == nil { t.name = "未知食物" }
                        }
                    }
                }
            )
        }
    }
}

// MARK: - 拍摄详情页（任意状态可查看，确认下一步操作）

struct CaptureDetailSheet: View {
    let taskID: Int
    @ObservedObject private var store = CaptureStore.shared
    @Environment(\.dismiss) private var dismiss

    private var task: CaptureTask? { store.tasks.first { $0.id == taskID } }

    var body: some View {
        NavigationStack {
            Group {
                if let t = task {
                    ScrollView {
                        VStack(spacing: 20) {
                            previewBlock(t)
                            nameField
                            if t.status == .processing {
                                HStack(spacing: 10) {
                                    AnalyzingSpinner()
                                    Text("正在抠图与识别…")
                                        .font(CameraPageTokens.font(CameraPageTokens.fsSm, .regular))
                                        .foregroundColor(CameraPageTokens.foregroundMuted)
                                }
                                .padding(.vertical, 8)
                            } else {
                                nutritionBlock(t)
                                gramsBlock
                            }
                            if let err = t.error {
                                Text(err)
                                    .font(CameraPageTokens.font(CameraPageTokens.fsSm, .regular))
                                    .foregroundColor(CameraPageTokens.error)
                            }
                            actionButtons(t)
                        }
                        .padding(24)
                    }
                } else {
                    Text("任务不存在或已删除")
                        .foregroundColor(CameraPageTokens.foregroundMuted)
                        .padding(40)
                }
            }
            .navigationTitle("拍摄详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func previewBlock(_ t: CaptureTask) -> some View {
        Image(uiImage: t.preview)
            .resizable().scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: 240)
            .background(Color(hex: "#F2F2F2"))
            .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rLg))
    }

    private var nameField: some View {
        TextField("食物名称", text: Binding(
            get: { store.tasks.first(where: { $0.id == taskID })?.name ?? "" },
            set: { newValue in store.update(taskID) { $0.name = newValue } }
        ))
        .font(CameraPageTokens.font(CameraPageTokens.fsLg, .medium))
        .padding(12)
        .background(CameraPageTokens.card)
        .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rMd))
        .onSubmit { commitName() }
    }

    private func commitName() {
        guard let t = task else { return }
        let n = t.name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }
        if let info = NutritionDB.shared.search(name: n) {
            let (kc, pr, cb, ft, tg, pg, gr) = (
                info.kcal100g, info.proteinG, info.carbG, info.fatG,
                info.typicalG, info.portionG, info.portionG ?? info.typicalG
            )
            store.update(taskID) {
                $0.kcal100g = kc
                $0.proteinG = pr
                $0.carbG = cb
                $0.fatG = ft
                $0.typicalG = tg
                $0.portionG = pg
                $0.grams = gr
            }
        }
    }

    private func nutritionBlock(_ t: CaptureTask) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(t.name)
                    .font(CameraPageTokens.font(CameraPageTokens.fsLg, .semibold))
                    .foregroundColor(CameraPageTokens.foreground)
                Spacer()
                if t.status == .logged {
                    Text("已记录")
                        .font(CameraPageTokens.font(CameraPageTokens.fsXs, .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(CameraPageTokens.success)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            HStack(spacing: 8) {
                NutriCell(title: "热量", value: "\(t.caloriesNow)", unit: "kcal")
                NutriCell(title: "蛋白", value: String(format: "%.1f", t.proteinG * t.grams / 100), unit: "g")
                NutriCell(title: "碳水", value: String(format: "%.1f", t.carbG * t.grams / 100), unit: "g")
                NutriCell(title: "脂肪", value: String(format: "%.1f", t.fatG * t.grams / 100), unit: "g")
            }
        }
    }

    private var gramsBlock: some View {
        let g = store.tasks.first(where: { $0.id == taskID })?.grams ?? 100
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("份量")
                    .font(CameraPageTokens.font(CameraPageTokens.fsSm, .medium))
                    .foregroundColor(CameraPageTokens.foregroundMuted)
                Spacer()
                Text("\(Int(g)) g")
                    .font(CameraPageTokens.font(CameraPageTokens.fsBase, .semibold))
                    .foregroundColor(CameraPageTokens.primary)
            }
            Slider(value: Binding(
                get: { store.tasks.first(where: { $0.id == taskID })?.grams ?? 100 },
                set: { newValue in store.update(taskID) { $0.grams = newValue } }
            ), in: 50...300, step: 50)
            .accentColor(CameraPageTokens.primary)
        }
    }

    private func actionButtons(_ t: CaptureTask) -> some View {
        VStack(spacing: 12) {
            if t.status != .processing {
                Button { recordToStomach(t) } label: {
                    Text("记录到胃袋")
                        .frame(maxWidth: .infinity).frame(height: CameraPageTokens.actionHeight)
                        .background(CameraPageTokens.primary).foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rMd))
                }
                .scaleButton()

                Button { recordAndPreset(t) } label: {
                    Text("记录并预设")
                        .frame(maxWidth: .infinity).frame(height: CameraPageTokens.actionHeight)
                        .background(CameraPageTokens.card).foregroundColor(CameraPageTokens.primary)
                        .overlay(RoundedRectangle(cornerRadius: CameraPageTokens.rMd)
                            .stroke(CameraPageTokens.primary, lineWidth: 1.5))
                        .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rMd))
                }
                .scaleButton()
            }

            Button { deleteTask() } label: {
                Text("删除任务")
                    .frame(maxWidth: .infinity).frame(height: CameraPageTokens.actionHeight)
                    .foregroundColor(CameraPageTokens.error)
                    .overlay(RoundedRectangle(cornerRadius: CameraPageTokens.rMd)
                        .stroke(CameraPageTokens.error.opacity(0.5), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rMd))
            }
            .scaleButton()
        }
    }

    private func recordToStomach(_ t: CaptureTask) {
        let n = t.cloudNutrition
        let imageData = t.stickerImage?.pngData()
        let ratio = t.grams / 100.0
        AppDataStore.shared.addRecord(DailyRecord(type: .food, name: t.name,
            calories: t.caloriesNow, amount: t.grams, imageData: imageData,
            protein: Int(round(t.proteinG * ratio)),
            carbs: Int(round(t.carbG * ratio)),
            fat: Int(round(t.fatG * ratio)),
            fiber: Int(round((n?.dietaryFiber ?? 0) * ratio)),
            sugar: 0,
            salt: (n?.sodium ?? 0) / 1000,
            tip: n?.vitaminTips ?? ""))
        store.update(taskID) { $0.status = .logged }
        dismiss()
    }

    private func recordAndPreset(_ t: CaptureTask) {
        let stickerImage = t.stickerImage
        let imageData = stickerImage?.pngData()
        let ratio = t.grams / 100.0
        let n = t.cloudNutrition
        let protein = Int(round(t.proteinG * ratio))
        let carbs = Int(round(t.carbG * ratio))
        let fat = Int(round(t.fatG * ratio))
        let fiber = Int(round((n?.dietaryFiber ?? 0) * ratio))
        let salt = (n?.sodium ?? 0) / 1000
        let tip = n?.vitaminTips ?? ""
        // 写入今日记录（含图片、完整营养成分，确保回显完整）
        AppDataStore.shared.addRecord(DailyRecord(type: .food, name: t.name,
            calories: t.caloriesNow, amount: t.grams, imageData: imageData,
            protein: protein, carbs: carbs, fat: fat,
            fiber: fiber, sugar: 0, salt: salt, tip: tip))
        AppDataStore.shared.addSavedSticker(FoodSticker(
            imageName: "", uiImage: stickerImage, name: t.name, cal: t.caloriesNow,
            date: todayDate(), time: nowTime(),
            protein: protein, carbs: carbs, fat: fat,
            fiber: fiber, sugar: 0, salt: salt, tip: tip))
        store.update(taskID) { $0.status = .logged }
        dismiss()
    }

    private func deleteTask() {
        store.remove(taskID)
        dismiss()
    }
}

private struct NutriCell: View {
    let title: String; let value: String; let unit: String
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(CameraPageTokens.font(CameraPageTokens.fsXs, .regular))
                .foregroundColor(CameraPageTokens.foregroundSubtle)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(CameraPageTokens.font(CameraPageTokens.fsBase, .semibold))
                    .foregroundColor(CameraPageTokens.foreground)
                Text(unit)
                    .font(CameraPageTokens.font(CameraPageTokens.fsXs, .regular))
                    .foregroundColor(CameraPageTokens.foregroundSubtle)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(CameraPageTokens.card)
        .clipShape(RoundedRectangle(cornerRadius: CameraPageTokens.rMd))
    }
}

// MARK: - 快门闪烁动效

private struct FlashOverlay: View {
    @State private var opacity: Double = 0.85
    var body: some View {
        Color.white.opacity(opacity)
            .onAppear { withAnimation(.easeOut(duration: 0.35)) { opacity = 0 } }
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

// MARK: - 点击缩放反馈

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

// MARK: - 日期辅助

private func nowTime() -> String {
    let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: Date())
}
private func todayDate() -> String {
    let f = DateFormatter(); f.dateFormat = "MM-dd"; return f.string(from: Date())
}

// MARK: - 模块合并桥接
// 拍摄 / 缩略等交互过程走「新模块」（CameraPage + 队列缩略）；
// 卡通贴纸与营养内容统一复用「老模块」：
//   - 贴纸：FoodStickerCaptureProcessor（VisionSegmentationHelper 抠图 + 火山方舟图生图 EmojiStickerGenerator）；
//   - 营养：火山方舟 FoodNutritionService，拍摄时仅请求一次并缓存，详情页复用，避免重复请求模型。
// 点开缩略图后的「详情页 UI」复用「老模块」FoodStickerResultViewController。

extension UIWindow {
    /// 取当前最上层可见的视图控制器，用于从 SwiftUI 弹出 UIKit 详情页。
    static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            for window in scene.windows where window.isKeyWindow {
                var top = window.rootViewController
                while let presented = top?.presentedViewController { top = presented }
                return top
            }
        }
        return nil
    }
}

/// 用 SwiftUI 详情页展示某次拍摄任务的结果（1:1 还原 Web 端 StickerDetailView）。
/// 仅传入任务 ID，详情页内部实时从 CaptureStore 读取任务状态与营养结果，
/// 杜绝「每点一次缩略图就重复请求一次模型」，并支持生成完成前仅显示关闭/删除。
fileprivate func openFoodStickerResult(task: CaptureTask) {
    let hosting = UIHostingController(
        rootView: StickerResultView(taskID: task.id))
    hosting.modalPresentationStyle = .fullScreen

    if let top = UIWindow.topViewController() {
        top.present(hosting, animated: true)
    }

    // 已缓存云端结果：直接复用，零额外请求
    if task.cloudNutrition != nil { return }
    if task.cloudError != nil { return }

    // cloudDone 但无结果：用已识别的本地面值兜底写回缓存，详情页会自动刷新
    if task.cloudDone {
        let local = FoodNutritionModel(
            foodName: task.name,
            calories: task.kcal100g,
            protein: task.proteinG,
            fat: task.fatG,
            carbohydrate: task.carbG,
            dietaryFiber: 0,
            sodium: 0,
            vitaminTips: "")
        CaptureStore.shared.update(task.id) { t in
            t.cloudNutrition = local
            t.cloudDone = true
        }
        return
    }

    // 极端兜底：用户极快打开、云端尚未回传时，仅请求「一次」并写回缓存；
    // 详情页通过 taskID 实时绑定 CaptureStore，写回后自动刷新，不再重复请求模型。
    if !task.cloudRequested {
        CaptureStore.shared.update(task.id) { $0.cloudRequested = true }
        FoodNutritionService.shared.recognize(image: task.sourceImage) { model, error in
            Task { @MainActor in
                CaptureStore.shared.update(task.id) { t in
                    t.cloudNutrition = model
                    t.cloudError = error
                    t.cloudDone = true
                }
            }
        }
    }
}
