import SwiftUI

// MARK: - 首页设计令牌 · 严格对照 Web 端 index.css @theme 定义

enum HomeTokens {

    // MARK: - 色彩 (精确 Hex)

    enum Color {
        /// 页面背景 #F8F8F8
        static let background = hex(0xF8F8F8)
        /// 卡片/顶栏背景 #FFFFFF
        static let cardBackground = hex(0xFFFFFF)
        /// 主文字 #1A1A1A
        static let foreground = hex(0x1A1A1A)
        /// 次要文字 #666666
        static let foregroundMuted = hex(0x666666)
        /// 辅助文字 #999999
        static let foregroundSubtle = hex(0x999999)
        /// 主色 #10B981
        static let primary = hex(0x10B981)
        /// 主色浅 #34D399
        static let primaryLight = hex(0x34D399)
        /// 错误色 #EF4444
        static let error = hex(0xEF4444)
        /// 分隔线 rgba(0,0,0,0.05)
        static let divider = SwiftUI.Color.black.opacity(0.05)
        /// 卡片边框 rgba(0,0,0,0.05)
        static let surfaceBorder = SwiftUI.Color.black.opacity(0.05)
        /// 主色 10% 透明度背景 (VS 标签背景)
        static let primaryBg10 = hex(0x10B981).opacity(0.10)
        /// 皇冠填充 #FFD700
        static let crownFill = hex(0xFFD700)
        /// 皇冠描边 #E0A100
        static let crownStroke = hex(0xE0A100)
        /// 水滴图标底透明度
        static let waterFillOpacity = hex(0x10B981).opacity(0.15)

        private static func hex(_ hex: UInt) -> SwiftUI.Color {
            let r = Double((hex >> 16) & 0xFF) / 255.0
            let g = Double((hex >> 8) & 0xFF) / 255.0
            let b = Double(hex & 0xFF) / 255.0
            return SwiftUI.Color(red: r, green: g, blue: b)
        }
    }

    // MARK: - 字体

    enum FontSize {
        /// 8px - PK 标签、VS
        static let tiny: CGFloat = 8
        /// 9px - kcal 后缀、VS badge
        static let caption2: CGFloat = 9
        /// 10px - meta、状态文字、标签
        static let caption1: CGFloat = 10
        /// 11px - 用户名、kcal 后缀(CalorieCard)
        static let footnote: CGFloat = 11
        /// 12px - 分隔点号
        static let small: CGFloat = 12
        /// 14px - 标题、数值、昵称
        static let body: CGFloat = 14
        /// 20px - 问候语
        static let greeting: CGFloat = 20
        /// 28px - 热量大数字
        static let heroNumber: CGFloat = 28
    }

    // MARK: - 间距

    enum Spacing {
        /// 顶栏顶部内边距 8pt（对齐贴纸页 CardTopBar，避免顶部空白过多）
        static let topBarTop: CGFloat = 8
        /// 顶栏下间距 6pt
        static let topBarBottom: CGFloat = 6
        /// 水平内边距 20pt
        static let horizontal: CGFloat = 20
        /// 主内容顶部间距 16pt
        static let mainTop: CGFloat = 16
        /// 底部留白 90pt (为 TabBar 留空间)
        static let bottom: CGFloat = 90
        /// 卡片内边距 14pt (垂直)
        static let cardPaddingV: CGFloat = 14
        /// 卡片内边距 16pt (水平)
        static let cardPaddingH: CGFloat = 16
        /// PK/Action 卡片下间距 12pt
        static let cardGap12: CGFloat = 12
        /// Action/Weight 卡片下间距 10pt
        static let cardGap10: CGFloat = 10
        /// Action 卡片水平间距 16pt
        static let actionHGap: CGFloat = 16
        /// Weight 卡片水平间距 12pt
        static let weightHGap: CGFloat = 12
        /// VS badge 水平内边距 8pt
        static let vsBadgeH: CGFloat = 8
        /// VS badge 垂直内边距 2pt
        static let vsBadgeV: CGFloat = 2
    }

    // MARK: - 尺寸

    enum Size {
        /// 头像 34×34
        static let avatar: CGFloat = 34
        /// 图标容器 42×42
        static let iconContainer: CGFloat = 42
        /// + 按钮 32×32
        static let plusButton: CGFloat = 32
        /// 图标 20×20
        static let icon: CGFloat = 20
        /// 小图标 14×14 (Trophy)
        static let smallIcon: CGFloat = 14
        /// 微图标 12×12 (CalorieCard 列图标)
        static let tinyIcon: CGFloat = 12
        /// 迷你折线图 40×14
        static let sparklineW: CGFloat = 40
        static let sparklineH: CGFloat = 14
        /// PK 分隔线宽 1pt
        static let dividerW: CGFloat = 1
    }

    // MARK: - 圆角

    enum Radius {
        /// 卡片圆角 16pt
        static let card: CGFloat = 16
        /// 图标容器圆角 14pt
        static let iconContainer: CGFloat = 14
        /// VS badge 圆角 8pt
        static let vsBadge: CGFloat = 8
        /// 进度条圆角(CalorieCard:3 / Action:2)
        static let progressBar6: CGFloat = 3
        /// Action/Weight 进度条圆角 2pt
        static let progressBar4: CGFloat = 2
    }

    // MARK: - 进度条高度

    enum ProgressHeight {
        /// PK 进度条 5pt
        static let pk: CGFloat = 5
        /// CalorieCard 底部进度条 6pt
        static let calorie: CGFloat = 6
        /// ActionCard/WeightCard 进度条 4pt
        static let action: CGFloat = 4
    }

    // MARK: - 阴影

    enum Shadow {
        /// 卡片阴影: 0 2px 8px rgba(0,0,0,0.03)
        static let card = SwiftUI.Color.black.opacity(0.03)
        static let cardRadius: CGFloat = 2
        static let cardY: CGFloat = 2
    }

    // MARK: - 字体字重映射

    enum FontWeight {
        static let regular: SwiftUI.Font.Weight = .regular     // 400
        static let medium: SwiftUI.Font.Weight = .medium       // 500
        static let semibold: SwiftUI.Font.Weight = .semibold   // 600
        static let bold: SwiftUI.Font.Weight = .bold           // 700
    }

    // MARK: - 行高系数

    enum LineHeight {
        /// hero 数字行高 1.15
        static let hero: CGFloat = 1.15
        /// meta 行高 1.3
        static let meta: CGFloat = 1.3
    }
}

// MARK: - 自定义字体快捷方法

extension View {
    /// 数字专用：Source Serif Pro（衬线，对应设计稿「数字 → Source Serif Pro」）
    func fontNumber(size: CGFloat) -> some View {
        self.font(.appBody(size: size, weight: .bold))
    }
}
