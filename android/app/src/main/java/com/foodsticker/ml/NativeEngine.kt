package com.foodsticker.ml

import android.content.res.AssetManager
import android.graphics.Bitmap

/** NCNN 原生推理引擎 JNI 封装（MobileSAM / AnimeGANv3 / EfficientNet-Lite4，FP16+Vulkan） */
object NativeEngine {
    init { System.loadLibrary("native_engine") }

    /** 加载全部模型，App启动时调用一次（建议在Splash预热） */
    external fun init(assetManager: AssetManager): Boolean

    external fun hasGpu(): Boolean

    /**
     * MobileSAM 抠图
     * @param bitmap 已等比缩放+左上pad到 size×size 的RGBA图
     * @return size×size 的 Alpha 字节数组（0/255），由 StickerComposer 做模糊+膨胀
     */
    external fun segment(bitmap: Bitmap, size: Int, contentW: Int, contentH: Int): ByteArray

    /** AnimeGANv3 风格化：inBitmap(白底主体 size²) → outBitmap(卡通RGB，同尺寸，需预建) */
    external fun cartoonize(inBitmap: Bitmap, outBitmap: Bitmap, size: Int)

    /** EfficientNet-Lite4 分类：300²输入 → [classId, confidence] */
    external fun classify(bitmap: Bitmap): FloatArray
}
