import UIKit
import SwiftUI
import Combine

// MARK: - 消化精灵（肚子小人动画）

final class StomachViewController: UIViewController {

    private let store = AppDataStore.shared
    private let spriteLabel = UILabel()
    private let statusLabel = UILabel()
    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let detailLabel = UILabel()
    private var animTimer: Timer?
    private var cancellable: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        setupUI()
        // 订阅今日记录变化：保存/删除后即使不切 Tab 也能即时刷新（Tab 切换不触发 viewWillAppear）
        cancellable = store.$todayRecords.sink { [weak self] _ in
            DispatchQueue.main.async { self?.refresh() }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
        startAnimation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        animTimer?.invalidate()
    }

    private func setupUI() {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.layer.shadowRadius = 12
        card.layer.shadowOpacity = 1
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            card.widthAnchor.constraint(equalToConstant: 280),
            card.heightAnchor.constraint(equalToConstant: 320)
        ])

        // 消化精灵 Emoji 动画
        spriteLabel.text = "🫧"
        spriteLabel.font = AppFont.ui(size: 80)
        spriteLabel.textAlignment = .center
        spriteLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(spriteLabel)

        // 状态文字
        statusLabel.text = "正在消化中..."
        statusLabel.font = AppFont.ui(size: 20, weight: .bold)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(statusLabel)

        // 消化进度条
        progressBar.progressTintColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
        progressBar.trackTintColor = UIColor(white: 0.9, alpha: 1)
        progressBar.progress = 0.45
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(progressBar)

        // 详细数据
        detailLabel.numberOfLines = 0
        detailLabel.textAlignment = .center
        detailLabel.font = AppFont.ui(size: 13)
        detailLabel.textColor = .secondaryLabel
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(detailLabel)

        NSLayoutConstraint.activate([
            spriteLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 30),
            spriteLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            statusLabel.topAnchor.constraint(equalTo: spriteLabel.bottomAnchor, constant: 16),
            statusLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            progressBar.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            progressBar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 30),
            progressBar.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -30),

            detailLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 20),
            detailLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            detailLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            detailLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
    }

    private func refresh() {
        let cal = store.todayCaloriesConsumed
        let water = store.todayWaterIntake
        let exercise = store.todayExerciseCalories

        let remaining = max(0, store.calorieTarget - cal)
        let foodCount = store.todayRecords.filter { $0.type == .food }.count

        statusLabel.text = foodCount > 0 ? "🫧 正在消化中..." : "😴 肚子空空"

        let target = store.calorieTarget > 0 ? store.calorieTarget : 2000
        let ratio = min(1.0, Float(cal) / Float(target))
        progressBar.progress = ratio

        detailLabel.text = """
        今日摄入: \(cal) Kcal
        运动消耗: \(exercise) Kcal
        剩余额度: \(remaining) Kcal
        饮水: \(water) / \(store.profile.waterGoal) ml
        """
    }

    private func startAnimation() {
        let emojis = ["🫧", "🫧", "🫧", "🤰", "🫧"]
        var idx = 0
        animTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
            self?.spriteLabel.text = emojis[idx % emojis.count]
            idx += 1
            UIView.animate(withDuration: 0.3) {
                self?.spriteLabel.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            } completion: { _ in
                UIView.animate(withDuration: 0.3) {
                    self?.spriteLabel.transform = .identity
                }
            }
        }
    }
}
