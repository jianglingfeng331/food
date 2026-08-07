import SwiftUI
import Combine

// MARK: - 减脂目标
//
// 身高 / 当前体重 / 目标体重 通过「点击进入滚轮选择页」编辑，
// 交互参考本项目统一卡片风格（滚轮 Picker + 完成保存）。

struct GoalView: View {
    @StateObject private var store = ProfileStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var editField: EditField? = nil

    enum EditField: Identifiable {
        case height, current, target
        var id: Int { hashValue }
    }

    /// 是否已完成初始设置（身高>0 且 当前体重>0）
    private var isSetup: Bool { store.heightCm > 0 && store.currentWeight > 0 }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if isSetup {
                    // BMI 概览
                    VStack(spacing: 8) {
                        Text(String(format: "BMI %.1f", store.bmi))
                            .font(.app(size: 34, weight: .bold))
                            .foregroundColor(CardTokens.Color.foreground)
                        Text("当前分类：\(store.bmiCategory)")
                            .font(.app(size: 14))
                            .foregroundColor(CardTokens.Color.foregroundMuted)
                        bmiBar
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .profileCard()
                } else {
                    // 未设置状态提示
                    VStack(spacing: 10) {
                        Image(systemName: "figure.stand")
                            .font(.system(size: 32))
                            .foregroundColor(CardTokens.Color.foregroundSubtle)
                        Text("尚未设置身体数据")
                            .font(.app(size: 16, weight: .medium))
                            .foregroundColor(CardTokens.Color.foreground)
                        Text("请点击下方设置身高、体重及目标")
                            .font(.app(size: 13))
                            .foregroundColor(CardTokens.Color.foregroundMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .profileCard()
                }

                // 目标录入（点击进入滚轮选择）
                VStack(spacing: 0) {
                    valueRow(title: "身高", display: store.heightCm > 0 ? String(format: "%.0f", store.heightCm) : "未设置", unit: "cm") {
                        editField = .height
                    }
                    divider
                    valueRow(title: "当前体重", display: store.currentWeight > 0 ? String(format: "%.1f", store.currentWeight) : "未设置", unit: "kg") {
                        editField = .current
                    }
                    divider
                    valueRow(title: "目标体重", display: store.targetWeight > 0 ? String(format: "%.1f", store.targetWeight) : "未设置", unit: "kg") {
                        editField = .target
                    }
                }
                .profileCard()

                if isSetup {
                    // 进度预测
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            metric(title: "已减", value: String(format: "%.1f", store.weightLost), unit: "kg")
                            Spacer()
                            metric(title: "距目标", value: String(format: "%.1f", store.remainingToTarget), unit: "kg")
                        }
                        let total = max(0.1, (store.weightLost + store.remainingToTarget))
                        progressBar(ratio: store.weightLost / total)
                        Text("完成度 \(Int((store.weightLost / total) * 100))%")
                            .font(.app(size: 12))
                            .foregroundColor(CardTokens.Color.foregroundSubtle)
                    }
                    .padding(16)
                    .profileCard()
                }
            }
            .padding(20)
        }
        .background(CardTokens.Color.background.ignoresSafeArea())
        .navigationTitle("减脂目标")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editField) { field in
            GoalValueSheet(field: field)
                .environmentObject(store)
                .interactiveDismissDisabled()
                .presentationDetents([.height(340)])
        }
    }

    // MARK: 视图碎片

    private var bmiBar: some View {
        GeometryReader { geo in
            let maxV = 40.0
            let w = geo.size.width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(LinearGradient(colors: [Color.orange.opacity(0.5), CardTokens.Color.primary, Color.purple.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 8)
                let x = min(max(store.bmi / maxV, 0), 1) * w
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .shadow(radius: 2)
                    .offset(x: x - 8, y: 0)
            }
            .frame(height: 16)
        }
        .frame(height: 16)
    }

    private func valueRow(title: String, display: String, unit: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).font(.app(size: 15)).foregroundColor(CardTokens.Color.foreground)
                Spacer()
                Text(display)
                    .font(.app(size: 16, weight: .semibold))
                    .foregroundColor(display == "未设置" ? CardTokens.Color.foregroundSubtle : CardTokens.Color.foreground)
                Text(unit).font(.app(size: 13)).foregroundColor(CardTokens.Color.foregroundSubtle)
                ChevronRightIcon()
                    .stroke(CardTokens.Color.foregroundSubtle, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 18, height: 18)
                    .padding(.leading, 4)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle()
            .fill(CardTokens.Color.foreground.opacity(0.06))
            .frame(height: 0.5)
    }

    private func metric(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.app(size: 12)).foregroundColor(CardTokens.Color.foregroundSubtle)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.app(size: 22, weight: .bold)).foregroundColor(CardTokens.Color.foreground)
                Text(unit).font(.app(size: 12)).foregroundColor(CardTokens.Color.foregroundSubtle)
            }
        }
    }

    private func progressBar(ratio: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.06))
                RoundedRectangle(cornerRadius: 6).fill(CardTokens.Color.primary)
                    .frame(width: geo.size.width * CGFloat(min(max(ratio, 0), 1)))
            }
            .frame(height: 10)
        }
        .frame(height: 10)
    }
}

// MARK: - 滚轮选择页（点击进入）

struct GoalValueSheet: View {
    let field: GoalView.EditField
    @StateObject private var store = ProfileStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var value: Double = 0

    private var titleText: String {
        switch field {
        case .height:  return "身高"
        case .current: return "当前体重"
        case .target:  return "目标体重"
        }
    }
    private var minValue: Double {
        switch field { case .height: return 140; default: return 35 }
    }
    private var maxValue: Double {
        switch field { case .height: return 210; default: return 150 }
    }
    private var stepValue: Double {
        switch field { case .height: return 1; default: return 0.5 }
    }
    private var unitText: String {
        switch field { case .height: return "cm"; default: return "kg" }
    }
    private var currentValue: Double {
        switch field {
        case .height:  return store.heightCm
        case .current: return store.currentWeight
        case .target:  return store.targetWeight
        }
    }
    private func apply(_ v: Double) {
        switch field {
        case .height:  store.heightCm = v
        case .current: store.currentWeight = v
        case .target:  store.targetWeight = v
        }
        store.saveGoals()
    }

    /// 使用整数步进生成选项值，避免 stride(by: 0.5) 的浮点精度漂移
    private var pickerValues: [Double] {
        if stepValue == 1 {
            return Array(stride(from: Int(minValue), through: Int(maxValue), by: 1)).map(Double.init)
        }
        // stepValue == 0.5：对 min/max 乘以 2 后用整数 stride，再映射回 Double
        let from = Int(minValue * 2)
        let through = Int(maxValue * 2)
        return Array(stride(from: from, through: through, by: 1)).map { Double($0) * 0.5 }
    }

    /// 将未设置的初始值（0）对齐到滚轮最小值，确保 selection 绑定始终在可选范围内
    private var safeInitialValue: Double {
        currentValue > 0 ? currentValue : minValue
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶栏
            HStack {
                Button("取消") { dismiss() }
                    .font(.app(size: 15))
                    .foregroundColor(CardTokens.Color.foregroundMuted)
                Spacer()
                Text(titleText)
                    .font(.app(size: 16, weight: .semibold))
                    .foregroundColor(CardTokens.Color.foreground)
                Spacer()
                Button("完成") {
                    apply(value)
                    dismiss()
                }
                .font(.app(size: 15, weight: .semibold))
                .foregroundColor(CardTokens.Color.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // 滚轮选择
            Picker(selection: $value, label: Text(titleText)) {
                ForEach(pickerValues, id: \.self) { v in
                    Text(String(format: stepValue >= 1 ? "%.0f" : "%.1f", v))
                        .font(.app(size: 18))
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)

            Text(unitText)
                .font(.app(size: 13))
                .foregroundColor(CardTokens.Color.foregroundSubtle)
                .padding(.bottom, 20)
        }
        .background(CardTokens.Color.background.ignoresSafeArea())
        .onAppear { value = safeInitialValue }
    }
}

// MARK: - 本地卡片样式（与 PK 风格一致）

extension View {
    func profileCard(padding: CGFloat = 16) -> some View {
        self
            .padding(.all, padding)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            )
    }
}
