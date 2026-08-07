import AVFoundation
import UIKit

// MARK: - 二维码扫描器

/// 使用 AVFoundation 实时扫描二维码，带居中绿色取景框。
/// 提供「从相册选图识别」兜底入口（单机演示 / 对方发截图时同样有用）。
final class QRScannerViewController: UIViewController {

    var onScanned: ((String) -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let overlay = UIView()
    private let tipLabel = UILabel()
    private let albumButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupOverlay()
        setupButtons()
        setupTip()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if session.isRunning == false { session.startRunning() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning { session.stopRunning() }
    }

    // MARK: 相机

    private func setupCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera),
              let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            tipLabel.text = "无法访问相机，请使用「从相册选图」或手动输入"
            return
        }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr]

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)
        self.previewLayer = layer
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    private func setupOverlay() {
        overlay.backgroundColor = .clear
        overlay.layer.borderColor = UIColor.systemGreen.cgColor
        overlay.layer.borderWidth = 3
        overlay.layer.cornerRadius = 16
        view.addSubview(overlay)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            overlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            overlay.widthAnchor.constraint(equalToConstant: 240),
            overlay.heightAnchor.constraint(equalToConstant: 240)
        ])
    }

    private func setupTip() {
        tipLabel.text = "将对方二维码放入框内"
        tipLabel.textColor = .white
        tipLabel.textAlignment = .center
        tipLabel.font = .systemFont(ofSize: 14)
        view.addSubview(tipLabel)
        tipLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tipLabel.topAnchor.constraint(equalTo: overlay.bottomAnchor, constant: 16),
            tipLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupButtons() {
        closeButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        albumButton.setTitle("从相册选图识别", for: .normal)
        albumButton.setTitleColor(.systemGreen, for: .normal)
        albumButton.addTarget(self, action: #selector(pickFromAlbum), for: .touchUpInside)
        view.addSubview(albumButton)
        albumButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            albumButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            albumButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    @objc private func pickFromAlbum() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    private func handleResult(_ string: String) {
        guard session.isRunning else { return }
        session.stopRunning()
        dismiss(animated: true) { [weak self] in
            self?.onScanned?(string)
        }
    }
}

// MARK: - 扫描回调

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let string = obj.stringValue else { return }
        handleResult(string)
    }
}

// MARK: - 相册兜底

extension QRScannerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage,
           let text = QRCoder.detect(from: image) {
            handleResult(text)
        } else {
            tipLabel.text = "未识别到二维码，请重试或手动输入"
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
