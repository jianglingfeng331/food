//
//  StickerResultView.swift
//  FoodSticker
//
//  拍摄缩略图点开的「详情页」—— 1:1 还原 Web 端 StickerDetailView 的 SwiftUI 重构版。
//  设计令牌（颜色/圆角/字号/间距/阴影）严格对齐 src/index.css :root 与 StickerDetailView.tsx。
//  不引入任何第三方库，图标优先复用工程内 LucideIcons（缺失图标在本文件内补充定义）。
//

import SwiftUI
import UIKit


// MARK: - 异步可变状态容器（引用类型，确保重识别回调能可靠写回并刷新 UI）
/// SwiftUI 的 View 是值类型，异步闭包按值捕获 self 副本，直接修改其中 @State 不会反映到 UI。
/// 因此把「重识别结果 / 初识名称 / 识别中」放在引用类型的 ObservableObject 中，
/// 回调里修改其 @Published 属性即可驱动详情视图刷新。
final class StickerResultState: ObservableObject {
    @Published var manualNutrition: FoodNutritionModel? = nil   // 手动重识别结果，覆盖任务结果
    @Published var originalName: String? = nil                  // 初识（AI 识别）名称，用于"返回初步识别名称"
    @Published var isReanalyzing: Bool = false                 // 名称修改后重新识别中
    @Published var previewImage: UIImage? = nil                // 保存后任务被移除时的兜底展示图
    @Published var saved: Bool = false                         // 是否已保存成功
}


// MARK: - 设计令牌（全部数值集中提取，便于批量修改）

enum SRTheme {
    // MARK: 字体族（对齐 Web :root --font-sans / --font-mono）
    // Web: --font-sans  = -apple-system, "SF Pro Display", "PingFang SC", system-ui, sans-serif
    //      --font-mono  = "SF Mono", "PingFang SC", monospace  (font-number 数字用)
    static let sansFont  = "SF Pro Text"      // 中文/英文/数字统一：SF Pro + PingFang SC
    static let numberFont = "SF Mono"          // 数字（热量/营养值/Kcal）用等宽，对齐 font-number

    // MARK: 颜色（对齐 Web :root）
    static let background       = Color(hex: "#F8FAF8")
    static let surface          = Color(hex: "#FFFFFF")
    static let foreground       = Color(hex: "#1A1A1A")
    static let foregroundMuted  = Color(hex: "#6B7280")
    static let foregroundSubtle = Color(hex: "#9CA3AF")
    static let primary          = Color(hex: "#10B981")
    static let primaryDark      = Color(hex: "#059669")
    static let error            = Color(hex: "#EF4444")
    static let primary10        = Color(hex: "#10B981").opacity(0.10)
    static let primary20        = Color(hex: "#10B981").opacity(0.20)
    static let surfaceBorder    = Color.black.opacity(0.05)

    // MARK: 字号（px，对照 Web Tailwind 尺寸）
    enum Font {
        static let name:         CGFloat = 22
        static let kcalValue:    CGFloat = 28
        static let kcalUnit:     CGFloat = 12
        static let sectionTitle: CGFloat = 16
        static let sectionSub:   CGFloat = 11
        static let nutrientLabel:CGFloat = 12
        static let nutrientValue:CGFloat = 23
        static let nutrientUnit: CGFloat = 12
        static let tipTitle:     CGFloat = 14   // 对齐 Web text-sm
        static let tipBody:      CGFloat = 11   // 对齐 Web text-[11px] leading-4
        static let dateTime:     CGFloat = 12
        static let status:       CGFloat = 12
    }

    // MARK: 圆角
    enum Radius {
        static let stickerImage: CGFloat = 28   // Web rounded-[28px]
        static let card:         CGFloat = 16   // Web rounded-lg
        static let tip:          CGFloat = 18   // Web rounded-[18px]
        static let iconButton:   CGFloat = 24   // 48×48 圆形
        static let titleBar:     CGFloat = 4    // 标题小竖条 w-[4px]
    }

    // MARK: 间距（px，对照 Web Tailwind 间距，严格 1:1）
    enum Space {
        static let pageX:        CGFloat = 20   // px-[20px]
        static let pageY:        CGFloat = 12   // py-[12px]
        static let basicInfoGap: CGFloat = 2    // gap-[2px]
        static let cardPad:      CGFloat = 16   // p-[16px]
        static let cardTitleMB:  CGFloat = 14   // mb-[14px]
        static let gridCellY:    CGFloat = 10   // py-[10px]
        static let tipBodyTop:   CGFloat = 8    // mb-[8px] (标题与正文间距)
        static let dateGap:      CGFloat = 16   // gap-[16px]
        static let dateIconGap:  CGFloat = 4    // gap-[4px]
        static let barPadX:      CGFloat = 20   // px-[20px]
        static let barPadTop:    CGFloat = 2    // pt-[2px]
        static let sectionGap:   CGFloat = 12   // 三大区块之间的统一间距 (Web 内容区 justify-between，等效均匀分布)
    }

    // MARK: 阴影
    enum Shadow {
        // 贴纸大图：0 10px 22px rgba(16,185,129,0.22) → SwiftUI radius = blur/2 = 11
        static let stickerColor = Color(hex: "#10B981").opacity(0.22)
        static let stickerRadius: CGFloat = 11
        static let stickerY:      CGFloat = 10
        // flat-card：0 1px 3px rgba(0,0,0,0.05) → radius = 3/2 = 1.5
        static let cardRadius:    CGFloat = 1.5
        static let cardY:         CGFloat = 1
    }
}

// MARK: - 字体辅助（统一中文/英文/数字，数字用等宽）

extension Font {
    /// 文本字体（中文/英文/数字一致）：SF Pro Text + PingFang SC
    static func srText(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(SRTheme.sansFont, size: size, relativeTo: .body).weight(weight)
    }
    /// 数字字体（等宽，对齐 Web font-number）：SF Mono + PingFang SC
    static func srNumber(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(SRTheme.numberFont, size: size, relativeTo: .body).weight(weight)
    }
}

// MARK: - 详情页主体

struct StickerResultView: View {
    /// 由拍摄页传入的拍摄任务 ID，内部实时读取任务状态与营养结果
    let taskID: Int
    /// 非 nil = 加载模式：进入后立即以该名称重新识别，期间只显示 loading spinner
    var reanalyzeName: String? = nil

    @Environment(\.dismiss) private var dismiss
    @StateObject private var state = StickerResultState()
    @State private var showDeleteConfirm = false
    @State private var showShare = false
    @State private var toast: String? = nil

    @State private var isSaving = false

    // UIHostingController 下 @Published 观察可能失效，用 @State UUID 强制 body 重绘
    @State private var renderToken = UUID()

    private var isAnalyzing: Bool { state.isReanalyzing }

    private var screenH: CGFloat { UIScreen.main.bounds.height }
    private var screenW: CGFloat { UIScreen.main.bounds.width }
    private var contentW: CGFloat { screenW - SRTheme.Space.pageX * 2 }
    // 主图正方形边长：严格对齐 Web StickerDetailView 大图卡片
    // Web: 卡片宽 = 80% × 56vw = 44.8vw，卡片高 = 20svh
    // 取二者较小值，保证正方形且完整落在卡片框内（scaledToFit 居中）
    private var stickerSize: CGFloat { min(screenW * 0.448, screenH * 0.20) }

    /// 当前拍摄任务（实时），找不到则任务已被移除
    private var task: CaptureTask? { CaptureStore.shared.tasks.first { $0.id == taskID } }
    /// 是否已经可以展示内容：有营养结果即可（含手动重识别/已保存落定的数据），
    /// 是否已展示完整识别结果（用于控制底部保存按钮、名称可编辑等）
    private var isReady: Bool { nutrition != nil && !isAnalyzing }
    /// 当前生效的营养结果：手动重识别优先，否则实时取任务结果
    /// （manualNutrition 为 nil 时回退 task.cloudNutrition，保证即使 onAppear/onReceive 未搬入也能展示）
    private var nutrition: FoodNutritionModel? {
        if let m = state.manualNutrition { return m }
        return task?.cloudNutrition
    }
    /// 当前展示用图片：优先成图，其次缩略图/原图；任务被移除（已保存）时回退到缓存图
    private var displayImage: UIImage? {
        if let t = task { return t.stickerImage ?? t.preview ?? t.sourceImage }
        return state.previewImage
    }
    /// 由 createdAt 推导的日期（MM月dd日）与时间（HH:mm）
    private var dateText: String {
        guard let t = task else { return "" }
        let df = DateFormatter(); df.dateFormat = "MM月dd日"; return df.string(from: t.createdAt)
    }
    private var timeText: String {
        guard let t = task else { return "" }
        let df = DateFormatter(); df.dateFormat = "HH:mm"; return df.string(from: t.createdAt)
    }
    private var safeAreaBottom: CGFloat {
        (UIApplication.shared.connectedScenes
            .first { $0 is UIWindowScene } as? UIWindowScene)?
            .windows.first { $0.isKeyWindow }?.safeAreaInsets.bottom ?? 0
    }
    private var bottomBarTotalHeight: CGFloat {
        48 + SRTheme.Space.barPadTop + safeAreaBottom
    }

    var body: some View {
        let _ = renderToken   // 强制依赖 @State，确保 body 响应 renderToken 变更而重绘

        ZStack(alignment: .bottom) {
            SRTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topImageRegion
                contentRegion
            }

            bottomBar
        }
        .alert("删除贴纸", isPresented: $showDeleteConfirm) {
            Button("再想想", role: .cancel) {}
            Button("删除", role: .destructive) { performDelete() }
        } message: {
            Text("删除后该拍摄记录将无法恢复。")
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
        .overlay(alignment: .center) { toastOverlay }
        // 进入详情页：若 cloudNutrition 已就绪则立即搬入置 ready；否则保持 idle 等 onReceive
        .onAppear {
            if state.originalName == nil, let initial = nutrition?.foodName, !initial.isEmpty {
                state.originalName = initial
            }
            // 加载模式：立即启动重识别 API
            if let name = reanalyzeName {
                startReanalyze(name: name)
            }
        }
        // 订阅 CaptureStore.tasks 变更：capture 后台完成 / reanalyze 回写后刷新 body
        // （nutrition 计算属性实时读 task.cloudNutrition，tasks 变化即触发重绘）
        .onReceive(CaptureStore.shared.$tasks) { _ in
            // 仅在非重识别中时同步 initialName
            if state.originalName == nil, let initial = nutrition?.foodName, !initial.isEmpty {
                state.originalName = initial
            }
        }
    }

    // MARK: 顶部贴纸大图区（正方形，不顶格，对齐 Web 渐变白→背景）

    private var topImageRegion: some View {
        ZStack {
            // 与中间内容区同色背景，消除顶部与中间的视觉分割，融为一体
            SRTheme.background

            if let img = displayImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: stickerSize, height: stickerSize)  // 正方形，参考 iOS 端尺寸
                    .clipShape(RoundedRectangle(cornerRadius: SRTheme.Radius.stickerImage))
                    .overlay(RoundedRectangle(cornerRadius: SRTheme.Radius.stickerImage)
                        .stroke(Color.white, lineWidth: 5))
                    .shadow(color: SRTheme.Shadow.stickerColor,
                            radius: SRTheme.Shadow.stickerRadius,
                            y: SRTheme.Shadow.stickerY)
                    .opacity((task?.status == .processing || isAnalyzing) ? 0.6 : 1)   // 生成中弱显
            } else {
                RoundedRectangle(cornerRadius: SRTheme.Radius.stickerImage)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: stickerSize, height: stickerSize)
            }
        }
        .frame(height: screenH * 0.32)   // 对齐 Web 大图区 height:32svh
        // 取消额外 top padding：Web 中图片垂直居中于 32svh 渐变区，无额外顶白
    }

    // MARK: 内容区（固定单屏，不滚动，对齐 Web px-20 py-12 + justify-between）

    private var contentRegion: some View {
        VStack(alignment: .center, spacing: 20) {   // 各区块之间统一 20pt 间距
            if reanalyzeName != nil {
                // 名称编辑后重新识别中：全内容替换为转圈 loading
                Spacer(minLength: 0)
                ProgressView()
                    .scaleEffect(1.8)
                    .tint(SRTheme.primary)
                Spacer().frame(height: 12)
                Text("识别生成中…")
                    .font(.srText(SRTheme.Font.status))
                    .foregroundColor(SRTheme.foregroundMuted)
                Spacer(minLength: 0)
            } else if isAnalyzing {
                // 重识别进行中：明确展示「识别生成中」加载态（仅图片 + 关闭/删除在底部）
                Spacer(minLength: 0)
                ProgressView("识别生成中…")
                    .font(.srText(SRTheme.Font.status))
                    .foregroundColor(SRTheme.foregroundMuted)
                Spacer(minLength: 0)
            } else if let n = nutrition {
                basicInfo
                nutrientCard
                tipCard
                dateTimeRow
            } else {
                // 初始加载中 / 识别失败
                Spacer(minLength: 0)
                if let err = task?.cloudError {
                    Text(String(describing: err))
                        .font(.srText(SRTheme.Font.status))
                        .foregroundColor(SRTheme.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                } else {
                    ProgressView("识别生成中…")
                        .font(.srText(SRTheme.Font.status))
                        .foregroundColor(SRTheme.foregroundMuted)
                }
                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, SRTheme.Space.pageX)
        .padding(.top, SRTheme.Space.pageY)   // 对齐 Web py-[12px]
        .padding(.bottom, bottomBarTotalHeight)
    }

    private var basicInfo: some View {
        let name = nutrition?.foodName ?? task?.name ?? ""
        let kcal = Int(round(nutrition?.calories ?? 0))
        return VStack(alignment: .center, spacing: SRTheme.Space.basicInfoGap) {
            // 食物名称：生成完成后可点击进入手动编辑
            Button {
                guard isReady else { return }
                showEditAlert(currentName: name)
            } label: {
                HStack(spacing: 4) {
                    Text(name)
                        .font(.srText(SRTheme.Font.name, weight: .bold))
                        .foregroundColor(SRTheme.foreground)
                        .multilineTextAlignment(.center)
                    if isReady {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(SRTheme.foregroundSubtle)
                    }
                }
            }
            .disabled(!isReady)
            // 返回初步识别名称：手动改名且不同于初识名时显示
            if let orig = state.originalName, orig != name {
                Button {
                    revertToOriginalName()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 11, weight: .medium))
                        Text("返回初步识别名称：\(orig)")
                            .font(.srText(11, weight: .medium))
                    }
                    .foregroundColor(SRTheme.primary)
                }
                .padding(.top, 2)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(kcal)")
                    .font(.srNumber(SRTheme.Font.kcalValue, weight: .bold))
                    .foregroundColor(SRTheme.primary)
                Text("Kcal")
                    .font(.srText(SRTheme.Font.kcalUnit))
                    .foregroundColor(SRTheme.foregroundSubtle)
            }
        }
    }

    // MARK: 营养卡片

    private var nutrientCard: some View {
        let n = nutrition
        let items: [(String, Int)] = [
            ("碳水", Int(round(n?.carbohydrate ?? 0))),
            ("蛋白质", Int(round(n?.protein ?? 0))),
            ("脂肪", Int(round(n?.fat ?? 0))),
            ("膳食纤维", Int(round(n?.dietaryFiber ?? 0))),
            ("糖", 0),   // 模型未返回 sugar，预留位
            ("盐", Int(round((n?.sodium ?? 0) / 1000))),   // mg → g
        ]
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(CardTokens.Color.primary)
                    .frame(width: 4, height: 15)
                Text("营养成分")
                    .font(.app(size: CardTokens.FontSize.lg, weight: .bold))
                    .foregroundColor(CardTokens.Color.foreground)
                Text("/ 每份")
                    .font(.app(size: CardTokens.FontSize.xs))
                    .foregroundColor(CardTokens.Color.foregroundSubtle)
            }
            .padding(.bottom, 12)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 3),
                      spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    nutrientCell(label: item.0, value: item.1,
                                 left: i % 3 != 0, top: i >= 3)
                }
            }
        }
        .padding(SRTheme.Space.cardPad)
        .background(SRTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: SRTheme.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: SRTheme.Radius.card)
            .stroke(SRTheme.surfaceBorder, lineWidth: 1))
        .shadow(color: .black.opacity(0.05),
                radius: SRTheme.Shadow.cardRadius,
                y: SRTheme.Shadow.cardY)
    }

    private func nutrientCell(label: String, value: Int, left: Bool, top: Bool) -> some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.app(size: CardTokens.FontSize.caption))
                .foregroundColor(CardTokens.Color.foregroundMuted)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.app(size: CardTokens.FontSize.nutrientValue, weight: .bold))
                    .foregroundColor(CardTokens.Color.primary)
                Text("g")
                    .font(.app(size: CardTokens.FontSize.caption))
                    .foregroundColor(CardTokens.Color.foregroundSubtle)
            }
            .lineLimit(1)
            .fixedSize()
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .overlay(alignment: .leading) {
            if left {
                Rectangle().fill(Color.black.opacity(0.05))
                    .frame(width: 0.5).frame(maxHeight: .infinity)
                    .padding(.vertical, 6)
            }
        }
        .overlay(alignment: .top) {
            if top {
                Rectangle().fill(Color.black.opacity(0.05))
                    .frame(height: 0.5).frame(maxWidth: .infinity)
                    .padding(.horizontal, 6)
            }
        }
    }

    // MARK: 小贴士卡

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.app(size: 18))
                    .foregroundColor(CardTokens.Color.primary)
                Text("小贴士")
                    .font(.app(size: CardTokens.FontSize.lg, weight: .bold))
                    .foregroundColor(CardTokens.Color.primary)
            }
            Text(nutrition?.vitaminTips ?? "")
                .font(.app(size: CardTokens.FontSize.base))
                .foregroundColor(CardTokens.Color.foreground)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(SRTheme.Space.cardPad)
        .background(SRTheme.primary10)
        .clipShape(RoundedRectangle(cornerRadius: SRTheme.Radius.tip))
        .overlay(RoundedRectangle(cornerRadius: SRTheme.Radius.tip)
            .stroke(SRTheme.primary20, lineWidth: 1))
    }

    // MARK: 日期时间行

    private var dateTimeRow: some View {
        let date = dateText
        let time = timeText
        return HStack(spacing: SRTheme.Space.dateGap) {
            HStack(spacing: SRTheme.Space.dateIconGap) {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(SRTheme.foregroundMuted)
                Text(date)
                    .font(.srText(SRTheme.Font.dateTime))
                    .foregroundColor(SRTheme.foregroundMuted)
            }
            Circle()
                .fill(SRTheme.foregroundSubtle.opacity(0.5))
                .frame(width: 3, height: 3)
            HStack(spacing: SRTheme.Space.dateIconGap) {
                Image(systemName: "clock")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(SRTheme.foregroundMuted)
                Text(time)
                    .font(.srText(SRTheme.Font.dateTime))
                    .foregroundColor(SRTheme.foregroundMuted)
            }
        }
    }

    // MARK: 底部操作栏
    // 生成过程中仅显示「关闭」与「删除」；
    // 全部内容生成完毕后，四个按钮（关闭、删除、保存、保存并预设）才完整显示。

    private var bottomBar: some View {
        HStack(spacing: 28) {   // 按钮之间固定 28pt 间距，紧凑
            iconButton(icon: XIcon(), color: SRTheme.foregroundMuted) { closeSelf() }
            iconButton(icon: Trash2Icon(), color: SRTheme.error) { showDeleteConfirm = true }
            // 重新识别中：保存/预设按钮半透明，点击提示稍候；关闭/删除正常使用
            if reanalyzeName != nil {
                iconButton(icon: DownloadIcon(), color: SRTheme.primary.opacity(0.35)) { showWaitAlert() }
                iconButton(icon: BookmarkIcon(), color: SRTheme.primary.opacity(0.35)) { showWaitAlert() }
            } else if isReady {
                iconButton(icon: DownloadIcon(), color: SRTheme.primary) { saveToList() }       // 保存到今日贴纸列表 + 胃袋
                iconButton(icon: BookmarkIcon(), color: SRTheme.primary) { savePreset() }       // 保存并预设
            }
        }
        .padding(.horizontal, SRTheme.Space.barPadX)
        .padding(.top, SRTheme.Space.barPadTop)
        .padding(.bottom, safeAreaBottom + 4)
        .frame(maxWidth: .infinity)
        .background(SRTheme.background)
        .zIndex(1)   // 确保固定在底部、不被内容区遮挡，按钮可点击
    }

    private func iconButton<Icon: Shape>(icon: Icon,
                                         color: Color = SRTheme.primary,
                                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            icon
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 24, height: 24)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
                .contentShape(Circle())
        }
        .buttonStyle(PressFillStyle(fill: color.opacity(0.22)))
    }

    /// 按下时背景明显变深，让"点上去有没有效果"一目了然
    private struct PressFillStyle: ButtonStyle {
        let fill: Color
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .overlay(
                    Circle().fill(fill).opacity(configuration.isPressed ? 1 : 0)
                )
                .scaleEffect(configuration.isPressed ? 0.92 : 1)
                .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
        }
    }

    // MARK: 行为

    // 该页面由 UIKit 以 fullScreen modal（present）方式弹出，
    // SwiftUI 的 @Environment(\.dismiss) 在此场景下无效，
    // 必须通过 UIKit 关闭宿主 UIHostingController。
    private func closeSelf() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = scene.windows.first(where: { $0.isKeyWindow }) {
            var top = window.rootViewController
            while let presented = top?.presentedViewController { top = presented }
            top?.dismiss(animated: true)
        }
    }

    private func performDelete() {
        CaptureStore.shared.remove(taskID)
        showToast("已删除该记录")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { closeSelf() }
    }

    /// 根据当前生效营养结果（手动改名后 = 重识别结果）构造贴纸对象
    private func buildSticker(per100: Bool) -> FoodSticker {
        let n = nutrition
        let name = n?.foodName ?? task?.name ?? ""
        // 保存并预设按 100g 计热量；保存到今日按当前识别份热量
        let cal: Int = per100
            ? Int(round(n?.calories ?? 0))
            : (task?.caloriesNow ?? Int(round(n?.calories ?? 0)))
        return FoodSticker(imageName: "",
                           uiImage: displayImage,
                           name: name,
                           cal: cal,
                           date: dateText,
                           time: timeText,
                           protein: Int(round(n?.protein ?? 0)),
                           carbs: Int(round(n?.carbohydrate ?? 0)),
                           fat: Int(round(n?.fat ?? 0)),
                           fiber: Int(round(n?.dietaryFiber ?? 0)),
                           sugar: 0,
                           salt: (n?.sodium ?? 0) / 1000,   // mg → g
                           tip: n?.vitaminTips ?? "")
    }

    /// 保存／保存并预设的公共落地逻辑
    /// - preset: true 时额外把食物写入「选择已有」默认列表（savedStickers）
    /// 行为：
    ///   1) 把当前最终识别结果（手动改名/重识别后的 manualNutrition 优先）落定为权威数据，
    ///      写回拍摄任务的 cloudNutrition，确保重开详情也是最新；并同步更新任务名称。
    ///   2) 写入「今日记录 / 胃袋」（todayRecords），可点开查看详情（含图）。
    ///   3) preset=true 时再写入「我的贴纸 / 预设」列表（savedStickers）。
    ///   4) 拍摄页缩略图自动消失；页面不关闭，立即回显最新修改后的数据（覆盖原有内容）。
    private func commitSave(preset: Bool) {
        guard isReady, isSaving == false else { return }
        isSaving = true
        defer { isSaving = false }

        let finalNutrition = nutrition
        let name = finalNutrition?.foodName ?? task?.name ?? ""
        let sticker = buildSticker(per100: preset)

        // 1) 缓存展示图（task 即将被移除），并把最新结果落定到任务
        state.previewImage = displayImage
        CaptureStore.shared.update(taskID) { t in
            if let n = finalNutrition { t.cloudNutrition = n }
            t.name = name
        }

        // 2) 写入「今日记录 / 胃袋」（可点开查看详情）
        AppDataStore.shared.addRecord(DailyRecord(
            type: .food,
            name: sticker.name,
            calories: sticker.cal,
            amount: Double(task?.grams ?? 100)))

        // 3) 仅「保存并预设」才进入预设列表，避免「保存」误存到预设
        if preset {
            AppDataStore.shared.addSavedSticker(sticker)
        }

        // 4) 将最终营养数据缓存到 state（remove 后 task 为 nil，nutrition 需要回退源）
        state.manualNutrition = finalNutrition

        // 5) 缩略图消失；详情页停留并立即回显最新数据（已保存）
        state.saved = true
        CaptureStore.shared.remove(taskID)
        showToast(preset ? "已保存并加入预设，可在「选择已有」选用" : "已保存到今日贴纸与胃袋")

        // 6) 关闭页面回到拍摄页：本页由 UIKit 以 fullScreen modal present，
        //    @Environment(.dismiss) 无效，必须用 UIKit 的 closeSelf() 关闭宿主控制器，
        //    使底层 Tab 在重新出现时 viewWillAppear 触发 → 刷新今日记录/大胃袋
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.closeSelf()
        }
    }

    /// 保存：记录到「今日贴纸列表」+「胃袋」，但不写入预设
    private func saveToList() { commitSave(preset: false) }

    /// 保存并预设：在保存基础上，将该食物纳入「选择已有」默认食物列表（savedStickers）
    private func savePreset() { commitSave(preset: true) }

    // MARK: 名称手动编辑 + 重识别

    private func revertToOriginalName() {
        guard let orig = state.originalName else { return }
        transitionToLoading(name: orig)
    }

    /// 从当前普通页 → 关闭 → present 加载页（加载页在 onAppear 中启动 API）
    private func transitionToLoading(name: String) {
        guard let currentVC = topMostViewController() else { return }
        let parentVC = currentVC.presentingViewController
        currentVC.dismiss(animated: false) {
            let loadVC = UIHostingController(
                rootView: StickerResultView(taskID: self.taskID, reanalyzeName: name)
            )
            loadVC.modalPresentationStyle = .fullScreen
            parentVC?.present(loadVC, animated: false)
        }
    }

    /// 加载模式下（reanalyzeName != nil）由 onAppear 调用，启动重识别 API
    /// API 回调后 dismiss 加载页 → present 结果页
    private func startReanalyze(name: String) {
        print("[StickerResultView] startReanalyze, name=\(name)")
        FoodNutritionService.shared.analyzeByName(name) { result, _ in
            DispatchQueue.main.async {
                print("[StickerResultView] startReanalyze 回调, result=\(result?.foodName ?? "nil")")
                if let result = result {
                    CaptureStore.shared.update(self.taskID) { t in t.cloudNutrition = result }
                }
                // dismiss 加载页 → present 全新结果页
                guard let loadVC = self.topMostViewController() else { return }
                let parentVC = loadVC.presentingViewController
                loadVC.dismiss(animated: false) {
                    let resultVC = UIHostingController(
                        rootView: StickerResultView(taskID: self.taskID)
                    )
                    resultVC.modalPresentationStyle = .fullScreen
                    parentVC?.present(resultVC, animated: false)
                }
            }
        }
    }

    /// 用 UIAlertController 显示错误提示（取代不工作的 SwiftUI toast）
    private func showErrorAlert(_ msg: String) {
        guard let vc = topMostViewController() else { return }
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        vc.present(alert, animated: true)
    }

    /// 加载模式下提示用户稍候
    private func showWaitAlert() {
        guard let vc = topMostViewController() else { return }
        let alert = UIAlertController(title: nil, message: "正在重新识别，请稍候…", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        vc.present(alert, animated: true)
    }

    /// 使用 UIKit UIAlertController 做名称编辑弹窗
    private func showEditAlert(currentName: String) {
        guard let currentVC = topMostViewController() else { return }
        let alert = UIAlertController(
            title: "修改食物名称",
            message: "编辑后将以该名称重新识别热量、营养成分与贴士。",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.text = currentName
            tf.placeholder = "请输入正确的食物名称"
            tf.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            self.transitionToLoading(name: name)
        })
        currentVC.present(alert, animated: true)
    }

    /// 查找当前最顶层的 UIViewController
    private func topMostViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              var top = window.rootViewController else { return nil }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    private var shareItems: [Any] {
        var items: [Any] = []
        if let img = displayImage { items.append(img) }
        let name = nutrition?.foodName ?? task?.name ?? ""
        let kcal = Int(round(nutrition?.calories ?? 0))
        items.append("\(name) · \(kcal) Kcal")
        return items
    }

    // MARK: Toast

    @ViewBuilder private var toastOverlay: some View {
        if let msg = toast {
            Text(msg)
                .font(.srText(SRTheme.Font.status))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.85))
                .cornerRadius(10)
                .animation(.easeInOut, value: toast)
        }
    }

    private func showToast(_ msg: String) {
        toast = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if toast == msg { toast = nil }
        }
    }
}

// MARK: - iOS 原生分享面板（替代 Web navigator.share）

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - 补充 Lucide 图标（工程内缺失，按 lucide-react 精确路径定义）

public struct Trash2Icon: Shape {
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 3, y: 6));  p.addLine(to: CGPoint(x: 21, y: 6))
        p.move(to: CGPoint(x: 19, y: 6)); p.addLine(to: CGPoint(x: 19, y: 20))
        p.addQuadCurve(to: CGPoint(x: 17, y: 22), control: CGPoint(x: 19, y: 22))
        p.addLine(to: CGPoint(x: 7, y: 22))
        p.addQuadCurve(to: CGPoint(x: 5, y: 20), control: CGPoint(x: 5, y: 22))
        p.addLine(to: CGPoint(x: 5, y: 6))
        p.move(to: CGPoint(x: 8, y: 6));  p.addLine(to: CGPoint(x: 8, y: 4))
        p.addQuadCurve(to: CGPoint(x: 10, y: 2), control: CGPoint(x: 8, y: 2))
        p.addLine(to: CGPoint(x: 14, y: 2))
        p.addQuadCurve(to: CGPoint(x: 16, y: 4), control: CGPoint(x: 16, y: 2))
        p.addLine(to: CGPoint(x: 16, y: 6))
        p.move(to: CGPoint(x: 10, y: 11)); p.addLine(to: CGPoint(x: 10, y: 17))
        p.move(to: CGPoint(x: 14, y: 11)); p.addLine(to: CGPoint(x: 14, y: 17))
        return p
    }
}

public struct Share2Icon: Shape {
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: 15, y: 5, width: 6, height: 6))   // center (18,8)
        p.addEllipse(in: CGRect(x: 3, y: 12, width: 6, height: 6))   // center (6,15)
        p.addEllipse(in: CGRect(x: 15, y: 19, width: 6, height: 6))  // center (18,22)
        p.move(to: CGPoint(x: 8.59, y: 13.51)); p.addLine(to: CGPoint(x: 15.42, y: 17.5))
        p.move(to: CGPoint(x: 15.41, y: 6.51)); p.addLine(to: CGPoint(x: 8.59, y: 10.5))
        return p
    }
}

public struct CalendarIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 8, y: 2));  p.addLine(to: CGPoint(x: 8, y: 6))
        p.move(to: CGPoint(x: 16, y: 2)); p.addLine(to: CGPoint(x: 16, y: 6))
        p.move(to: CGPoint(x: 3, y: 10)); p.addLine(to: CGPoint(x: 21, y: 10))
        p.move(to: CGPoint(x: 5, y: 4));  p.addLine(to: CGPoint(x: 19, y: 4))
        p.addQuadCurve(to: CGPoint(x: 21, y: 6), control: CGPoint(x: 21, y: 4))
        p.addLine(to: CGPoint(x: 21, y: 20))
        p.addQuadCurve(to: CGPoint(x: 19, y: 22), control: CGPoint(x: 21, y: 22))
        p.addLine(to: CGPoint(x: 7, y: 22))
        p.addQuadCurve(to: CGPoint(x: 5, y: 20), control: CGPoint(x: 5, y: 22))
        p.addLine(to: CGPoint(x: 5, y: 6))
        p.addQuadCurve(to: CGPoint(x: 5, y: 4), control: CGPoint(x: 5, y: 6))
        return p
    }
}

public struct LightbulbIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 12, y: 3))
        p.addQuadCurve(to: CGPoint(x: 19, y: 10), control: CGPoint(x: 19, y: 5))
        p.addQuadCurve(to: CGPoint(x: 12, y: 14), control: CGPoint(x: 19, y: 12))
        p.addQuadCurve(to: CGPoint(x: 5, y: 10), control: CGPoint(x: 5, y: 12))
        p.addQuadCurve(to: CGPoint(x: 12, y: 3), control: CGPoint(x: 5, y: 5))
        p.move(to: CGPoint(x: 9, y: 17)); p.addLine(to: CGPoint(x: 15, y: 17))
        p.move(to: CGPoint(x: 10, y: 21)); p.addLine(to: CGPoint(x: 14, y: 21))
        return p
    }
}

public struct BookmarkIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 19, y: 21))
        p.addLine(to: CGPoint(x: 12, y: 16))
        p.addLine(to: CGPoint(x: 5, y: 21))
        p.addLine(to: CGPoint(x: 5, y: 5))
        p.addQuadCurve(to: CGPoint(x: 7, y: 3), control: CGPoint(x: 5, y: 3))
        p.addLine(to: CGPoint(x: 17, y: 3))
        p.addQuadCurve(to: CGPoint(x: 19, y: 5), control: CGPoint(x: 19, y: 3))
        p.closeSubpath()
        return p
    }
}

// 保存（纳入今日食物清单）图标：lucide download
public struct DownloadIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 12, y: 3));  p.addLine(to: CGPoint(x: 12, y: 15))
        p.move(to: CGPoint(x: 7, y: 10));  p.addLine(to: CGPoint(x: 12, y: 15))
        p.move(to: CGPoint(x: 17, y: 10)); p.addLine(to: CGPoint(x: 12, y: 15))
        p.move(to: CGPoint(x: 4, y: 19));  p.addLine(to: CGPoint(x: 20, y: 19))
        return p
    }
}
