import UIKit
import SwiftUI

// MARK: - 个人中心

final class ProfileViewController: UIViewController {

    private let store = AppDataStore.shared
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        setupScrollView()
        setupHeader()
        setupWeightProgress()
        setupMenu()
    }

    private func setupScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        stack.axis = .vertical
        stack.spacing = 16
        scrollView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    private func setupHeader() {
        let card = makeCard()
        card.translatesAutoresizingMaskIntoConstraints = false

        let avatar = UILabel()
        avatar.text = store.profile.avatar
        avatar.font = AppFont.ui(size: 44)
        avatar.textAlignment = .center

        let nameLabel = UILabel()
        nameLabel.text = store.profile.name
        nameLabel.font = AppFont.ui(size: 20, weight: .bold)
        nameLabel.textAlignment = .center

        let stats = UILabel()
        stats.text = "减脂第 \(store.profile.days)天 · BMI \(String(format: "%.1f", store.profile.bmi))"
        stats.font = AppFont.ui(size: 12)
        stats.textColor = .secondaryLabel
        stats.textAlignment = .center

        let vStack = UIStackView(arrangedSubviews: [avatar, nameLabel, stats])
        vStack.axis = .vertical
        vStack.spacing = 8
        vStack.alignment = .center
        vStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vStack)

        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            vStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
            vStack.centerXAnchor.constraint(equalTo: card.centerXAnchor)
        ])
        stack.addArrangedSubview(card)
    }

    private func setupWeightProgress() {
        let card = makeCard()
        card.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = "📉 减重进度"
        title.font = AppFont.ui(size: 14, weight: .semibold)

        let startW = 76.0; let current = store.profile.currentWeight; let target = store.profile.targetWeight
        let total = startW - target
        let lost = store.profile.weightLost
        let ratio = min(1.0, lost / total)

        let detail = UILabel()
        detail.text = "已减 \(String(format: "%.1f", lost)) kg (\(Int(ratio * 100))%) · \(String(format: "%.1f", max(0, current - target))) kg 剩余"
        detail.font = AppFont.ui(size: 12)
        detail.textColor = .secondaryLabel

        let barBg = UIView(); barBg.backgroundColor = UIColor(white: 0.9, alpha: 1); barBg.layer.cornerRadius = 6
        let barFill = UIView(); barFill.backgroundColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0); barFill.layer.cornerRadius = 6
        barBg.addSubview(barFill)

        for v in [title, detail, barBg] {
            v.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(v)
        }
        barFill.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            detail.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
            detail.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            barBg.topAnchor.constraint(equalTo: detail.bottomAnchor, constant: 10),
            barBg.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            barBg.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            barBg.heightAnchor.constraint(equalToConstant: 12),
            barBg.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),

            barFill.topAnchor.constraint(equalTo: barBg.topAnchor),
            barFill.leadingAnchor.constraint(equalTo: barBg.leadingAnchor),
            barFill.bottomAnchor.constraint(equalTo: barBg.bottomAnchor),
            barFill.widthAnchor.constraint(equalTo: barBg.widthAnchor, multiplier: CGFloat(ratio))
        ])
        stack.addArrangedSubview(card)
    }

    private func setupMenu() {
        let card = makeCard()
        let items: [(String, String)] = [
            ("🎯", "减脂目标"),
            ("📊", "体重趋势"),
            ("🏆", "成就徽章"),
            ("🏋️", "运动计划"),
            ("⏰", "提醒设置"),
            ("⚙️", "账户设置"),
            ("❓", "帮助与反馈"),
        ]

        let menuStack = UIStackView()
        menuStack.axis = .vertical
        menuStack.spacing = 0
        menuStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(menuStack)

        NSLayoutConstraint.activate([
            menuStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            menuStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
            menuStack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            menuStack.trailingAnchor.constraint(equalTo: card.trailingAnchor)
        ])

        for (i, item) in items.enumerated() {
            let row = makeMenuRow(emoji: item.0, title: item.1)
            menuStack.addArrangedSubview(row)
            if i < items.count - 1 {
                let sep = UIView(); sep.backgroundColor = UIColor(white: 0.9, alpha: 1)
                sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                menuStack.addArrangedSubview(sep)
            }
        }
        stack.addArrangedSubview(card)
    }

    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.withAlphaComponent(0.04).cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 8
        v.layer.shadowOpacity = 1
        return v
    }

    private func makeMenuRow(emoji: String, title: String) -> UIView {
        let row = UIView()
        let emojiLabel = UILabel(); emojiLabel.text = emoji; emojiLabel.font = AppFont.ui(size: 18)
        let titleLabel = UILabel(); titleLabel.text = title; titleLabel.font = AppFont.ui(size: 15)
        let arrow = UILabel(); arrow.text = "›"; arrow.font = AppFont.ui(size: 18); arrow.textColor = .tertiaryLabel

        for v in [emojiLabel, titleLabel, arrow] {
            v.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(v)
        }
        NSLayoutConstraint.activate([
            emojiLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            emojiLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            arrow.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            arrow.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            row.heightAnchor.constraint(equalToConstant: 44)
        ])
        return row
    }
}
