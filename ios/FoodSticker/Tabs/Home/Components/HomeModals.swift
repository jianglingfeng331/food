import SwiftUI

// MARK: - 首页弹窗（运动消耗 / 今日体重 / 今日饮水）
// 严格对照 Web 端 src/components/HomeModals.tsx + src/index.css 的精确数值重构。
// 所有外观参数统一提取到 HomeModalTokens，便于后续批量修改。

// MARK: - 仅顶部圆角 Shape（用于底部弹窗面板）

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - 弹窗设计令牌（= Web 精确数值，禁止系统默认）

enum HomeModalTokens {
    // 通用底部弹窗容器（对照 .sheet 类：bg-black/40 + rounded-t-[20px] + shadow-[0_-4px_24px_rgba(0,0,0,.12)]）
    enum Sheet {
        static let backgroundColor = HomeTokens.Color.cardBackground      // #FFFFFF
        static let horizontalPadding: CGFloat = 18                        // p-[18px]
        static let topPadding: CGFloat = 18                              // p-[18px]
        static let bottomPadding: CGFloat = 28                           // pb-[28px]
        static let cornerRadius: CGFloat = 20                            // rounded-t-[20px]
        static let maxHeightRatio: CGFloat = 0.85                        // max-h-[85vh]
        static let shadowColor = Color.black.opacity(0.12)               // rgba(0,0,0,.12)
        static let shadowRadius: CGFloat = 12                            // blur 24 -> 12
        static let shadowX: CGFloat = 0                                  // 0
        static let shadowY: CGFloat = -4                                 // -4px
        static let scrimOpacity: Double = 0.4                            // bg-black/40

        static let grabberWidth: CGFloat = 36                            // w-[36px]
        static let grabberHeight: CGFloat = 4                            // h-[4px]
        static let grabberColor = HomeTokens.Color.foreground.opacity(0.15) // bg-foreground/15
        static let grabberBottom: CGFloat = 14                           // mb-[14px]

        static let titleFont: CGFloat = 16                               // text-[16px] font-bold
        static let titleBottom: CGFloat = 14                             // mb-[14px]
        static let cancelFont: CGFloat = 14                              // text-[14px]
    }

    // 主/次按钮（对照 .btn-primary / 描边按钮）
    enum Button {
        static let primaryRadius: CGFloat = 12                           // rounded-[12px]
        static let primaryVPadding: CGFloat = 12                         // py-[12px]
        static let primaryFont: CGFloat = 15                             // text-[15px]
        static let primaryText = Color.white
        static let primaryBg = HomeTokens.Color.primary                  // #10B981
        static let primaryShadow = HomeTokens.Color.primary.opacity(0.15) // btn-primary shadow
        static let primaryShadowRadius: CGFloat = 6                      // 12/2
        static let primaryShadowY: CGFloat = 4                           // 4px
        static let disabledBg = HomeTokens.Color.foreground.opacity(0.10) // bg-foreground/10
        static let disabledText = HomeTokens.Color.foregroundSubtle      // text-foreground-subtle

        static let secondaryRadius: CGFloat = 12
        static let secondaryVPadding: CGFloat = 12
        static let secondaryFont: CGFloat = 15
        static let secondaryText = HomeTokens.Color.primary
        static let secondaryBorder = HomeTokens.Color.primary
        static let secondaryDisabledBorder = HomeTokens.Color.foreground.opacity(0.15)
        static let secondaryDisabledText = HomeTokens.Color.foregroundSubtle
        static let secondaryTopMargin: CGFloat = 10                      // mt-[10px]
    }

    // 滚轮（对照 WheelPicker：ITEM_H=40 VISIBLE=5 PAD=80）
    enum Wheel {
        static let itemHeight: CGFloat = 40
        static let visibleCount: CGFloat = 5
        static let maskHeight: CGFloat = 80                              // 上下渐变遮罩高度
        static let selectionBoxHeight: CGFloat = 40                      // h-[40px]
        static let selectionBoxRadius: CGFloat = 10                      // rounded-[10px]
        static let selectionBoxInsetX: CGFloat = 10                      // inset-x-[10px]
        static let selectionBoxBg = HomeTokens.Color.primary.opacity(0.10)  // bg-primary/10
        static let selectionBoxRing = HomeTokens.Color.primary.opacity(0.30) // ring-1 ring-primary/30
        static let itemFont: CGFloat = 16                                // text-[16px]
        static let itemSelectedColor = HomeTokens.Color.primary          // text-primary
        static let itemUnselectedColor = HomeTokens.Color.foregroundSubtle // text-foreground-subtle
        static let maskColor = HomeTokens.Color.background               // from-background
        static let maskColorClear = HomeTokens.Color.background.opacity(0) // to-transparent
    }

    // 运动弹窗
    enum Exercise {
        static let segmentedPadding: CGFloat = 3                         // p-[3px]
        static let segmentedButtonVPadding: CGFloat = 6                  // py-[6px]
        static let segmentedFont: CGFloat = 13                           // text-[13px]
        static let chipGap: CGFloat = 8                                  // gap-[8px]
        static let chipHMargin: CGFloat = 14                             // px-[14px]
        static let chipVMargin: CGFloat = 8                              // py-[8px]
        static let chipFont: CGFloat = 13                                // text-[13px]
        static let chipRateFont: CGFloat = 11                            // text-[11px]
        static let chipRateOpacity: Double = 0.8                         // opacity-80
        static let chipRateSpacing: CGFloat = 4                          // ml-[4px]
        static let chipBorderWidth: CGFloat = 1                          // border
        static let chipSelectedBg = HomeTokens.Color.primary
        static let chipSelectedText = Color.white
        static let chipUnselectedBg = HomeTokens.Color.background        // bg-background
        static let chipUnselectedText = HomeTokens.Color.foregroundMuted // text-foreground-muted
        static let chipBorder = HomeTokens.Color.surfaceBorder           // border-surface-border

        static let inputRadius: CGFloat = 12                             // rounded-[12px]
        static let inputHMargin: CGFloat = 14                            // px-[14px]
        static let inputVMargin: CGFloat = 10                            // py-[10px]
        static let inputFont: CGFloat = 15                               // text-[15px]
        static let inputText = HomeTokens.Color.foreground
        static let inputPlaceholder = HomeTokens.Color.foregroundSubtle
        static let inputBorder = HomeTokens.Color.surfaceBorder
        static let inputFocusBorder = HomeTokens.Color.primary

        static let gridGap: CGFloat = 12                                 // gap-[12px]
        static let wheelLabelFont: CGFloat = 12                          // text-[12px]
        static let wheelLabelColor = HomeTokens.Color.foregroundMuted
        static let wheelLabelBottom: CGFloat = 6                         // mb-[6px]

        static let previewRadius: CGFloat = 12                           // rounded-[12px]
        static let previewBg = HomeTokens.Color.background               // bg-background
        static let previewHMargin: CGFloat = 14                          // px-[14px]
        static let previewVMargin: CGFloat = 10                          // py-[10px]
        static let previewLabelFont: CGFloat = 13                        // text-[13px]
        static let previewLabelColor = HomeTokens.Color.foregroundMuted
        static let previewValueFont: CGFloat = 18                        // text-[18px] font-bold

        static let blockBottomMargin: CGFloat = 14                       // mb-[14px]
        static let wheelBlockBottomMargin: CGFloat = 16                  // mt/[mb]-[16px]
    }

    // 体重弹窗
    enum Weight {
        static let bigNumberFont: CGFloat = 44                           // text-[44px] font-bold
        static let bigNumberColor = HomeTokens.Color.foreground
        static let unitFont: CGFloat = 18                                // text-[18px]
        static let unitColor = HomeTokens.Color.foregroundSubtle
        static let valueGap: CGFloat = 6                                 // gap-[6px]
        static let valueBottom: CGFloat = 18                             // mb-[18px]
        static let keyboardColumns: Int = 3
        static let keyboardGap: CGFloat = 10                             // gap-[10px]
        static let keyHeight: CGFloat = 56                               // h-[56px]
        static let keyRadius: CGFloat = 14                               // rounded-[14px]
        static let keyBg = HomeTokens.Color.background                   // bg-background
        static let keyFont: CGFloat = 22                                 // text-[22px]
        static let keyColor = HomeTokens.Color.foreground
        static let confirmTop: CGFloat = 16                              // mt-[16px]
    }

    // 饮水弹窗
    enum Water {
        static let bigValueFont: CGFloat = 40                            // text-[40px] font-bold
        static let bigValueColor = HomeTokens.Color.primary
        static let unitFont: CGFloat = 18
        static let unitColor = HomeTokens.Color.foregroundSubtle
        static let valueGap: CGFloat = 6
        static let valueBottom: CGFloat = 4                              // mb-[4px]
        static let subFont: CGFloat = 12                                 // text-[12px]
        static let subColor = HomeTokens.Color.foregroundSubtle
        static let subBottom: CGFloat = 20                               // mb-[20px]
        static let trackHeight: CGFloat = 10                             // h-[10px]
        static let thumbSize: CGFloat = 24                               // h-[24px] w-[24px]
        static let trackBg = HomeTokens.Color.background                 // bg-background
        static let thumbColor = Color.white
        static let thumbShadow = Color.black.opacity(0.2)               // shadow-[0_2px_6px_rgba(0,0,0,.2)]
        static let thumbShadowRadius: CGFloat = 3                        // 6/2
        static let thumbShadowY: CGFloat = 2                            // 2px
        static let thumbRing = HomeTokens.Color.primary                  // ring-2 ring-primary
        static let scaleFont: CGFloat = 10                               // text-[10px]
        static let scaleColor = HomeTokens.Color.foregroundSubtle
        static let scaleBottom: CGFloat = 16                             // mb-[16px]
        static let presetGap: CGFloat = 8                                // gap-[8px]
        static let presetHMargin: CGFloat = 12                          // px-[12px]
        static let presetVMargin: CGFloat = 7                            // py-[7px]
        static let presetFont: CGFloat = 12                              // text-[12px]
    }
}

// MARK: - 通用底部弹窗容器（scrim + 面板 + 抓手 + 标题 + 取消）

struct BottomSheet<Content: View>: View {
    let title: String
    let onDismiss: () -> Void
    @ViewBuilder let content: () -> Content

    // 顶部边缘下滑关闭：拖拽偏移 + 丝滑回弹
    @State private var dragOffset: CGFloat = 0
    private let dismissThreshold: CGFloat = 120

    private var dragGesture: some Gesture {
        // coordinateSpace: .global 用屏幕坐标系测量位移，避免面板自身位移导致的坐标空间反馈抖动
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                // 只允许向下拖拽（offset >= 0）
                dragOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                if value.translation.height > dismissThreshold {
                    onDismiss()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        dragOffset = 0
                    }
                }
            }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 透明点击层（去掉灰色蒙版，仍可点外部关闭）
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                // 顶部拖拽热区（全宽）—— 触控弹出层顶部边缘即可下滑关闭
                ZStack {
                    Capsule()
                        .fill(HomeModalTokens.Sheet.grabberColor)
                        .frame(width: HomeModalTokens.Sheet.grabberWidth,
                               height: HomeModalTokens.Sheet.grabberHeight)
                }
                .frame(maxWidth: .infinity, minHeight: 32)
                .contentShape(Rectangle())
                .gesture(dragGesture)
                .padding(.bottom, HomeModalTokens.Sheet.grabberBottom)

                // 标题行
                HStack {
                    Text(title)
                        .font(.app(size: HomeModalTokens.Sheet.titleFont, weight: .bold))
                        .foregroundColor(HomeTokens.Color.foreground)
                    Spacer()
                    Button(action: onDismiss) {
                        Text("取消")
                            .font(.app(size: HomeModalTokens.Sheet.cancelFont))
                            .foregroundColor(HomeTokens.Color.foregroundSubtle)
                    }
                }
                .padding(.bottom, HomeModalTokens.Sheet.titleBottom)

                ScrollView(showsIndicators: false) {
                    content()
                }
            }
            .padding(.horizontal, HomeModalTokens.Sheet.horizontalPadding)
            .padding(.top, HomeModalTokens.Sheet.topPadding)
            .padding(.bottom, HomeModalTokens.Sheet.bottomPadding)
            .background(HomeModalTokens.Sheet.backgroundColor)
            .clipShape(RoundedCorner(radius: HomeModalTokens.Sheet.cornerRadius,
                                     corners: [.topLeft, .topRight]))
            .shadow(color: HomeModalTokens.Sheet.shadowColor,
                    radius: HomeModalTokens.Sheet.shadowRadius,
                    x: HomeModalTokens.Sheet.shadowX,
                    y: HomeModalTokens.Sheet.shadowY)
            // 按内容自适应高度（仅设上限作为超大内容的安全兜底，不会造成底部空白）
            .frame(maxWidth: .infinity,
                   maxHeight: UIScreen.main.bounds.height * HomeModalTokens.Sheet.maxHeightRatio)
            .offset(y: dragOffset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

// MARK: - 按钮

struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.app(size: HomeModalTokens.Button.primaryFont, weight: .semibold))
                .foregroundColor(isEnabled ? HomeModalTokens.Button.primaryText : HomeModalTokens.Button.disabledText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HomeModalTokens.Button.primaryVPadding)
                .background(isEnabled ? HomeModalTokens.Button.primaryBg : HomeModalTokens.Button.disabledBg)
                .cornerRadius(HomeModalTokens.Button.primaryRadius)
                .shadow(color: HomeModalTokens.Button.primaryShadow,
                        radius: HomeModalTokens.Button.primaryShadowRadius,
                        y: HomeModalTokens.Button.primaryShadowY)
        }
        .disabled(!isEnabled)
    }
}

struct SecondaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.app(size: HomeModalTokens.Button.secondaryFont, weight: .semibold))
                .foregroundColor(isEnabled ? HomeModalTokens.Button.secondaryText : HomeModalTokens.Button.secondaryDisabledText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HomeModalTokens.Button.secondaryVPadding)
                .background(
                    RoundedRectangle(cornerRadius: HomeModalTokens.Button.secondaryRadius)
                        .stroke(isEnabled ? HomeModalTokens.Button.secondaryBorder : HomeModalTokens.Button.secondaryDisabledBorder,
                                lineWidth: 1)
                )
        }
        .disabled(!isEnabled)
    }
}

// MARK: - 紧凑换行布局（iOS 15 兼容，对照 flex-wrap）

struct ItemSizeKey: PreferenceKey {
    static var defaultValue: [String: CGSize] { [:] }
    static func reduce(value: inout [String: CGSize], nextValue: () -> [String: CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct TagCloud<Data, ID, Content>: View where Data: RandomAccessCollection, ID: Hashable, Content: View {
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let spacing: CGFloat
    let lineSpacing: CGFloat
    @ViewBuilder let content: (Data.Element) -> Content

    @State private var sizes: [String: CGSize] = [:]
    @State private var totalHeight: CGFloat = .zero

    private func key(_ e: Data.Element) -> String { "\(e[keyPath: id])" }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            var rows: [[Data.Element]] = []
            var current: [Data.Element] = []
            var x: CGFloat = 0
            for e in data {
                let w = sizes[key(e)]?.width ?? 80
                if x + w > width, !current.isEmpty {
                    rows.append(current); current = []; x = 0
                }
                current.append(e)
                x += w + spacing
            }
            if !current.isEmpty { rows.append(current) }

            let rowHeights = rows.map { r in
                r.compactMap { sizes[key($0)]?.height }.max() ?? 34
            }
            let h = rowHeights.reduce(0, +) + CGFloat(max(0, rows.count - 1)) * lineSpacing
            DispatchQueue.main.async {
                if abs(totalHeight - h) > 0.5 { totalHeight = h }
            }

            return VStack(alignment: .leading, spacing: lineSpacing) {
                ForEach(0..<rows.count, id: \.self) { ri in
                    HStack(spacing: spacing) {
                        ForEach(rows[ri], id: id) { e in
                            content(e)
                                .background(GeometryReader { g in
                                    Color.clear.preference(key: ItemSizeKey.self, value: [key(e): g.size])
                                })
                        }
                    }
                }
            }
            .frame(width: width, alignment: .topLeading)
        }
        .frame(height: totalHeight)
        .onPreferenceChange(ItemSizeKey.self) { dict in
            let merged = sizes.merging(dict) { _, new in new }
            if merged != sizes { sizes = merged }
        }
    }
}

// MARK: - 滚轮选择器（对照 WheelPicker：DragGesture 自绘，可吸附，视觉 1:1）

struct WheelPicker: View {
    let items: [Int]
    @Binding var selection: Int
    let unit: String

    private let itemHeight = HomeModalTokens.Wheel.itemHeight
    private var viewHeight: CGFloat { itemHeight * HomeModalTokens.Wheel.visibleCount }
    /// Web 端 PAD = (VIEW_H - ITEM_H) / 2，确保选中项在视野中央
    private var centerOffset: CGFloat { (viewHeight - itemHeight) / 2 }

    @State private var offsetY: CGFloat = 0
    @GestureState private var drag: (translation: CGFloat, active: Bool) = (0, false)

    private var selectedIndex: Int {
        let i = items.firstIndex(of: selection) ?? 0
        return max(0, min(items.count - 1, i))
    }
    private func clamped(_ o: CGFloat) -> CGFloat {
        let minVal = centerOffset - itemHeight * CGFloat(items.count - 1)
        return Swift.max(minVal, Swift.min(centerOffset, o))
    }
    private func indexFor(_ o: CGFloat) -> Int {
        let i = Int(round((centerOffset - o) / itemHeight))
        return max(0, min(items.count - 1, i))
    }

    var body: some View {
        GeometryReader { geo in
            let displayOffset = clamped(offsetY + drag.translation)
            let currentIndex = indexFor(displayOffset)

            ZStack(alignment: .topLeading) {
                // 选中框（对照 inset-x-[10px] top-1/2 h-[40px] rounded-[10px] bg-primary/10 ring-1 ring-primary/30）
                RoundedRectangle(cornerRadius: HomeModalTokens.Wheel.selectionBoxRadius)
                    .fill(HomeModalTokens.Wheel.selectionBoxBg)
                    .overlay(RoundedRectangle(cornerRadius: HomeModalTokens.Wheel.selectionBoxRadius)
                        .stroke(HomeModalTokens.Wheel.selectionBoxRing, lineWidth: 1))
                    .frame(width: geo.size.width - HomeModalTokens.Wheel.selectionBoxInsetX * 2,
                           height: HomeModalTokens.Wheel.selectionBoxHeight)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                // 条目：显式 frame 高度 = 容器高度，避免超大 VStack 在 ZStack 中被居中导致的偏移
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                        Text("\(item)\(unit)")
                            .font(.appBody(size: HomeModalTokens.Wheel.itemFont,
                                          weight: idx == currentIndex ? .bold : .regular))
                            .foregroundColor(idx == currentIndex
                                            ? HomeModalTokens.Wheel.itemSelectedColor
                                            : HomeModalTokens.Wheel.itemUnselectedColor)
                            .frame(width: geo.size.width, height: itemHeight)
                            .lineLimit(1)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                .offset(y: displayOffset)

                // 上下渐变遮罩（对照 from-background to-transparent 各 80px）
                LinearGradient(colors: [HomeModalTokens.Wheel.maskColor, HomeModalTokens.Wheel.maskColorClear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: HomeModalTokens.Wheel.maskHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .allowsHitTesting(false)
                LinearGradient(colors: [HomeModalTokens.Wheel.maskColorClear, HomeModalTokens.Wheel.maskColor],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: HomeModalTokens.Wheel.maskHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .allowsHitTesting(false)
            }
            .frame(height: viewHeight)
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($drag) { value, state, _ in
                        state = (value.translation.height, true)
                    }
                    .onChanged { value in
                        let i = indexFor(clamped(offsetY + value.translation.height))
                        if items[i] != selection { selection = items[i] }
                    }
                    .onEnded { value in
                        let o = clamped(offsetY + value.translation.height)
                        let i = indexFor(o)
                        // 先无动画同步到手指松开的当前位置，避免 drag 归零后从旧 offsetY 回弹
                        offsetY = o
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            offsetY = centerOffset - itemHeight * CGFloat(i)
                        }
                        selection = items[i]
                    }
            )
            .onTapGesture { loc in
                let i = Int(floor((loc.y - offsetY) / itemHeight))
                let clampedIdx = max(0, min(items.count - 1, i))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offsetY = centerOffset - itemHeight * CGFloat(clampedIdx)
                }
                selection = items[clampedIdx]
            }
            .onAppear { offsetY = centerOffset - itemHeight * CGFloat(selectedIndex) }
            .onChange(of: selectedIndex) { _ in
                guard !drag.active else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offsetY = centerOffset - itemHeight * CGFloat(selectedIndex)
                }
            }
        }
        .frame(height: viewHeight)
        .background(
            RoundedRectangle(cornerRadius: HomeModalTokens.Exercise.inputRadius)
                .fill(HomeTokens.Color.background)
        )
    }
}

// MARK: - 饮水滑块（对照 track + thumb，DragGesture 自绘）

struct WaterSlider: View {
    @Binding var value: Int
    let max: Int

    private var pct: CGFloat { CGFloat(value) / CGFloat(max) }
    private let trackHeight = HomeModalTokens.Water.trackHeight
    private let thumbSize = HomeModalTokens.Water.thumbSize

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let thumbX = pct * w
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(HomeModalTokens.Water.trackBg)
                    .frame(height: trackHeight)
                Capsule()
                    .fill(ProgressGradient.primary)
                    .frame(width: Swift.max(0, thumbX), height: trackHeight)
            }
            .frame(height: trackHeight)
            .frame(maxHeight: .infinity, alignment: .center)
            .overlay(
                Circle()
                    .fill(HomeModalTokens.Water.thumbColor)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: HomeModalTokens.Water.thumbShadow,
                            radius: HomeModalTokens.Water.thumbShadowRadius,
                            y: HomeModalTokens.Water.thumbShadowY)
                    .overlay(Circle().stroke(HomeModalTokens.Water.thumbRing, lineWidth: 2))
                    .position(x: Swift.max(thumbSize / 2, Swift.min(w - thumbSize / 2, thumbX)),
                              y: geo.size.height / 2)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        let p = Swift.max(CGFloat(0), Swift.min(CGFloat(1), v.location.x / w))
                        let raw = p * CGFloat(max)
                        value = Int((raw / 50).rounded()) * 50   // 吸附到 50ml
                    }
            )
        }
        .frame(height: Swift.max(trackHeight, thumbSize))
    }
}

// MARK: - 数据模型

struct SavedSport: Identifiable {
    let id = UUID()
    let name: String
    let rate: Int
}

private struct Preset: Identifiable {
    var id: String { name }
    let name: String
    let rate: Int
}

// MARK: - 运动消耗弹窗

struct ExerciseModalView: View {
    @Binding var savedSports: [SavedSport]
    let onConfirm: (String, Int) -> Void
    let onDismiss: () -> Void

    private let presets: [Preset] = [
        Preset(name: "跑步", rate: 600), Preset(name: "骑行", rate: 480),
        Preset(name: "游泳", rate: 550), Preset(name: "快走", rate: 320),
        Preset(name: "力量训练", rate: 400), Preset(name: "跳绳", rate: 700),
        Preset(name: "瑜伽", rate: 240), Preset(name: "篮球", rate: 500)
    ]
    private let durationOptions = Array(stride(from: 15, through: 120, by: 5))  // 15..120 step5
    private let rateOptions = Array(stride(from: 200, through: 800, by: 50))    // 200..800 step50

    @State private var mode: ExerciseMode = .preset
    @State private var selected: String? = nil
    @State private var duration: Int = 30
    @State private var customName: String = ""
    @State private var customRate: Int = 400
    @FocusState private var nameFocused: Bool

    private var allPresets: [Preset] {
        presets + savedSports
            .filter { s in !presets.contains(where: { $0.name == s.name }) }
            .map { Preset(name: $0.name, rate: $0.rate) }
    }
    private var rate: Int? {
        if mode == .preset { return allPresets.first(where: { $0.name == selected })?.rate }
        return customRate
    }
    private var calories: Int {
        guard let r = rate else { return 0 }
        return Int(round(Double(r) * Double(duration) / 60.0))
    }
    private var canConfirm: Bool {
        if mode == .preset { return selected != nil }
        return !customName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        BottomSheet(title: "记录运动消耗", onDismiss: onDismiss) {
            VStack(spacing: 0) {
                segmented
                    .padding(.bottom, HomeModalTokens.Exercise.blockBottomMargin)

                if mode == .preset {
                    chips
                        .padding(.bottom, HomeModalTokens.Exercise.blockBottomMargin)
                    durationWheelBlock
                        .padding(.bottom, HomeModalTokens.Exercise.wheelBlockBottomMargin)
                } else {
                    customInput
                        .padding(.bottom, HomeModalTokens.Exercise.blockBottomMargin)
                    HStack(spacing: HomeModalTokens.Exercise.gridGap) {
                        wheelColumn(label: "每小时消耗", items: rateOptions, selection: $customRate, unit: " kcal/h")
                        wheelColumn(label: "运动时长", items: durationOptions, selection: $duration, unit: " 分钟")
                    }
                    .padding(.bottom, HomeModalTokens.Exercise.blockBottomMargin)
                }

                previewRow
                    .padding(.top, HomeModalTokens.Exercise.wheelBlockBottomMargin)
                    .padding(.bottom, 12)

                confirmBlock
            }
        }
    }

    // 模式切换（胶囊分段，对照 web：flex-1 rounded-full py-[6px] text-[13px]，选中 bg-primary 白字）
    private var segmented: some View {
        HStack(spacing: 0) {
            ForEach(ExerciseMode.allCases, id: \.self) { m in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { mode = m }
                } label: {
                    Text(m == .preset ? "预设运动" : "自定义运动")
                        .font(.app(size: HomeModalTokens.Exercise.segmentedFont))
                        .foregroundColor(mode == m ? Color.white : HomeTokens.Color.foregroundMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, HomeModalTokens.Exercise.segmentedButtonVPadding)
                        .background(mode == m ? HomeTokens.Color.primary : Color.clear)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(HomeModalTokens.Exercise.segmentedPadding)
        .background(HomeTokens.Color.background)
        .clipShape(Capsule())
    }

    private var confirmBlock: some View {
        VStack(spacing: 0) {
            PrimaryButton(title: "确认记录", isEnabled: canConfirm) {
                if mode == .preset {
                    guard let name = selected else { return }
                    onConfirm(name, calories)
                } else {
                    let name = customName.trimmingCharacters(in: .whitespaces)
                    onConfirm(name, calories)
                }
            }
            if mode == .custom {
                SecondaryButton(title: "保存并确认", isEnabled: canConfirm) {
                    let name = customName.trimmingCharacters(in: .whitespaces)
                    savedSports.append(SavedSport(name: name, rate: customRate))
                    onConfirm(name, calories)
                }
                .padding(.top, HomeModalTokens.Button.secondaryTopMargin)
            }
        }
    }

    private var chips: some View {
        TagCloud(data: allPresets, id: \.id,
                 spacing: HomeModalTokens.Exercise.chipGap,
                 lineSpacing: HomeModalTokens.Exercise.chipGap) { p in
            Button {
                selected = (selected == p.name) ? nil : p.name
            } label: {
                HStack(spacing: HomeModalTokens.Exercise.chipRateSpacing) {
                    Text(p.name)
                        .font(.app(size: HomeModalTokens.Exercise.chipFont))
                    Text("\(p.rate) kcal")
                        .font(.app(size: HomeModalTokens.Exercise.chipRateFont))
                        .opacity(HomeModalTokens.Exercise.chipRateOpacity)
                }
                .foregroundColor(selected == p.name
                                 ? HomeModalTokens.Exercise.chipSelectedText
                                 : HomeModalTokens.Exercise.chipUnselectedText)
                .padding(.horizontal, HomeModalTokens.Exercise.chipHMargin)
                .padding(.vertical, HomeModalTokens.Exercise.chipVMargin)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(selected == p.name
                          ? HomeModalTokens.Exercise.chipSelectedBg
                          : HomeModalTokens.Exercise.chipUnselectedBg))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(selected == p.name
                            ? HomeModalTokens.Exercise.chipSelectedBg
                            : HomeModalTokens.Exercise.chipBorder,
                            lineWidth: HomeModalTokens.Exercise.chipBorderWidth))
            }
        }
    }

    private var customInput: some View {
        TextField("输入运动名称，如：爬山", text: $customName)
            .font(.app(size: HomeModalTokens.Exercise.inputFont))
            .foregroundColor(HomeModalTokens.Exercise.inputText)
            .padding(.horizontal, HomeModalTokens.Exercise.inputHMargin)
            .padding(.vertical, HomeModalTokens.Exercise.inputVMargin)
            .background(
                RoundedRectangle(cornerRadius: HomeModalTokens.Exercise.inputRadius)
                    .fill(HomeModalTokens.Exercise.chipUnselectedBg)
                    .overlay(RoundedRectangle(cornerRadius: HomeModalTokens.Exercise.inputRadius)
                        .stroke(nameFocused ? HomeModalTokens.Exercise.inputFocusBorder
                                           : HomeModalTokens.Exercise.inputBorder,
                                lineWidth: 1))
            )
            .focused($nameFocused)
    }

    private var durationWheelBlock: some View {
        wheelColumn(label: "运动时长", items: durationOptions, selection: $duration, unit: " 分钟")
    }

    private func wheelColumn(label: String, items: [Int], selection: Binding<Int>, unit: String) -> some View {
        VStack(spacing: 0) {
            Text(label)
                .font(.app(size: HomeModalTokens.Exercise.wheelLabelFont))
                .foregroundColor(HomeModalTokens.Exercise.wheelLabelColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, HomeModalTokens.Exercise.wheelLabelBottom)
            WheelPicker(items: items, selection: selection, unit: unit)
        }
    }

    private var previewRow: some View {
        HStack {
            Text("预计消耗")
                .font(.app(size: HomeModalTokens.Exercise.previewLabelFont))
                .foregroundColor(HomeModalTokens.Exercise.previewLabelColor)
            Spacer()
            Text("\(calories) kcal")
                .fontNumber(size: HomeModalTokens.Exercise.previewValueFont)
                .foregroundColor(HomeTokens.Color.primary)
        }
        .padding(.horizontal, HomeModalTokens.Exercise.previewHMargin)
        .padding(.vertical, HomeModalTokens.Exercise.previewVMargin)
        .background(RoundedRectangle(cornerRadius: HomeModalTokens.Exercise.previewRadius)
            .fill(HomeModalTokens.Exercise.previewBg))
    }
}

private enum ExerciseMode: String, CaseIterable {
    case preset, custom
}

// MARK: - 今日体重弹窗（九宫格键盘）

struct WeightModalView: View {
    let initial: String?
    let onConfirm: (Double) -> Void
    let onDismiss: () -> Void

    private let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "back"]
    @State private var val: String = ""

    private var num: Double { Double(val) ?? 0 }
    private var valid: Bool {
        let n = num
        return !val.isEmpty && n > 0 && n < 400
    }

    init(initial: String?, onConfirm: @escaping (Double) -> Void, onDismiss: @escaping () -> Void) {
        self.initial = initial
        self.onConfirm = onConfirm
        self.onDismiss = onDismiss
        let cleaned = initial?
            .replacingOccurrences(of: #"[^0-9.]"#, with: "", options: .regularExpression) ?? ""
        let num = Double(cleaned)
        _val = State(initialValue: num.map { String($0) } ?? "")
    }

    private func press(_ k: String) {
        if k == "back" { val = String(val.dropLast()); return }
        if k == "." { val = (val.contains(".") || val.isEmpty) ? val : val + "."; return }
        if val == "0" { val = k; return }
        if val.replacingOccurrences(of: ".", with: "").count >= 4 { return }
        val += k
    }

    var body: some View {
        BottomSheet(title: "记录今日体重", onDismiss: onDismiss) {
            VStack(spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: HomeModalTokens.Weight.valueGap) {
                    Text(val.isEmpty ? "0" : val)
                        .font(.app(size: HomeModalTokens.Weight.bigNumberFont, weight: .bold))
                        .foregroundColor(HomeModalTokens.Weight.bigNumberColor)
                    Text("kg")
                        .font(.app(size: HomeModalTokens.Weight.unitFont))
                        .foregroundColor(HomeModalTokens.Weight.unitColor)
                }
                .padding(.bottom, HomeModalTokens.Weight.valueBottom)

                LazyVGrid(columns: Array(repeating:
                            GridItem(.flexible(), spacing: HomeModalTokens.Weight.keyboardGap),
                            count: HomeModalTokens.Weight.keyboardColumns),
                          spacing: HomeModalTokens.Weight.keyboardGap) {
                    ForEach(keys, id: \.self) { k in
                        Button { press(k) } label: {
                            Text(k == "back" ? "⌫" : k)
                                .font(.appBody(size: HomeModalTokens.Weight.keyFont))
                                .foregroundColor(HomeModalTokens.Weight.keyColor)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .frame(height: HomeModalTokens.Weight.keyHeight)
                                .background(RoundedRectangle(cornerRadius: HomeModalTokens.Weight.keyRadius)
                                    .fill(HomeModalTokens.Weight.keyBg))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                PrimaryButton(title: "确认保存", isEnabled: valid) {
                    onConfirm(num)
                }
                .padding(.top, HomeModalTokens.Weight.confirmTop)
            }
        }
    }
}

// MARK: - 今日饮水弹窗（滑块 + 预设）

struct WaterModalView: View {
    let initial: Int
    let onConfirm: (Int) -> Void
    let onDismiss: () -> Void

    private let maxValue = 3000
    private let presets = [200, 500, 1000, 1500, 2000, 2500]
    @State private var value: Int = 0

    init(initial: Int, onConfirm: @escaping (Int) -> Void, onDismiss: @escaping () -> Void) {
        self.initial = initial
        self.onConfirm = onConfirm
        self.onDismiss = onDismiss
        _value = State(initialValue: min(maxValue, max(0, initial)))
    }

    var body: some View {
        BottomSheet(title: "记录今日饮水", onDismiss: onDismiss) {
            VStack(spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: HomeModalTokens.Water.valueGap) {
                    Text(String(format: "%.2f", Double(value) / 1000.0))
                        .fontNumber(size: HomeModalTokens.Water.bigValueFont)
                        .foregroundColor(HomeModalTokens.Water.bigValueColor)
                    Text("L")
                        .font(.app(size: HomeModalTokens.Water.unitFont))
                        .foregroundColor(HomeModalTokens.Water.unitColor)
                }
                .padding(.bottom, HomeModalTokens.Water.valueBottom)

                Text("\(value) ml / 目标 2500 ml")
                    .font(.app(size: HomeModalTokens.Water.subFont))
                    .foregroundColor(HomeModalTokens.Water.subColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, HomeModalTokens.Water.subBottom)

                WaterSlider(value: $value, max: maxValue)
                    .padding(.bottom, HomeModalTokens.Water.scaleBottom)

                HStack {
                    Text("0")
                    Spacer()
                    Text("1.5L")
                    Spacer()
                    Text("3.0L")
                }
                .font(.app(size: HomeModalTokens.Water.scaleFont))
                .foregroundColor(HomeModalTokens.Water.scaleColor)
                .padding(.bottom, HomeModalTokens.Water.presetGap)

                TagCloud(data: presets, id: \.self,
                         spacing: HomeModalTokens.Water.presetGap,
                         lineSpacing: HomeModalTokens.Water.presetGap) { p in
                    Button {
                        value = p
                    } label: {
                        Text("\(p)ml")
                            .font(.app(size: HomeModalTokens.Water.presetFont))
                            .foregroundColor(value == p ? Color.white : HomeTokens.Color.foregroundMuted)
                            .padding(.horizontal, HomeModalTokens.Water.presetHMargin)
                            .padding(.vertical, HomeModalTokens.Water.presetVMargin)
                            .background(Capsule().fill(value == p
                                                      ? HomeTokens.Color.primary
                                                      : HomeModalTokens.Water.trackBg))
                            .overlay(Capsule().stroke(value == p
                                                      ? HomeTokens.Color.primary
                                                      : HomeTokens.Color.surfaceBorder,
                                                      lineWidth: 1))
                    }
                }
                .padding(.bottom, HomeModalTokens.Water.scaleBottom)

                PrimaryButton(title: "确认保存") {
                    onConfirm(value)
                }
            }
        }
    }
}
