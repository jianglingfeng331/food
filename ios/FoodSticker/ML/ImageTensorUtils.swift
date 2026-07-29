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
    func toAlphaCGImage(width: Int, height: Int, threshold: Float) -> CGImage {
        let ptr = dataPointer.bindMemory(to: Float.self, capacity: width * height)
        var bytes = [UInt8](repeating: 0, count: width * height)
        for i in 0..<(width * height) { bytes[i] = ptr[i] > threshold ? 255 : 0 }
        let data = CFDataCreate(nil, bytes, bytes.count)!
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8,
                       bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
                       bitmapInfo: [], provider: CGDataProvider(data: data)!,
                       decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
    }

    /// AnimeGAN tanh输出 (1,3,H,W) ∈[-1,1] → RGB CGImage
    func tanhToRGBCGImage(width: Int, height: Int) -> CGImage {
        let ptr = dataPointer.bindMemory(to: Float.self, capacity: 3 * width * height)
        let plane = width * height
        var bytes = [UInt8](repeating: 255, count: width * height * 4)
        for i in 0..<plane {
            bytes[i * 4 + 0] = UInt8(max(0, min(255, (ptr[i] + 1) * 127.5)))            // R
            bytes[i * 4 + 1] = UInt8(max(0, min(255, (ptr[plane + i] + 1) * 127.5)))    // G
            bytes[i * 4 + 2] = UInt8(max(0, min(255, (ptr[plane * 2 + i] + 1) * 127.5)))// B
        }
        let data = CFDataCreate(nil, bytes, bytes.count)!
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                       bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                       provider: CGDataProvider(data: data)!,
                       decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
    }
}
