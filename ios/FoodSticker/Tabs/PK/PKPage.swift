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
        static let metricLead:  CGFloat = 11   // XX 领先
        static let metricValue: CGFloat = 11   // 条上数值
        static let sectionTitle:CGFloat = 16   // 区块标题
        static let legend:      CGFloat = 12
        static let segBtn:      CGFloat = 12
        static let caption:     CGFloat = 12   // 图下说明
        static let captionSm:   CGFloat = 11
        static let exName:      CGFloat = 13
        static let exValue:     CGFloat = 15
        static let ballPct:     CGFloat = 22   // 水球中心百分比
        static let ballLabel:   CGFloat = 13
        static let ballGoal:    CGFloat = 11
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
    let avatar: String
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

    static let me = PKUser(
        name: "小鹿", avatar: "AvatarMe",
        intake: [1450, 1520, 1380, 1600, 1490, 1700, 1400],
        burned: [320, 280, 410, 350, 300, 460, 380],
        exerciseMin: [45, 38, 55, 47, 40, 65, 52],
        weights: [58.2, 58.0, 57.7, 57.9, 57.5, 57.3, 57.1],
        waterGoal: 2000,
        water: [1300, 1500, 1600, 1400, 1500, 1700, 1500])

    static let rival = PKUser(
        name: "小宇", avatar: "AvatarRival",
        intake: [1280, 1350, 1420, 1300, 1450, 1250, 1380],
        burned: [260, 300, 240, 350, 280, 320, 290],
        exerciseMin: [35, 42, 33, 50, 40, 45, 39],
        weights: [55.6, 55.4, 55.5, 55.2, 55.0, 54.9, 54.7],
        waterGoal: 1800,
        water: [1100, 1300, 1400, 1200, 1300, 1450, 1300])

    // ── 汇总指标（与 Web metrics 完全一致） ──
    struct Metric {
        let label: String
        let me: Double
        let rival: Double
        let unit: String
        let lowerBetter: Bool
        var meWin: Bool { lowerBetter ? me < rival : me > rival }
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
    static var rivalWins: Int { metrics.count - meWins }
    static var leaderIsMe: Bool { meWins >= rivalWins }
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
    var body: some View {
        HStack(spacing: 14) {
            legendItem(color: PKTokens.Color.me, name: PKMock.me.name)
            legendItem(color: PKTokens.Color.rival, name: PKMock.rival.name)
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
    let imageName: String
    var size: CGFloat = PKTokens.Layout.avatarSize
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
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
    private let metrics = PKMock.metrics

    var body: some View {
        VStack(spacing: 0) {
            // 顶部 6px 渐变条
            LinearGradient(colors: [PKTokens.Color.me, PKTokens.Color.rival],
                           startPoint: .leading, endPoint: .trailing)
                .frame(height: PKTokens.Layout.stripH)

            // 标题行
            HStack {
                Text("本周 PK 战报")
                    .font(.app(size: PKTokens.Font.cardHeader, weight: .semibold))
                    .foregroundColor(PKTokens.Color.foreground)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "trophy")
                        .font(.app(size: 12))
                    Text("第 12 周")
                        .font(.app(size: PKTokens.Font.weekTag))
                }
                .foregroundColor(PKTokens.Color.primary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 4)

            // 对手头部
            HStack(alignment: .top, spacing: 0) {
                userColumn(user: PKMock.me, crowned: PKMock.leaderIsMe,
                           wins: PKMock.meWins,
                           badgeBg: PKTokens.Color.primaryBg10,
                           badgeFg: PKTokens.Color.primary)
                    .frame(maxWidth: .infinity)

                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [PKTokens.Color.me, PKTokens.Color.rival],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: PKTokens.Layout.vsCircle, height: PKTokens.Layout.vsCircle)
                        .shadow(color: PKTokens.Shadow.vs,
                                radius: PKTokens.Shadow.vsRadius, y: PKTokens.Shadow.vsY)
                    SwordsGlyph()
                }
                .frame(width: PKTokens.Layout.vsColW)
                .frame(maxHeight: .infinity)

                userColumn(user: PKMock.rival, crowned: !PKMock.leaderIsMe,
                           wins: PKMock.rivalWins,
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

    private func userColumn(user: PKUser, crowned: Bool, wins: Int,
                            badgeBg: Color, badgeFg: Color) -> some View {
        VStack(spacing: 0) {
            PKAvatar(imageName: user.avatar)
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

    var body: some View {
        let meWin = metric.meWin
        let maxV = max(metric.me, metric.rival, 1)

        VStack(spacing: 6) {
            HStack {
                Text(metric.label)
                    .font(.app(size: PKTokens.Font.metricLabel))
                    .foregroundColor(PKTokens.Color.muted)
                Spacer()
                Text("\(meWin ? PKMock.me.name : PKMock.rival.name) 领先")
                    .font(.app(size: PKTokens.Font.metricLead, weight: .medium))
                    .foregroundColor(meWin ? PKTokens.Color.me : PKTokens.Color.rival)
            }
            HStack(spacing: 10) {
                // 我方
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(PKMock.me.name) \(metric.meText)")
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
                    Text("\(PKMock.rival.name) \(metric.rivalText)")
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
                        .font(.app(size: 8 * s))
                        .foregroundColor(PKTokens.Color.me)
                        .position(x: (xa + barW / 2) * s, y: (y1 - ha - 6) * s)
                    Text(String(Int(b[i])))
                        .font(.app(size: 8 * s))
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
    @State private var mode = 0
    var body: some View {
        VStack(spacing: 0) {
            PKSectionTitle(systemIcon: "flame", title: "热量对比")
            HStack {
                PKLegend()
                Spacer()
                CalSegmented(mode: $mode)
            }
            .padding(.bottom, 12)
            PKBarChart(a: mode == 0 ? PKMock.me.intake : PKMock.me.burned,
                       b: mode == 0 ? PKMock.rival.intake : PKMock.rival.burned)
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
            let all = a + b
            var minV = all.min()!, maxV = all.max()!
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
            // 折线
            func polyline(_ arr: [Double]) -> Path {
                var p = Path()
                p.move(to: CGPoint(x: px(0), y: py(arr[0])))
                for i in 1..<n { p.addLine(to: CGPoint(x: px(i), y: py(arr[i]))) }
                return p
            }
            ctx.stroke(polyline(a), with: .color(PKTokens.Color.me),
                       style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            ctx.stroke(polyline(b), with: .color(PKTokens.Color.rival),
                       style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round,
                                          dash: [6, 5]))
            // 数据点 + 数值
            for i in 0..<n {
                let pa = CGPoint(x: px(i), y: py(a[i]))
                let pb = CGPoint(x: px(i), y: py(b[i]))
                for (pt, color) in [(pa, PKTokens.Color.me), (pb, PKTokens.Color.rival)] {
                    let dot = Path(ellipseIn: CGRect(x: pt.x - 3, y: pt.y - 3, width: 6, height: 6))
                    ctx.fill(dot, with: .color(.white))
                    ctx.stroke(dot, with: .color(color), lineWidth: 2)
                }
                ctx.draw(Text(String(format: "%.1f", a[i]))
                            .font(.app(size: 7.5)).foregroundColor(PKTokens.Color.me),
                         at: CGPoint(x: pa.x, y: pa.y - 10), anchor: .center)
                ctx.draw(Text(String(format: "%.1f", b[i]))
                            .font(.app(size: 7.5)).foregroundColor(PKTokens.Color.rival),
                         at: CGPoint(x: pb.x, y: pb.y + 10), anchor: .center)
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
    var body: some View {
        let meLoss = PKMock.me.weights[0] - PKMock.me.weights[6]
        let rivalLoss = PKMock.rival.weights[0] - PKMock.rival.weights[6]
        VStack(spacing: 0) {
            PKSectionTitle(systemIcon: "chart.line.downtrend.xyaxis", title: "体重变化")
            PKLineChart(a: PKMock.me.weights, b: PKMock.rival.weights)
            HStack {
                Text("\(PKMock.me.name) 减 \(String(format: "%.1f", meLoss)) kg")
                Spacer()
                Text("\(PKMock.rival.name) 减 \(String(format: "%.1f", rivalLoss)) kg")
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
    var body: some View {
        let exMe = PKMock.me.exerciseMin.reduce(0, +)
        let exRival = PKMock.rival.exerciseMin.reduce(0, +)
        let exMax = max(exMe, exRival)

        VStack(alignment: .leading, spacing: 0) {
            PKSectionTitle(systemIcon: "dumbbell", title: "运动时长对比")
            PKLegend()
            VStack(spacing: 14) {
                exerciseRow(name: PKMock.me.name, minutes: exMe, pct: exMe / exMax,
                            valueColor: PKTokens.Color.primary,
                            fill: AnyShapeStyle(
                                LinearGradient(colors: [PKTokens.Color.me, PKTokens.Color.rival],
                                               startPoint: .leading, endPoint: .trailing)))
                exerciseRow(name: PKMock.rival.name, minutes: exRival, pct: exRival / exMax,
                            valueColor: PKTokens.Color.rival,
                            fill: AnyShapeStyle(PKTokens.Color.rival))
            }
            .padding(.top, 14)
            Text("本周累计运动时长 · \(exMe >= exRival ? PKMock.me.name : PKMock.rival.name) 领先 \(Int(abs(exMe - exRival))) 分钟")
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
                                .font(.app(size: 8)).foregroundColor(color),
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
    var body: some View {
        let me = PKMock.me, rival = PKMock.rival
        let today = PKMock.today

        VStack(spacing: 0) {
            PKSectionTitle(systemIcon: "drop", title: "饮水达标对比")

            HStack(alignment: .top) {
                Spacer()
                WaterBallView(pct: min(1, me.water[today] / me.waterGoal),
                              color: PKTokens.Color.me, label: me.name,
                              goalMl: Int(me.waterGoal), todayMl: Int(me.water[today]))
                Spacer()
                WaterBallView(pct: min(1, rival.water[today] / rival.waterGoal),
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
                    PKLegend()
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
    var body: some View {
        VStack(spacing: 0) {
            CardTopBar(nickname: PKMock.me.name)

            ScrollView(showsIndicators: false) {
                VStack(spacing: PKTokens.Layout.sectionGap) {
                    BattleReportCard()
                    CalorieSection()
                    WeightSection()
                    ExerciseSection()
                    WaterSection()
                }
                .padding(.horizontal, PKTokens.Layout.pageH)
                .padding(.top, PKTokens.Layout.pageTop)
                .padding(.bottom, PKTokens.Layout.pageBottom)
            }
        }
        .background(PKTokens.Color.background.ignoresSafeArea())
    }
}

#Preview {
    PKPageView()
}
