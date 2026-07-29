import UIKit
import SwiftUI

// MARK: - 统一字体系统
//
// 对照设计稿《字体规范》：
//   正文（中文）：思源宋体 Noto Serif SC   +   英文/数字：Source Serif Pro（衬线）
//   标题（中文）：思源黑体 Noto Sans SC    +   英文/数字：Inter（无衬线）
//
// 实现要点：
//   1. 中英混排采用「级联字体」(cascadeList)：拉丁字体为主，遇到其不包含的字符（中文）
//      自动回退到 CJK 字体，从而同一段文字无需拆分即可正确显示两种字体。
//   2. 可变字体（Inter / Noto Sans SC）通过 UIFontDescriptor 的 weight trait 取对应字重实例。

enum AppFont {

    // MARK: - PostScript 名（必须与 Info.plist 的 UIAppFonts 及打包文件一致）

    private enum Name {
        // 拉丁衬线 —— 正文英文/数字（Source Serif Pro，静态字重）
        static let serifRegular  = "SourceSerif4-Regular"
        static let serifSemibold = "SourceSerif4-Semibold"
        static let serifBold     = "SourceSerif4-Bold"
        // 拉丁无衬线 —— 标题英文/数字（Inter，可变字体，默认 Regular）
        static let sansLatin     = "Inter-Regular"
        // 中文宋体 —— 正文（静态字重）
        static let cjkSerifRegular = "NotoSerifSC-Regular"
        static let cjkSerifBold    = "NotoSerifSC-Bold"
        // 中文黑体 —— 标题（Noto Sans SC，可变字体，默认 Thin，需按字重建实例）
        static let cjkSans        = "NotoSansSC-Thin"
    }

    // MARK: - UIKit (UIFont)

    /// 正文：思源宋体 + Source Serif Pro
    static func body(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let (latinName, cjkName) = serifPair(weight: weight)
        let latin = UIFont(name: latinName, size: size)!
        let cjk   = UIFont(name: cjkName, size: size)!
        return .mixed(latin: latin, cjk: cjk)
    }

    /// 标题：思源黑体 + Inter
    static func title(size: CGFloat, weight: UIFont.Weight = .semibold) -> UIFont {
        let latin = UIFont.variable(name: Name.sansLatin, size: size, weight: weight)
        let cjk   = UIFont.variable(name: Name.cjkSans, size: size, weight: weight)
        return .mixed(latin: latin, cjk: cjk)
    }

    /// 自动按字重选择 标题 / 正文（用于批量替换 UIFont.systemFont / .boldSystemFont）
    static func ui(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        switch weight {
        case .semibold, .bold, .heavy, .black:
            return title(size: size, weight: weight)
        default:
            return body(size: size, weight: weight)
        }
    }

    // MARK: - SwiftUI (Font)

    /// 自动按字重选择 标题 / 正文（用于批量替换 .font(.system(...))）
    static func app(size: CGFloat, weight: UIFont.Weight = .regular) -> Font {
        Font(ui(size: size, weight: weight))
    }

    /// 显式正文（思源宋体 + Source Serif Pro）
    static func appBody(size: CGFloat, weight: UIFont.Weight = .regular) -> Font {
        Font(body(size: size, weight: weight))
    }

    /// 显式标题（思源黑体 + Inter）
    static func appTitle(size: CGFloat, weight: UIFont.Weight = .semibold) -> Font {
        Font(title(size: size, weight: weight))
    }

    // MARK: - 内部

    /// 根据字重选择正文拉丁字体文件 + 中文宋体文件
    /// 中文宋体仅有 Regular / Bold 两档，semi/medium 复用 Regular。
    private static func serifPair(weight: UIFont.Weight) -> (latin: String, cjk: String) {
        switch weight {
        case .bold, .heavy, .black:
            return (Name.serifBold, Name.cjkSerifBold)
        case .semibold, .medium:
            return (Name.serifSemibold, Name.cjkSerifRegular)
        default:
            return (Name.serifRegular, Name.cjkSerifRegular)
        }
    }
}

extension UIFont {

    /// 创建中英混排复合字体：latin 优先用于拉丁字符，未覆盖字符（中文）级联回退到 cjk
    static func mixed(latin: UIFont, cjk: UIFont) -> UIFont {
        let cascade = cjk.fontDescriptor
        let desc = latin.fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName.cascadeList: [cascade]
        ])
        return UIFont(descriptor: desc, size: latin.pointSize)
    }

    /// 从可变字体按字重建实例；若字体未注册则安全回退到系统字体
    static func variable(name: String, size: CGFloat, weight: UIFont.Weight) -> UIFont {
        guard let base = UIFont(name: name, size: size) else {
            // 字体未打包或未注册（检查 UIAppFonts / target membership）
            return UIFont.systemFont(ofSize: size, weight: weight)
        }
        let desc = base.fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight.rawValue]
        ])
        return UIFont(descriptor: desc, size: size)
    }
}

// MARK: - SwiftUI Font Extensions
// 让 `.font(.app(...))`、`.font(.appBody(...))` 语法在 SwiftUI View 中直接可用
// 参数使用 Font.Weight（而非 UIFont.Weight），避免 SwiftUI 上下文中类型歧义

private extension Font.Weight {
    var ui: UIFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin:       return .thin
        case .light:      return .light
        case .regular:    return .regular
        case .medium:     return .medium
        case .semibold:   return .semibold
        case .bold:       return .bold
        case .heavy:      return .heavy
        case .black:      return .black
        default:          return .regular
        }
    }
}

extension Font {
    /// 自动按字重选择 标题 / 正文
    static func app(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        AppFont.app(size: size, weight: weight.ui)
    }

    /// 显式正文（思源宋体 + Source Serif Pro）
    static func appBody(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        AppFont.appBody(size: size, weight: weight.ui)
    }

    /// 显式标题（思源黑体 + Inter）
    static func appTitle(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        AppFont.appTitle(size: size, weight: weight.ui)
    }
}
