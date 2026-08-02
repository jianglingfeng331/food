import UIKit
import SwiftUI
import Combine

// MARK: - 健康记录管理页（饮食/运动/饮水/体重 CRUD）

final class RecordViewController: UIViewController {

    private let store = AppDataStore.shared
    private var selectedType: RecordType
    private var cancellable: AnyCancellable?

    init(initialType: RecordType = .food) {
        self.selectedType = initialType
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    private var filteredRecords: [DailyRecord] { store.todayRecords.filter { $0.type == selectedType } }

    private let segControl = UISegmentedControl(items: RecordType.allCases.map { $0.label })
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let addButton = UIButton(type: .system)
    private let emptyLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        setupSegmentedControl()
        setupTableView()
        setupAddButton()
        setupEmptyLabel()
        // 订阅今日记录变化：保存/删除后即使不切 Tab 也能即时刷新（Tab 切换不触发 viewWillAppear）
        cancellable = store.$todayRecords.sink { [weak self] _ in
            DispatchQueue.main.async { self?.reloadData() }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    private func setupSegmentedControl() {
        segControl.selectedSegmentIndex = 0
        segControl.selectedSegmentTintColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
        segControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segControl.addTarget(self, action: #selector(typeChanged), for: .valueChanged)
        view.addSubview(segControl)
        segControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            segControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func setupTableView() {
        tableView.delegate = self; tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segControl.bottomAnchor, constant: 12),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupAddButton() {
        addButton.setTitle("+ 添加记录", for: .normal)
        addButton.titleLabel?.font = AppFont.ui(size: 17, weight: .semibold)
        addButton.backgroundColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = 14
        addButton.addTarget(self, action: #selector(addRecord), for: .touchUpInside)
        view.addSubview(addButton)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            addButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupEmptyLabel() {
        emptyLabel.text = "暂无记录，点击下方添加～"
        emptyLabel.textColor = .tertiaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.font = AppFont.ui(size: 14)
        view.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
    }

    @objc private func typeChanged() {
        selectedType = RecordType.allCases[segControl.selectedSegmentIndex]
        reloadData()
    }

    private func reloadData() {
        tableView.reloadData()
        emptyLabel.isHidden = !filteredRecords.isEmpty
    }

    @objc private func addRecord() { showAddAlert() }

    private func showAddAlert() {
        let alert = UIAlertController(
            title: "添加\(selectedType.label)记录",
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { $0.placeholder = "名称" }

        if selectedType == .weight {
            alert.addTextField { t in t.placeholder = "体重 (kg)"; t.keyboardType = .decimalPad }
        } else if selectedType == .water {
            alert.addTextField { t in t.placeholder = "饮水量 (ml)"; t.keyboardType = .numberPad }
        } else if selectedType == .food {
            alert.addTextField { t in t.placeholder = "热量 (Kcal)"; t.keyboardType = .numberPad }
            alert.addTextField { t in t.placeholder = "份量 (g)"; t.keyboardType = .numberPad }
        } else if selectedType == .exercise {
            alert.addTextField { t in t.placeholder = "时长 (分钟)"; t.keyboardType = .numberPad }
            alert.addTextField { t in t.placeholder = "消耗热量 (Kcal)"; t.keyboardType = .numberPad }
        }

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "添加", style: .default) { [weak self] _ in
            guard let self = self, let fields = alert.textFields else { return }
            let name = fields[0].text ?? "未知"

            switch self.selectedType {
            case .food:
                let cal = Int(fields[1].text ?? "0") ?? 0
                let amount = Double(fields.count > 2 ? fields[2].text ?? "0" : "0") ?? 0
                self.store.addRecord(DailyRecord(type: .food, name: name, calories: cal, amount: amount))
            case .exercise:
                let amount = Double(fields[1].text ?? "0") ?? 0
                let cal = Int(fields.count > 2 ? fields[2].text ?? "0" : "0") ?? 0
                self.store.addRecord(DailyRecord(type: .exercise, name: name, calories: cal, amount: amount))
            case .water:
                let amount = Double(fields[1].text ?? "0") ?? 0
                self.store.addRecord(DailyRecord(type: .water, name: name, calories: 0, amount: amount, unit: "ml"))
            case .weight:
                let amount = Double(fields[1].text ?? "0") ?? 0
                self.store.addRecord(DailyRecord(type: .weight, name: name, calories: 0, amount: amount, unit: "kg"))
            }
            self.reloadData()
        })
        present(alert, animated: true)
    }
}

// MARK: - TableView

extension RecordViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filteredRecords.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let r = filteredRecords[indexPath.row]
        var content = cell.defaultContentConfiguration()
        let emoji: String = {
            switch r.type {
            case .food: return "🍽️"
            case .exercise: return "🏃"
            case .water: return "💧"
            case .weight: return "⚖️"
            }
        }()
        content.text = "\(emoji) \(r.name)"
        content.textProperties.font = AppFont.ui(size: 15)
        var detail = ""
        if r.type == .food { detail = "\(r.calories) Kcal · \(Int(r.amount))\(r.unit)" }
        else if r.type == .exercise { detail = "\(r.calories) Kcal · \(Int(r.amount))\(r.unit)" }
        else if r.type == .water { detail = "\(Int(r.amount)) \(r.unit)" }
        else { detail = "\(String(format: "%.1f", r.amount)) \(r.unit)" }
        content.secondaryText = "\(detail) · \(r.time)"
        content.secondaryTextProperties.font = AppFont.ui(size: 11)
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let del = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, done in
            guard let self = self else { return }
            let id = self.filteredRecords[indexPath.row].id
            self.store.removeRecord(id)
            self.reloadData()
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [del])
    }
}
