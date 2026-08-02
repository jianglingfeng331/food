import SwiftUI

// MARK: - 运动计划

struct WorkoutPlanView: View {
    @StateObject private var store = ProfileStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                let done = store.workouts.filter { $0.done }.count
                VStack(spacing: 8) {
                    HStack {
                        Text("本周完成 \(done) / \(store.workouts.count)")
                            .font(.app(size: 15, weight: .semibold))
                            .foregroundColor(CardTokens.Color.foreground)
                        Spacer()
                        Text("\(Int(Double(done) / Double(store.workouts.count) * 100))%")
                            .font(.app(size: 14, weight: .bold))
                            .foregroundColor(CardTokens.Color.primary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.06))
                            RoundedRectangle(cornerRadius: 6).fill(CardTokens.Color.primary)
                                .frame(width: geo.size.width * CGFloat(Double(done) / Double(max(1, store.workouts.count))))
                        }
                        .frame(height: 8)
                    }
                    .frame(height: 8)
                }
                .padding(16)
                .profileCard()

                VStack(spacing: 0) {
                    ForEach(store.workouts) { item in
                        HStack(spacing: 12) {
                            Button(action: { store.toggleWorkout(item.id) }) {
                                Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(item.done ? CardTokens.Color.primary : CardTokens.Color.foregroundSubtle)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.app(size: 15, weight: .semibold))
                                    .foregroundColor(item.done ? CardTokens.Color.foregroundSubtle : CardTokens.Color.foreground)
                                    .strikethrough(item.done)
                                Text(item.detail)
                                    .font(.app(size: 12))
                                    .foregroundColor(CardTokens.Color.foregroundSubtle)
                            }
                            Spacer()
                            Text(item.weekday)
                                .font(.app(size: 13, weight: .medium))
                                .foregroundColor(CardTokens.Color.foregroundMuted)
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .onTapGesture { store.toggleWorkout(item.id) }
                        if item.id != store.workouts.last?.id {
                            Divider().opacity(0.5)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .profileCard()

                Text("点击左侧圆圈或整行即可标记完成")
                    .font(.app(size: 12))
                    .foregroundColor(CardTokens.Color.foregroundSubtle)
            }
            .padding(20)
        }
        .background(CardTokens.Color.background.ignoresSafeArea())
        .navigationTitle("运动计划")
        .navigationBarTitleDisplayMode(.inline)
    }
}
