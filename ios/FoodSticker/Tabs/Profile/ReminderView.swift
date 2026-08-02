import SwiftUI

// MARK: - 提醒设置

struct ReminderView: View {
    @StateObject private var store = ProfileStore.shared
    @Environment(\.dismiss) private var dismiss

    private let timeFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                reminderRow(emoji: "💧", title: "饮水提醒", subtitle: "定时提醒补充水分",
                            isOn: $store.waterReminderOn, time: $store.waterReminderTime)
                reminderRow(emoji: "⚖️", title: "称重提醒", subtitle: "每天固定时间称重记录",
                            isOn: $store.weighReminderOn, time: $store.weighReminderTime)
                reminderRow(emoji: "🏃", title: "运动提醒", subtitle: "别让计划溜走",
                            isOn: $store.exerciseReminderOn, time: $store.exerciseReminderTime)

                Text("提醒由本机通知触发（Mock 阶段仅记录设置，真实推送后续接入）")
                    .font(.app(size: 12))
                    .foregroundColor(CardTokens.Color.foregroundSubtle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            .padding(20)
        }
        .background(CardTokens.Color.background.ignoresSafeArea())
        .navigationTitle("提醒设置")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { store.saveReminders() }
    }

    private func reminderRow(emoji: String, title: String, subtitle: String,
                             isOn: Binding<Bool>, time: Binding<Date>) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(emoji).font(.system(size: 24))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.app(size: 15, weight: .semibold)).foregroundColor(CardTokens.Color.foreground)
                    Text(subtitle).font(.app(size: 12)).foregroundColor(CardTokens.Color.foregroundSubtle)
                }
                Spacer()
                Toggle("", isOn: isOn).labelsHidden()
            }
            .padding(.vertical, 12)

            if isOn.wrappedValue {
                Divider().opacity(0.5)
                HStack {
                    Text("提醒时间").font(.app(size: 13)).foregroundColor(CardTokens.Color.foregroundMuted)
                    Spacer()
                    DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }
                .padding(.vertical, 10)
            }
        }
        .padding(.horizontal, 16)
        .profileCard()
    }
}
