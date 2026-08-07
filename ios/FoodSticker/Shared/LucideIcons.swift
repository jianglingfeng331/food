//
//  LucideIcons.swift
//  FoodSticker
//
//  自动生成于 2026-07-28
//  来源: lucide-react v0.511.0 → node_modules/lucide-react/dist/esm/icons/
//  转换脚本: scripts/extract_lucide_icons.cjs
//
//  ⚠️ 此文件由脚本自动生成，请勿手动编辑。
//  重新运行: node scripts/extract_lucide_icons.cjs
//

import SwiftUI

// MARK: - Lucide Icon Shapes (1:1 Web 精确还原)
//
// 硬约束参数（与 lucide-react defaultAttributes 完全一致）：
//   viewBox: 0 0 24 24
//   fill: none
//   stroke: currentColor
//   strokeWidth: 2
//   strokeLinecap: round
//   strokeLinejoin: round
//
// 使用方式:
//   UtensilsCrossedIcon()
//     .stroke(Color(hex: "#10B981"), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
//     .frame(width: 24, height: 24)
//     .aspectRatio(contentMode: .fit)
//

// MARK: - utensils-crossed (UtensilsCrossedIcon)

/// lucide-react: utensils-crossed | viewBox: 0 0 24 24 | stroke-width: 2
public struct UtensilsCrossedIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()

        // path n7qcjb — 刀叉。两段弧用三次贝塞尔精确逼近，避免 addArc 在 ImageRenderer 下方向/形状漂移
        path.move(to: CGPoint(x: 16, y: 2))
        path.addLine(to: CGPoint(x: 13.7, y: 4.3))
        // 弧1：(13.7,4.3) → (13.7,8.5)，向左鼓（中心 15.8424,6.4）
        path.addCurve(to: CGPoint(x: 13.7, y: 8.5),
                      control1: CGPoint(x: 12.574, y: 5.406),
                      control2: CGPoint(x: 12.557, y: 7.337))
        path.addLine(to: CGPoint(x: 15.5, y: 10.3))
        // 弧2：(15.5,10.3) → (19.7,10.3)，向下鼓（中心 17.6,8.1576）
        path.addCurve(to: CGPoint(x: 19.7, y: 10.3),
                      control1: CGPoint(x: 16.663, y: 11.443),
                      control2: CGPoint(x: 18.533, y: 11.444))
        path.addLine(to: CGPoint(x: 22, y: 8))
        // path d0u48b
        path.move(to: CGPoint(x: 15, y: 15))
        path.addLine(to: CGPoint(x: 3.3, y: 3.3))
        // 勺子弧：(3.3,3.3) → (3.3,9.3)，向左鼓（中心 6.2394,6.3）
        path.addCurve(to: CGPoint(x: 3.3, y: 9.3),
                      control1: CGPoint(x: 1.619, y: 4.953),
                      control2: CGPoint(x: 1.619, y: 7.647))
        path.addLine(to: CGPoint(x: 10.6, y: 16.6))
        path.addCurve(to: CGPoint(x: 13.4, y: 16.6), control1: CGPoint(x: 11.3, y: 17.3), control2: CGPoint(x: 12.6, y: 17.3))
        path.addLine(to: CGPoint(x: 15, y: 15))
        path.closeSubpath()
        path.move(to: CGPoint(x: 15, y: 15))
        path.addLine(to: CGPoint(x: 22, y: 22))
        // path yn04lh
        path.move(to: CGPoint(x: 2.1, y: 21.8))
        path.addLine(to: CGPoint(x: 8.5, y: 15.5))
        // path 194lzd
        path.move(to: CGPoint(x: 19, y: 5))
        path.addLine(to: CGPoint(x: 12, y: 12))

        // 应用缩放：所有坐标按 scale 缩放
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - sticker (StickerIcon)

/// lucide-react: sticker | viewBox: 0 0 24 24 | stroke-width: 2
public struct StickerIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()

        // path 1: M15.5 3H5a2 2 0 0 0-2 2v14c0 1.1.9 2 2 2h14a2 2 0 0 0 2-2V8.5L15.5 3Z
        path.move(to: CGPoint(x: 15.5, y: 3))
        path.addLine(to: CGPoint(x: 5, y: 3))
        path.addArc(center: CGPoint(x: 5, y: 5), radius: 2,
                    startAngle: Angle(radians: -CGFloat.pi / 2),
                    endAngle: Angle(radians: -CGFloat.pi),
                    clockwise: true)
        path.addLine(to: CGPoint(x: 3, y: 19))
        path.addCurve(to: CGPoint(x: 5, y: 21),
                      control1: CGPoint(x: 3, y: 20.1),
                      control2: CGPoint(x: 3.9, y: 21))
        path.addLine(to: CGPoint(x: 19, y: 21))
        path.addArc(center: CGPoint(x: 19, y: 19), radius: 2,
                    startAngle: Angle(radians: CGFloat.pi / 2),
                    endAngle: Angle(radians: 0),
                    clockwise: true)
        path.addLine(to: CGPoint(x: 21, y: 8.5))
        path.addLine(to: CGPoint(x: 15.5, y: 3))
        path.closeSubpath()

        // path 2: M14 3v4a2 2 0 0 0 2 2h4 (fold line)
        path.move(to: CGPoint(x: 14, y: 3))
        path.addLine(to: CGPoint(x: 14, y: 7))
        path.addArc(center: CGPoint(x: 16, y: 7), radius: 2,
                    startAngle: Angle(radians: CGFloat.pi),
                    endAngle: Angle(radians: CGFloat.pi / 2),
                    clockwise: true)
        path.addLine(to: CGPoint(x: 20, y: 9))

        // path 3: M8 13h.01 (left eye)
        path.move(to: CGPoint(x: 8, y: 13))
        path.addLine(to: CGPoint(x: 8.01, y: 13))

        // path 4: M16 13h.01 (right eye)
        path.move(to: CGPoint(x: 16, y: 13))
        path.addLine(to: CGPoint(x: 16.01, y: 13))

        // path 5: M10 16s.8 1 2 1c1.3 0 2-1 2-1 (smile)
        path.move(to: CGPoint(x: 10, y: 16))
        path.addCurve(to: CGPoint(x: 12, y: 17),
                      control1: CGPoint(x: 10, y: 16),
                      control2: CGPoint(x: 10.8, y: 17))
        path.addCurve(to: CGPoint(x: 14, y: 16),
                      control1: CGPoint(x: 13.3, y: 17),
                      control2: CGPoint(x: 14, y: 16))

        // 应用缩放：所有坐标按 scale 缩放
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - swords (SwordsIcon)

/// lucide-react: swords | viewBox: 0 0 24 24 | stroke-width: 2
public struct SwordsIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()

        // polyline 1hfsw2
        path.move(to: CGPoint(x: 14.5, y: 17.5))
        path.addLine(to: CGPoint(x: 3, y: 6))
        path.addLine(to: CGPoint(x: 3, y: 3))
        path.addLine(to: CGPoint(x: 6, y: 3))
        path.addLine(to: CGPoint(x: 17.5, y: 14.5))
        // line 1vrmhu
        path.move(to: CGPoint(x: 13, y: 19))
        path.addLine(to: CGPoint(x: 19, y: 13))
        // line 1bron3
        path.move(to: CGPoint(x: 16, y: 16))
        path.addLine(to: CGPoint(x: 20, y: 20))
        // line 13pww6
        path.move(to: CGPoint(x: 19, y: 21))
        path.addLine(to: CGPoint(x: 21, y: 19))
        // polyline hbey2j
        path.move(to: CGPoint(x: 14.5, y: 6.5))
        path.addLine(to: CGPoint(x: 18, y: 3))
        path.addLine(to: CGPoint(x: 21, y: 3))
        path.addLine(to: CGPoint(x: 21, y: 6))
        path.addLine(to: CGPoint(x: 17.5, y: 9.5))
        // line 1hf58s
        path.move(to: CGPoint(x: 5, y: 14))
        path.addLine(to: CGPoint(x: 9, y: 18))
        // line pidxm4
        path.move(to: CGPoint(x: 7, y: 17))
        path.addLine(to: CGPoint(x: 4, y: 20))
        // line 1pehsh
        path.move(to: CGPoint(x: 3, y: 19))
        path.addLine(to: CGPoint(x: 5, y: 21))

        // 应用缩放：所有坐标按 scale 缩放
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - camera (CameraIcon)

/// lucide-react: camera | viewBox: 0 0 24 24 | stroke-width: 2
public struct CameraIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()

        // path 1: M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z
        path.move(to: CGPoint(x: 14.5, y: 4))
        path.addLine(to: CGPoint(x: 9.5, y: 4))
        path.addLine(to: CGPoint(x: 7, y: 7))
        path.addLine(to: CGPoint(x: 4, y: 7))
        path.addArc(center: CGPoint(x: 4, y: 9), radius: 2,
                    startAngle: Angle(radians: -CGFloat.pi / 2),
                    endAngle: Angle(radians: -CGFloat.pi),
                    clockwise: true)
        path.addLine(to: CGPoint(x: 2, y: 18))
        path.addArc(center: CGPoint(x: 4, y: 18), radius: 2,
                    startAngle: Angle(radians: CGFloat.pi),
                    endAngle: Angle(radians: CGFloat.pi / 2),
                    clockwise: true)
        path.addLine(to: CGPoint(x: 20, y: 20))
        path.addArc(center: CGPoint(x: 20, y: 18), radius: 2,
                    startAngle: Angle(radians: CGFloat.pi / 2),
                    endAngle: Angle(radians: 0),
                    clockwise: true)
        path.addLine(to: CGPoint(x: 22, y: 9))
        path.addArc(center: CGPoint(x: 20, y: 9), radius: 2,
                    startAngle: Angle(radians: 0),
                    endAngle: Angle(radians: -CGFloat.pi / 2),
                    clockwise: true)
        path.addLine(to: CGPoint(x: 17, y: 7))
        path.addLine(to: CGPoint(x: 14.5, y: 4))
        path.closeSubpath()

        // circle: cx=12, cy=13, r=3
        path.addEllipse(in: CGRect(x: 9, y: 10, width: 6, height: 6))

        // 应用缩放：所有坐标按 scale 缩放
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - dumbbell (DumbbellIcon)

/// lucide-react: dumbbell | viewBox: 0 0 24 24 | stroke-width: 2
public struct DumbbellIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()

        // path 9m4mmf
        path.move(to: CGPoint(x: 17.596, y: 12.768))
        path.addArc(center: CGPoint(x: 19.0105, y: 11.3535), radius: 2.0004, startAngle: Angle(radians: 2.3562), endAngle: Angle(radians: -0.7854), clockwise: false)
        path.addLine(to: CGPoint(x: 18.657, y: 8.172))
        path.addArc(center: CGPoint(x: 20.071, y: 6.7575), radius: 2.0001, startAngle: Angle(radians: 2.356), endAngle: Angle(radians: -0.7856), clockwise: false)
        path.addLine(to: CGPoint(x: 18.657, y: 2.515))
        path.addArc(center: CGPoint(x: 17.2425, y: 3.929), radius: 2.0001, startAngle: Angle(radians: -0.7852), endAngle: Angle(radians: -3.9268), clockwise: false)
        path.addLine(to: CGPoint(x: 14.061, y: 3.575))
        path.addArc(center: CGPoint(x: 12.6465, y: 4.9895), radius: 2.0004, startAngle: Angle(radians: -0.7854), endAngle: Angle(radians: -3.927), clockwise: false)
        path.closeSubpath()
        // path 17g3f0
        path.move(to: CGPoint(x: 2.5, y: 21.5))
        path.addLine(to: CGPoint(x: 3.9, y: 20.1))
        // path 1qn309
        path.move(to: CGPoint(x: 20.1, y: 3.9))
        path.addLine(to: CGPoint(x: 21.5, y: 2.5))
        // path 1t2c92
        path.move(to: CGPoint(x: 5.343, y: 21.485))
        path.addArc(center: CGPoint(x: 6.7575, y: 20.071), radius: 2.0001, startAngle: Angle(radians: 2.3564), endAngle: Angle(radians: -0.7852), clockwise: false)
        path.addLine(to: CGPoint(x: 9.939, y: 20.425))
        path.addArc(center: CGPoint(x: 11.3535, y: 19.0105), radius: 2.0004, startAngle: Angle(radians: 2.3562), endAngle: Angle(radians: -0.7854), clockwise: false)
        path.addLine(to: CGPoint(x: 6.404, y: 11.232))
        path.addArc(center: CGPoint(x: 4.9895, y: 12.6465), radius: 2.0004, startAngle: Angle(radians: -0.7854), endAngle: Angle(radians: -3.927), clockwise: false)
        path.addLine(to: CGPoint(x: 5.343, y: 15.828))
        path.addArc(center: CGPoint(x: 3.929, y: 17.2425), radius: 2.0001, startAngle: Angle(radians: -0.7856), endAngle: Angle(radians: -3.9272), clockwise: false)
        path.closeSubpath()
        // path 6umqxw
        path.move(to: CGPoint(x: 9.6, y: 14.4))
        path.addLine(to: CGPoint(x: 14.4, y: 9.6))

        // 应用缩放：所有坐标按 scale 缩放
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - droplets (DropletsIcon)

/// lucide-react: droplets | viewBox: 0 0 24 24 | stroke-width: 2
public struct DropletsIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()

        // path 1ptgy4
        path.move(to: CGPoint(x: 7, y: 16.3))
        path.addCurve(to: CGPoint(x: 11, y: 12.25), control1: CGPoint(x: 9.2, y: 16.3), control2: CGPoint(x: 11, y: 14.47))
        path.addCurve(to: CGPoint(x: 7, y: 5.3), control1: CGPoint(x: 11, y: 10.03), control2: CGPoint(x: 7.29, y: 6.75))
        path.addCurve(to: CGPoint(x: 4.71, y: 9.06), control1: CGPoint(x: 6.71, y: 6.75), control2: CGPoint(x: 5.86, y: 8.14))
        path.addCurve(to: CGPoint(x: 3, y: 12.25), control1: CGPoint(x: 3.56, y: 9.98), control2: CGPoint(x: 3, y: 11.1))
        path.addCurve(to: CGPoint(x: 7, y: 16.3), control1: CGPoint(x: 3, y: 14.47), control2: CGPoint(x: 4.8, y: 16.3))
        path.closeSubpath()
        // path 1sl1rz
        path.move(to: CGPoint(x: 12.56, y: 6.6))
        path.addArc(center: CGPoint(x: 3.2611, y: 0.7801), radius: 10.97, startAngle: Angle(radians: 0.5592), endAngle: Angle(radians: 0.2056), clockwise: false)
        path.addCurve(to: CGPoint(x: 18, y: 9.52), control1: CGPoint(x: 14.5, y: 5.52), control2: CGPoint(x: 16, y: 7.92))
        path.addCurve(to: CGPoint(x: 21, y: 15.02), control1: CGPoint(x: 20, y: 11.12), control2: CGPoint(x: 21, y: 13.02))
        path.addArc(center: CGPoint(x: 14.0201, y: 15.0489), radius: 6.98, startAngle: Angle(radians: -0.0041), endAngle: Angle(radians: 2.3551), clockwise: true)

        // 应用缩放：所有坐标按 scale 缩放
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - scale (ScaleIcon)

/// lucide-react: scale | viewBox: 0 0 24 24 | stroke-width: 2
public struct ScaleIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()

        // path 108xh3
        path.move(to: CGPoint(x: 12, y: 3))
        path.addLine(to: CGPoint(x: 12, y: 21))
        // path zcdpyk
        path.move(to: CGPoint(x: 19, y: 8))
        path.addLine(to: CGPoint(x: 22, y: 16))
        path.addArc(center: CGPoint(x: 19, y: 12), radius: 5, startAngle: Angle(radians: 0.9273), endAngle: Angle(radians: 2.2143), clockwise: true)
        path.closeSubpath()
        path.addLine(to: CGPoint(x: 19, y: 7))
        // path 1yorad
        path.move(to: CGPoint(x: 3, y: 7))
        path.addLine(to: CGPoint(x: 4, y: 7))
        path.addArc(center: CGPoint(x: 4, y: -10), radius: 17, startAngle: Angle(radians: 1.5708), endAngle: Angle(radians: 1.0808), clockwise: false)
        path.addLine(to: CGPoint(x: 13, y: 5))
        // path eua70x
        path.move(to: CGPoint(x: 5, y: 8))
        path.addLine(to: CGPoint(x: 8, y: 16))
        path.addArc(center: CGPoint(x: 5, y: 12), radius: 5, startAngle: Angle(radians: 0.9273), endAngle: Angle(radians: 2.2143), clockwise: true)
        path.closeSubpath()
        path.addLine(to: CGPoint(x: 5, y: 7))
        // path 1b0cd5
        path.move(to: CGPoint(x: 7, y: 21))
        path.addLine(to: CGPoint(x: 17, y: 21))

        // 应用缩放：所有坐标按 scale 缩放
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - trophy (TrophyIcon)

/// lucide-react: trophy | viewBox: 0 0 24 24 | stroke-width: 2
public struct TrophyIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()

        // path pwuv1l
        path.move(to: CGPoint(x: 10, y: 14.66))
        path.addLine(to: CGPoint(x: 10, y: 17))
        path.addArc(center: CGPoint(x: 9, y: 17), radius: 1, startAngle: Angle(radians: 0), endAngle: Angle(radians: 1.5708), clockwise: true)
        path.addLine(to: CGPoint(x: 9, y: 20))
        // path 1y54w1
        path.move(to: CGPoint(x: 14, y: 14.66))
        path.addLine(to: CGPoint(x: 14, y: 17))
        path.addArc(center: CGPoint(x: 15, y: 17), radius: 1, startAngle: Angle(radians: 3.1416), endAngle: Angle(radians: 1.5708), clockwise: false)
        path.addLine(to: CGPoint(x: 15, y: 20))
        // path e30mpu
        path.move(to: CGPoint(x: 17.916, y: 10))
        path.addLine(to: CGPoint(x: 19.5, y: 10))
        path.addArc(center: CGPoint(x: 19.5, y: 7.5), radius: 2.5, startAngle: Angle(radians: 1.5708), endAngle: Angle(radians: 0), clockwise: false)
        path.addLine(to: CGPoint(x: 22, y: 5))
        path.addArc(center: CGPoint(x: 21, y: 5), radius: 1, startAngle: Angle(radians: 0), endAngle: Angle(radians: -1.5708), clockwise: false)
        path.addLine(to: CGPoint(x: 18, y: 4))
        // path 57wxv0
        path.move(to: CGPoint(x: 4, y: 22))
        path.addLine(to: CGPoint(x: 20, y: 22))
        // path 1mhfuq
        path.move(to: CGPoint(x: 6, y: 9))
        path.addArc(center: CGPoint(x: 12, y: 9), radius: 6, startAngle: Angle(radians: 3.1416), endAngle: Angle(radians: 0), clockwise: false)
        path.addLine(to: CGPoint(x: 18, y: 3))
        path.addArc(center: CGPoint(x: 17, y: 3), radius: 1, startAngle: Angle(radians: 0), endAngle: Angle(radians: -1.5708), clockwise: false)
        path.addLine(to: CGPoint(x: 7, y: 2))
        path.addArc(center: CGPoint(x: 7, y: 3), radius: 1, startAngle: Angle(radians: -1.5708), endAngle: Angle(radians: -3.1416), clockwise: false)
        path.closeSubpath()
        // path i0yafy
        path.move(to: CGPoint(x: 6.084, y: 10))
        path.addLine(to: CGPoint(x: 4.5, y: 10))
        path.addArc(center: CGPoint(x: 4.5, y: 7.5), radius: 2.5, startAngle: Angle(radians: 1.5708), endAngle: Angle(radians: 3.1416), clockwise: true)
        path.addLine(to: CGPoint(x: 2, y: 5))
        path.addArc(center: CGPoint(x: 3, y: 5), radius: 1, startAngle: Angle(radians: 3.1416), endAngle: Angle(radians: 4.7124), clockwise: true)
        path.addLine(to: CGPoint(x: 6, y: 4))

        // 应用缩放：所有坐标按 scale 缩放
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - crown (CrownIcon)

/// lucide-react: crown | viewBox: 0 0 24 24 | stroke-width: 2
public struct CrownIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()

        // path 1vdc57
        path.move(to: CGPoint(x: 11.562, y: 3.266))
        path.addArc(center: CGPoint(x: 12, y: 3.5072), radius: 0.5, startAngle: Angle(radians: -2.6383), endAngle: Angle(radians: -0.5033), clockwise: true)
        path.addLine(to: CGPoint(x: 15.39, y: 8.87))
        path.addArc(center: CGPoint(x: 16.269, y: 8.3931), radius: 1, startAngle: Angle(radians: 2.6445), endAngle: Angle(radians: 0.8802), clockwise: false)
        path.addLine(to: CGPoint(x: 21.183, y: 5.5))
        path.addArc(center: CGPoint(x: 21.4985, y: 5.8879), radius: 0.5, startAngle: Angle(radians: -2.2536), endAngle: Angle(radians: 0.2653), clockwise: true)
        path.addLine(to: CGPoint(x: 19.147, y: 16.265))
        path.addArc(center: CGPoint(x: 18.183, y: 15.999), radius: 1, startAngle: Angle(radians: 0.2692), endAngle: Angle(radians: 1.5628), clockwise: true)
        path.addLine(to: CGPoint(x: 5.81, y: 16.999))
        path.addArc(center: CGPoint(x: 5.817, y: 15.999), radius: 1, startAngle: Angle(radians: 1.5778), endAngle: Angle(radians: 2.8724), clockwise: true)
        path.addLine(to: CGPoint(x: 2.02, y: 6.02))
        path.addArc(center: CGPoint(x: 2.5025, y: 5.8889), radius: 0.5, startAngle: Angle(radians: 2.8763), endAngle: Angle(radians: 5.3952), clockwise: true)
        path.addLine(to: CGPoint(x: 7.094, y: 9.165))
        path.addArc(center: CGPoint(x: 7.731, y: 8.3941), radius: 1, startAngle: Angle(radians: 2.2614), endAngle: Angle(radians: 0.4971), clockwise: false)
        path.closeSubpath()
        // path 11awu3
        path.move(to: CGPoint(x: 5, y: 21))
        path.addLine(to: CGPoint(x: 19, y: 21))

        // 应用缩放：所有坐标按 scale 缩放
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - chevron-down (ChevronDownIcon)

/// lucide-react: chevron-down | viewBox: 0 0 24 24 | stroke-width: 2
public struct ChevronDownIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()

        // path qrunsl
        path.move(to: CGPoint(x: 6, y: 9))
        path.addLine(to: CGPoint(x: 12, y: 15))
        path.addLine(to: CGPoint(x: 18, y: 9))

        // 应用缩放：所有坐标按 scale 缩放
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - activity (ActivityIcon)

/// lucide-react: activity | viewBox: 0 0 24 24 | stroke-width: 2
public struct ActivityIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()

        // path 169zse
        path.move(to: CGPoint(x: 22, y: 12))
        path.addLine(to: CGPoint(x: 19.52, y: 12))
        path.addArc(center: CGPoint(x: 19.5157, y: 14), radius: 2, startAngle: Angle(radians: -1.5687), endAngle: Angle(radians: -2.8682), clockwise: false)
        path.addLine(to: CGPoint(x: 15.24, y: 21.82))
        path.addArc(center: CGPoint(x: 15, y: 21.75), radius: 0.25, startAngle: Angle(radians: 0.2838), endAngle: Angle(radians: 2.8578), clockwise: true)
        path.addLine(to: CGPoint(x: 9.24, y: 2.18))
        path.addArc(center: CGPoint(x: 9, y: 2.25), radius: 0.25, startAngle: Angle(radians: -0.2838), endAngle: Angle(radians: -2.8578), clockwise: false)
        path.addLine(to: CGPoint(x: 6.41, y: 10.54))
        path.addArc(center: CGPoint(x: 4.4843, y: 10), radius: 2, startAngle: Angle(radians: 0.2734), endAngle: Angle(radians: 1.5679), clockwise: true)
        path.addLine(to: CGPoint(x: 2, y: 12))

        // 应用缩放：所有坐标按 scale 缩放
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - clock (ClockIcon)

/// lucide-react: clock | viewBox: 0 0 24 24 | stroke-width: 2
public struct ClockIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()

        // circle 1mglay
        path.addEllipse(in: CGRect(x: 2, y: 2, width: 20, height: 20))
        // path mmk7yg
        path.move(to: CGPoint(x: 12, y: 6))
        path.addLine(to: CGPoint(x: 12, y: 12))
        path.addLine(to: CGPoint(x: 16, y: 14))

        // 应用缩放：所有坐标按 scale 缩放
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - flame (FlameIcon)

/// lucide-react: flame | viewBox: 0 0 24 24 | stroke-width: 2
public struct FlameIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()

        // path 1slcih
        path.move(to: CGPoint(x: 12, y: 3))
        path.addQuadCurve(to: CGPoint(x: 16, y: 9.5), control: CGPoint(x: 13, y: 7))
        path.addQuadCurve(to: CGPoint(x: 19, y: 15), control: CGPoint(x: 19, y: 12))
        path.addArc(center: CGPoint(x: 12, y: 15), radius: 7, startAngle: Angle(radians: 0), endAngle: Angle(radians: 3.1416), clockwise: true)
        path.addCurve(to: CGPoint(x: 3.5, y: 10), control1: CGPoint(x: 5, y: 13), control2: CGPoint(x: 3.5, y: 12))
        path.addQuadCurve(to: CGPoint(x: 6, y: 6), control: CGPoint(x: 3.5, y: 8))

        // 应用缩放：所有坐标按 scale 缩放
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - plus (PlusIcon)

/// lucide-react: plus | viewBox: 0 0 24 24 | stroke-width: 2
public struct PlusIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()

        // path 1ays0h
        path.move(to: CGPoint(x: 5, y: 12))
        path.addLine(to: CGPoint(x: 19, y: 12))
        // path s699le
        path.move(to: CGPoint(x: 12, y: 5))
        path.addLine(to: CGPoint(x: 12, y: 19))

        // 应用缩放：所有坐标按 scale 缩放
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - AnyShape (类型擦除包装器)

/// 允许在集合中存储不同类型的 SwiftUI Shape
/// 使用方式: let shapes = [AnyShape(UtensilsCrossedIcon()), AnyShape(CameraIcon())]
public struct AnyShape: Shape, @unchecked Sendable {
    private let _path: @Sendable (CGRect) -> Path

    public init<S: Shape>(_ shape: S) {
        _path = { shape.path(in: $0) }
    }

    public func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - x (XIcon) — 关闭按钮

/// lucide-react: x | viewBox: 0 0 24 24 | stroke-width: 2
public struct XIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()
        path.move(to: CGPoint(x: 18, y: 6))
        path.addLine(to: CGPoint(x: 6, y: 18))
        path.move(to: CGPoint(x: 6, y: 6))
        path.addLine(to: CGPoint(x: 18, y: 18))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - images (ImagesIcon) — 相册 / 选择照片

/// lucide-react: images | viewBox: 0 0 24 24 | stroke-width: 2
/// path: M18 22H4a2 2 0 0 1-2-2V6 / m22 13-1.296-1.296a2.41 2.41 0 0 0-3.408 0L11 18
///       / circle cx=12 cy=8 r=2 / rect width=16 height=16 x=6 y=2 rx=2
public struct ImagesIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()

        // 前卡片（圆角矩形）
        path.addRoundedRect(in: CGRect(x: 6, y: 2, width: 16, height: 16),
                            cornerSize: CGSize(width: 2, height: 2))

        // 后卡片轮廓：底沿 + 左下圆角 + 左边，再接顶部弧 + 右边
        var back = Path()
        back.move(to: CGPoint(x: 18, y: 22))
        back.addLine(to: CGPoint(x: 4, y: 22))
        // a2 2 0 0 1 -2 -2  → 以 (2,22) 为圆心的 1/4 圆角
        back.addQuadCurve(to: CGPoint(x: 2, y: 20), control: CGPoint(x: 2, y: 22))
        back.addLine(to: CGPoint(x: 2, y: 6))
        // 顶部弧：m22 13 → (22,13) → (20.704,11.704)，半径 2.41 轻微上凸
        back.move(to: CGPoint(x: 22, y: 13))
        back.addLine(to: CGPoint(x: 20.704, y: 11.704))
        back.addQuadCurve(to: CGPoint(x: 17.296, y: 11.704), control: CGPoint(x: 19, y: 10.3))
        back.addLine(to: CGPoint(x: 11, y: 18))
        path.addPath(back)

        // 太阳（圆）
        path.addEllipse(in: CGRect(x: 10, y: 6, width: 4, height: 4))

        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - rotate-ccw (RotateCcwIcon) — 重新拍摄

/// lucide-react: rotate-ccw | viewBox: 0 0 24 24 | stroke-width: 2（带箭头的环，简化表达）
public struct RotateCcwIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()
        path.addArc(center: CGPoint(x: 12, y: 12), radius: 9,
                    startAngle: .degrees(45), endAngle: .degrees(315), clockwise: false)
        // 箭头头部
        path.move(to: CGPoint(x: 12, y: 3))
        path.addLine(to: CGPoint(x: 12, y: 7))
        path.addLine(to: CGPoint(x: 16, y: 5))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - user (UserIcon) — 默认头像 / 本人

/// lucide-react: user | viewBox: 0 0 24 24 | stroke-width: 2
public struct UserIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()
        // 身体：M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2
        path.move(to: CGPoint(x: 19, y: 21))
        path.addLine(to: CGPoint(x: 19, y: 19))
        path.addLine(to: CGPoint(x: 15, y: 19))
        path.addQuadCurve(to: CGPoint(x: 9, y: 19), control: CGPoint(x: 9, y: 19))
        path.addLine(to: CGPoint(x: 5, y: 19))
        path.addLine(to: CGPoint(x: 5, y: 21))
        // 头：circle cx=12 cy=7 r=4
        path.addEllipse(in: CGRect(x: 8, y: 3, width: 8, height: 8))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - chevron-right (ChevronRightIcon)

/// lucide-react: chevron-right | viewBox: 0 0 24 24 | stroke-width: 2
public struct ChevronRightIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()
        path.move(to: CGPoint(x: 9, y: 6))
        path.addLine(to: CGPoint(x: 15, y: 12))
        path.addLine(to: CGPoint(x: 9, y: 18))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - settings (SettingsIcon)

/// lucide-react: settings | viewBox: 0 0 24 24 | stroke-width: 2（齿轮：外环 + 中心孔 + 四辐条）
public struct SettingsIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()
        path.addEllipse(in: CGRect(x: 4, y: 4, width: 16, height: 16))
        path.addEllipse(in: CGRect(x: 10, y: 10, width: 4, height: 4))
        // 四辐条
        path.move(to: CGPoint(x: 12, y: 2)); path.addLine(to: CGPoint(x: 12, y: 5))
        path.move(to: CGPoint(x: 12, y: 19)); path.addLine(to: CGPoint(x: 12, y: 22))
        path.move(to: CGPoint(x: 2, y: 12)); path.addLine(to: CGPoint(x: 5, y: 12))
        path.move(to: CGPoint(x: 19, y: 12)); path.addLine(to: CGPoint(x: 22, y: 12))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - log-out (LogOutIcon)

/// lucide-react: log-out | viewBox: 0 0 24 24 | stroke-width: 2
public struct LogOutIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()
        // M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4
        path.move(to: CGPoint(x: 9, y: 21))
        path.addLine(to: CGPoint(x: 5, y: 21))
        path.addQuadCurve(to: CGPoint(x: 3, y: 19), control: CGPoint(x: 3, y: 21))
        path.addLine(to: CGPoint(x: 3, y: 5))
        path.addQuadCurve(to: CGPoint(x: 5, y: 3), control: CGPoint(x: 3, y: 3))
        path.addLine(to: CGPoint(x: 9, y: 3))
        // m16 17 5-5-5-5
        path.move(to: CGPoint(x: 16, y: 17))
        path.addLine(to: CGPoint(x: 21, y: 12))
        path.addLine(to: CGPoint(x: 16, y: 7))
        // M21 12H9
        path.move(to: CGPoint(x: 21, y: 12))
        path.addLine(to: CGPoint(x: 9, y: 12))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - pencil (PencilIcon) — 编辑昵称

/// lucide-react: pencil | viewBox: 0 0 24 24 | stroke-width: 2（简化钢笔）
public struct PencilIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()
        // M12 20h9
        path.move(to: CGPoint(x: 12, y: 20))
        path.addLine(to: CGPoint(x: 21, y: 20))
        // M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z
        path.move(to: CGPoint(x: 16.5, y: 3.5))
        path.addLine(to: CGPoint(x: 19.5, y: 6.5))
        path.addLine(to: CGPoint(x: 7, y: 19))
        path.addLine(to: CGPoint(x: 4, y: 20))
        path.addLine(to: CGPoint(x: 5, y: 16))
        path.addLine(to: CGPoint(x: 16.5, y: 3.5))
        path.closeSubpath()
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - check (CheckIcon) — 保存

/// lucide-react: check | viewBox: 0 0 24 24 | stroke-width: 2
public struct CheckIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()
        path.move(to: CGPoint(x: 20, y: 6))
        path.addLine(to: CGPoint(x: 9, y: 17))
        path.addLine(to: CGPoint(x: 4, y: 12))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - trash-2 (TrashIcon) — 删除

/// lucide-react: trash-2 | viewBox: 0 0 24 24 | stroke-width: 2
public struct TrashIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()
        // M3 6h18
        path.move(to: CGPoint(x: 3, y: 6))
        path.addLine(to: CGPoint(x: 21, y: 6))
        // M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6
        path.move(to: CGPoint(x: 19, y: 6))
        path.addLine(to: CGPoint(x: 19, y: 20))
        path.addQuadCurve(to: CGPoint(x: 17, y: 22), control: CGPoint(x: 19, y: 22))
        path.addLine(to: CGPoint(x: 7, y: 22))
        path.addQuadCurve(to: CGPoint(x: 5, y: 20), control: CGPoint(x: 5, y: 22))
        path.addLine(to: CGPoint(x: 5, y: 6))
        // M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2
        path.move(to: CGPoint(x: 8, y: 6))
        path.addLine(to: CGPoint(x: 8, y: 4))
        path.addQuadCurve(to: CGPoint(x: 10, y: 2), control: CGPoint(x: 8, y: 2))
        path.addLine(to: CGPoint(x: 14, y: 2))
        path.addQuadCurve(to: CGPoint(x: 16, y: 4), control: CGPoint(x: 16, y: 2))
        path.addLine(to: CGPoint(x: 16, y: 6))
        // M10 11v6  /  M14 11v6
        path.move(to: CGPoint(x: 10, y: 11)); path.addLine(to: CGPoint(x: 10, y: 17))
        path.move(to: CGPoint(x: 14, y: 11)); path.addLine(to: CGPoint(x: 14, y: 17))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - trending-up (TrendingUpIcon) — 体重趋势

/// lucide-react: trending-up | viewBox: 0 0 24 24 | stroke-width: 2
public struct TrendingUpIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()
        // M22 7l-8.5 8.5-5-5L2 17
        path.move(to: CGPoint(x: 22, y: 7))
        path.addLine(to: CGPoint(x: 13.5, y: 15.5))
        path.addLine(to: CGPoint(x: 9.5, y: 11.5))
        path.addLine(to: CGPoint(x: 2, y: 19))
        // M16 7h6v6（末端上升箭头）
        path.move(to: CGPoint(x: 16, y: 7))
        path.addLine(to: CGPoint(x: 22, y: 7))
        path.addLine(to: CGPoint(x: 22, y: 13))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

/// lucide-react: bell | viewBox: 0 0 24 24 | stroke-width: 2
public struct BellIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()
        // M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9
        path.move(to: CGPoint(x: 6, y: 8))
        path.addQuadCurve(to: CGPoint(x: 18, y: 8), control: CGPoint(x: 18, y: 1.5))
        path.addLine(to: CGPoint(x: 21, y: 17))
        path.addLine(to: CGPoint(x: 3, y: 17))
        path.addLine(to: CGPoint(x: 6, y: 8))
        // M10.3 21a1.94 1.94 0 0 0 3.4 0
        path.move(to: CGPoint(x: 10.3, y: 21))
        path.addQuadCurve(to: CGPoint(x: 13.7, y: 21), control: CGPoint(x: 12, y: 23))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - log-in (LogInIcon) — 注册 / 登录

/// lucide-react: log-in | viewBox: 0 0 24 24 | stroke-width: 2
public struct LogInIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()
        // M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4
        path.move(to: CGPoint(x: 15, y: 3))
        path.addLine(to: CGPoint(x: 19, y: 3))
        path.addQuadCurve(to: CGPoint(x: 21, y: 5), control: CGPoint(x: 21, y: 3))
        path.addLine(to: CGPoint(x: 21, y: 19))
        path.addQuadCurve(to: CGPoint(x: 19, y: 21), control: CGPoint(x: 21, y: 21))
        path.addLine(to: CGPoint(x: 15, y: 21))
        // m10 17 5-5-5-5
        path.move(to: CGPoint(x: 10, y: 17))
        path.addLine(to: CGPoint(x: 15, y: 12))
        path.addLine(to: CGPoint(x: 10, y: 7))
        // M21 12H10
        path.move(to: CGPoint(x: 21, y: 12))
        path.addLine(to: CGPoint(x: 10, y: 12))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - message-square (MessageSquareIcon) — 意见反馈

/// lucide-react: message-square | viewBox: 0 0 24 24 | stroke-width: 2
/// path: M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z
public struct MessageSquareIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()
        // 气泡主体：M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z
        path.move(to: CGPoint(x: 21, y: 15))
        path.addArc(center: CGPoint(x: 19, y: 15), radius: 2,
                    startAngle: Angle(radians: 0),
                    endAngle: Angle(radians: CGFloat.pi / 2),
                    clockwise: false)
        path.addLine(to: CGPoint(x: 7, y: 17))
        path.addLine(to: CGPoint(x: 3, y: 21))
        path.addLine(to: CGPoint(x: 3, y: 5))
        path.addArc(center: CGPoint(x: 5, y: 5), radius: 2,
                    startAngle: Angle(radians: CGFloat.pi),
                    endAngle: Angle(radians: -CGFloat.pi / 2),
                    clockwise: true)
        path.addLine(to: CGPoint(x: 19, y: 3))
        path.addArc(center: CGPoint(x: 19, y: 5), radius: 2,
                    startAngle: Angle(radians: -CGFloat.pi / 2),
                    endAngle: Angle(radians: 0),
                    clockwise: false)
        path.closeSubpath()
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}

// MARK: - info (InfoIcon) — 关于我们

/// lucide-react: info | viewBox: 0 0 24 24 | stroke-width: 2
/// circle cx=12 cy=12 r=10 / line x1=12 y1=16 x2=12 y2=12 / line x1=12 y1=8 x2=12.01 y2=8
public struct InfoIcon: Shape {
    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24.0
        var path = Path()
        // 外圆
        path.addEllipse(in: CGRect(x: 2, y: 2, width: 20, height: 20))
        // 竖线（下半段）
        path.move(to: CGPoint(x: 12, y: 16))
        path.addLine(to: CGPoint(x: 12, y: 12))
        // 圆点（顶部）
        path.move(to: CGPoint(x: 12, y: 8))
        path.addLine(to: CGPoint(x: 12.01, y: 8))
        return path.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
}
