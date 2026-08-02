import SwiftUI

// MARK: - 成就徽章

struct AchievementView: View {
    @StateObject private var store = ProfileStore.shared

    private var badges: [Badge] {
        let lost = store.weightLost
        let doneCount = store.workouts.filter { $0.done }.count
        return [
            Badge(emoji: "🌱", title: "迈开第一步", desc: "记录第一笔体重", earned: store.weightHistory.count > 1),
            Badge(emoji: "🔥", title: "已减 1kg", desc: "累计减重 1 公斤", earned: lost >= 1),
            Badge(emoji: "💪", title: "已减 3kg", desc: "累计减重 3 公斤", earned: lost >= 3),
            Badge(emoji: "🏅", title: "已减 5kg", desc: "累计减重 5 公斤", earned: lost >= 5),
            Badge(emoji: "📅", title: "运动打卡", desc: "完成一次运动计划", earned: doneCount >= 1),
            Badge(emoji: "📆", title: "周计划达人", desc: "完成全部 7 天计划", earned: doneCount >= 7),
            Badge(emoji: "🎯", title: "目标在望", desc: "距目标不足 2kg", earned: store.remainingToTarget <= 2 && store.remainingToTarget > 0),
            Badge(emoji: "👑", title: "达成目标", desc: "达到目标体重", earned: store.remainingToTarget <= 0.05),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                let earned = badges.filter { $0.earned }.count
                HStack {
                    Text("已解锁 \(earned) / \(badges.count)")
                        .font(.app(size: 16, weight: .semibold))
                        .foregroundColor(CardTokens.Color.foreground)
                    Spacer()
                    Text("继续加油 💪")
                        .font(.app(size: 13))
                        .foregroundColor(CardTokens.Color.foregroundSubtle)
                }
                .padding(16)
                .profileCard()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(badges) { b in
                        VStack(spacing: 8) {
                            Text(b.emoji)
                                .font(.system(size: 40))
                                .opacity(b.earned ? 1 : 0.3)
                                .overlay(
                                    b.earned ? nil :
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.gray.opacity(0.6)).padding(6))
                                )
                            Text(b.title)
                                .font(.app(size: 14, weight: .semibold))
                                .foregroundColor(b.earned ? CardTokens.Color.foreground : CardTokens.Color.foregroundSubtle)
                            Text(b.desc)
                                .font(.app(size: 11))
                                .foregroundColor(CardTokens.Color.foregroundSubtle)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(b.earned ? CardTokens.Color.primaryBg10 : Color.white)
                                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(b.earned ? CardTokens.Color.primaryBorder15 : Color.clear, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 20)
        }
        .background(CardTokens.Color.background.ignoresSafeArea())
        .navigationTitle("成就徽章")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct Badge: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let desc: String
    let earned: Bool
}
