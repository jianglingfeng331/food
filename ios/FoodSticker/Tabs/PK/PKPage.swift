import SwiftUI

// MARK: =====================================================================
// MARK: - PK 设计令牌（1:1 对齐 Web src/pages/PK.tsx，所有样式参数集中于此）
// MARK: =====================================================================

enum PKTokens {

    enum Color {
        static let me        = SwiftUI.Color(hex: 0x10B981)          // C.me
        static let rival     = SwiftUI.Color(hex: 0x34D399)          // C.rival
        static let grid      = SwiftUI.Color.black.opacity(0.05)     // C.grid
        static let sub       = SwiftUI.Color(hex: 0x999999)          // C.sub
        static let faint     = SwiftUI.Color(hex: 0x1A1A1A).opacity(0.03) // C.faint
        static let loseGray  = SwiftUI.Color(hex: 0xBBBBBB)          // 输方文字 #BBBBBB
        static let crownFill = SwiftUI.Color(hex: 0xFFD700)
        static let crownStroke = SwiftUI.Color(hex: 0xE0A100)
        static let rivalBadgeBg = SwiftUI.Color(hex: 0x34D399).opacity(0.15) // rgba(52,211,153,0.15)
        static let background     = CardTokens.Color.background      // #F8F8F8
        static let card           = CardTokens.Color.cardBackground  // #FFFFFF
        static let cardBorder     = CardTokens.Color.surfaceBorder   // rgba(0,0,0,0.05)
        static let divider        = SwiftUI.Color.black.opacity(0.05)
        static let foreground     = CardTokens.Color.foreground      // #1A1A1A
        static let muted          = CardTokens.Color.foregroundMuted // #666666
        static let subtle         = CardTokens.Color.foregroundSubtle// #999999
        static let primary        = CardTokens.Color.primary         // #10B981
        static let primaryBg10    = CardTokens.Color.primaryBg10
        // 水球玻璃质感（Web radialGradient 三段）
        static let glass0 = SwiftUI.Color.white.opacity(0.95)
        static let glass1 = SwiftUI.Color(hex: 0xEAFAF3).opacity(0.35)
        static let glass2 = SwiftUI.Color(hex: 0xCDEEDE).opacity(0.22)
        static let glassStroke = SwiftUI.Color.white.opacity(0.85)
        static let ballRim = SwiftUI.Color(hex: 0x10B981).opacity(0.28)
    }

    enum Font {
        static let cardHeader:  CGFloat = 13   // 本周 PK 战报
        static let weekTag:     CGFloat = 12   // 第 12 周
        static let userName:    CGFloat = 14   // 头像下昵称
        static let winBadge:    CGFloat = 11   // 赢 X 项
        static let compareHead: CGFloat = 12   // 单项对比
        static let metricLabel: CGFloat = 12   // 指标名
        static let metricLead:  CGFloat = 12   // XX 领先
        static let metricValue: CGFloat = 13   // 条上数值
        static let sectionTitle:CGFloat = 16   // 区块标题
        static let legend:      CGFloat = 12
        static let segBtn:      CGFloat = 12
        static let caption:     CGFloat = 12   // 图下说明
        static let captionSm:   CGFloat = 12
        static let exName:      CGFloat = 13
        static let exValue:     CGFloat = 15
        static let ballPct:     CGFloat = 22   // 水球中心百分比
        static let ballLabel:   CGFloat = 13
        static let ballGoal:    CGFloat = 13
        static let trendHead:   CGFloat = 13   // 每日饮水量趋势
        static let weightNote:  CGFloat = 12
    }

    enum Layout {
        static let pageH:       CGFloat = 20   // px-[20px]
        static let pageTop:     CGFloat = 16   // pt-[16px]
        static let pageBottom:  CGFloat = 110  // pb-[110px]
        static let sectionGap:  CGFloat = 14   // space-y-[14px]
        static let cardRadius:  CGFloat = 16   // flat-card radius-lg
        static let cardPad:     CGFloat = 16   // p-[16px]
        static let stripH:      CGFloat = 6    // 战报卡顶部渐变条
        static let avatarSize:  CGFloat = 60
        static let crownSize:   CGFloat = 22
        static let vsCircle:    CGFloat = 46
        static let vsColW:      CGFloat = 60
        static let swordIcon:   CGFloat = 22
        static let barH:        CGFloat = 6    // 对比进度条高
        static let metricGap:   CGFloat = 14   // 指标行间距
        static let titleBarW:   CGFloat = 4    // SectionTitle 圆条
        static let titleBarH:   CGFloat = 15
        static let titleIcon:   CGFloat = 18
        static let legendDot:   CGFloat = 10
        static let ballSize:    CGFloat = 134
    }

    enum Shadow {
        static let card       = SwiftUI.Color.black.opacity(0.03)   // 0 2 8
        static let cardRadius: CGFloat = 4
        static let cardY:      CGFloat = 2
        static let vs         = SwiftUI.Color(hex: 0x10B981).opacity(0.35) // 0 6 16
        static let vsRadius:   CGFloat = 8
        static let vsY:        CGFloat = 6
    }

    enum Anim {
        static let barSwitch = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.4) // Web 400ms
        static let wave1Dur: Double = 3.6
        static let wave2Dur: Double = 5.0
    }
}

// MARK: =====================================================================
// MARK: - 数据（对齐 Web 本周 7/20–7/26 双用户数据）
// MARK: =====================================================================

struct PKUser {
    let name: String
    let avatar: UIImage?        // 已上传头像；为 nil 时使用 emojiAvatar 或默认占位
    let emojiAvatar: String?    // 后端 emoji 头像（兜底）
    let intake: [Double]
    let burned: [Double]
    let exerciseMin: [Double]
    let weights: [Double]
    let waterGoal: Double
    let water: [Double]
}

enum PKMock {
    static let days = ["一", "二", "三", "四", "五", "六", "日"]
    static let today = 5   // 周六

    /// 清空态（数据已清空）：所有数值为 0，头像为 nil（默认占位图）
    static let empty = PKUser(
        name: "", avatar: nil, emojiAvatar: nil,
        intake: [0,0,0,0,0,0,0],
        burned: [0,0,0,0,0,0,0],
        exerciseMin: [0,0,0,0,0,0,0],
        weights: [0,0,0,0,0,0,0],
        waterGoal: 0,
        water: [0,0,0,0,0,0,0])

    // 已清零：与 empty 一致，避免默认假数据干扰测试
    static let me = empty
    static let rival = empty

    // ── 汇总指标（与 Web metrics 完全一致） ──
    struct Metric {
        let label: String
        let me: Double
        let rival: Double
        let unit: String
        let lowerBetter: Bool
        /// 打平：双方数值相等，不计分
        var isTie: Bool { me == rival }
        /// 我方严格胜出（非平局）
        var meWin: Bool { isTie ? false : (lowerBetter ? me < rival : me > rival) }
        /// 对手严格胜出（非平局）
        var rivalWin: Bool { isTie ? false : (lowerBetter ? rival < me : rival > me) }
        func fmt(_ v: Double) -> String {
            v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
        }
        var meText: String { "\(fmt(me))\(unit)" }
        var rivalText: String { "\(fmt(rival))\(unit)" }
    }

    static var metrics: [Metric] {
        func avg(_ a: [Double]) -> Double { a.reduce(0, +) / Double(a.count) }
        func sum(_ a: [Double]) -> Double { a.reduce(0, +) }
        return [
            Metric(label: "平均每日摄入",
                   me: avg(me.intake).rounded(), rival: avg(rival.intake).rounded(),
                   unit: " kcal", lowerBetter: true),
            Metric(label: "总运动消耗",
                   me: sum(me.burned), rival: sum(rival.burned),
                   unit: " kcal", lowerBetter: false),
            Metric(label: "本周减重",
                   me: ((me.weights[0] - me.weights[6]) * 10).rounded() / 10,
                   rival: ((rival.weights[0] - rival.weights[6]) * 10).rounded() / 10,
                   unit: " kg", lowerBetter: false),
            Metric(label: "饮水达标率",
                   me: (Double(me.water.filter { $0 >= me.waterGoal }.count) / 7 * 100).rounded(),
                   rival: (Double(rival.water.filter { $0 >= rival.waterGoal }.count) / 7 * 100).rounded(),
                   unit: "%", lowerBetter: false),
        ]
    }
    static var meWins: Int { metrics.filter { $0.meWin }.count }
    static var rivalWins: Int { metrics.filter { $0.rivalWin }.count }
    static var leaderIsMe: Bool { meWins > rivalWins }
}

// MARK: =====================================================================
// MARK: - 通用小组件
// MARK: =====================================================================

// flat-card：白底 + 圆角16 + 1px 黑5%边框 + 阴影(0,2,8,rgba(0,0,0,0.03))
struct PKFlatCard: ViewModifier {
    var padding: CGFloat = PKTokens.Layout.cardPad
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: PKTokens.Layout.cardRadius)
                    .fill(PKTokens.Color.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: PKTokens.Layout.cardRadius)
                            .stroke(PKTokens.Color.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: PKTokens.Shadow.card,
                            radius: PKTokens.Shadow.cardRadius,
                            y: PKTokens.Shadow.cardY)
            )
    }
}
extension View {
    func pkFlatCard(padding: CGFloat = PKTokens.Layout.cardPad) -> some View {
        modifier(PKFlatCard(padding: padding))
    }
}

// SectionTitle：绿色圆条 + 图标 + 16 bold 标题
struct PKSectionTitle: View {
    let systemIcon: String
    let title: String
    var body: some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(PKTokens.Color.primary)
                .frame(width: PKTokens.Layout.titleBarW, height: PKTokens.Layout.titleBarH)
            Image(systemName: systemIcon)
                .font(.app(size: PKTokens.Layout.titleIcon - 3, weight: .medium))
                .foregroundColor(PKTokens.Color.primary)
                .frame(width: PKTokens.Layout.titleIcon, height: PKTokens.Layout.titleIcon)
            Text(title)
                .font(.app(size: PKTokens.Font.sectionTitle, weight: .bold))
                .foregroundColor(PKTokens.Color.foreground)
            Spacer()
        }
        .padding(.bottom, 14)
    }
}

// Legend：两色圆点图例
struct PKLegend: View {
    var meName: String = PKMock.me.name
    var rivalName: String = PKMock.rival.name
    var body: some View {
        HStack(spacing: 14) {
            legendItem(color: PKTokens.Color.me, name: meName)
            legendItem(color: PKTokens.Color.rival, name: rivalName)
        }
    }
    private func legendItem(color: Color, name: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color)
                .frame(width: PKTokens.Layout.legendDot, height: PKTokens.Layout.legendDot)
            Text(name)
                .font(.app(size: PKTokens.Font.legend))
                .foregroundColor(PKTokens.Color.muted)
        }
    }
}

// Avatar：圆形 + 2px 白色 ring + shadow-sm
struct PKAvatar: View {
    let image: UIImage?
    let emoji: String?
    var size: CGFloat = PKTokens.Layout.avatarSize

    init(image: UIImage? = nil, emoji: String? = nil, size: CGFloat = PKTokens.Layout.avatarSize) {
        self.image = image
        self.emoji = emoji
        self.size = size
    }

    var body: some View {
        if let img = image {
            AvatarView(img, size: size)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        } else if let e = emoji, !e.isEmpty {
            emojiCore(e)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        } else {
            AvatarView(nil, size: size)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
    }

    private func emojiCore(_ e: String) -> some View {
        EmojiAvatar(emoji: e, size: size)
    }
}

// MARK: - Emoji 头像占位（独立 struct 避免类型检查器在 PKAvatar body 中崩溃）
private struct EmojiAvatar: View {
    let emoji: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(PKTokens.Color.primaryBg10)
            Text(emoji)
                .font(.system(size: size * 0.55))
        }
        .frame(width: size, height: size)
    }
}

// 双剑图标（Canvas 复刻 lucide Swords 24×24 路径，白色描边2）
struct SwordsGlyph: View {
    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 24
            ctx.scaleBy(x: s, y: s)
            var style = StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            style.lineWidth = 2
            func stroke(_ pts: [(CGFloat, CGFloat)], closed: Bool = false) {
                var p = Path()
                p.move(to: CGPoint(x: pts[0].0, y: pts[0].1))
                for pt in pts.dropFirst() { p.addLine(to: CGPoint(x: pt.0, y: pt.1)) }
                if closed { p.closeSubpath() }
                ctx.stroke(p, with: .color(.white), style: style)
            }
            stroke([(14.5, 17.5), (3, 6), (3, 3), (6, 3), (17.5, 14.5)])   // 左剑刃
            stroke([(13, 19), (19, 13)])                                    // 左剑格
            stroke([(16, 16), (20, 20)])                                    // 左剑柄
            stroke([(19, 21), (21, 19)])                                    // 左柄尾
            stroke([(14.5, 6.5), (18, 3), (21, 3), (21, 6), (17.5, 10)])    // 右剑刃
            stroke([(5, 14), (9, 18)])                                      // 右剑格
            stroke([(7, 17), (4, 20)])                                      // 右剑柄
            stroke([(3, 19), (5, 21)])                                      // 右柄尾
        }
        .frame(width: PKTokens.Layout.swordIcon, height: PKTokens.Layout.swordIcon)
    }
}

// MARK: =====================================================================
// MARK: - 1. 本周 PK 战报卡
// MARK: =====================================================================

struct BattleReportCard: View {
    var meUser: PKUser = PKMock.me
    var rivalUser: PKUser = PKMock.rival
    var leaderIsMe: Bool = PKMock.leaderIsMe
    var leaderIsRival: Bool = false
    var meWins: Int = PKMock.meWins
    var rivalWins: Int = PKMock.rivalWins
    var metrics: [PKMock.Metric] = PKMock.metrics
    /// 是否已绑定对手：未绑定时只展示自己的数据，不显示对战与皇冠
    var hasOpponent: Bool = true
    /// 双方是否有任何实际数据：无数据时均不显示皇冠
    var hasData: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // 标题行
            HStack {
                Text("本周战报")
                    .font(.app(size: PKTokens.Font.cardHeader, weight: .semibold))
                    .foregroundColor(PKTokens.Color.foreground)
                Spacer()
                if hasOpponent {
                    Text("VS")
                        .font(.app(size: 13, weight: .bold))
                        .foregroundColor(PKTokens.Color.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(PKTokens.Color.primaryBg10))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 4)

            if hasOpponent {
                // 已绑定：双栏对战头部
                HStack(alignment: .top, spacing: 0) {
                    userColumn(user: meUser, crowned: hasData && leaderIsMe,
                               wins: meWins,
                               badgeBg: PKTokens.Color.primaryBg10,
                               badgeFg: PKTokens.Color.primary)
                        .frame(maxWidth: .infinity)

                    Text("VS")
                        .font(.app(size: 14, weight: .bold))
                        .foregroundColor(PKTokens.Color.sub)
                        .frame(width: PKTokens.Layout.vsColW)
                        .frame(maxHeight: .infinity)

                    userColumn(user: rivalUser, crowned: hasData && leaderIsRival,
                               wins: rivalWins,
                               badgeBg: PKTokens.Color.rivalBadgeBg,
                               badgeFg: PKTokens.Color.rival)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                // 单项对比
                VStack(alignment: .leading, spacing: 0) {
                    Divider().overlay(PKTokens.Color.divider)
                    Text("单项对比")
                        .font(.app(size: PKTokens.Font.compareHead, weight: .medium))
                        .foregroundColor(PKTokens.Color.muted)
                        .padding(.top, 14)
                        .padding(.bottom, 12)
                    VStack(spacing: PKTokens.Layout.metricGap) {
                        ForEach(metrics, id: \.label) { m in
                            MetricCompareRow(metric: m)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            } else {
                // 未绑定：仅展示自己的数据
                HStack(alignment: .center, spacing: 0) {
                    PKAvatar(image: meUser.avatar, emoji: meUser.emojiAvatar)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meUser.name)
                            .font(.app(size: PKTokens.Font.userName, weight: .bold))
                            .foregroundColor(PKTokens.Color.foreground)
                        Text("绑定对手后开启对战")
                            .font(.app(size: 12))
                            .foregroundColor(PKTokens.Color.subtle)
                    }
                    .padding(.leading, 12)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                // 仅自己的数据
                VStack(alignment: .leading, spacing: 0) {
                    Divider().overlay(PKTokens.Color.divider)
                    Text("我的数据")
                        .font(.app(size: PKTokens.Font.compareHead, weight: .medium))
                        .foregroundColor(PKTokens.Color.muted)
                        .padding(.top, 14)
                        .padding(.bottom, 12)
                    VStack(spacing: 10) {
                        ForEach(metrics, id: \.label) { m in
                            selfMetricRow(label: m.label, value: m.meText)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: PKTokens.Layout.cardRadius)
                .fill(PKTokens.Color.card)
                .overlay(
                    RoundedRectangle(cornerRadius: PKTokens.Layout.cardRadius)
                        .stroke(PKTokens.Color.cardBorder, lineWidth: 1)
                )
                .shadow(color: PKTokens.Shadow.card,
                        radius: PKTokens.Shadow.cardRadius, y: PKTokens.Shadow.cardY)
        )
        .clipShape(RoundedRectangle(cornerRadius: PKTokens.Layout.cardRadius))
    }

    private func selfMetricRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.app(size: PKTokens.Font.metricLabel))
                .foregroundColor(PKTokens.Color.muted)
            Spacer()
            Text(value)
                .font(.app(size: PKTokens.Font.metricValue, weight: .medium))
                .foregroundColor(PKTokens.Color.foreground)
        }
    }

    private func userColumn(user: PKUser, crowned: Bool, wins: Int,
                            badgeBg: Color, badgeFg: Color) -> some View {
        VStack(spacing: 0) {
            PKAvatar(image: user.avatar, emoji: user.emojiAvatar)
                .overlay(alignment: .topTrailing) {
                    if crowned {
                        Image(systemName: "crown.fill")
                            .font(.app(size: 18))
                            .foregroundColor(PKTokens.Color.crownFill)
                            .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
                            .frame(width: PKTokens.Layout.crownSize,
                                   height: PKTokens.Layout.crownSize)
                            .offset(x: 2, y: -10)
                    }
                }
            Text(user.name)
                .font(.app(size: PKTokens.Font.userName, weight: .bold))
                .foregroundColor(PKTokens.Color.foreground)
                .padding(.top, 8)
            Text("赢 \(wins) 项")
                .font(.app(size: PKTokens.Font.winBadge))
                .foregroundColor(badgeFg)
                .padding(.horizontal, 10)
                .padding(.vertical, 2)
                .background(Capsule().fill(badgeBg))
                .padding(.top, 2)
        }
    }
}

// 单项对比行：左右双进度条
struct MetricCompareRow: View {
    let metric: PKMock.Metric
    var meName: String = PKMock.me.name
    var rivalName: String = PKMock.rival.name

    var body: some View {
        let meWin = metric.meWin
        let isTie = metric.me == metric.rival
        let maxV = max(metric.me, metric.rival, 1)

        VStack(spacing: 6) {
            HStack {
                Text(metric.label)
                    .font(.app(size: PKTokens.Font.metricLabel))
                    .foregroundColor(PKTokens.Color.muted)
                Spacer()
                Text(isTie ? "" : "\(meWin ? meName : rivalName) 领先")
                    .font(.app(size: PKTokens.Font.metricLead, weight: .medium))
                    .foregroundColor(meWin ? PKTokens.Color.me : PKTokens.Color.rival)
            }
            HStack(spacing: 10) {
                // 我方
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(meName) \(metric.meText)")
                        .font(.app(size: PKTokens.Font.metricValue))
                        .foregroundColor(meWin ? PKTokens.Color.me : PKTokens.Color.loseGray)
                    progressBar(pct: metric.me / maxV, win: meWin,
                                winFill: AnyShapeStyle(
                                    LinearGradient(colors: [PKTokens.Color.me, PKTokens.Color.rival],
                                                   startPoint: .leading, endPoint: .trailing)),
                                loseFill: AnyShapeStyle(PKTokens.Color.me.opacity(0.3)))
                }
                .frame(maxWidth: .infinity)
                // 对方
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(rivalName) \(metric.rivalText)")
                        .font(.app(size: PKTokens.Font.metricValue))
                        .foregroundColor(!meWin ? PKTokens.Color.rival : PKTokens.Color.loseGray)
                    progressBar(pct: metric.rival / maxV, win: !meWin,
                                winFill: AnyShapeStyle(PKTokens.Color.rival),
                                loseFill: AnyShapeStyle(PKTokens.Color.rival.opacity(0.3)))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func progressBar(pct: Double, win: Bool,
                             winFill: AnyShapeStyle, loseFill: AnyShapeStyle) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(PKTokens.Color.faint)
                Capsule()
                    .fill(win ? winFill : loseFill)
                    .frame(width: geo.size.width * pct)
            }
        }
        .frame(height: PKTokens.Layout.barH)
    }
}

// MARK: =====================================================================
// MARK: - 2. 热量对比：分组柱状图 + 摄入/消耗切换
// MARK: =====================================================================

struct CalSegmented: View {
    @Binding var mode: Int   // 0 摄入 / 1 消耗
    var body: some View {
        HStack(spacing: 0) {
            segBtn("摄入", idx: 0)
            segBtn("消耗", idx: 1)
        }
        .padding(3)
        .background(Capsule().fill(PKTokens.Color.background))
    }
    private func segBtn(_ title: String, idx: Int) -> some View {
        Button {
            withAnimation(PKTokens.Anim.barSwitch) { mode = idx }
        } label: {
            Text(title)
                .font(.app(size: PKTokens.Font.segBtn))
                .foregroundColor(mode == idx ? .white : PKTokens.Color.muted)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(mode == idx ? PKTokens.Color.primary : .clear))
        }
        .buttonStyle(.plain)
    }
}

// 分组柱状图（Web viewBox 320×176 等比缩放；SwiftUI 布局实现以获得原生切换动画）
struct PKBarChart: View {
    let a: [Double]
    let b: [Double]

    // Web 图表几何常量
    private let W: CGFloat = 320, H: CGFloat = 176
    private let x0: CGFloat = 8, x1: CGFloat = 312
    private let y0: CGFloat = 16, y1: CGFloat = 146

    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width / W
            let n = a.count
            let groupW = (x1 - x0) / CGFloat(n)
            let barW = min(13, groupW * 0.3)
            let top = (a + b).max()! * 1.18

            ZStack(alignment: .topLeading) {
                // 网格线
                ForEach([0.0, 0.5, 1.0], id: \.self) { t in
                    Rectangle()
                        .fill(PKTokens.Color.grid)
                        .frame(width: (x1 - x0) * s, height: 1)
                        .position(x: (x0 + (x1 - x0) / 2) * s,
                                  y: (y1 - CGFloat(t) * (y1 - y0)) * s)
                }
                ForEach(0..<n, id: \.self) { i in
                    let cx = x0 + groupW * (CGFloat(i) + 0.5)
                    let ha = (a[i] / top) * (y1 - y0)
                    let hb = (b[i] / top) * (y1 - y0)
                    let xa = cx - barW - 2
                    let xb = cx + 2

                    // 我方柱
                    RoundedRectangle(cornerRadius: 3 * s)
                        .fill(PKTokens.Color.me)
                        .frame(width: barW * s, height: ha * s)
                        .position(x: (xa + barW / 2) * s, y: (y1 - ha / 2) * s)
                    // 对方柱
                    RoundedRectangle(cornerRadius: 3 * s)
                        .fill(PKTokens.Color.rival)
                        .frame(width: barW * s, height: hb * s)
                        .position(x: (xb + barW / 2) * s, y: (y1 - hb / 2) * s)
                    // 数值标签
                    Text(String(Int(a[i])))
                        .font(.app(size: 11 * s, weight: .medium))
                        .foregroundColor(PKTokens.Color.me)
                        .position(x: (xa + barW / 2) * s, y: (y1 - ha - 6) * s)
                    Text(String(Int(b[i])))
                        .font(.app(size: 11 * s, weight: .medium))
                        .foregroundColor(PKTokens.Color.rival)
                        .position(x: (xb + barW / 2) * s, y: (y1 - hb - 6) * s)
                    // 星期
                    Text(PKMock.days[i])
                        .font(.app(size: 10 * s))
                        .foregroundColor(PKTokens.Color.sub)
                        .position(x: cx * s, y: (y1 + 11) * s)
                }
            }
        }
        .aspectRatio(W / H, contentMode: .fit)
    }
}

struct CalorieSection: View {
    var me: PKUser = PKMock.me
    var rival: PKUser = PKMock.rival
    @State private var mode = 0
    var body: some View {
        VStack(spacing: 0) {
            PKSectionTitle(systemIcon: "flame", title: "热量对比")
            HStack {
                PKLegend(meName: me.name, rivalName: rival.name)
                Spacer()
                CalSegmented(mode: $mode)
            }
            .padding(.bottom, 12)
            PKBarChart(a: mode == 0 ? me.intake : me.burned,
                       b: mode == 0 ? rival.intake : rival.burned)
            Text(mode == 0 ? "每日摄入热量 (kcal)" : "每日运动消耗 (kcal)")
                .font(.app(size: PKTokens.Font.caption))
                .foregroundColor(PKTokens.Color.subtle)
                .padding(.top, 6)
        }
        .pkFlatCard()
    }
}

// MARK: =====================================================================
// MARK: - 3. 体重变化：双折线图（Canvas 等比缩放绘制）
// MARK: =====================================================================

struct PKLineChart: View {
    let a: [Double]
    let b: [Double]

    private let W: CGFloat = 320, H: CGFloat = 188
    private let x0: CGFloat = 16, x1: CGFloat = 304
    private let y0: CGFloat = 18, y1: CGFloat = 152

    var body: some View {
        Canvas { ctx, size in
            let s = size.width / W
            ctx.scaleBy(x: s, y: s)

            let n = a.count
            // 只对 > 0 的有效值（已登记体重）做坐标范围（体重不可能为 0）
            let validValues = (a + b).filter { $0 > 0 }
            var minV = validValues.min() ?? 50
            var maxV = validValues.max() ?? 100
            if maxV - minV < 0.1 { maxV += 1; minV -= 1 }
            let pad = (maxV - minV) * 0.25
            minV -= pad; maxV += pad

            func px(_ i: Int) -> CGFloat { x0 + (x1 - x0) * CGFloat(i) / CGFloat(n - 1) }
            func py(_ v: Double) -> CGFloat { y1 - (v - minV) / (maxV - minV) * (y1 - y0) }

            // 网格线
            for t in [0.0, 0.5, 1.0] {
                let y = y1 - t * (y1 - y0)
                var p = Path()
                p.move(to: CGPoint(x: x0, y: y)); p.addLine(to: CGPoint(x: x1, y: y))
                ctx.stroke(p, with: .color(PKTokens.Color.grid), lineWidth: 1)
            }
            // 折线：只连接有效值（> 0），未来未登记的天断开不画
            func polyline(_ arr: [Double]) -> Path {
                var p = Path()
                var started = false
                for i in 0..<n {
                    guard arr[i] > 0 else { continue }  // 跳过未登记的天
                    let pt = CGPoint(x: px(i), y: py(arr[i]))
                    if !started { p.move(to: pt); started = true }
                    else { p.addLine(to: pt) }
                }
                return p
            }
            ctx.stroke(polyline(a), with: .color(PKTokens.Color.me),
                       style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            ctx.stroke(polyline(b), with: .color(PKTokens.Color.rival),
                       style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round,
                                          dash: [6, 5]))
            // 数据点 + 数值：只对 > 0 的有效值显示
            for i in 0..<n {
                if a[i] > 0 {
                    let pa = CGPoint(x: px(i), y: py(a[i]))
                    let dotA = Path(ellipseIn: CGRect(x: pa.x - 3, y: pa.y - 3, width: 6, height: 6))
                    ctx.fill(dotA, with: .color(.white))
                    ctx.stroke(dotA, with: .color(PKTokens.Color.me), lineWidth: 2)
                    ctx.draw(Text(String(format: "%.1f", a[i]))
                                .font(.app(size: 10, weight: .medium)).foregroundColor(PKTokens.Color.me),
                             at: CGPoint(x: pa.x, y: pa.y - 10), anchor: .center)
                }
                if b[i] > 0 {
                    let pb = CGPoint(x: px(i), y: py(b[i]))
                    let dotB = Path(ellipseIn: CGRect(x: pb.x - 3, y: pb.y - 3, width: 6, height: 6))
                    ctx.fill(dotB, with: .color(.white))
                    ctx.stroke(dotB, with: .color(PKTokens.Color.rival), lineWidth: 2)
                    ctx.draw(Text(String(format: "%.1f", b[i]))
                                .font(.app(size: 10, weight: .medium)).foregroundColor(PKTokens.Color.rival),
                             at: CGPoint(x: pb.x, y: pb.y + 10), anchor: .center)
                }
            }
            // 星期
            for i in 0..<n {
                ctx.draw(Text(PKMock.days[i])
                            .font(.app(size: 10)).foregroundColor(PKTokens.Color.sub),
                         at: CGPoint(x: px(i), y: y1 + 13), anchor: .center)
            }
        }
        .aspectRatio(W / H, contentMode: .fit)
    }
}

struct WeightSection: View {
    var me: PKUser = PKMock.me
    var rival: PKUser = PKMock.rival

    /// 减重值：本周最早有效体重 vs 本周最新有效体重（仅在 >= 2 条记录时计算）
    private func loss(_ ws: [Double]) -> Double {
        let valid = ws.enumerated().filter { $0.element > 0 }.sorted(by: { $0.offset < $1.offset })
        guard valid.count >= 2 else { return 0 }
        return (valid.first!.element - valid.last!.element)
    }

    var body: some View {
        let meLoss = loss(me.weights)
        let rivalLoss = loss(rival.weights)
        return VStack(spacing: 0) {
            PKSectionTitle(systemIcon: "chart.line.downtrend.xyaxis", title: "体重变化")
            PKLineChart(a: me.weights, b: rival.weights)
            HStack {
                Text("\(me.name) 减 \(String(format: "%.1f", meLoss)) kg")
                Spacer()
                Text("\(rival.name) 减 \(String(format: "%.1f", rivalLoss)) kg")
            }
            .font(.app(size: PKTokens.Font.weightNote))
            .foregroundColor(PKTokens.Color.muted)
            .padding(.top, 8)
        }
        .pkFlatCard()
    }
}

// MARK: =====================================================================
// MARK: - 4. 运动时长对比：累计横向条形
// MARK: =====================================================================

struct ExerciseSection: View {
    var me: PKUser = PKMock.me
    var rival: PKUser = PKMock.rival
    var body: some View {
        let exMe = me.exerciseMin.reduce(0, +)
        let exRival = rival.exerciseMin.reduce(0, +)
        let exMax = max(exMe, exRival)

        VStack(alignment: .leading, spacing: 0) {
            PKSectionTitle(systemIcon: "dumbbell", title: "运动时长对比")
            PKLegend(meName: me.name, rivalName: rival.name)
            VStack(spacing: 14) {
                exerciseRow(name: me.name, minutes: exMe, pct: exMe / exMax,
                            valueColor: PKTokens.Color.primary,
                            fill: AnyShapeStyle(
                                LinearGradient(colors: [PKTokens.Color.me, PKTokens.Color.rival],
                                               startPoint: .leading, endPoint: .trailing)))
                exerciseRow(name: rival.name, minutes: exRival, pct: exRival / exMax,
                            valueColor: PKTokens.Color.rival,
                            fill: AnyShapeStyle(PKTokens.Color.rival))
            }
            .padding(.top, 14)
            Text("本周累计运动时长 · \(exMe >= exRival ? me.name : rival.name) 领先 \(Int(abs(exMe - exRival))) 分钟")
                .font(.app(size: PKTokens.Font.caption))
                .foregroundColor(PKTokens.Color.subtle)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
        }
        .pkFlatCard()
    }

    private func exerciseRow(name: String, minutes: Double, pct: Double,
                             valueColor: Color, fill: AnyShapeStyle) -> some View {
        VStack(spacing: 5) {
            HStack {
                Text(name)
                    .font(.app(size: PKTokens.Font.exName))
                    .foregroundColor(PKTokens.Color.muted)
                Spacer()
                Text("\(Int(minutes)) 分钟")
                    .font(.app(size: PKTokens.Font.exValue))
                    .foregroundColor(valueColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(PKTokens.Color.faint)
                    Capsule().fill(fill).frame(width: geo.size.width * pct)
                }
            }
            .frame(height: PKTokens.Layout.barH)
        }
    }
}

// MARK: =====================================================================
// MARK: - 5. 饮水达标对比：3D 玻璃水球 + 每日趋势
// MARK: =====================================================================

// 玻璃水球（TimelineView 驱动波浪/气泡动画，几何参数 1:1 对齐 Web SVG）
struct WaterBallView: View {
    let pct: Double
    let color: Color
    let label: String
    let goalMl: Int
    let todayMl: Int

    private let size = PKTokens.Layout.ballSize   // 134
    private let pad: CGFloat = 6

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { ctx, _ in
                    let r = size / 2 - pad
                    let cx = size / 2, cy = size / 2
                    let waterY = cy + r - pct * (2 * r)
                    let D = size

                    // 玻璃球体底色（radial 35%/28%/80%）
                    let ballRect = CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)
                    let glass = Gradient(stops: [
                        .init(color: PKTokens.Color.glass0, location: 0),
                        .init(color: PKTokens.Color.glass1, location: 0.55),
                        .init(color: PKTokens.Color.glass2, location: 1),
                    ])
                    ctx.fill(Path(ellipseIn: ballRect),
                             with: .radialGradient(glass,
                                                   center: CGPoint(x: size * 0.35, y: size * 0.28),
                                                   startRadius: 0, endRadius: size * 0.8))
                    ctx.stroke(Path(ellipseIn: ballRect),
                               with: .color(PKTokens.Color.glassStroke), lineWidth: 2)

                    // ── 球内内容（裁剪） ──
                    var inner = ctx
                    inner.clip(to: Path(ellipseIn: ballRect))

                    // 波浪 1：0 → -D，3.6s
                    let phase1 = -CGFloat((t.truncatingRemainder(dividingBy: PKTokens.Anim.wave1Dur))
                                          / PKTokens.Anim.wave1Dur) * D
                    var w1 = inner
                    w1.translateBy(x: phase1, y: 0)
                    let waveGrad = Gradient(stops: [
                        .init(color: color.opacity(0.9), location: 0),
                        .init(color: color.opacity(0.55), location: 1),
                    ])
                    w1.fill(wavePath(waterY: waterY, D: D),
                            with: .linearGradient(waveGrad,
                                                  startPoint: CGPoint(x: 0, y: waterY - 5),
                                                  endPoint: CGPoint(x: 0, y: size)))
                    // 波浪 2：-D → 0，5s，opacity 0.22
                    let phase2 = -D + CGFloat((t.truncatingRemainder(dividingBy: PKTokens.Anim.wave2Dur))
                                              / PKTokens.Anim.wave2Dur) * D
                    var w2 = inner
                    w2.translateBy(x: phase2, y: 0)
                    w2.fill(wavePath(waterY: waterY, D: D), with: .color(color.opacity(0.22)))

                    // 上浮气泡（x/r/dur/begin 对齐 Web）
                    let bubbles: [(x: CGFloat, r: CGFloat, dur: Double, begin: Double)] = [
                        (cx - 20, 3, 3.2, 0), (cx + 12, 2, 2.6, 0.9),
                        (cx + 22, 2.4, 3.8, 1.7), (cx - 8, 1.8, 3.0, 2.4),
                    ]
                    for bub in bubbles {
                        let progress = ((t - bub.begin).truncatingRemainder(dividingBy: bub.dur) + bub.dur)
                            .truncatingRemainder(dividingBy: bub.dur) / bub.dur
                        let startY = cy + r - 4
                        let endY = waterY + 2
                        let y = startY + (endY - startY) * progress
                        let opacity = 0.6 * progress
                        inner.fill(Path(ellipseIn: CGRect(x: bub.x - bub.r, y: y - bub.r,
                                                          width: bub.r * 2, height: bub.r * 2)),
                                   with: .color(.white.opacity(opacity)))
                    }

                    // 光影折射高光（旋转 -30°）
                    var hl = inner
                    let hlCenter = CGPoint(x: cx - r * 0.35, y: cy - r * 0.42)
                    hl.translateBy(x: hlCenter.x, y: hlCenter.y)
                    hl.rotate(by: .degrees(-30))
                    hl.fill(Path(ellipseIn: CGRect(x: -r * 0.3, y: -r * 0.16,
                                                   width: r * 0.6, height: r * 0.32)),
                            with: .color(.white.opacity(0.55)))

                    // 球缘描边
                    ctx.stroke(Path(ellipseIn: ballRect),
                               with: .color(PKTokens.Color.ballRim), lineWidth: 1.5)

                    // 中心百分比（白描边光晕：8 向偏移白字 + 黑字）
                    let pctText = "\(Int((pct * 100).rounded()))%"
                    let center = CGPoint(x: size / 2, y: size * 0.53 - 7)
                    let sw: CGFloat = 1.5
                    for dx in [-sw, 0, sw] {
                        for dy in [-sw, 0, sw] where !(dx == 0 && dy == 0) {
                            ctx.draw(Text(pctText)
                                        .font(.app(size: PKTokens.Font.ballPct, weight: .bold))
                                        .foregroundColor(.white),
                                     at: CGPoint(x: center.x + dx, y: center.y + dy), anchor: .center)
                        }
                    }
                    ctx.draw(Text(pctText)
                                .font(.app(size: PKTokens.Font.ballPct, weight: .bold))
                                .foregroundColor(PKTokens.Color.foreground),
                             at: center, anchor: .center)
                }
                .frame(width: size, height: size)
            }
            .id(pct)  // 强制 TimelineView 在水位变化时重建，确保百分比随之更新

            Text(label)
                .font(.app(size: PKTokens.Font.ballLabel, weight: .medium))
                .foregroundColor(PKTokens.Color.foreground)
                .padding(.top, 8)
            Text("\(todayMl)/\(goalMl) ml")
                .font(.app(size: PKTokens.Font.ballGoal))
                .foregroundColor(PKTokens.Color.subtle)
        }
    }

    // 波浪路径（Web：seg = D/2，amp = 5，宽 2D）
    private func wavePath(waterY: CGFloat, D: CGFloat) -> Path {
        var p = Path()
        let amp: CGFloat = 5
        let seg = D / 2
        let Wt = D * 2
        p.move(to: CGPoint(x: 0, y: waterY))
        var x: CGFloat = 0
        var up = true
        while x < Wt {
            let nx = x + seg
            let cy = up ? waterY - amp : waterY + amp
            p.addQuadCurve(to: CGPoint(x: nx, y: waterY),
                           control: CGPoint(x: x + seg / 2, y: cy))
            x = nx; up.toggle()
        }
        p.addLine(to: CGPoint(x: Wt, y: size))
        p.addLine(to: CGPoint(x: 0, y: size))
        p.closeSubpath()
        return p
    }
}

// 饮水趋势：双面积折线图 + 各自目标虚线
struct PKWaterTrend: View {
    let meArr: [Double]
    let rivalArr: [Double]
    let goalMe: Double
    let goalRival: Double

    private let W: CGFloat = 320, H: CGFloat = 192
    private let x0: CGFloat = 18, x1: CGFloat = 302
    private let y0: CGFloat = 16, y1: CGFloat = 158

    var body: some View {
        Canvas { ctx, size in
            let s = size.width / W
            ctx.scaleBy(x: s, y: s)

            let n = meArr.count
            let all = meArr + rivalArr + [goalMe, goalRival]
            var minV = all.min()!, maxV = all.max()!
            let pad = (maxV - minV) * 0.18
            minV = max(0, minV - pad); maxV += pad

            func px(_ i: Int) -> CGFloat { x0 + (x1 - x0) * CGFloat(i) / CGFloat(n - 1) }
            func py(_ v: Double) -> CGFloat { y1 - (v - minV) / (maxV - minV) * (y1 - y0) }

            // 网格线
            for t in [0.0, 0.5, 1.0] {
                let y = y1 - t * (y1 - y0)
                var p = Path()
                p.move(to: CGPoint(x: x0, y: y)); p.addLine(to: CGPoint(x: x1, y: y))
                ctx.stroke(p, with: .color(PKTokens.Color.grid), lineWidth: 1)
            }
            // 目标虚线
            for (goal, color) in [(goalMe, PKTokens.Color.me), (goalRival, PKTokens.Color.rival)] {
                var p = Path()
                p.move(to: CGPoint(x: x0, y: py(goal)))
                p.addLine(to: CGPoint(x: x1, y: py(goal)))
                ctx.stroke(p, with: .color(color.opacity(0.55)),
                           style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
            }
            // 面积填充
            func area(_ arr: [Double]) -> Path {
                var p = Path()
                p.move(to: CGPoint(x: px(0), y: y1))
                for i in 0..<n { p.addLine(to: CGPoint(x: px(i), y: py(arr[i]))) }
                p.addLine(to: CGPoint(x: px(n - 1), y: y1))
                p.closeSubpath()
                return p
            }
            ctx.fill(area(meArr), with: .color(PKTokens.Color.me.opacity(0.16)))
            ctx.fill(area(rivalArr), with: .color(PKTokens.Color.rival.opacity(0.16)))
            // 折线
            func polyline(_ arr: [Double]) -> Path {
                var p = Path()
                p.move(to: CGPoint(x: px(0), y: py(arr[0])))
                for i in 1..<n { p.addLine(to: CGPoint(x: px(i), y: py(arr[i]))) }
                return p
            }
            let lineStyle = StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            ctx.stroke(polyline(meArr), with: .color(PKTokens.Color.me), style: lineStyle)
            ctx.stroke(polyline(rivalArr), with: .color(PKTokens.Color.rival), style: lineStyle)
            // 数据点 + 数值
            for i in 0..<n {
                for (arr, color, dy) in [(meArr, PKTokens.Color.me, CGFloat(-10)),
                                         (rivalArr, PKTokens.Color.rival, CGFloat(10))] {
                    let pt = CGPoint(x: px(i), y: py(arr[i]))
                    let dot = Path(ellipseIn: CGRect(x: pt.x - 2.8, y: pt.y - 2.8,
                                                     width: 5.6, height: 5.6))
                    ctx.fill(dot, with: .color(.white))
                    ctx.stroke(dot, with: .color(color), lineWidth: 2)
                    ctx.draw(Text(String(Int(arr[i])))
                                .font(.app(size: 10, weight: .medium)).foregroundColor(color),
                             at: CGPoint(x: pt.x, y: pt.y + dy), anchor: .center)
                }
            }
            // 星期
            for i in 0..<n {
                ctx.draw(Text(PKMock.days[i])
                            .font(.app(size: 10)).foregroundColor(PKTokens.Color.sub),
                         at: CGPoint(x: px(i), y: y1 + 13), anchor: .center)
            }
        }
        .aspectRatio(W / H, contentMode: .fit)
    }
}

struct WaterSection: View {
    var me: PKUser = PKMock.me
    var rival: PKUser = PKMock.rival
    var today: Int = PKMock.today

    var body: some View {
        VStack(spacing: 0) {
            PKSectionTitle(systemIcon: "drop", title: "饮水达标对比")

            HStack(alignment: .top) {
                Spacer()
                let mePct = me.waterGoal > 0 ? min(1, me.water[today] / me.waterGoal) : 0
                WaterBallView(pct: mePct,
                              color: PKTokens.Color.me, label: me.name,
                              goalMl: Int(me.waterGoal), todayMl: Int(me.water[today]))
                Spacer()
                let rivalPct = rival.waterGoal > 0 ? min(1, rival.water[today] / rival.waterGoal) : 0
                WaterBallView(pct: rivalPct,
                              color: PKTokens.Color.rival, label: rival.name,
                              goalMl: Int(rival.waterGoal), todayMl: Int(rival.water[today]))
                Spacer()
            }
            .padding(.top, 8)

            VStack(spacing: 0) {
                Divider().overlay(PKTokens.Color.divider)
                HStack {
                    Text("每日饮水量趋势")
                        .font(.app(size: PKTokens.Font.trendHead, weight: .medium))
                        .foregroundColor(PKTokens.Color.muted)
                    Spacer()
                    PKLegend(meName: me.name, rivalName: rival.name)
                }
                .padding(.top, 12)
                .padding(.bottom, 8)
                PKWaterTrend(meArr: me.water, rivalArr: rival.water,
                             goalMe: me.waterGoal, goalRival: rival.waterGoal)
                Text("每日饮水量 (ml) · 虚线为各自目标")
                    .font(.app(size: PKTokens.Font.captionSm))
                    .foregroundColor(PKTokens.Color.subtle)
                    .padding(.top, 4)
            }
            .padding(.top, 16)
        }
        .pkFlatCard()
    }
}

// MARK: =====================================================================
// MARK: - 页面主体
// MARK: =====================================================================

struct PKPageView: View {
    @ObservedObject var store: AppDataStore
    @ObservedObject var binding: PKBindingCoordinator
    @ObservedObject private var avatarStore = AvatarStore.shared
    var onBind: () -> Void
    var onScan: () -> Void
    var onMyQR: () -> Void
    var onUnbind: () -> Void
    var onProfile: (() -> Void)? = nil

    @State private var isGuest: Bool = AuthService.shared.isGuest

    var body: some View {
        VStack(spacing: 0) {
            CardTopBar(nickname: nickname, avatarImage: avatarStore.avatarImage, onProfileTap: onProfile)

            ScrollView(showsIndicators: false) {
                VStack(spacing: PKTokens.Layout.sectionGap) {
                    relationCard
                    BattleReportCard(
                        meUser: meData,
                        rivalUser: rivalData,
                        leaderIsMe: leaderIsMe,
                        leaderIsRival: leaderIsRival,
                        meWins: meWins,
                        rivalWins: rivalWins,
                        metrics: weeklyMetrics,
                        hasOpponent: binding.opponent != nil,
                        hasData: hasAnyData
                    )
                    CalorieSection(me: meData, rival: rivalData)
                    WeightSection(me: meData, rival: rivalData)
                    ExerciseSection(me: meData, rival: rivalData)
                    WaterSection(me: meData, rival: rivalData, today: todayIndex)
                }
                .padding(.horizontal, PKTokens.Layout.pageH)
                .padding(.top, PKTokens.Layout.pageTop)
                .padding(.bottom, PKTokens.Layout.pageBottom)
            }
        }
        .background(PKTokens.Color.background.ignoresSafeArea())
        .refreshable {
            // 下拉刷新：先刷新绑定关系（跨设备同步），再拉取最新 PK 周数据
            // 用 detached Task 确保 refresh 不被视图重建取消
            await Task.detached { @MainActor in
                await binding.refresh()
                await store.refresh()
            }.value
        }
        .onReceive(NotificationCenter.default.publisher(for: .authDidChange)) { _ in
            isGuest = AuthService.shared.isGuest
        }
    }

    // MARK: 桥接属性（AppDataStore 真实数据 → PKMock 兼容类型）

    /// 今天在本周的索引位置（0=周一 ... 6=周日）
    private var todayWeekIndex: Int {
        let cal = Calendar.current
        let now = Date()
        var mondayComp = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        mondayComp.weekday = 2 // 周一
        guard let monday = cal.date(from: mondayComp) else { return 0 }
        return max(0, min(6, cal.dateComponents([.day], from: monday, to: now).day ?? 0))
    }

    /// 从本地真实数据映射为我方 PKUser（数据清空时全为 0，联动首页清空状态）
    /// 所有数据统一取云端 pkWeek，通过 addRecord 后刷新 pkWeek 保证实时性
    private var meData: PKUser {
        let me = store.pkWeeks.first?.me
        let waterGoal = Double(store.profile.waterGoal > 0 ? store.profile.waterGoal : 2000)

        // 全部使用云端数据；云端数组为空时兜底全0
        let intake: [Double] = me?.dailyIntake.isEmpty == false
            ? me!.dailyIntake.map(Double.init)
            : Array(repeating: 0.0, count: 7)

        let burned: [Double] = me?.dailyBurned.isEmpty == false
            ? me!.dailyBurned.map(Double.init)
            : Array(repeating: 0.0, count: 7)

        let exerciseMin: [Double] = me?.dailyExerciseMin.isEmpty == false
            ? me!.dailyExerciseMin.map(Double.init)
            : Array(repeating: 0.0, count: 7)

        let water: [Double] = me?.dailyWater.isEmpty == false
            ? me!.dailyWater.map(Double.init)
            : Array(repeating: 0.0, count: 7)

        let weights: [Double] = me?.dailyWeights ?? Array(repeating: 0.0, count: 7)

        return PKUser(
            name: (avatarStore.nickname != "游客" && !avatarStore.nickname.isEmpty)
                ? avatarStore.nickname
                : (store.profile.name.isEmpty ? "我" : store.profile.name),
            avatar: avatarStore.avatarImage,
            emojiAvatar: nil,
            intake: intake,
            burned: burned,
            exerciseMin: exerciseMin,
            weights: weights,
            waterGoal: waterGoal,
            water: water
        )
    }

    /// 从本地真实数据 + 后端 PK 周数据映射为对手 PKUser
    private var rivalData: PKUser {
        let p = store.partnerProfile
        let partner = store.pkWeeks.first?.partner
        let todayIdx = todayWeekIndex

        // 体重：服务端历史 6 天 + todayIdx 用 partnerProfile.currentWeight 覆盖（sync 中已从记录更新）
        var rivalWeights: [Double] = {
            if let w = partner?.dailyWeights, w.contains(where: { $0 > 0 }) { return w }
            return Array(repeating: p.currentWeight, count: 7)
        }()
        if p.currentWeight > 0 {
            rivalWeights[todayIdx] = p.currentWeight
        }

        // 饮水：服务端数据（缓存失效后已为最新）
        var rivalWater: [Double] = partner.map { $0.dailyWater.map(Double.init) } ?? Array(repeating: 0.0, count: 7)

        return PKUser(
            name: p.name.isEmpty ? "对手" : p.name,
            avatar: p.avatarImage,
            emojiAvatar: p.avatar.isEmpty ? nil : p.avatar,
            intake: partner.map { $0.dailyIntake.map(Double.init) } ?? [0,0,0,0,0,0,0],
            burned: partner.map { $0.dailyBurned.map(Double.init) } ?? [0,0,0,0,0,0,0],
            exerciseMin: partner.map { $0.dailyExerciseMin.map(Double.init) } ?? [0,0,0,0,0,0,0],
            weights: rivalWeights,
            waterGoal: Double(p.waterGoal > 0 ? p.waterGoal : 2000),
            water: rivalWater
        )
    }

    /// 双方是否有任何实际数据（摄入 + 消耗 + 饮水 + 运动时长 任一 > 0）
    private var hasAnyData: Bool {
        let myTotal = meData.intake.reduce(0, +) + meData.burned.reduce(0, +) +
                      meData.water.reduce(0, +) + meData.exerciseMin.reduce(0, +)
        let rivalTotal = rivalData.intake.reduce(0, +) + rivalData.burned.reduce(0, +) +
                         rivalData.water.reduce(0, +) + rivalData.exerciseMin.reduce(0, +)
        return myTotal > 0 || rivalTotal > 0
    }

    /// 我方严格胜出的项数（基于 weeklyMetrics，打平不计分）
    private var meWins: Int {
        guard hasAnyData else { return 0 }
        return weeklyMetrics.filter { $0.meWin }.count
    }

    /// 对手严格胜出的项数（打平不计分）
    private var rivalWins: Int {
        guard hasAnyData else { return 0 }
        return weeklyMetrics.filter { $0.rivalWin }.count
    }

    /// 我方领先：赢的项数严格多于对手（打平项不参与）
    private var leaderIsMe: Bool { meWins > rivalWins }
    /// 对手领先：赢的项数严格多于我方
    private var leaderIsRival: Bool { rivalWins > meWins }

    private var weeklyMetrics: [PKMock.Metric] {
        func avg(_ a: [Double]) -> Double { a.reduce(0, +) / Double(max(a.count, 1)) }
        func sum(_ a: [Double]) -> Double { a.reduce(0, +) }
        /// 计算体重变化百分比：
        ///   规则：取本周最后一条有效体重（最新） vs 本周倒数第二条有效体重（上次）
        ///   变化% = (最新 - 上次) / 上次 * 100
        ///   无"上次"时为 0%
        ///   结果为负=减重，正=增重；取反后以"减重百分比"显示（正=减得更多，越大越好）
        func weightLossPercent(_ ws: [Double]) -> Double {
            // 过滤 0，按时间顺序取有效记录（索引 0=周一 ... 6=周日）
            let valid = ws.enumerated().filter { $0.element > 0 }.sorted(by: { $0.offset < $1.offset })
            guard valid.count >= 2 else { return 0 }  // 少于2条记录，没有"上次"对比
            let latest = valid.last!.element
            let previous = valid[valid.count - 2].element
            guard previous > 0 else { return 0 }
            // 变化百分比（最新 vs 上次）
            let changePct = (latest - previous) / previous * 100.0
            // 转为"减重百分比"：变化为负（减重）时，返回正值；减重越大，值越高
            return -changePct
        }
        let myIn = avg(meData.intake)
        let rivalIn = avg(rivalData.intake)
        let myBurn = sum(meData.burned)
        let rivalBurn = sum(rivalData.burned)
        // 本周减重：以变化百分比对比（无上次登记则为 0%）
        let myWeightPct = weightLossPercent(meData.weights)
        let rivalWeightPct = weightLossPercent(rivalData.weights)
        // 总饮水量（比达标率更直观，避免未设目标时显示 0% 误解为没数据）
        let myWater = sum(meData.water)
        let rivalWater = sum(rivalData.water)
        return [
            PKMock.Metric(label: "平均每日摄入", me: myIn, rival: rivalIn, unit: " kcal", lowerBetter: true),
            PKMock.Metric(label: "总运动消耗", me: myBurn, rival: rivalBurn, unit: " kcal", lowerBetter: false),
            PKMock.Metric(label: "本周减重变化", me: round(myWeightPct * 10) / 10,
                          rival: round(rivalWeightPct * 10) / 10,
                          unit: "%", lowerBetter: false),
            PKMock.Metric(label: "总饮水量", me: myWater, rival: rivalWater, unit: " ml", lowerBetter: false),
        ]
    }

    /// 今日在一周中的索引（0=周一 ... 6=周日）
    private var todayIndex: Int {
        let wd = Calendar.current.component(.weekday, from: Date()) // 1=Sun...7=Sat
        return (wd + 5) % 7 // 转成 0=Mon...6=Sun
    }

    // 当前用户昵称（优先 AvatarStore 全站中枢，回退 AuthService / profile）
    private var nickname: String {
        let avatarName = avatarStore.nickname
        if avatarName != "游客" && !avatarName.isEmpty { return avatarName }
        let n = AuthService.shared.currentUser?.nickname ?? store.profile.name
        return n.isEmpty ? "我" : n
    }

    // MARK: PK 关系卡片
    @ViewBuilder
    private var relationCard: some View {
        if let opp = binding.opponent {
            // 已绑定
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Text(opp.avatar)
                        .font(.app(size: 28))
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(PKTokens.Color.rivalBadgeBg))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("已与 \(opp.nickname) 绑定 PK")
                            .font(.app(size: 15, weight: .semibold))
                            .foregroundColor(PKTokens.Color.foreground)
                        Text("点击下方查看本周对战详情")
                            .font(.app(size: 12))
                            .foregroundColor(PKTokens.Color.subtle)
                    }
                    Spacer()
                    Button(action: onUnbind) {
                        Text("解绑")
                            .font(.app(size: 13, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Capsule().fill(Color.red.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .pkFlatCard()
        } else {
            // 未绑定
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.circle")
                        .font(.app(size: 30))
                        .foregroundColor(PKTokens.Color.primary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("还没有 PK 对手")
                            .font(.app(size: 15, weight: .semibold))
                            .foregroundColor(PKTokens.Color.foreground)
                        Text(isGuest ? "登录后可邀请好友与你 PK" : "扫码或分享你的二维码邀请好友")
                            .font(.app(size: 12))
                            .foregroundColor(PKTokens.Color.subtle)
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    // 主按钮：游客→登录，已登录→扫码绑定
                    Button(action: isGuest ? onBind : onScan) {
                        HStack(spacing: 6) {
                            Image(systemName: "qrcode.viewfinder")
                            Text(isGuest ? "登录并绑定" : "扫码绑定")
                        }
                        .font(.app(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(PKTokens.Color.primary))
                    }
                    .buttonStyle(.plain)

                    Button(action: onMyQR) {
                        HStack(spacing: 6) {
                            Image(systemName: "qrcode")
                            Text("我的码")
                        }
                        .font(.app(size: 14, weight: .medium))
                        .foregroundColor(PKTokens.Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(PKTokens.Color.primaryBg10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .pkFlatCard()
        }
    }
}

#Preview {
    PKPageView(
        store: AppDataStore.shared,
        binding: PKBindingCoordinator.shared,
        onBind: {}, onScan: {}, onMyQR: {}, onUnbind: {}
    )
    .environmentObject(PKBindingCoordinator.shared)
}
