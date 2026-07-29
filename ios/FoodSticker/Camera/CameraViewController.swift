import UIKit
import SwiftUI
import AVFoundation
import PhotosUI

/// 相机采集：拍照 + 相册选图 + 取景框引导
final class CameraViewController: UIViewController {
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var guideLayer = CAShapeLayer()
    private var tipLabel = UILabel()
    private var shutterBtn = UIButton()
    private var albumBtn = UIButton()
    private var noCameraLabel = UILabel()
    var onCapture: ((_ full: UIImage, _ thumb: UIImage) -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        setupCamera()
        setupRouter()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        layoutUI()
    }

    // MARK: - Router

    private func setupRouter() {
        onCapture = { [weak self] full, _ in
            guard let nav = self?.navigationController else { return }
            Router.handleCapture(full, from: nav)
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        // 取景引导虚线框
        guideLayer.strokeColor = UIColor.white.withAlphaComponent(0.9).cgColor
        guideLayer.fillColor = UIColor.clear.cgColor
        guideLayer.lineWidth = 2
        guideLayer.lineDashPattern = [10, 6]
        view.layer.addSublayer(guideLayer)

        // 引导文字
        tipLabel.text = "将食品对准框内中心"
        tipLabel.textColor = .white
        tipLabel.textAlignment = .center
        tipLabel.font = AppFont.ui(size: 14)
        view.addSubview(tipLabel)

        // 快门按钮
        shutterBtn.layer.cornerRadius = 36
        shutterBtn.backgroundColor = .white
        shutterBtn.addTarget(self, action: #selector(capture), for: .touchUpInside)
        view.addSubview(shutterBtn)

        // 相册按钮
        albumBtn.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        albumBtn.tintColor = .white
        albumBtn.addTarget(self, action: #selector(pickFromAlbum), for: .touchUpInside)
        view.addSubview(albumBtn)

        // 模拟器/无摄像头提示
        noCameraLabel.text = "当前设备无摄像头\n请使用相册选取照片"
        noCameraLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        noCameraLabel.textAlignment = .center
        noCameraLabel.font = AppFont.ui(size: 13)
        noCameraLabel.numberOfLines = 0
        noCameraLabel.isHidden = true
        view.addSubview(noCameraLabel)
    }

    private func layoutUI() {
        let w = view.bounds.width
        let h = view.bounds.height

        let side = w * 0.72
        let frame = CGRect(x: (w - side) / 2, y: (h - side) / 2 - 40, width: side, height: side)
        guideLayer.path = UIBezierPath(roundedRect: frame, cornerRadius: 24).cgPath

        tipLabel.frame = CGRect(x: 0, y: frame.maxY + 12, width: w, height: 24)

        shutterBtn.frame = CGRect(x: w / 2 - 36, y: h - 130, width: 72, height: 72)
        albumBtn.frame = CGRect(x: 32, y: h - 118, width: 48, height: 48)

        noCameraLabel.frame = CGRect(x: 40, y: h - 220, width: w - 80, height: 50)
    }

    // MARK: - Camera

    private func setupCamera() {
        #if targetEnvironment(simulator)
            noCameraLabel.isHidden = false
            shutterBtn.isHidden = true
        #else
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input),
              session.canAddOutput(photoOutput) else {
            noCameraLabel.isHidden = false
            shutterBtn.isHidden = true
            return
        }
        session.addInput(input)
        session.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .balanced

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
        #endif
    }

    // MARK: - Actions

    @objc private func capture() {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    @objc private func pickFromAlbum() {
        var cfg = PHPickerConfiguration()
        cfg.filter = .images
        let picker = PHPickerViewController(configuration: cfg)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func emit(_ image: UIImage) {
        let thumb = image.resized(maxSide: 320)
        onCapture?(image, thumb)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let img = UIImage(data: data) else { return }
        emit(img)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension CameraViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        results.first?.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
            guard let img = obj as? UIImage else { return }
            DispatchQueue.main.async { self?.emit(img) }
        }
    }
}
