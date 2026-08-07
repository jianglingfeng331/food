import SwiftUI

// MARK: - Flat Card 容器修饰符

struct FlatCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: HomeTokens.Radius.card)
                    .fill(HomeTokens.Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HomeTokens.Radius.card)
                    .stroke(HomeTokens.Color.surfaceBorder, lineWidth: 1)
            )
            .shadow(
                color: HomeTokens.Shadow.card,
                radius: HomeTokens.Shadow.cardRadius,
                y: HomeTokens.Shadow.cardY
            )
    }
}

extension View {
    func flatCard() -> some View {
        modifier(FlatCardModifier())
    }
}

// MARK: - 进度条渐变

enum ProgressGradient {
    /// primary: #10B981 → #34D399
    static let primary = LinearGradient(
        colors: [HomeTokens.Color.primary, HomeTokens.Color.primaryLight],
        startPoint: .leading,
        endPoint: .trailing
    )
    /// secondary: #34D399 → rgba(16,185,129,0.6)
    static let secondary = LinearGradient(
        colors: [HomeTokens.Color.primaryLight, HomeTokens.Color.primary.opacity(0.6)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - 进度条视图 (可复用)

struct ProgressBarView: View {
    let progress: Double     // 0...100
    let height: CGFloat
    let cornerRadius: CGFloat
    let gradient: LinearGradient

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(HomeTokens.Color.background)
                    .frame(height: height)

                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(gradient)
                    .frame(width: max(0, geo.size.width) * CGFloat(progress / 100.0), height: height)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: height)
    }
}
