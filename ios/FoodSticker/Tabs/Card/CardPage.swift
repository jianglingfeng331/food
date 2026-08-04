import SwiftUI
import UIKit

// 全局扩展：支持 SwiftUI.Color(hex: 0xRRGGBB)，供 CardTokens 中所有颜色常量使用
extension SwiftUI.Color {
    init(hex: UInt) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255.0,
                  green: Double((hex >> 8) & 0xFF) / 255.0,
                  blue: Double(hex & 0xFF) / 255.0)
    }
}

/// 贴纸图片统一渲染：优先使用用户保存的真实 uiImage，其次按 imageName 加载资源，
/// 都没有时回退为首字占位（避免破图）。
struct StickerImageView: View {
    let sticker: FoodSticker
    var contentMode: ContentMode = .fill

    var body: some View {
        if let ui = sticker.uiImage {
            Image(uiImage: ui)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else if !sticker.imageName.isEmpty, let _ = UIImage(named: sticker.imageName) {
            Image(sticker.imageName)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            ZStack {
                Color.white
                Text(String(sticker.name.prefix(1)))
                    .font(.app(size: 40, weight: .bold))
                    .foregroundColor(CardTokens.Color.primary)
            }
        }
    }
}

enum CardTokens {
    enum Color {
        static let background        = SwiftUI.Color(hex: 0xF8F8F8)
        static let cardBackground    = SwiftUI.Color(hex: 0xFFFFFF)
        static let surface           = SwiftUI.Color(hex: 0xFFFFFF)
        static let surfaceBorder     = SwiftUI.Color.black.opacity(0.05)
        static let surfaceBorderSoft = SwiftUI.Color.black.opacity(0.04)
        static let foreground        = SwiftUI.Color(hex: 0x1A1A1A)
        static let foregroundMuted   = SwiftUI.Color(hex: 0x666666)
        static let foregroundSubtle  = SwiftUI.Color(hex: 0x999999)
        static let primary           = SwiftUI.Color(hex: 0x10B981)
        static let primaryLight      = SwiftUI.Color(hex: 0x34D399)
        static let primaryDark       = SwiftUI.Color(hex: 0x059669)
        static let primaryGlow       = SwiftUI.Color(hex: 0x10B981).opacity(0.12)
        static let primaryBg10       = SwiftUI.Color(hex: 0x10B981).opacity(0.10)
        static let primaryBorder15   = SwiftUI.Color(hex: 0x10B981).opacity(0.15)
        static let error             = SwiftUI.Color(hex: 0xEF4444)
        static let errorBg10         = SwiftUI.Color(hex: 0xEF4444).opacity(0.10)
        static let labelText         = SwiftUI.Color(hex: 0x1A1A1A)
        static let labelCal          = SwiftUI.Color(hex: 0x22C55E)

        // 暖色胃壁（对齐 Web：#FFF8EE → #FFEBDD → #FFDAC9）
        static let boardInner = SwiftUI.Color(hex: 0xFFF8EE)
        static let boardMid   = SwiftUI.Color(hex: 0xFFEBDD)
        static let boardEdge  = SwiftUI.Color(hex: 0xFFDAC9)

        // 小人 / 精灵（对齐 Web SVG 精确色值）
        static let skin            = SwiftUI.Color(hex: 0xFFF3E6)
        static let skinStroke      = SwiftUI.Color(hex: 0xF2C79B)
        static let blush           = SwiftUI.Color(hex: 0xFF9DBB)
        static let blushOpacity    = SwiftUI.Color(hex: 0xFF9DBB).opacity(0.55)
        static let capPink         = SwiftUI.Color(hex: 0xFFB3C8)
        static let capPinkStroke   = SwiftUI.Color(hex: 0xE79BC0)
        static let capBall         = SwiftUI.Color(hex: 0xFFFFFF)
        static let armSleeve       = SwiftUI.Color(hex: 0xFFD3B6)
        static let armStroke       = SwiftUI.Color(hex: 0xF2A365)
        static let armHand         = SwiftUI.Color(hex: 0xFFE0C2)
        static let armHandStroke   = SwiftUI.Color(hex: 0xE0A86B)
        static let legPants        = SwiftUI.Color(hex: 0xFFC2DC)
        static let legStroke       = SwiftUI.Color(hex: 0xE79BC0)
        static let slipper         = SwiftUI.Color(hex: 0xFFE08A)
        static let slipperStroke   = SwiftUI.Color(hex: 0xE0A100)
        static let tummyBody       = SwiftUI.Color(hex: 0xFFE08A)
        static let tummyBodyStroke = SwiftUI.Color(hex: 0xF5B700)
        static let tummyFace       = SwiftUI.Color(hex: 0x3A2E1F)
        static let tummyInner      = SwiftUI.Color(hex: 0xFFF3C4)
        static let tummyBlush      = SwiftUI.Color(hex: 0xFF9AA2)
        static let tummyLeafStroke = SwiftUI.Color(hex: 0x7CB342)
        static let tummyLeaf       = SwiftUI.Color(hex: 0x9CCC65)
        static let waveWhite       = SwiftUI.Color(hex: 0xFFFFFF)
        static let wavePink        = SwiftUI.Color(hex: 0xFFB6C1)
        static let bubble          = SwiftUI.Color(hex: 0xFFFFFF)
        static let zzz             = SwiftUI.Color(hex: 0x8FBEF0)

        // 分享平台（对齐 Web 端精确色值）
        static let wechat          = SwiftUI.Color(hex: 0x07C160)
        static let weibo           = SwiftUI.Color(hex: 0xE6162D)
        static let link            = SwiftUI.Color(hex: 0x3B82F6)
    }
    enum FontSize {
        static let xs:  CGFloat = 11
        static let sm:  CGFloat = 13
        static let base:CGFloat = 14
        static let lg:  CGFloat = 16
        static let xl:  CGFloat = 20
        static let xl2: CGFloat = 22
        // 详情页精确字号（对齐 Web）
        static let caption:       CGFloat = 12   // 每份/日期/标签/平台名
        static let calorieBig:    CGFloat = 28   // 热量大数字
        static let nutrientValue: CGFloat = 23   // 营养成分数值
        static let detailTitle:   CGFloat = 18   // 弹窗/分享标题
    }
    enum Spacing {
        static let h:        CGFloat = 20
        static let topBar:   CGFloat = 40
        static let section:  CGFloat = 12
        static let card:     CGFloat = 14
        static let detail:   CGFloat = 24   // 详情页左右边距（Web px-[24px]）
    }
    enum Size {
        static let tipIcon:  CGFloat = 24   // 小贴士图标
        static let metaIcon: CGFloat = 16   // 日期/时间图标
        static let shareBtn: CGFloat = 52   // 分享平台圆形按钮
    }
    enum Radius {
        static let xl:   CGFloat = 32
        static let lg:   CGFloat = 16
        static let md:   CGFloat = 12
        static let sm:   CGFloat = 10
        static let card: CGFloat = 16
        static let sticker: CGFloat = 24
        static let tile: CGFloat = 12
        // 详情页精确圆角（对齐 Web）
        static let stickerLarge:  CGFloat = 28   // 大图圆角
        static let tip:           CGFloat = 18   // 小贴士卡
        static let confirm:       CGFloat = 20   // 删除确认弹窗
        static let sheet:         CGFloat = 24   // 分享面板
        static let nutrientCard:  CGFloat = 6    // 营养成分卡
        static let seg:      CGFloat = 20   // 双 pill 容器圆角（Web rounded-[20px]）
        static let segInner: CGFloat = 17   // 选中/未选按钮圆角（Web rounded-[17px]）
        static let board:    CGFloat = 24   // 胃壁板圆角（Web rounded-[24px]）
    }
    enum Shadow {
        static let card          = SwiftUI.Color.black.opacity(0.03)
        static let cardRadius:   CGFloat = 2
        static let cardY:        CGFloat = 2
        static let sticker       = SwiftUI.Color(hex: 0x10B981).opacity(0.08)
        static let board         = SwiftUI.Color.black.opacity(0.04)
        static let boardRadius:  CGFloat = 16   // Web box-shadow 0 8px 32px → blur/2
        static let boardY:       CGFloat = 8
    }
    enum Board {
        static let height:      CGFloat = 420  // 对齐 Web 端 height: "420px"
        static let stickerSize: CGFloat = 100  // 对齐 Web 端贴纸图片 100px
        static let stickerBorder: CGFloat = 4
        static let tileSize:    CGFloat = 44
        static let tiltMax:     Double  = 8
    }
    enum Week {
        static let itemH:    CGFloat = 60
        static let itemPadX: CGFloat = 4
        static let radius:   CGFloat = 16
        static let border:   CGFloat = 2
        static let gap:      CGFloat = 4
        static let dayFont:  CGFloat = 18
        static let weekFont: CGFloat = 10
        static let dot:      CGFloat = 4
    }
}

// 便捷别名：视图内可直接用 FontSize.xxx
typealias FontSize = CardTokens.FontSize

// MARK: =====================================================================
// MARK: - 数据模型
// MARK: =====================================================================

struct FoodSticker: Identifiable, Equatable {
    let id = UUID()
    let imageName: String
    /// 用户拍照/生成的真实贴纸图（优先于 imageName 渲染），用于保存/预设后回显
    let uiImage: UIKit.UIImage?
    let name: String
    let cal: Int
    let date: String
    let time: String
    let protein: Int
    let carbs: Int
    let fat: Int
    let fiber: Int
    let sugar: Int
    let salt: Double
    let tip: String

    // 显式 init：确保 uiImage 参数始终被编译器识别（避免合成构造器缓存问题）
    init(imageName: String,
         uiImage: UIKit.UIImage? = nil,
         name: String,
         cal: Int,
         date: String = "",
         time: String = "",
         protein: Int = 0,
         carbs: Int = 0,
         fat: Int = 0,
         fiber: Int = 0,
         sugar: Int = 0,
         salt: Double = 0,
         tip: String = "") {
        self.imageName = imageName
        self.uiImage = uiImage
        self.name = name
        self.cal = cal
        self.date = date
        self.time = time
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.salt = salt
        self.tip = tip
    }
}

struct BoardSticker: Identifiable {
    let id = UUID()
    let sticker: FoodSticker
    let left: CGFloat     // 0..1，相对板左边缘
    let top: CGFloat      // 0..1，相对板顶边缘
    let angle: Double
    let scale: Double
    let zIndex: Int
}

enum DiaryMode: String, CaseIterable {
    case me  = "我的"
    case him = "对方的"
}

// MARK: =====================================================================
// MARK: - Mock 数据（对齐 Web 端 foodStickersData）
// MARK: =====================================================================

/// 预设贴纸数据（CardMock），用于贴纸日记页的板子布局和"选择已有"降级展示
enum CardMock {
    static let me: [FoodSticker] = [
        FoodSticker(imageName: "sticker_salad", name: "水果沙拉", cal: 180, date: "7月20日", time: "08:15",
                    protein: 3, carbs: 32, fat: 1, fiber: 5, sugar: 22, salt: 0.1,
                    tip: "五颜六色的水果开派对啦～维C、纤维和花青素全员到齐！记得现拌现吃，用酸奶代替沙拉酱更低卡。"),
        FoodSticker(imageName: "sticker_apple", name: "苹果", cal: 95, date: "7月21日", time: "08:40",
                    protein: 0, carbs: 25, fat: 0, fiber: 4, sugar: 19, salt: 0,
                    tip: "一天一苹果，医生远离我～果皮里的果胶是肠道小扫把，连皮吃更棒哦！"),
        FoodSticker(imageName: "sticker_sandwich", name: "三明治", cal: 320, date: "7月22日", time: "12:20",
                    protein: 14, carbs: 35, fat: 12, fiber: 3, sugar: 4, salt: 1.2,
                    tip: "全麦面包 + 鸡胸 + 蔬菜，蛋白质碳水脂肪刚刚好，午后续航力满格！"),
        FoodSticker(imageName: "sticker_avocado", name: "牛油果", cal: 160, date: "7月23日", time: "12:45",
                    protein: 2, carbs: 9, fat: 15, fiber: 7, sugar: 1, salt: 0.01,
                    tip: "优质脂肪小炸弹！单不饱和脂肪酸呵护小心心，配全麦就是绝绝子。"),
        FoodSticker(imageName: "sticker_milk", name: "牛奶", cal: 120, date: "7月24日", time: "15:30",
                    protein: 8, carbs: 12, fat: 5, fiber: 0, sugar: 12, salt: 0.1,
                    tip: "补钙小能手～温热引用更舒服，乳糖不耐的宝子可以换无乳糖款。"),
        FoodSticker(imageName: "sticker_banana", name: "香蕉", cal: 105, date: "7月25日", time: "16:10",
                    protein: 1, carbs: 27, fat: 0, fiber: 3, sugar: 14, salt: 0,
                    tip: "运动前后吃一根，钾元素帮你赶走疲惫，天然甜味还能解馋！"),
        FoodSticker(imageName: "sticker_egg", name: "鸡蛋", cal: 78, date: "7月26日", time: "19:00",
                    protein: 6, carbs: 0, fat: 5, fiber: 0, sugar: 0, salt: 0.2,
                    tip: "蛋白是吸收率满分的优质蛋白，水煮或少油煎，健身党的本命食材。")
    ]

    static let him: [FoodSticker] = [
        FoodSticker(imageName: "sticker_sandwich", name: "牛油果吐司", cal: 320, date: "7月20日", time: "07:50",
                    protein: 9, carbs: 34, fat: 16, fiber: 5, sugar: 3, salt: 1.4,
                    tip: "他的元气早餐～牛油果 + 全麦吐司，脂肪碳水双在线，开启活力一天！"),
        FoodSticker(imageName: "sticker_milk", name: "蓝莓酸奶", cal: 180, date: "7月21日", time: "08:10",
                    protein: 7, carbs: 24, fat: 4, fiber: 2, sugar: 18, salt: 0.1,
                    tip: "花青素满满的蓝莓碰上益生菌，肠道和眼睛都笑开花～"),
        FoodSticker(imageName: "sticker_banana", name: "鲜橙汁", cal: 150, date: "7月22日", time: "08:35",
                    protein: 2, carbs: 33, fat: 0, fiber: 1, sugar: 28, salt: 0.05,
                    tip: "维C小喷泉！不过果汁糖分偏高，更推荐直接啃橙子留纤维哦。"),
        FoodSticker(imageName: "sticker_salad", name: "沙拉碗", cal: 220, date: "7月23日", time: "12:30",
                    protein: 5, carbs: 22, fat: 11, fiber: 6, sugar: 8, salt: 0.6,
                    tip: "彩虹蔬菜大集会，橄榄油醋汁提香不抢戏，轻盈又顶饱。"),
        FoodSticker(imageName: "sticker_apple", name: "草莓", cal: 90, date: "7月24日", time: "15:00",
                    protein: 1, carbs: 21, fat: 0, fiber: 3, sugar: 15, salt: 0,
                    tip: "红彤彤的甜蜜小炸弹，维C和鞣花酸一起守护你的少女心～"),
        FoodSticker(imageName: "sticker_egg", name: "全麦面包", cal: 200, date: "7月25日", time: "15:40",
                    protein: 8, carbs: 36, fat: 3, fiber: 6, sugar: 3, salt: 1.0,
                    tip: "慢碳水选手，升糖慢、扛饿久，下午茶选它不犯困。"),
        FoodSticker(imageName: "sticker_avocado", name: "蛋白棒", cal: 170, date: "7月26日", time: "18:20",
                    protein: 20, carbs: 18, fat: 5, fiber: 4, sugar: 9, salt: 0.8,
                    tip: "随身蛋白补给站，撸铁前后一根，肌肉悄悄变强壮。")
    ]

    private static func board(for stickers: [FoodSticker], with specs: [(Int, CGFloat, CGFloat, Double, Double, Int)]) -> [BoardSticker] {
        specs.map { s in
            BoardSticker(sticker: stickers[s.0], left: s.1, top: s.2, angle: s.3, scale: s.4, zIndex: s.5)
        }
    }

    static let boardMe: [BoardSticker] = board(for: me, with: [
        (0, 0.20, 0.15, -15, 1.00, 1),
        (1, 0.65, 0.25,   8, 0.85, 2),
        (2, 0.35, 0.45, -22, 0.95, 3),
        (3, 0.70, 0.55,  12, 0.80, 4),
        (4, 0.15, 0.60,  -8, 0.90, 5),
        (5, 0.50, 0.70,  18, 0.88, 6),
        (6, 0.80, 0.35,  -5, 0.75, 7)
    ])

    static let boardHim: [BoardSticker] = board(for: him, with: [
        (0, 0.18, 0.20,  10, 0.95, 1),
        (1, 0.60, 0.18, -12, 0.88, 2),
        (2, 0.72, 0.40,   6, 0.82, 3),
        (3, 0.30, 0.50, -18, 1.00, 4),
        (4, 0.55, 0.60,  15, 0.78, 5),
        (5, 0.20, 0.72,  -6, 0.90, 6),
        (6, 0.78, 0.68,  20, 0.80, 7)
    ])

    static func stickers(for mode: DiaryMode) -> [FoodSticker] { mode == .me ? me : him }
    static func board(for mode: DiaryMode) -> [BoardSticker] { mode == .me ? boardMe : boardHim }
    static func totalCalories(for mode: DiaryMode) -> Int { stickers(for: mode).reduce(0) { $0 + $1.cal } }
}

// MARK: =====================================================================
// MARK: - 顶栏
// MARK: =====================================================================

struct CardTopBar: View {
    let nickname: String
    /// 点击右侧「我的」头像入口（与首页顶部保持一致）
    var onProfileTap: (() -> Void)? = nil

    @ObservedObject private var avatarStore = AvatarStore.shared

    var body: some View {
        // 与首页 TopBarView 统一：问候语 + 昵称(标题) / 副标题，右侧「我的」头像按钮
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("嗨，\(nickname)")
                    .font(.app(size: 22, weight: .bold))
                    .foregroundColor(CardTokens.Color.foreground)
                Text("今天也要好好吃饭呀")
                    .font(.app(size: 13))
                    .foregroundColor(CardTokens.Color.foregroundMuted)
            }
            Spacer()
            Button(action: { onProfileTap?() }) {
                AvatarView(avatarStore.avatarImage, size: 40)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, CardTokens.Spacing.h)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

// MARK: =====================================================================
// MARK: - 双胶囊切换
// MARK: =====================================================================

struct DiarySegmented: View {
    @Binding var mode: DiaryMode
    var body: some View {
        // 对齐 Web：bg-black/4 + rounded-20 + p-3 + gap-2
        HStack(spacing: 2) {
            segItem(.me, icon: "person")
            segItem(.him, icon: "heart")
        }
        .padding(3)
        .background(CardTokens.Color.surfaceBorderSoft)
        .clipShape(RoundedRectangle(cornerRadius: CardTokens.Radius.seg))
    }
    private func segItem(_ m: DiaryMode, icon: String) -> some View {
        let sel = mode == m
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { mode = m }
        } label: {
            // 对齐 Web：gap-5 + px-10 py-5 + rounded-17 + text-12 medium
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.app(size: 12, weight: .medium))
                Text(m.rawValue)
                    .font(.app(size: 12, weight: .medium))
            }
            .foregroundColor(sel ? CardTokens.Color.foreground : CardTokens.Color.foregroundMuted.opacity(0.6))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(sel ? CardTokens.Color.cardBackground : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: CardTokens.Radius.segInner))
            .shadow(color: sel ? CardTokens.Shadow.card : .clear, radius: CardTokens.Shadow.cardRadius, y: CardTokens.Shadow.cardY)
        }
    }
}

// MARK: =====================================================================
// MARK: - 周历
// MARK: =====================================================================

struct WeekDayItem: Identifiable {
    let id: String
    let date: Date
    let day: Int
    let weekday: String
    let isToday: Bool
}

struct DayCell: View {
    let item: WeekDayItem
    let selected: Bool
    var onTap: () -> Void

    var body: some View {
        // 对齐 Web：选中 = 白底 + primary 2px 边框 + shadow-md；未选中 = white/60 + 透明边框
        VStack(spacing: 0) {
            Text(item.weekday)
                .font(.app(size: CardTokens.Week.weekFont, weight: selected ? .medium : .regular))
                .foregroundColor(selected ? CardTokens.Color.primary : CardTokens.Color.foregroundSubtle)
                .padding(.bottom, 4)
            Text("\(item.day)")
                .font(.app(size: CardTokens.Week.dayFont, weight: .bold))
                .foregroundColor(selected ? CardTokens.Color.primary : CardTokens.Color.foreground)
        }
        .frame(maxWidth: .infinity)
        .frame(height: CardTokens.Week.itemH)
        .background(
            RoundedRectangle(cornerRadius: CardTokens.Week.radius)
                .fill(selected ? SwiftUI.Color.white : SwiftUI.Color.white.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CardTokens.Week.radius)
                .stroke(selected ? CardTokens.Color.primary : SwiftUI.Color.clear,
                        lineWidth: CardTokens.Week.border)
        )
        // 底部小圆点：选中或今天可见（对齐 Web opacity 切换）
        .overlay(alignment: .bottom) {
            Circle()
                .fill(CardTokens.Color.primary)
                .frame(width: CardTokens.Week.dot, height: CardTokens.Week.dot)
                .padding(.bottom, 6)
                .opacity(selected || item.isToday ? 1 : 0)
        }
        .shadow(color: selected ? SwiftUI.Color.black.opacity(0.10) : .clear, radius: 6, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: CardTokens.Week.radius))
        .onTapGesture { onTap() }
    }
}

struct WeekCalendarView: View {
    @Binding var selectedDay: Date

    @State private var weekOffset = 0
    @State private var dragX: CGFloat = 0
    @State private var animating = false

    // 对齐 Web：过去 4 周 ~ 未来 4 周
    private static let pastLimit = 4
    private static let futureLimit = 4
    private static let weekdayNames = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

    // 对齐 Web generateWeekDays：以本周一为基准 + offset*7 天
    private func weekDays(_ offset: Int) -> [WeekDayItem] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let wd = cal.component(.weekday, from: today)          // 1 = 周日
        let mondayOffset = wd == 1 ? 6 : wd - 2
        let monday = cal.date(byAdding: .day, value: -mondayOffset + offset * 7, to: today) ?? today
        return (0..<7).map { i in
            let d = cal.date(byAdding: .day, value: i, to: monday) ?? monday
            return WeekDayItem(id: "\(offset)-\(i)",
                               date: d,
                               day: cal.component(.day, from: d),
                               weekday: Self.weekdayNames[i],
                               isToday: cal.isDate(d, inSameDayAs: today))
        }
    }

    private func weekRow(_ offset: Int, width: CGFloat) -> some View {
        HStack(spacing: CardTokens.Week.gap) {
            ForEach(weekDays(offset)) { item in
                DayCell(item: item,
                        selected: Calendar.current.isDate(item.date, inSameDayAs: selectedDay)) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedDay = item.date
                    }
                }
            }
        }
        .frame(width: width)
    }

    var body: some View {
        // 对齐 Web：三页轨道（上一周/当前周/下一周），拖动跟手，越过阈值正向切换后无缝换周
        GeometryReader { geo in
            let pageW = geo.size.width
            HStack(spacing: 0) {
                weekRow(weekOffset - 1, width: pageW)
                weekRow(weekOffset, width: pageW)
                weekRow(weekOffset + 1, width: pageW)
            }
            .frame(height: geo.size.height)
            .offset(x: -pageW + dragX)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { v in
                        guard !animating else { return }
                        var next = v.translation.width
                        // 边界锁死：最旧一周不能再往右拖，最未来一周不能再往左拖
                        let atPastEdge = weekOffset <= -Self.pastLimit && next > 0
                        let atFutureEdge = weekOffset >= Self.futureLimit && next < 0
                        if atPastEdge || atFutureEdge { next = 0 }
                        dragX = max(-pageW, min(pageW, next))
                    }
                    .onEnded { v in
                        guard !animating else { return }
                        let dx = v.translation.width
                        let vx = v.predictedEndTranslation.width - dx   // 惯性速度分量
                        let threshold = pageW * 0.25
                        var target = weekOffset
                        if dx > 0, weekOffset > -Self.pastLimit, dx > threshold || vx > 120 {
                            target -= 1
                        } else if dx < 0, weekOffset < Self.futureLimit, -dx > threshold || -vx > 120 {
                            target += 1
                        }
                        if target != weekOffset {
                            // 阶段一：沿拖拽方向把目标周滑入中心（360ms，对齐 Web cubic-bezier(0.22,1,0.36,1)）
                            animating = true
                            withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.36)) {
                                dragX = -CGFloat(target - weekOffset) * pageW
                            }
                            // 阶段二：动画结束后无缝换周（关闭动画瞬间复位），无反向回弹
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                                var tx = Transaction()
                                tx.disablesAnimations = true
                                withTransaction(tx) {
                                    weekOffset = target
                                    dragX = 0
                                }
                                animating = false
                            }
                        } else {
                            withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.36)) {
                                dragX = 0
                            }
                        }
                    }
            )
        }
        .frame(height: CardTokens.Week.itemH + 8)
        // 只裁左右（隐藏相邻周页面），上下各放宽 14pt，左右各放宽 4pt，避免选中格的绿色边框/下投阴影被裁掉
        .mask(Rectangle().padding(.vertical, -14).padding(.horizontal, -4))
        .padding(.horizontal, CardTokens.Spacing.h)
    }
}

// MARK: =====================================================================
// MARK: - 贴纸卡（食物板上的单张贴纸，使用真实 PNG）
// MARK: =====================================================================

struct StickerChipView: View {
    let sticker: FoodSticker
    let angle: Double
    let scale: Double
    var onTap: () -> Void

    @State private var offset = CGSize.zero
    @State private var start = CGSize.zero
    @State private var dragging = false

    var body: some View {
        let size = CardTokens.Board.stickerSize   // 100
        let r = CardTokens.Radius.sticker         // 24
        ZStack {
            // 阴影光晕层（对齐 Web：rgba(16,185,129,0.08) + blur8，位于图片后方）
            RoundedRectangle(cornerRadius: r)
                .fill(CardTokens.Color.primary.opacity(0.08))
                .frame(width: size, height: size)
                .blur(radius: 8)
                .offset(y: 8)

            // 图片层（对齐 Web：object-cover 填满 + 白边4 + 圆角24 + 阴影 0_4px_16px）
            StickerImageView(sticker: sticker, contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: r))
                .overlay(RoundedRectangle(cornerRadius: r)
                    .stroke(Color.white, lineWidth: CardTokens.Board.stickerBorder))
                .shadow(color: .black.opacity(0.08), radius: 16, y: 4)
        }
        .frame(width: size, height: size)
        // 标签：悬挂在图片下方（对齐 Web -bottom-36px 的纵向双行标签）
        .overlay(alignment: .top) {
            VStack(spacing: 2) {
                Text(sticker.name)
                    .font(.app(size: 10, weight: .medium))
                    .foregroundColor(CardTokens.Color.foreground)
                Text("\(sticker.cal) Kcal")
                    .font(.app(size: 9, weight: .bold))
                    .foregroundColor(CardTokens.Color.labelCal)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(CardTokens.Color.cardBackground.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            .offset(y: size + 6)
        }
        .rotationEffect(.degrees(angle))
        .scaleEffect(scale)
        .scaleEffect(dragging ? 1.08 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: dragging)
        .offset(offset)
        // 点按打开详情；长按后拖动移动贴纸（避免普通拖动手势拦截页面上下滚动）
        .onTapGesture { onTap() }
        .gesture(
            // maximumDistance 放宽到 40pt：手指轻微移动不再取消长按（原默认 10pt 是"要按好几次"的主因）
            // DragGesture 使用 .global 坐标系：贴纸自身被 offset 移动后不会反馈干扰拖动坐标（原局部坐标系会抖动）
            LongPressGesture(minimumDuration: 0.25, maximumDistance: 40)
                .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
                .onChanged { value in
                    if case .second(true, let drag) = value {
                        if !dragging {
                            dragging = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        if let drag {
                            offset = CGSize(width: start.width + drag.translation.width,
                                            height: start.height + drag.translation.height)
                        }
                    }
                }
                .onEnded { value in
                    if case .second(true, let drag?) = value {
                        start = CGSize(width: start.width + drag.translation.width,
                                       height: start.height + drag.translation.height)
                        offset = start
                    }
                    dragging = false
                }
        )
    }
}

// MARK: =====================================================================
// MARK: - 胃壁波浪（1:1 还原 Web 两层 svg path）
// MARK: =====================================================================

struct WavePathView: View {
    let color: SwiftUI.Color
    let variant: Int   // 1 = 白色高光层，2 = 粉色褶皱层
    var body: some View {
        Canvas { ctx, size in
            let X = { (x: CGFloat) in x / 400 * size.width }
            let Y = { (y: CGFloat) in y / 300 * size.height }
            var p = Path()
            p.move(to: CGPoint(x: X(0), y: Y(variant == 1 ? 150 : 170)))
            if variant == 1 {
                p.addCurve(to: CGPoint(x: X(240), y: Y(140)),
                           control1: CGPoint(x: X(80), y: Y(100)),
                           control2: CGPoint(x: X(160), y: Y(190)))
                p.addCurve(to: CGPoint(x: X(400), y: Y(130)),
                           control1: CGPoint(x: X(320), y: Y(95)),
                           control2: CGPoint(x: X(360), y: Y(160)))
            } else {
                p.addCurve(to: CGPoint(x: X(240), y: Y(160)),
                           control1: CGPoint(x: X(80), y: Y(120)),
                           control2: CGPoint(x: X(160), y: Y(200)))
                p.addCurve(to: CGPoint(x: X(400), y: Y(150)),
                           control1: CGPoint(x: X(320), y: Y(120)),
                           control2: CGPoint(x: X(360), y: Y(180)))
            }
            p.addLine(to: CGPoint(x: X(400), y: Y(300)))
            p.addLine(to: CGPoint(x: X(0), y: Y(300)))
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
        }
    }
}

struct WaveLayer: View {
    let width: CGFloat
    let height: CGFloat
    var body: some View {
        let h1 = height * 0.46
        let h2 = height * 0.30
        ZStack(alignment: .bottomLeading) {
            WavePathView(color: CardTokens.Color.waveWhite.opacity(0.4), variant: 1)
                .frame(width: width, height: h1)
            WavePathView(color: CardTokens.Color.wavePink.opacity(0.3), variant: 2)
                .frame(width: width, height: h2)
        }
        .frame(width: width, height: height, alignment: .bottomLeading)
    }
}

// MARK: =====================================================================
// MARK: - 泡泡（1:1 还原 Web TUMMY_BUBBLES 上浮动画）
// MARK: =====================================================================

struct Bubbles: View {
    let width: CGFloat
    let height: CGFloat
    @State private var rise = false
    let specs: [(left: CGFloat, size: CGFloat, dur: Double, delay: Double)] = [
        (0.10, 22, 7.0, 0.0),
        (0.26, 12, 6.0, 1.4),
        (0.44, 28, 9.0, 0.8),
        (0.62, 15, 7.5, 2.2),
        (0.80, 20, 8.0, 0.4)
    ]
    var body: some View {
        ZStack {
            ForEach(0..<specs.count, id: \.self) { i in
                let s = specs[i]
                bubble(size: s.size)
                    .position(x: width * s.left, y: rise ? height * 0.15 : height * 0.85)
                    .opacity(rise ? 0 : 0.7)
                    .animation(.easeInOut(duration: s.dur).repeatForever(autoreverses: false).delay(s.delay),
                               value: rise)
            }
        }
        .onAppear { rise = true }
    }
    func bubble(size: CGFloat) -> some View {
        Circle()
            .fill(CardTokens.Color.bubble.opacity(0.5))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .fill(CardTokens.Color.bubble.opacity(0.7))
                    .frame(width: size * 0.5, height: size * 0.5)
                    .offset(y: -size * 0.15)
            )
    }
}

// MARK: =====================================================================
// MARK: - 小人 SVG（1:1 还原 Web CharHead / CharArm / CharLegs）
// MARK: =====================================================================

struct CharHeadCanvas: View {
    var body: some View {
        Canvas { ctx, size in
            let X = { (x: CGFloat) in x / 120 * size.width }
            let Y = { (y: CGFloat) in y / 120 * size.height }

            // 脸
            let face = Path(roundedRect: CGRect(x: X(18), y: Y(30), width: X(84), height: Y(82)),
                            cornerRadius: X(26))
            ctx.fill(face, with: .color(CardTokens.Color.skin))
            ctx.stroke(face, with: .color(CardTokens.Color.skinStroke),
                       style: StrokeStyle(lineWidth: X(3)))
            // 腮红
            for c in [(38.0, 82.0), (82.0, 82.0)] {
                let r = Path(ellipseIn: CGRect(x: X(c.0 - 8), y: Y(c.1 - 8), width: X(16), height: Y(16)))
                ctx.fill(r, with: .color(CardTokens.Color.blushOpacity))
            }
            // 睡眼 ^
            for e in [(32.0, 70.0, 42.0, 60.0, 52.0, 70.0),
                      (68.0, 70.0, 78.0, 60.0, 88.0, 70.0)] {
                var p = Path()
                p.move(to: CGPoint(x: X(e.0), y: Y(e.1)))
                p.addQuadCurve(to: CGPoint(x: X(e.4), y: Y(e.5)),
                               control: CGPoint(x: X(e.2), y: Y(e.3)))
                ctx.stroke(p, with: .color(CardTokens.Color.skinStroke),
                           style: StrokeStyle(lineWidth: X(3.2), lineCap: .round))
            }
            // 嘴
            var m = Path()
            m.move(to: CGPoint(x: X(50), y: Y(86)))
            m.addQuadCurve(to: CGPoint(x: X(70), y: Y(86)), control: CGPoint(x: X(60), y: Y(96)))
            ctx.stroke(m, with: .color(CardTokens.Color.skinStroke),
                       style: StrokeStyle(lineWidth: X(3.2), lineCap: .round))
            // 睡帽
            var cap = Path()
            cap.move(to: CGPoint(x: X(22), y: Y(40)))
            cap.addCurve(to: CGPoint(x: X(108), y: Y(26)),
                         control1: CGPoint(x: X(48), y: Y(4)),
                         control2: CGPoint(x: X(92), y: Y(2)))
            cap.addCurve(to: CGPoint(x: X(98), y: Y(39)),
                         control1: CGPoint(x: X(112), y: Y(33)),
                         control2: CGPoint(x: X(106), y: Y(41)))
            cap.addCurve(to: CGPoint(x: X(26), y: Y(44)),
                         control1: CGPoint(x: X(74), y: Y(20)),
                         control2: CGPoint(x: X(44), y: Y(22)))
            cap.addCurve(to: CGPoint(x: X(22), y: Y(40)),
                         control1: CGPoint(x: X(22), y: Y(46)),
                         control2: CGPoint(x: X(20), y: Y(44)))
            cap.closeSubpath()
            ctx.fill(cap, with: .color(CardTokens.Color.capPink))
            ctx.stroke(cap, with: .color(CardTokens.Color.capPinkStroke),
                       style: StrokeStyle(lineWidth: X(3)))
            // 帽边线
            var cl = Path()
            cl.move(to: CGPoint(x: X(22), y: Y(40)))
            cl.addQuadCurve(to: CGPoint(x: X(98), y: Y(39)), control: CGPoint(x: X(60), y: Y(26)))
            ctx.stroke(cl, with: .color(CardTokens.Color.capPinkStroke),
                       style: StrokeStyle(lineWidth: X(5), lineCap: .round))
            // 帽球
            let ball = Path(ellipseIn: CGRect(x: X(108 - 8), y: Y(26 - 8), width: X(16), height: Y(16)))
            ctx.fill(ball, with: .color(CardTokens.Color.capBall))
            ctx.stroke(ball, with: .color(CardTokens.Color.capPinkStroke),
                       style: StrokeStyle(lineWidth: X(2)))
            // Zzz
            var z = Path()
            z.move(to: CGPoint(x: X(94), y: Y(10)))
            z.addLine(to: CGPoint(x: X(104), y: Y(10)))
            z.addLine(to: CGPoint(x: X(94), y: Y(20)))
            z.addLine(to: CGPoint(x: X(104), y: Y(20)))
            ctx.stroke(z, with: .color(CardTokens.Color.zzz),
                       style: StrokeStyle(lineWidth: X(3), lineCap: .round, lineJoin: .round))
        }
    }
}

struct CharArmCanvas: View {
    var body: some View {
        Canvas { ctx, size in
            let X = { (x: CGFloat) in x / 60 * size.width }
            let Y = { (y: CGFloat) in y / 90 * size.height }
            // 袖子
            var sleeve = Path()
            sleeve.move(to: CGPoint(x: X(40), y: Y(8)))
            sleeve.addCurve(to: CGPoint(x: X(10), y: Y(52)),
                            control1: CGPoint(x: X(18), y: Y(12)),
                            control2: CGPoint(x: X(8), y: Y(30)))
            sleeve.addCurve(to: CGPoint(x: X(26), y: Y(55)),
                            control1: CGPoint(x: X(11), y: Y(62)),
                            control2: CGPoint(x: X(22), y: Y(64)))
            sleeve.addCurve(to: CGPoint(x: X(48), y: Y(20)),
                            control1: CGPoint(x: X(30), y: Y(40)),
                            control2: CGPoint(x: X(36), y: Y(26)))
            sleeve.closeSubpath()
            ctx.fill(sleeve, with: .color(CardTokens.Color.armSleeve))
            ctx.stroke(sleeve, with: .color(CardTokens.Color.armStroke),
                       style: StrokeStyle(lineWidth: X(3)))
            // 袖口
            let cuff = Path(ellipseIn: CGRect(x: X(16 - 12), y: Y(54 - 9), width: X(24), height: Y(18)))
            ctx.fill(cuff, with: .color(.white))
            ctx.stroke(cuff, with: .color(CardTokens.Color.armStroke),
                       style: StrokeStyle(lineWidth: X(2)))
            // 小手
            let hand = Path(ellipseIn: CGRect(x: X(14 - 9), y: Y(58 - 9), width: X(18), height: Y(18)))
            ctx.fill(hand, with: .color(CardTokens.Color.armHand))
            ctx.stroke(hand, with: .color(CardTokens.Color.armHandStroke),
                       style: StrokeStyle(lineWidth: X(2)))
        }
    }
}

struct CharLegsCanvas: View {
    var body: some View {
        Canvas { ctx, size in
            let X = { (x: CGFloat) in x / 160 * size.width }
            let Y = { (y: CGFloat) in y / 60 * size.height }
            func pants(_ x0: CGFloat) -> Path {
                var p = Path()
                p.move(to: CGPoint(x: X(x0), y: Y(0)))
                p.addLine(to: CGPoint(x: X(x0), y: Y(38)))
                p.addQuadCurve(to: CGPoint(x: X(x0 + 12), y: Y(50)), control: CGPoint(x: X(x0), y: Y(50)))
                p.addLine(to: CGPoint(x: X(x0 + 26), y: Y(50)))
                p.addQuadCurve(to: CGPoint(x: X(x0 + 38), y: Y(38)), control: CGPoint(x: X(x0 + 38), y: Y(50)))
                p.addLine(to: CGPoint(x: X(x0 + 38), y: Y(0)))
                p.closeSubpath()
                return p
            }
            let lp = pants(40)
            ctx.fill(lp, with: .color(CardTokens.Color.legPants))
            ctx.stroke(lp, with: .color(CardTokens.Color.legStroke), style: StrokeStyle(lineWidth: X(3)))
            let rp = pants(82)
            ctx.fill(rp, with: .color(CardTokens.Color.legPants))
            ctx.stroke(rp, with: .color(CardTokens.Color.legStroke), style: StrokeStyle(lineWidth: X(3)))
            // 裤脚
            func cuffRect(_ x0: CGFloat) {
                let r = Path(roundedRect: CGRect(x: X(x0), y: Y(34), width: X(42), height: Y(13)),
                             cornerRadius: X(6))
                ctx.fill(r, with: .color(.white))
                ctx.stroke(r, with: .color(CardTokens.Color.legStroke), style: StrokeStyle(lineWidth: X(2)))
            }
            cuffRect(38)
            cuffRect(80)
            // 拖鞋
            func slipper(_ cx: CGFloat) {
                let s = Path(ellipseIn: CGRect(x: X(cx - 17), y: Y(53 - 7), width: X(34), height: Y(14)))
                ctx.fill(s, with: .color(CardTokens.Color.slipper))
                ctx.stroke(s, with: .color(CardTokens.Color.slipperStroke), style: StrokeStyle(lineWidth: X(2)))
            }
            slipper(59)
            slipper(101)
        }
    }
}

// MARK: =====================================================================
// MARK: - 小人部件（带 Web 端微动画）
// MARK: =====================================================================

struct BellyHeadView: View {
    @State private var bob = false
    var body: some View {
        CharHeadCanvas()
            .frame(width: 122, height: 112)
            .offset(y: bob ? -8 : 0)
            .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: bob)
            .onAppear { bob = true }
    }
}

struct BellyLeftHandView: View {
    @State private var wave = false
    var body: some View {
        CharArmCanvas()
            .frame(width: 58, height: 86)
            .rotationEffect(.degrees(wave ? 10 : -6), anchor: .bottom)
            .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: wave)
            .onAppear { wave = true }
    }
}

struct BellyRightHandView: View {
    var body: some View {
        CharArmCanvas()
            .frame(width: 58, height: 86)
            .scaleEffect(x: -1)
            .rotationEffect(.degrees(8))
    }
}

struct BellyLegsView: View {
    var body: some View {
        CharLegsCanvas()
            .frame(width: 170, height: 62)
    }
}

// MARK: =====================================================================
// MARK: - 食物板 + 睡觉小人组合
// MARK: =====================================================================

struct FoodBoardView: View {
    let stickers: [BoardSticker]
    @Binding var selected: FoodSticker?
    let totalCalories: Int
    var onAddTap: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = CardTokens.Board.height
            ZStack {
                // 胃壁（对齐 Web radial-gradient 背景）
                Rectangle()
                    .fill(RadialGradient(colors: [CardTokens.Color.boardInner,
                                                  CardTokens.Color.boardMid,
                                                  CardTokens.Color.boardEdge],
                                         center: .init(x: 0.5, y: 0.14),
                                         startRadius: 0,
                                         endRadius: h * 0.95))
                    .frame(width: w, height: h)

                // 顶部高光
                RadialGradient(colors: [.white.opacity(0.65), .white.opacity(0)],
                               center: .init(x: 0.5, y: 0.10),
                               startRadius: 0,
                               endRadius: h * 0.55)
                    .frame(width: w, height: h)
                    .allowsHitTesting(false)

                WaveLayer(width: w, height: h)
                    .drawingGroup()   // 静态 Canvas 波浪层光栅化，减少滚动时重绘，提升上下滚动流畅度
                    .allowsHitTesting(false)

                Bubbles(width: w, height: h)
                    .frame(width: w, height: h)
                    .allowsHitTesting(false)

                // 空状态提示
                if stickers.isEmpty {
                    VStack(spacing: 10) {
                        Circle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.app(size: 22, weight: .medium))
                                    .foregroundColor(CardTokens.Color.primary.opacity(0.6))
                            )
                            .onTapGesture {
                                onAddTap?()
                            }
                        Text("这一天还没有记录食物")
                            .font(.app(size: 14, weight: .medium))
                            .foregroundColor(CardTokens.Color.foregroundMuted)
                    }
                }

                // 贴纸
                ForEach(stickers) { bs in
                    StickerChipView(sticker: bs.sticker,
                                    angle: bs.angle,
                                    scale: bs.scale) {
                        selected = bs.sticker
                    }
                    .position(x: bs.left * w, y: bs.top * h)
                    .zIndex(Double(bs.zIndex))
                }

                // 底部消化状态条（对齐 Web bg-white/55 通栏）
                VStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "flame")
                            .font(.app(size: 11))
                            .foregroundColor(CardTokens.Color.foregroundSubtle)
                        Text("消化中 · 已入肚 \(totalCalories) Kcal，转化 1600 Kcal 能量")
                            .font(.app(size: 11))
                            .foregroundColor(CardTokens.Color.foregroundSubtle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(SwiftUI.Color.white.opacity(0.55))
                }
                .frame(width: w, height: h)
                .allowsHitTesting(false)
            }
            .frame(width: w, height: h)
            // 整板按 24 圆角裁剪（含底部两角，对齐 Web rounded-[24px] + overflow-hidden）
            .clipShape(RoundedRectangle(cornerRadius: CardTokens.Radius.board))
            .overlay(
                RoundedRectangle(cornerRadius: CardTokens.Radius.board)
                    .stroke(CardTokens.Color.surfaceBorder, lineWidth: 1)
            )
            .shadow(color: CardTokens.Shadow.board,
                    radius: CardTokens.Shadow.boardRadius, y: CardTokens.Shadow.boardY)
        }
        .frame(height: CardTokens.Board.height)
    }
}

struct BellyCharacterView: View {
    let stickers: [BoardSticker]
    @Binding var selected: FoodSticker?
    let totalCalories: Int
    var onAddTap: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let boardW = w - CardTokens.Spacing.h * 2   // 与卡片同宽
            let boardH = CardTokens.Board.height
            // 对齐 Web：paddingTop 58 / paddingBottom 34；头 112 高压板 54；裤腿与板底重叠 28
            let padTop: CGFloat = 58
            let padBottom: CGFloat = 34
            let totalH = padTop + boardH + padBottom
            let boardLeft = (w - boardW) / 2

            ZStack {
                // 裤腿（对齐 Web z-[0]：位于板后方，底部对齐容器）
                BellyLegsView()
                    .position(x: w / 2, y: totalH - 31)

                // 胃壁板（z-[1]）
                FoodBoardView(stickers: stickers, selected: $selected, totalCalories: totalCalories, onAddTap: onAddTap)
                    .frame(width: boardW, height: boardH)
                    .position(x: w / 2, y: padTop + boardH / 2)

                // 头部（顶部居中，压在板上缘 54pt）
                BellyHeadView()
                    .position(x: w / 2, y: 56)

                // 左手（Web left:-14px top:92：紧贴板左缘，完整可见）
                BellyLeftHandView()
                    .position(x: boardLeft - 14 + 29, y: 92 + 43)

                // 右手（Web right:-14px top:150）
                BellyRightHandView()
                    .position(x: w - boardLeft + 14 - 29, y: 150 + 43)
            }
            .frame(width: w, height: totalH)
        }
        .frame(height: CardTokens.Board.height + 92)
    }
}

// MARK: =====================================================================
// MARK: - 预算卡
// MARK: =====================================================================

struct CalorieBudgetCard: View {
    let target: Int
    let consumed: Int
    private var progress: CGFloat { CGFloat(min(consumed, target)) / CGFloat(max(target, 1)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.app(size: FontSize.sm, weight: .semibold))
                        .foregroundColor(CardTokens.Color.primary)
                    Text("今日热量预算")
                        .font(.app(size: FontSize.base, weight: .semibold))
                        .foregroundColor(CardTokens.Color.foreground)
                }
                Spacer()
                Text("\(consumed) / \(target) kcal")
                    .font(.app(size: FontSize.sm, weight: .medium))
                    .foregroundColor(CardTokens.Color.foregroundMuted)
            }
            ProgressBarView(progress: progress, height: 8, cornerRadius: 4, gradient: ProgressGradient.primary)
        }
        .padding(CardTokens.Spacing.card)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CardTokens.Radius.card)
                .fill(CardTokens.Color.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: CardTokens.Radius.card)
                        .stroke(CardTokens.Color.surfaceBorder, lineWidth: 1)
                )
                .shadow(color: CardTokens.Shadow.card, radius: CardTokens.Shadow.cardRadius, y: CardTokens.Shadow.cardY)
        )
        .padding(.horizontal, CardTokens.Spacing.h)
    }
}

// MARK: =====================================================================
// MARK: - 记录列表
// MARK: =====================================================================

struct FoodRecordList: View {
    let records: [FoodSticker]
    var onSelect: ((FoodSticker) -> Void)? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: CardTokens.Spacing.section) {
            Text("今日记录")
                .font(.app(size: FontSize.lg, weight: .bold))
                .foregroundColor(CardTokens.Color.foreground)
                .padding(.horizontal, CardTokens.Spacing.h)

            VStack(spacing: 10) {
                ForEach(records) { r in
                    HStack(spacing: 12) {
                        // 优先展示真实保存的食物图片（uiImage），其次是预置贴纸，最后回退为首字占位
                        if let ui = r.uiImage {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFit()
                                .frame(width: CardTokens.Board.tileSize, height: CardTokens.Board.tileSize)
                                .background(
                                    RoundedRectangle(cornerRadius: CardTokens.Radius.tile)
                                        .fill(CardTokens.Color.primaryBg10)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: CardTokens.Radius.tile))
                        } else if !r.imageName.isEmpty {
                            Image(r.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: CardTokens.Board.tileSize, height: CardTokens.Board.tileSize)
                                .background(
                                    RoundedRectangle(cornerRadius: CardTokens.Radius.tile)
                                        .fill(CardTokens.Color.primaryBg10)
                                )
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: CardTokens.Radius.tile)
                                    .fill(CardTokens.Color.primaryBg10)
                                Text(String(r.name.prefix(1)))
                                    .font(.app(size: 18, weight: .bold))
                                    .foregroundColor(CardTokens.Color.primary)
                            }
                            .frame(width: CardTokens.Board.tileSize, height: CardTokens.Board.tileSize)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(r.name)
                                .font(.app(size: FontSize.base, weight: .semibold))
                                .foregroundColor(CardTokens.Color.foreground)
                            HStack(spacing: 8) {
                                Label("\(r.date)", systemImage: "calendar")
                                    .font(.app(size: FontSize.xs))
                                    .foregroundColor(CardTokens.Color.foregroundSubtle)
                                Label("\(r.time)", systemImage: "clock")
                                    .font(.app(size: FontSize.xs))
                                    .foregroundColor(CardTokens.Color.foregroundSubtle)
                            }
                        }
                        Spacer()
                        Text("\(r.cal) kcal")
                            .font(.app(size: FontSize.sm, weight: .bold))
                            .foregroundColor(CardTokens.Color.primary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: CardTokens.Radius.md)
                            .fill(CardTokens.Color.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: CardTokens.Radius.md)
                                    .stroke(CardTokens.Color.surfaceBorder, lineWidth: 1)
                            )
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect?(r) }
                }
            }
            .padding(.horizontal, CardTokens.Spacing.h)
        }
    }
}

// MARK: =====================================================================
// MARK: - 贴纸详情页
// MARK: =====================================================================

struct StickerDetailView: View {
    let stickers: [FoodSticker]
    let initialIndex: Int
    var onDelete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var current: Int
    @State private var dragX: CGFloat = 0
    @State private var showDelete = false
    @State private var showShare = false
    @State private var toast: String?

    init(stickers: [FoodSticker], initialIndex: Int, onDelete: (() -> Void)? = nil) {
        self.stickers = stickers
        self.initialIndex = initialIndex
        self.onDelete = onDelete
        _current = State(initialValue: min(max(initialIndex, 0), max(stickers.count - 1, 0)))
    }

    private var sticker: FoodSticker { stickers[current % max(stickers.count, 1)] }

    // 营养成分网格（对齐 Web：碳水/蛋白质/脂肪/膳食纤维/糖/盐，全部以 g 展示，单位不折行）
    private var nutrients: [(label: String, value: String)] {
        func fmt(_ v: Double) -> String {
            v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
        }
        return [("碳水", "\(sticker.carbs)"),
                ("蛋白质", "\(sticker.protein)"),
                ("脂肪", "\(sticker.fat)"),
                ("膳食纤维", "\(sticker.fiber)"),
                ("糖", "\(sticker.sugar)"),
                ("盐", fmt(sticker.salt))]
    }

    private var slideH: CGFloat { UIScreen.main.bounds.height * 0.32 }   // Web h-[32svh]
    private let slideFrac: CGFloat = 0.56                                // Web SLIDE_VW = 56vw

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 顶部贴纸轮播区（还原 Web：中间主图 + 左右半透明相邻贴纸，跟手拖拽切换）
                carousel
                    .frame(height: slideH)
                    .background(
                        LinearGradient(colors: [.white, CardTokens.Color.background],
                                       startPoint: .top, endPoint: .bottom)
                    )

                // 详情内容区（可滚动以容纳小贴士完整文本）
                ScrollView(showsIndicators: false) {
                    detailContent
                }

                // 底部操作栏
                bottomBar
            }
            .background(CardTokens.Color.background)
            .ignoresSafeArea(.container, edges: .bottom)

            if showDelete { deleteAlert }
            if showShare { sharePanel }
            if let toast { toastOverlay(toast) }
        }
    }

    // MARK: 贴纸轮播（还原 Web：56% 宽轨道，主图 80% 宽 / 20svh 高，相邻贴纸按距离半透明缩小，跟手拖拽）
    private var carousel: some View {
        GeometryReader { geo in
            let winW = geo.size.width
            let slideW = winW * slideFrac
            let imgH = UIScreen.main.bounds.height * 0.20    // Web h-[20svh]
            let cpos = CGFloat(current) - dragX / max(slideW, 1)

            HStack(spacing: 0) {
                ForEach(Array(stickers.enumerated()), id: \.element.id) { i, s in
                    let dist = abs(CGFloat(i) - cpos)
                    let opacity = max(0.5, 1 - dist * 0.7)         // Web: max(0.5, 1 - dist*0.7)
                    let scale = 1 - min(0.1, dist * 0.08)          // Web: 1 - min(0.1, dist*0.08)
                    // 优先展示真实保存的食物图片（uiImage），其次是预置贴纸，最后回退为首字占位
                    if let ui = s.uiImage {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(width: slideW * 0.8, height: imgH)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .overlay(RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white, lineWidth: 5))
                            .shadow(color: CardTokens.Color.primary.opacity(0.22), radius: 11, y: 10)
                            .opacity(opacity)
                            .scaleEffect(scale)
                            .frame(width: slideW)
                    } else if !s.imageName.isEmpty {
                        Image(s.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: slideW * 0.8, height: imgH)  // Web w-[80%]
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .overlay(RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white, lineWidth: 5))
                            .shadow(color: CardTokens.Color.primary.opacity(0.22), radius: 11, y: 10)
                            .opacity(opacity)
                            .scaleEffect(scale)
                            .frame(width: slideW)
                    } else {
                        ZStack {
                            Color.white
                                .clipShape(RoundedRectangle(cornerRadius: 28))
                                .overlay(RoundedRectangle(cornerRadius: 28)
                                    .stroke(CardTokens.Color.primary.opacity(0.15), lineWidth: 1))
                            Text(String(s.name.prefix(1)))
                                .font(.app(size: 32, weight: .bold))
                                .foregroundColor(CardTokens.Color.primary)
                        }
                        .frame(width: slideW * 0.8, height: imgH)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: CardTokens.Color.primary.opacity(0.15), radius: 6, y: 4)
                        .opacity(opacity)
                        .scaleEffect(scale)
                        .frame(width: slideW)
                    }
                }
            }
            .frame(height: geo.size.height)
            .offset(x: (winW - slideW) / 2 - CGFloat(current) * slideW + dragX)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { v in dragX = v.translation.width }
                    .onEnded { v in
                        let delta = -v.translation.width / max(slideW, 1)
                        let target = max(0, min(stickers.count - 1,
                                                Int((CGFloat(current) + delta).rounded())))
                        withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.38)) {
                            current = target
                            dragX = 0
                        }
                    }
            )
        }
    }

    // MARK: 详情内容
    private var detailContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 基础信息：名称 + 热量（对齐 Web：居中上下排列）
            VStack(spacing: 2) {
                Text(sticker.name)
                    .font(.app(size: FontSize.xl2, weight: .bold))
                    .foregroundColor(CardTokens.Color.foreground)
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text("\(sticker.cal)")
                        .font(.app(size: FontSize.calorieBig, weight: .bold))
                        .foregroundColor(CardTokens.Color.primary)
                    Text("Kcal")
                        .font(.app(size: FontSize.caption))
                        .foregroundColor(CardTokens.Color.foregroundSubtle)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, CardTokens.Spacing.detail)

            // 营养成分卡（Web flat-card：白底、圆角16、边框、阴影）
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(CardTokens.Color.primary)
                        .frame(width: 4, height: 15)
                    Text("营养成分")
                        .font(.app(size: FontSize.lg, weight: .bold))
                        .foregroundColor(CardTokens.Color.foreground)
                    Text("/ 每份")
                        .font(.app(size: FontSize.xs))
                        .foregroundColor(CardTokens.Color.foregroundSubtle)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 0) {
                    ForEach(Array(nutrients.enumerated()), id: \.offset) { idx, n in
                        VStack(spacing: 5) {
                            Text(n.label)
                                .font(.app(size: FontSize.caption))
                                .foregroundColor(CardTokens.Color.foregroundMuted)
                            // 数值 + 单位同行（对齐 Web：单位紧跟数值，不折行）
                            HStack(alignment: .lastTextBaseline, spacing: 2) {
                                Text(n.value)
                                    .font(.app(size: FontSize.nutrientValue, weight: .bold))
                                    .foregroundColor(CardTokens.Color.primary)
                                Text("g")
                                    .font(.app(size: FontSize.caption))
                                    .foregroundColor(CardTokens.Color.foregroundSubtle)
                            }
                            .lineLimit(1)
                            .fixedSize()
                            .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(alignment: .leading) {
                            if idx % 3 != 0 {
                                Rectangle()
                                    .fill(Color.black.opacity(0.05))
                                    .frame(width: 0.5)
                                    .padding(.vertical, 6)
                            }
                        }
                        .overlay(alignment: .top) {
                            if idx >= 3 {
                                Rectangle()
                                    .fill(Color.black.opacity(0.05))
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 6)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: CardTokens.Radius.lg)
                    .fill(CardTokens.Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: CardTokens.Radius.lg)
                            .stroke(Color.black.opacity(0.05), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal, CardTokens.Spacing.detail)

            // 小贴士卡（Web 圆角 18，primary/20 边框，primary/10 底）
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.app(size: 18))
                        .foregroundColor(CardTokens.Color.primary)
                    Text("小贴士")
                        .font(.app(size: FontSize.lg, weight: .bold))
                        .foregroundColor(CardTokens.Color.primary)
                }
            Text(sticker.tip)
                .font(.app(size: FontSize.base))
                .foregroundColor(CardTokens.Color.foreground)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CardTokens.Radius.tip)
                    .fill(CardTokens.Color.primary.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: CardTokens.Radius.tip)
                        .stroke(CardTokens.Color.primary.opacity(0.2), lineWidth: 1))
            )
            .padding(.horizontal, CardTokens.Spacing.detail)

            // 日期时间行（对齐 Web：整体居中）
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.app(size: CardTokens.Size.metaIcon))
                    .foregroundColor(CardTokens.Color.foregroundMuted)
                Text(sticker.date)
                    .font(.app(size: FontSize.caption))
                    .foregroundColor(CardTokens.Color.foregroundMuted)
                Circle().fill(CardTokens.Color.foregroundSubtle).frame(width: 3, height: 3)
                Image(systemName: "clock")
                    .font(.app(size: CardTokens.Size.metaIcon))
                    .foregroundColor(CardTokens.Color.foregroundMuted)
                Text(sticker.time)
                    .font(.app(size: FontSize.caption))
                    .foregroundColor(CardTokens.Color.foregroundMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, CardTokens.Spacing.detail)

            Spacer(minLength: 0)
        }
    }

    // MARK: 底部操作栏（关闭 / 删除 / 分享）—— 对齐 Web 端样式
    private var bottomBar: some View {
        HStack(spacing: 0) {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.app(size: 24, weight: .medium))
                    .foregroundColor(CardTokens.Color.primary)
                    .frame(width: 48, height: 48)
                    .contentShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
            Spacer()
            Button { showDelete = true } label: {
                Image(systemName: "trash")
                    .font(.app(size: 24))
                    .foregroundColor(CardTokens.Color.primary)
                    .frame(width: 48, height: 48)
                    .contentShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
            Spacer()
            Button { showShare = true } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.app(size: 24))
                    .foregroundColor(CardTokens.Color.primary)
                    .frame(width: 48, height: 48)
                    .contentShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 2)
        .padding(.bottom, max(bottomSafeInset, 4))
        .background(CardTokens.Color.background)
    }

    /// UIKit 安全区域底部高度（兼容 iOS 14）
    private var bottomSafeInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .safeAreaInsets.bottom ?? 0
    }

    // MARK: 删除确认弹窗（Web bg-black/40 + 圆角 20 白卡）
    private var deleteAlert: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
                .onTapGesture { showDelete = false }
            VStack(spacing: 16) {
                Text("删除贴纸")
                    .font(.app(size: FontSize.detailTitle, weight: .bold))
                    .foregroundColor(CardTokens.Color.foreground)
                Text("确定要删除「\(sticker.name)」吗？\n删除后将无法恢复。")
                    .font(.app(size: FontSize.sm))
                    .foregroundColor(CardTokens.Color.foregroundMuted)
                    .multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    Button { showDelete = false } label: {
                        Text("再想想")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundColor(CardTokens.Color.foreground)
                            .background(RoundedRectangle(cornerRadius: 10).fill(CardTokens.Color.background))
                    }
                    Button {
                        showDelete = false
                        dismiss()
                        onDelete?()
                    } label: {
                        Text("删除")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundColor(.white)
                            .background(RoundedRectangle(cornerRadius: 10).fill(CardTokens.Color.error))
                    }
                }
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: CardTokens.Radius.confirm)
                .fill(CardTokens.Color.cardBackground))
            .padding(.horizontal, 40)
        }
    }

    // MARK: 分享面板（Web 底部弹出，圆角 24 白卡，4 平台）
    private var sharePanel: some View {
        let items: [(String, SwiftUI.Color, String, () -> Void)] = [
            ("微信", CardTokens.Color.wechat, "message.fill", { fireToast("已唤起微信") }),
            ("朋友圈", CardTokens.Color.wechat, "sun.haze.fill", { fireToast("已唤起朋友圈") }),
            ("微博", CardTokens.Color.weibo, "flame.fill", { fireToast("已唤起微博") }),
            ("复制链接", CardTokens.Color.link, "link", {
                UIPasteboard.general.string = "https://health.app/sticker/\(sticker.id)"
                fireToast("链接已复制")
            })
        ]
        return VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text("分享「\(sticker.name)」")
                    .font(.app(size: FontSize.detailTitle, weight: .bold))
                    .foregroundColor(CardTokens.Color.foreground)
                HStack(spacing: 24) {
                    ForEach(items, id: \.0) { name, color, icon, action in
                        VStack(spacing: 6) {
                            Button(action: action) {
                                Image(systemName: icon)
                                    .font(.app(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: CardTokens.Size.shareBtn, height: CardTokens.Size.shareBtn)
                                    .background(Circle().fill(color))
                            }
                            Text(name)
                                .font(.app(size: FontSize.caption))
                                .foregroundColor(CardTokens.Color.foregroundMuted)
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(CardTokens.Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CardTokens.Radius.sheet, style: .continuous))

            Button { showShare = false } label: {
                Text("取消")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(CardTokens.Color.foreground)
                    .background(CardTokens.Color.cardBackground)
            }
        }
        .background(Color.black.opacity(0.4).ignoresSafeArea()
            .onTapGesture { showShare = false })
    }

    // MARK: Toast
    private func fireToast(_ msg: String) {
        showShare = false
        toast = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { toast = nil }
    }

    private func toastOverlay(_ msg: String) -> some View {
        VStack {
            Spacer()
            Text(msg)
                .font(.app(size: FontSize.sm))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.black.opacity(0.8)))
                .padding(.bottom, 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea()
    }
}

// MARK: - 通用按压缩放按钮样式（对齐 Web active:scale-90 反馈）
private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: =====================================================================
// MARK: - 主页面
// MARK: =====================================================================

struct CardPageView: View {
    @StateObject private var store = AppDataStore.shared
    @ObservedObject private var avatarStore = AvatarStore.shared
    @State private var mode: DiaryMode = .me
    @State private var selectedDay = Date()
    @State private var selected: FoodSticker?
    @State private var calendarResetID = UUID()
    /// 点击顶部「我的」头像入口
    var onProfile: (() -> Void)? = nil
    /// 点击空状态「+」或需要添加食物 → 唤起拍摄
    var onAddTap: (() -> Void)? = nil
    private var nickname: String {
        if mode == .me {
            // 优先 AvatarStore（全站中枢），回退 profile.name
            let avatarName = avatarStore.nickname
            if avatarName != "未登录" && !avatarName.isEmpty { return avatarName }
            return store.profile.name.isEmpty ? "我" : store.profile.name
        } else {
            return store.partnerProfile.name.isEmpty ? "对方" : store.partnerProfile.name
        }
    }

    private let dayFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "M月d日"; return f
    }()

    /// 当前选中日期对应的「M月d日」标签，用于按日期过滤食物数据
    private var selectedLabel: String { dayFmt.string(from: selectedDay) }

    /// 当前选中日期真实保存的食物
    /// - .me 读取我方记录（todayRecords），.him 读取对方记录（partnerRecords，二维码关联后写入）
    private var foodStickers: [FoodSticker] {
        let source = mode == .me ? store.todayRecords : store.partnerRecords
        return source
            .filter { $0.type == .food && $0.date == selectedLabel }
            .map {
                FoodSticker(imageName: "",
                            uiImage: $0.imageData.flatMap { UIImage(data: $0) },
                            name: $0.name, cal: $0.calories,
                            date: $0.date, time: $0.time,
                            protein: $0.protein, carbs: $0.carbs, fat: $0.fat,
                            fiber: $0.fiber, sugar: $0.sugar, salt: $0.salt, tip: $0.tip)
            }
    }

    // 胃壁板：把当前选中日期的真实贴纸错落摆放（已清空 Mock，仅展示真实数据）
    private var boardStickers: [BoardSticker] {
        foodStickers.enumerated().map { i, s in
            // 在板右上角区域错落摆放真实贴纸
            let lefts: [CGFloat] = [0.30, 0.62, 0.45, 0.78, 0.20]
            let tops:  [CGFloat] = [0.30, 0.45, 0.62, 0.72, 0.18]
            let idx = i % lefts.count
            return BoardSticker(sticker: s,
                                left: lefts[idx],
                                top: tops[idx],
                                angle: Double(idx * 7 - 14),
                                scale: 0.82,
                                zIndex: 10 + i)
        }
    }

    private var boardCalories: Int {
        foodStickers.reduce(0) { $0 + $1.cal }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: CardTokens.Spacing.section) {
                CardTopBar(nickname: nickname, onProfileTap: onProfile)

                // 今天 + 我的/对方的 + 回到今日
                HStack {
                    Text("今天")
                        .font(.app(size: FontSize.xl2, weight: .bold))
                        .foregroundColor(CardTokens.Color.foreground)
                    DiarySegmented(mode: $mode)
                    Spacer()
                    if !Calendar.current.isDate(selectedDay, inSameDayAs: Date()) {
                        Button(action: {
                            selectedDay = Date()
                            calendarResetID = UUID()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 10, weight: .medium))
                                Text("回到今日")
                                    .font(.app(size: 12, weight: .medium))
                            }
                            .foregroundColor(Color(hex: "#4CAF50"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "#E8F5E9"))
                            )
                        }
                    }
                }
                .padding(.horizontal, CardTokens.Spacing.h)
                .padding(.top, 8)

                WeekCalendarView(selectedDay: $selectedDay)
                    .id(calendarResetID)
                    .padding(.top, 4)

                HStack {
                    Text("瞧瞧都吃了些什么？")
                        .font(.app(size: FontSize.lg, weight: .bold))
                        .foregroundColor(CardTokens.Color.foreground)
                    Spacer()
                    Text("总计 \(boardCalories) Kcal")
                        .font(.app(size: FontSize.sm))
                        .foregroundColor(CardTokens.Color.foregroundMuted)
                }
                .padding(.horizontal, CardTokens.Spacing.h)
                .padding(.vertical, 8)

                // 同一份数据实例：胃壁、列表、详情共用，避免 id 不一致导致详情定位错位
                let foods = foodStickers
                BellyCharacterView(stickers: foods.isEmpty ? [] : boardStickers, selected: $selected, totalCalories: boardCalories, onAddTap: onAddTap)

                CalorieBudgetCard(
                    target: AppDataStore.shared.calorieTarget,
                    consumed: boardCalories
                )

                // 今日记录：真实展示当前选中日期保存的食物（动态加载 AppDataStore.todayRecords）
                FoodRecordList(records: foods) { r in
                    selected = r
                }

                Spacer(minLength: 24)
            }
        }
        .background(CardTokens.Color.background)
        // todayRecords / savedStickers / selectedDay / mode 变更 → 刷新依赖子视图
        .onChange(of: store.todayRecords.count) { _ in }
        .onChange(of: store.savedStickers.count) { _ in }
        .onChange(of: selectedDay) { _ in }
        .onChange(of: mode) { _ in }
        .fullScreenCover(item: $selected) { sticker in
            // 使用与列表/胃壁同一份实例，保证点击定位精准（不会回退到第 0 个）
            let stickers = foodStickers
            let idx = stickers.firstIndex(where: { $0.id == sticker.id })
                ?? stickers.firstIndex(where: { $0.name == sticker.name && $0.cal == sticker.cal && $0.time == sticker.time })
                ?? 0
            StickerDetailView(stickers: stickers, initialIndex: idx, onDelete: {
                // 仅在「我的」模式下允许删除；对方记录仅可查看
                guard mode == .me else {
                    selected = nil
                    return
                }
                let target = sticker
                let source = store.todayRecords
                if let record = source.first(where: {
                    $0.name == target.name && $0.calories == target.cal &&
                    $0.date == target.date && $0.time == target.time
                }) {
                    store.removeRecord(record.id)
                }
                selected = nil
            })
        }
    }
}

#Preview {
    CardPageView()
}
