import SwiftUI

// MARK: - 顶部栏

struct TopBarView: View {
    let nickname: String
    var onProfileTap: (() -> Void)?

    @State private var greeting: String = ""

    var body: some View {
        HStack {
            // 左侧：问候语 · 昵称 + 下拉箭头
            HStack(spacing: 6) {
                Text(greeting)
                    .font(.app(size: HomeTokens.FontSize.greeting,
                                  weight: HomeTokens.FontWeight.bold))
                    .foregroundColor(HomeTokens.Color.foreground)

                Text("·")
                    .font(.app(size: HomeTokens.FontSize.small))
                    .foregroundColor(HomeTokens.Color.foregroundSubtle)

                Text(nickname)
                    .font(.app(size: HomeTokens.FontSize.body))
                    .foregroundColor(HomeTokens.Color.foregroundMuted)

                Image(systemName: "chevron.down")
                    .font(.app(size: HomeTokens.FontSize.small))
                    .foregroundColor(HomeTokens.Color.foregroundMuted)
                    .frame(width: 20, height: 20)
            }

            Spacer()

            // 右侧：个人中心入口
            Button(action: { onProfileTap?() }) {
                Image(systemName: "person.crop.circle")
                    .font(.app(size: 24))
                    .foregroundColor(HomeTokens.Color.foregroundMuted)
            }
        }
        .padding(.top, HomeTokens.Spacing.topBarTop)
        .padding(.bottom, HomeTokens.Spacing.topBarBottom)
        .padding(.horizontal, HomeTokens.Spacing.horizontal)
        .background(HomeTokens.Color.cardBackground)
        .onAppear { updateGreeting() }
    }

    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: greeting = "早上好"
        case 11..<14: greeting = "中午好"
        case 14..<18: greeting = "下午好"
        default: greeting = "晚上好"
        }
    }
}
