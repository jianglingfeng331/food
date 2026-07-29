import UIKit
import AVFoundation
import PhotosUI

/// 示例业务流程页：实时抠图 + iOS Emoji 风格 3D 贴纸生成。
///
/// 完整演示链路：
/// 开启相机预览 → 显示黄色 ROI 选框 → 点击「生成贴纸」→ 高清抠图 → 生成贴纸 → 结果展示 / 保存到相册。
///
/// 集成说明：
/// - `RealTimeSegmentationEngine` 提供实时预览抠图回调与高清抓拍抠图接口；
/// - `StickerRenderer` 将前景合成为 1024×1024 的 iOS Emoji 白底贴纸；
/// - `StickerAIService` 负责（可选）AI 风格化，默认 stub 模式直接返回原图。
final class StickerFlowViewController: UIViewController {

    // MARK: - 相机
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let captureQueue = DispatchQueue(label: "foodsticker.flow.capture")
    private var isSegmenting = false

    // MARK: - UI
    private let previewContainer = UIView()
    private let roiView = ROIView()              // 黄色 ROI 选框
    private let livePreview = UIImageView()      // 实时抠图预览（右上角小窗）
    private let resultView = UIImageView()       // 最终结果
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let closeBtn = UIButton(type: .system)
    private let albumBtn = UIButton(type: .system)
    private let generateBtn = UIButton(type: .system)
    private let saveBtn = UIButton(type: .system)

    // MARK: - 引擎
    private let engine = RealTimeSegmentationEngine()
    private var aiService = StickerAIService()
    private var currentForeground: UIImage?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewContainer.bounds
        // ROI 初始居中
        if roiView.frame == .zero {
            let side = min(previewContainer.bounds.width, previewContainer.bounds.height) * 0.6
            roiView.frame = CGRect(x: (previewContainer.bounds.width - side) / 2,
                                   y: (previewContainer.bounds.height - side) / 2,
                                   width: side, height: side)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }

    // MARK: - UI 搭建
    private func setupUI() {
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewContainer)

        roiView.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.addSubview(roiView)

        livePreview.contentMode = .scaleAspectFit
        livePreview.layer.borderColor = UIColor.systemYellow.cgColor
        livePreview.layer.borderWidth = 1
        livePreview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(livePreview)

        resultView.contentMode = .scaleAspectFit
        resultView.isHidden = true
        resultView.layer.cornerRadius = 16
        resultView.clipsToBounds = true
        resultView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultView)

        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        spinner.color = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)

        closeBtn.setTitle("✕", for: .normal)
        closeBtn.setTitleColor(.white, for: .normal)
        closeBtn.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        closeBtn.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        closeBtn.layer.cornerRadius = 22
        closeBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeBtn)

        albumBtn.setTitle("相册", for: .normal)
        albumBtn.setTitleColor(.white, for: .normal)
        albumBtn.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        albumBtn.layer.cornerRadius = 22
        albumBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        albumBtn.addTarget(self, action: #selector(openAlbum), for: .touchUpInside)
        albumBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(albumBtn)

        generateBtn.setTitle("生成贴纸", for: .normal)
        generateBtn.setTitleColor(.white, for: .normal)
        generateBtn.backgroundColor = UIColor(red: 0.063, green: 0.725, blue: 0.506, alpha: 1) // #10B981
        generateBtn.layer.cornerRadius = 24
        generateBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        generateBtn.addTarget(self, action: #selector(generate), for: .touchUpInside)
        generateBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(generateBtn)

        saveBtn.setTitle("保存到相册", for: .normal)
        saveBtn.setTitleColor(.white, for: .normal)
        saveBtn.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        saveBtn.layer.cornerRadius = 24
        saveBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        saveBtn.addTarget(self, action: #selector(save), for: .touchUpInside)
        saveBtn.isHidden = true
        saveBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveBtn)

        NSLayoutConstraint.activate([
            previewContainer.topAnchor.constraint(equalTo: view.topAnchor),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeBtn.widthAnchor.constraint(equalToConstant: 44),
            closeBtn.heightAnchor.constraint(equalToConstant: 44),

            albumBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            albumBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            albumBtn.widthAnchor.constraint(equalToConstant: 56),
            albumBtn.heightAnchor.constraint(equalToConstant: 44),

            livePreview.topAnchor.constraint(equalTo: albumBtn.bottomAnchor, constant: 12),
            livePreview.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            livePreview.widthAnchor.constraint(equalToConstant: 110),
            livePreview.heightAnchor.constraint(equalToConstant: 110),

            saveBtn.bottomAnchor.constraint(equalTo: generateBtn.topAnchor, constant: -12),
            saveBtn.leadingAnchor.constraint(equalTo: generateBtn.leadingAnchor),
            saveBtn.trailingAnchor.constraint(equalTo: generateBtn.trailingAnchor),
            saveBtn.heightAnchor.constraint(equalToConstant: 48),

            generateBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            generateBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            generateBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            generateBtn.heightAnchor.constraint(equalToConstant: 48),

            statusLabel.bottomAnchor.constraint(equalTo: saveBtn.topAnchor, constant: -16),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            resultView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            resultView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            resultView.heightAnchor.constraint(equalTo: resultView.widthAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - 相机搭建
    private func setupCamera() {
        #if targetEnvironment(simulator)
        setStatus("模拟器无摄像头：点「相册」选择照片体验完整流程")
        return
        #else
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input),
              session.canAddOutput(photoOutput),
              session.canAddOutput(videoOutput) else {
            setStatus("无法访问摄像头")
            return
        }
        session.addInput(input)
        session.addOutput(photoOutput)
        session.addOutput(videoOutput)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if let conn = videoOutput.connection(with: .video) {
            conn.videoOrientation = .portrait
        }
        videoOutput.setSampleBufferDelegate(self, queue: captureQueue)

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        previewContainer.layer.insertSublayer(layer, at: 0)
        previewLayer = layer

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    granted ? self?.startSession() : self?.setStatus("请在设置中允许相机权限")
                }
            }
        default:
            setStatus("请在设置中允许相机权限")
        }
        #endif
    }

    private func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    // MARK: - 实时预览抠图回调（演示 engine.segmentPreviewFrame）

    private func normalizedROI() -> CGRect? {
        let b = previewContainer.bounds
        guard !b.isEmpty else { return nil }
        let f = roiView.frame
        return CGRect(x: f.minX / b.width, y: f.minY / b.height,
                      width: f.width / b.width, height: f.height / b.height)
    }

    // MARK: - 生成 / 处理
    @objc private func generate() {
        #if targetEnvironment(simulator)
        openAlbum()
        return
        #endif
        setStatus("高清抠图中…")
        spinner.startAnimating()
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    /// 统一处理：原图 → 高清抠图 → 渲染贴纸 → AI 风格化 → 展示。
    private func process(image: UIImage) {
        setStatus("抠图中…")
        spinner.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            self.engine.roi = self.normalizedROI()
            guard let fg = self.engine.segmentStill(image: image.upright()) else {
                DispatchQueue.main.async {
                    self.spinner.stopAnimating()
                    self.setStatus("抠图失败，请调整选框或重试")
                }
                return
            }
            let sticker = StickerRenderer.render(fg, style: .emojiWhite)
            self.aiService.fidelity = 0.9
            self.aiService.generate(foreground: sticker) { result in
                DispatchQueue.main.async {
                    self.spinner.stopAnimating()
                    switch result {
                    case .success(let out):
                        self.currentForeground = out
                        self.resultView.image = out
                        self.resultView.isHidden = false
                        self.saveBtn.isHidden = false
                        self.setStatus("贴纸生成完成，可保存到相册")
                    case .failure(let e):
                        self.setStatus("生成失败：\(e.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - 相册
    @objc private func openAlbum() {
        var cfg = PHPickerConfiguration()
        cfg.filter = .images
        cfg.selectionLimit = 1
        let picker = PHPickerViewController(configuration: cfg)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - 保存 / 关闭
    @objc private func save() {
        guard let img = currentForeground else { return }
        UIImageWriteToSavedPhotosAlbum(img, self, #selector(saveDone(_:didFinish:ctx:)), nil)
    }

    @objc private func saveDone(_ image: UIImage, didFinish saving: Bool, ctx: UnsafeRawPointer?) {
        setStatus(saving ? "已保存到相册" : "保存失败")
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    private func setStatus(_ text: String) {
        statusLabel.text = text
    }
}

// MARK: - AVCapturePhotoCaptureDelegate（高清抓拍）

extension StickerFlowViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        spinner.stopAnimating()
        guard let data = photo.fileDataRepresentation(), let img = UIImage(data: data) else {
            setStatus("拍照失败，请重试")
            return
        }
        process(image: img)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate（实时预览抠图）

extension StickerFlowViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard !isSegmenting else { return }
        isSegmenting = true
        engine.roi = normalizedROI()
        engine.segmentPreviewFrame(sampleBuffer, maxSide: 384) { [weak self] img in
            self?.livePreview.image = img
            self?.isSegmenting = false
        }
    }
}

// MARK: - PHPickerViewControllerDelegate（相册选图）

extension StickerFlowViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        results.first?.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
            guard let img = obj as? UIImage else { return }
            DispatchQueue.main.async { self?.process(image: img) }
        }
    }
}

// MARK: - 黄色 ROI 选框（可拖动 / 捏合缩放）

/// 黄色 ROI 选框：支持单指拖动平移、双指捏合缩放，框内区域即抠图识别区。
final class ROIView: UIView {

    private let dashedLayer = CAShapeLayer()
    private var panStartCenter = CGPoint.zero
    private var pinchStartFrame = CGRect.zero
    private var pinchStartScale: CGFloat = 1

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }

    private func setup() {
        backgroundColor = UIColor.systemYellow.withAlphaComponent(0.12)
        dashedLayer.strokeColor = UIColor.systemYellow.cgColor
        dashedLayer.fillColor = UIColor.clear.cgColor
        dashedLayer.lineWidth = 2
        dashedLayer.lineDashPattern = [8, 6]
        layer.addSublayer(dashedLayer)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        addGestureRecognizer(pan)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinch(_:)))
        addGestureRecognizer(pinch)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        dashedLayer.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1),
                                        cornerRadius: 8).cgPath
    }

    @objc private func pan(_ g: UIPanGestureRecognizer) {
        guard let sup = superview else { return }
        let t = g.translation(in: sup)
        if g.state == .began { panStartCenter = center }
        var c = panStartCenter
        c.x += t.x; c.y += t.y
        c.x = min(max(c.x, frame.width / 2), sup.bounds.width - frame.width / 2)
        c.y = min(max(c.y, frame.height / 2), sup.bounds.height - frame.height / 2)
        center = c
    }

    @objc private func pinch(_ g: UIPinchGestureRecognizer) {
        guard let sup = superview else { return }
        if g.state == .began { pinchStartFrame = frame; pinchStartScale = g.scale }
        let scale = g.scale / pinchStartScale
        var w = pinchStartFrame.width * scale
        var h = pinchStartFrame.height * scale
        let maxSide = min(sup.bounds.width, sup.bounds.height) * 0.95
        w = min(max(w, 80), maxSide)
        h = min(max(h, 80), maxSide)
        frame = CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)
    }
}

// MARK: - UIImage 方向修正（拍照结果常带旋转，抠图前转正）

extension UIImage {
    func upright() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result ?? self
    }
}
