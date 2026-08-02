import UIKit
import Photos

/// 贴纸详情页：展示 AI 生成的食物贴纸 + 营养信息。
///
/// 布局（从上到下）：
/// - 贴纸大图（居中，带透明背景棋盘格）
/// - 食物名称（可编辑，输入后点「重新分析」用 AI 重新算热量/营养）
/// - 日期
/// - 热量卡片（大卡数）
/// - 营养成分列表
/// - 贴士卡片
/// - 底部按钮栏：关闭 / 保存 / 保存并加入预设
///
/// 通过 `update(with:nutrition:error:)` 在最终任务完成后动态刷新。
final class FoodStickerResultViewController: UIViewController {

    // MARK: - 数据
    private let original: UIImage
    private let previewSticker: UIImage
    private let taskID: Int?
    private let createdAt: Date
    private var finalSticker: UIImage?
    private var nutrition: FoodNutritionModel?

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    // 贴纸大图
    private let stickerIV = UIImageView()
    private let aiBadge = UILabel()

    // 名称（可编辑）+ 重新分析按钮
    private let nameField = UITextField()
    private let reanalyzeBtn = UIButton(type: .system)
    private let nameRow = UIStackView()

    private let dateLabel = UILabel()

    // 热量
    private let caloriesCard = UIView()
    private let caloriesValue = UILabel()
    private let caloriesUnit = UILabel()

    // 营养成分
    private let nutritionTitle = UILabel()
    private let nutritionStack = UIStackView()
    private let proteinLabel = UILabel()
    private let fatLabel = UILabel()
    private let carbLabel = UILabel()
    private let fiberLabel = UILabel()
    private let sodiumLabel = UILabel()

    // 贴士
    private let tipsCard = UIView()
    private let tipsLabel = UILabel()

    // 底部按钮
    private let buttonBar = UIStackView()
    private let closeBtn = UIButton(type: .system)
    private let deleteBtn = UIButton(type: .system)
    private let saveBtn = UIButton(type: .system)
    private let savePresetBtn = UIButton(type: .system)
    private var pendingPresetSave = false

    // 状态
    private let statusLabel = UILabel()
    private var isAnalyzing = false

    // 缓存 view 加载前收到的更新数据
    private var pendingSticker: UIImage?
    private var pendingNutrition: FoodNutritionModel?
    private var pendingError: Error?

    init(previewSticker: UIImage, original: UIImage, taskID: Int? = nil, createdAt: Date = Date()) {
        self.previewSticker = previewSticker
        self.original = original
        self.taskID = taskID
        self.createdAt = createdAt
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "食物贴纸"
        setupUI()
        renderPreview()
        // 应用 view 加载前缓存的更新数据
        if pendingSticker != nil || pendingNutrition != nil {
            update(with: pendingSticker, nutrition: pendingNutrition, error: pendingError)
        }
    }

    // MARK: - UI 构建

    private func setupUI() {
        view.backgroundColor = UIColor(hex: 0xF8F8F8)

        // ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Stack（统一左右 24 边距，卡片铺满）
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48)
        ])

        // ---- 贴纸大图（圆角卡片） ----
        let stickerCard = makeCard(cornerRadius: 28)
        stickerCard.backgroundColor = UIColor(hex: 0xF2F2F2)
        stickerCard.heightAnchor.constraint(equalToConstant: 300).isActive = true

        stickerIV.contentMode = .scaleAspectFit
        stickerIV.translatesAutoresizingMaskIntoConstraints = false
        stickerCard.addSubview(stickerIV)
        NSLayoutConstraint.activate([
            stickerIV.leadingAnchor.constraint(equalTo: stickerCard.leadingAnchor, constant: 24),
            stickerIV.trailingAnchor.constraint(equalTo: stickerCard.trailingAnchor, constant: -24),
            stickerIV.topAnchor.constraint(equalTo: stickerCard.topAnchor, constant: 24),
            stickerIV.bottomAnchor.constraint(equalTo: stickerCard.bottomAnchor, constant: -24)
        ])

        aiBadge.text = "AI生成"
        aiBadge.font = .systemFont(ofSize: 11, weight: .semibold)
        aiBadge.textColor = .white
        aiBadge.backgroundColor = UIColor(hex: 0x10B981)
        aiBadge.layer.cornerRadius = 10
        aiBadge.clipsToBounds = true
        aiBadge.textAlignment = .center
        aiBadge.translatesAutoresizingMaskIntoConstraints = false
        aiBadge.widthAnchor.constraint(equalToConstant: 56).isActive = true
        aiBadge.heightAnchor.constraint(equalToConstant: 22).isActive = true
        stickerCard.addSubview(aiBadge)
        NSLayoutConstraint.activate([
            aiBadge.trailingAnchor.constraint(equalTo: stickerCard.trailingAnchor, constant: -14),
            aiBadge.bottomAnchor.constraint(equalTo: stickerCard.bottomAnchor, constant: -14)
        ])

        // ---- 名称（可编辑）+ 重新分析 ----
        nameField.font = .systemFont(ofSize: 22, weight: .bold)
        nameField.textColor = UIColor(hex: 0x1A1A1A)
        nameField.textAlignment = .center
        nameField.borderStyle = .none
        nameField.placeholder = "识别中…"
        nameField.returnKeyType = .done
        nameField.clearButtonMode = .whileEditing
        nameField.delegate = self

        styleButton(reanalyzeBtn, title: "重新分析", bg: UIColor(hex: 0x10B981), fg: .white, corner: 20)
        reanalyzeBtn.widthAnchor.constraint(equalToConstant: 120).isActive = true
        reanalyzeBtn.addTarget(self, action: #selector(reanalyzeTapped), for: .touchUpInside)

        nameRow.axis = .vertical
        nameRow.spacing = 12
        nameRow.alignment = .center
        nameRow.translatesAutoresizingMaskIntoConstraints = false
        nameRow.addArrangedSubview(nameField)
        nameRow.addArrangedSubview(reanalyzeBtn)

        let nameCard = makeCard()
        nameCard.addSubview(nameRow)
        NSLayoutConstraint.activate([
            nameRow.topAnchor.constraint(equalTo: nameCard.topAnchor, constant: 18),
            nameRow.leadingAnchor.constraint(equalTo: nameCard.leadingAnchor, constant: 16),
            nameRow.trailingAnchor.constraint(equalTo: nameCard.trailingAnchor, constant: -16),
            nameRow.bottomAnchor.constraint(equalTo: nameCard.bottomAnchor, constant: -18)
        ])

        // ---- 日期时间 ----
        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = UIColor(hex: 0x999999)
        dateLabel.textAlignment = .center
        let df = DateFormatter()
        df.dateFormat = "yyyy年M月d日 HH:mm"
        dateLabel.text = df.string(from: createdAt)

        // ---- 热量卡片（白卡 + 绿色大数字） ----
        caloriesCard.backgroundColor = .white
        caloriesCard.layer.cornerRadius = 16
        caloriesCard.layer.shadowColor = UIColor.black.cgColor
        caloriesCard.layer.shadowOpacity = 0.04
        caloriesCard.layer.shadowRadius = 8
        caloriesCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        caloriesCard.heightAnchor.constraint(equalToConstant: 96).isActive = true
        let calTitle = UILabel()
        calTitle.text = "热量"
        calTitle.font = .systemFont(ofSize: 12)
        calTitle.textColor = UIColor(hex: 0x666666)
        calTitle.textAlignment = .center

        caloriesValue.font = .systemFont(ofSize: 32, weight: .bold)
        caloriesValue.textColor = UIColor(hex: 0x22C55E)
        caloriesValue.textAlignment = .center
        caloriesValue.text = "--"

        caloriesUnit.font = .systemFont(ofSize: 12)
        caloriesUnit.textColor = UIColor(hex: 0x666666)
        caloriesUnit.textAlignment = .center
        caloriesUnit.text = "kcal"

        let calInner = UIStackView(arrangedSubviews: [calTitle, caloriesValue, caloriesUnit])
        calInner.axis = .vertical
        calInner.spacing = 2
        calInner.alignment = .center
        calInner.translatesAutoresizingMaskIntoConstraints = false
        caloriesCard.addSubview(calInner)
        NSLayoutConstraint.activate([
            calInner.centerXAnchor.constraint(equalTo: caloriesCard.centerXAnchor),
            calInner.centerYAnchor.constraint(equalTo: caloriesCard.centerYAnchor)
        ])

        // ---- 营养成分 ----
        nutritionTitle.text = "营养成分"
        nutritionTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        nutritionTitle.textColor = UIColor(hex: 0x1A1A1A)
        nutritionTitle.textAlignment = .left
        nutritionTitle.translatesAutoresizingMaskIntoConstraints = false

        nutritionStack.axis = .vertical
        nutritionStack.spacing = 10
        nutritionStack.alignment = .fill
        nutritionStack.translatesAutoresizingMaskIntoConstraints = false

        let labels = [proteinLabel, fatLabel, carbLabel, fiberLabel, sodiumLabel]
        for l in labels {
            l.font = .systemFont(ofSize: 14)
            l.textColor = UIColor(hex: 0x1A1A1A)
            l.numberOfLines = 1
            nutritionStack.addArrangedSubview(l)
        }
        proteinLabel.text = "蛋白质：-- g"
        fatLabel.text     = "脂肪：-- g"
        carbLabel.text    = "碳水：-- g"
        fiberLabel.text   = "膳食纤维：-- g"
        sodiumLabel.text  = "钠：-- mg"

        let nutCard = makeCard()
        let nutInner = UIStackView(arrangedSubviews: [nutritionTitle, nutritionStack])
        nutInner.axis = .vertical
        nutInner.spacing = 12
        nutInner.alignment = .fill
        nutInner.translatesAutoresizingMaskIntoConstraints = false
        nutCard.addSubview(nutInner)
        NSLayoutConstraint.activate([
            nutInner.topAnchor.constraint(equalTo: nutCard.topAnchor, constant: 16),
            nutInner.leadingAnchor.constraint(equalTo: nutCard.leadingAnchor, constant: 16),
            nutInner.trailingAnchor.constraint(equalTo: nutCard.trailingAnchor, constant: -16),
            nutInner.bottomAnchor.constraint(equalTo: nutCard.bottomAnchor, constant: -16)
        ])

        // ---- 贴士 ----
        let tipIcon = UIImageView(image: UIImage(systemName: "lightbulb.fill"))
        tipIcon.tintColor = UIColor(hex: 0x10B981)
        tipIcon.contentMode = .scaleAspectFit
        tipIcon.translatesAutoresizingMaskIntoConstraints = false
        tipIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        tipIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true

        tipsLabel.font = .systemFont(ofSize: 13)
        tipsLabel.textColor = UIColor(hex: 0x666666)
        tipsLabel.numberOfLines = 0
        tipsLabel.text = "营养识别中，请稍候…"
        tipsLabel.translatesAutoresizingMaskIntoConstraints = false

        tipsCard.backgroundColor = .white
        tipsCard.layer.cornerRadius = 18
        tipsCard.layer.shadowColor = UIColor.black.cgColor
        tipsCard.layer.shadowOpacity = 0.04
        tipsCard.layer.shadowRadius = 8
        tipsCard.layer.shadowOffset = CGSize(width: 0, height: 2)

        let tipRow = UIStackView(arrangedSubviews: [tipIcon, tipsLabel])
        tipRow.axis = .horizontal
        tipRow.spacing = 10
        tipRow.alignment = .top
        tipRow.translatesAutoresizingMaskIntoConstraints = false
        tipsCard.addSubview(tipRow)
        NSLayoutConstraint.activate([
            tipRow.topAnchor.constraint(equalTo: tipsCard.topAnchor, constant: 16),
            tipRow.leadingAnchor.constraint(equalTo: tipsCard.leadingAnchor, constant: 16),
            tipRow.trailingAnchor.constraint(equalTo: tipsCard.trailingAnchor, constant: -16),
            tipRow.bottomAnchor.constraint(equalTo: tipsCard.bottomAnchor, constant: -16)
        ])

        // ---- 底部按钮 ----
        buttonBar.axis = .horizontal
        buttonBar.spacing = 8
        buttonBar.distribution = .fillEqually
        buttonBar.translatesAutoresizingMaskIntoConstraints = false
        buttonBar.heightAnchor.constraint(equalToConstant: 48).isActive = true

        styleButton(closeBtn, title: "关闭", bg: UIColor(hex: 0xF2F2F2), fg: UIColor(hex: 0x1A1A1A), corner: 12)
        styleButton(deleteBtn, title: "删除", bg: UIColor(hex: 0xEF4444).withAlphaComponent(0.10), fg: UIColor(hex: 0xEF4444), corner: 12)
        styleButton(saveBtn, title: "保存", bg: UIColor(hex: 0x10B981), fg: .white, corner: 12)
        styleButton(savePresetBtn, title: "保存并预设", bg: UIColor(hex: 0x059669), fg: .white, corner: 12)

        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        deleteBtn.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        saveBtn.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        savePresetBtn.addTarget(self, action: #selector(savePresetTapped), for: .touchUpInside)

        buttonBar.addArrangedSubview(closeBtn)
        buttonBar.addArrangedSubview(deleteBtn)
        buttonBar.addArrangedSubview(saveBtn)
        buttonBar.addArrangedSubview(savePresetBtn)

        // ---- 状态 ----
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = UIColor(hex: 0x999999)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        // ---- 组装 ----
        stack.addArrangedSubview(stickerCard)
        stack.addArrangedSubview(nameCard)
        stack.addArrangedSubview(dateLabel)
        stack.addArrangedSubview(caloriesCard)
        stack.addArrangedSubview(nutCard)
        stack.addArrangedSubview(tipsCard)
        stack.addArrangedSubview(buttonBar)
        stack.addArrangedSubview(statusLabel)
    }

    // 统一白卡：圆角 + 柔和阴影（对齐 CardTokens 视觉）
    private func makeCard(cornerRadius: CGFloat = 16) -> UIView {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = cornerRadius
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.04
        v.layer.shadowRadius = 8
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func styleButton(_ btn: UIButton, title: String, bg: UIColor, fg: UIColor, corner: CGFloat = 10) {
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(fg, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        btn.titleLabel?.minimumScaleFactor = 0.7
        btn.backgroundColor = bg
        btn.layer.cornerRadius = corner
        btn.clipsToBounds = true
    }

    private func renderPreview() {
        stickerIV.image = previewSticker
    }

    // MARK: - 动态更新

    func update(with sticker: UIImage?, nutrition: FoodNutritionModel?, error: Error?) {
        // view 未加载时缓存数据，待 viewDidLoad 后统一应用
        guard isViewLoaded else {
            pendingSticker = sticker ?? pendingSticker
            pendingNutrition = nutrition ?? pendingNutrition
            pendingError = error ?? pendingError
            return
        }
        DispatchQueue.main.async {
            if let s = sticker {
                self.finalSticker = s
                self.stickerIV.image = s
            }
            if let n = nutrition {
                self.nutrition = n
                self.nameField.text = n.foodName
                self.caloriesValue.text = String(format: "%.0f", n.calories)
                self.proteinLabel.text = "蛋白质：\(String(format: "%.1f", n.protein)) g"
                self.fatLabel.text     = "脂肪：\(String(format: "%.1f", n.fat)) g"
                self.carbLabel.text    = "碳水：\(String(format: "%.1f", n.carbohydrate)) g"
                self.fiberLabel.text   = "膳食纤维：\(String(format: "%.1f", n.dietaryFiber)) g"
                self.sodiumLabel.text  = "钠：\(String(format: "%.0f", n.sodium)) mg"
                self.tipsLabel.text = "贴士：\(n.vitaminTips)"
                self.setAnalyzing(false)
                self.statusLabel.text = "营养识别完成"
            } else if let e = error {
                self.nameField.text = "识别失败"
                self.tipsLabel.text = "营养识别失败：\(e.localizedDescription)"
                self.setAnalyzing(false)
                self.statusLabel.text = "识别失败"
            }
        }
    }

    // MARK: - 重新分析（按名称）

    @objc private func reanalyzeTapped() {
        nameField.resignFirstResponder()
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty, !isAnalyzing else { return }
        setAnalyzing(true)
        statusLabel.text = "正在根据「\(name)」重新分析…"
        FoodNutritionService.shared.analyzeByName(name) { [weak self] model, error in
            guard let self else { return }
            if let m = model {
                self.nutrition = m
                DispatchQueue.main.async {
                    self.nameField.text = m.foodName
                    self.caloriesValue.text = String(format: "%.0f", m.calories)
                    self.proteinLabel.text = "蛋白质：\(String(format: "%.1f", m.protein)) g"
                    self.fatLabel.text     = "脂肪：\(String(format: "%.1f", m.fat)) g"
                    self.carbLabel.text    = "碳水：\(String(format: "%.1f", m.carbohydrate)) g"
                    self.fiberLabel.text   = "膳食纤维：\(String(format: "%.1f", m.dietaryFiber)) g"
                    self.sodiumLabel.text  = "钠：\(String(format: "%.0f", m.sodium)) mg"
                    self.tipsLabel.text = "贴士：\(m.vitaminTips)"
                    self.setAnalyzing(false)
                    self.statusLabel.text = "已根据「\(m.foodName)」更新营养"
                }
            } else {
                DispatchQueue.main.async {
                    self.setAnalyzing(false)
                    self.statusLabel.text = "重新分析失败：\(error?.localizedDescription ?? "未知错误")"
                }
            }
        }
    }

    private func setAnalyzing(_ v: Bool) {
        isAnalyzing = v
        reanalyzeBtn.isEnabled = !v
        reanalyzeBtn.alpha = v ? 0.5 : 1
        reanalyzeBtn.setTitle(v ? "分析中…" : "重新分析", for: .normal)
    }

    // MARK: - 按钮事件

    @objc private func closeTapped() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func deleteTapped() {
        if let id = taskID {
            CaptureStore.shared.remove(id)
        }
        statusLabel.text = "已删除该记录"
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func saveTapped() {
        commitSave(preset: false)
    }

    @objc private func savePresetTapped() {
        commitSave(preset: true)
    }

    /// 保存逻辑：
    /// - 写入「今日记录 / 胃袋」(AppDataStore.addRecord)，底部 Tab 的 viewWillAppear 会自动刷新
    /// - 仅「保存并预设」额外写入「我的预设」(addSavedSticker)
    /// - 保存成功后自动返回上一页，确保用户立即在今日记录/大胃袋看到数据
    private func commitSave(preset: Bool) {
        guard let n = nutrition else {
            statusLabel.text = "营养信息尚未就绪，请稍候…"
            return
        }
        let edited = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = edited.isEmpty ? n.foodName : edited
        let cal = Int(round(n.calories))

        // 1) 写入今日记录 / 胃袋（本地持久化，离线也可留存）
        AppDataStore.shared.addRecord(DailyRecord(
            type: .food,
            name: finalName,
            calories: cal,
            amount: 100))

        // 2) 仅「保存并预设」才进入预设列表，避免「保存」误存到预设
        if preset {
            if let sticker = buildFoodSticker() {
                AppDataStore.shared.addSavedSticker(sticker)
            }
        }

        // 3) 反馈并自动返回
        statusLabel.text = preset ? "已保存并加入预设 ✓" : "已保存到今日贴纸与胃袋 ✓"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self else { return }
            if let nav = self.navigationController {
                nav.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        }
    }

    // 用当前营养/名称构造 FoodSticker 写入预设（图片以空 imageName 占位，仅保留营养数据）
    private func buildFoodSticker() -> FoodSticker? {
        guard let n = nutrition else { return nil }
        let edited = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = edited.isEmpty ? n.foodName : edited
        return FoodSticker(imageName: "",
                           name: finalName,
                           cal: Int(n.calories),
                           date: todayDateString(),
                           time: nowTimeString(),
                           protein: Int(n.protein),
                           carbs: Int(n.carbohydrate),
                           fat: Int(n.fat),
                           fiber: Int(n.dietaryFiber),
                           sugar: 0,
                           salt: n.sodium / 1000.0,
                           tip: n.vitaminTips)
    }

    private func todayDateString() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date())
    }
    private func nowTimeString() -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: Date())
    }
}

// MARK: - UITextFieldDelegate（回车即重新分析）
extension FoodStickerResultViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        reanalyzeTapped()
        return true
    }
}

// MARK: - UIColor Hex 辅助（对齐 CardTokens 色值）
fileprivate extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8) & 0xFF) / 255
        let b = CGFloat(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
