import CoreML
import CoreImage
import VideoToolbox

/// CGImage / MLMultiArray 互转辅助（各推理引擎共用）
extension CGImage {
    /// 缩放绘制到 CVPixelBuffer（左上对齐，余下区域填0 —— SAM 的 pad 约定）
    func resizedPixelBuffer(width: Int, height: Int,
                            contentWidth: Int, contentHeight: Int) throws -> CVPixelBuffer {
        var pb: CVPixelBuffer?
        CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA,
                            [kCVPixelBufferCGImageCompatibilityKey: true] as CFDictionary, &pb)
        guard let buffer = pb else { throw NSError(domain: "pb", code: -1) }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                            width: width, height: height, bitsPerComponent: 8,
                            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue |
                                        CGBitmapInfo.byteOrder32Little.rawValue)!
        // 左上对齐：CG坐标系y翻转后绘制在顶部
        ctx.draw(self, in: CGRect(x: 0, y: height - contentHeight,
                                  width: contentWidth, height: contentHeight))
        return buffer
    }
}

extension MLMultiArray {
    /// SAM mask logits → 灰度Alpha图（>threshold 为前景255）
    /// 兼容 float32 / double 数据类型，避免 bindMemory 因数据类型不匹配导致 EXC_BAD_ACCESS
    func toAlphaCGImage(width: Int, height: Int, threshold: Float) -> CGImage {
        let count = width * height
        var bytes = [UInt8](repeating: 0, count: count)
        // 安全取值：优先 floatValue，回退 doubleValue（CoreML mlprogram 可能输出 Float64）
        let useFloat = (dataType == .float32 || dataType == .float16)
        for i in 0..<count {
            let val: Float
            if useFloat {
                val = self[i].floatValue
            } else {
                val = Float(self[i].doubleValue)
            }
            bytes[i] = val > threshold ? 255 : 0
        }
        let data = CFDataCreate(nil, bytes, bytes.count)!
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8,
                       bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
                       bitmapInfo: [], provider: CGDataProvider(data: data)!,
                       decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
    }

    /// AnimeGAN tanh输出 (1,3,H,W) ∈[-1,1] → RGB CGImage
    /// 注意：CoreML 输出常为 FP16，必须用 subscript.floatValue 取值（与 toAlphaCGImage 一致）。
    /// 若用 bindMemory(to: Float.self) 会把 2 字节半精度当 4 字节单精度读，产生整屏雪花噪点。
    func tanhToRGBCGImage(width: Int, height: Int) -> CGImage {
        let plane = width * height
        var bytes = [UInt8](repeating: 255, count: width * height * 4)
        for i in 0..<plane {
            let r = self[i].floatValue
            let g = self[plane + i].floatValue
            let b = self[plane * 2 + i].floatValue
            bytes[i * 4 + 0] = UInt8(max(0, min(255, (r + 1) * 127.5)))            // R
            bytes[i * 4 + 1] = UInt8(max(0, min(255, (g + 1) * 127.5)))            // G
            bytes[i * 4 + 2] = UInt8(max(0, min(255, (b + 1) * 127.5)))            // B
        }
        let data = CFDataCreate(nil, bytes, bytes.count)!
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                       bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                       provider: CGDataProvider(data: data)!,
                       decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
    }
}
