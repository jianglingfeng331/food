package com.foodsticker.pipeline

import android.app.ActivityManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import com.foodsticker.cloud.CloudApi
import com.foodsticker.ml.NativeEngine
import com.foodsticker.nutrition.FoodInfo
import com.foodsticker.nutrition.NutritionDb
import com.foodsticker.sticker.StickerComposer
import kotlinx.coroutines.*

enum class DeviceTier { HIGH, MID, LOW }

data class PipelineResult(
    val sticker: Bitmap,        // 透明底贴纸（黑内轮廓+白外描边）
    val alphaPng: ByteArray,    // 原始Alpha（云端高清导出复用）
    val food: FoodInfo?,
    val usedCloud: Boolean,
)

/** 端侧主流水线：分类并行 + (SAM→AnimeGAN→合成)串行，中高端机 ≤1s */
class StickerPipeline(private val context: Context) {
    private val tier: DeviceTier = detectTier(context)
    private val samSize = if (tier == DeviceTier.LOW) 512 else 1024
    private val ganSize = if (tier == DeviceTier.LOW) 384 else 512
    private val maxSide = if (tier == DeviceTier.LOW) 1080 else 2048
    private val db = NutritionDb(context)

    companion object {
        const val CONFIDENCE_THRESHOLD = 0.85f

        fun detectTier(ctx: Context): DeviceTier {
            val am = ctx.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val mem = ActivityManager.MemoryInfo().also { am.getMemoryInfo(it) }
            val gb = mem.totalMem / (1L shl 30)
            return when {
                gb >= 6 && NativeEngine.hasGpu() -> DeviceTier.HIGH
                NativeEngine.hasGpu() -> DeviceTier.MID
                else -> DeviceTier.LOW
            }
        }
    }

    suspend fun process(original: Bitmap): PipelineResult = coroutineScope {
        // ── 并行分支1：分类（端侧→云端兜底） ──
        val foodTask = async(Dispatchers.Default) { recognizeFood(original) }

        // ── 并行预处理：三路缩放同时做 ──
        val samInput = async(Dispatchers.Default) { padToSquare(original, samSize) }
        val clsInput = async(Dispatchers.Default) { centerCrop(original, 300) }

        // ── 串行推理链：SAM → 主体 → AnimeGAN → 合成 ──
        val (padded, cw, ch) = samInput.await()
        val alphaBytes = NativeEngine.segment(padded, samSize, cw, ch)          // ~400ms
        val alphaSmall = StickerComposer.buildSmoothAlpha(alphaBytes, samSize)  // 1.5px模糊
        // 裁掉pad区并放大回原图分辨率
        val alpha = Bitmap.createScaledBitmap(
            Bitmap.createBitmap(alphaSmall, 0, 0, cw, ch),
            original.width, original.height, true)

        val subject = applyAlphaOnWhite(original, alpha, ganSize)               // 白底主体
        val cartoon = Bitmap.createBitmap(ganSize, ganSize, Bitmap.Config.ARGB_8888)
        NativeEngine.cartoonize(subject, cartoon, ganSize)                      // ~180ms

        val sticker = StickerComposer.compose(cartoon, alpha, outlinePx = 4f, maxSide = maxSide)

        val food = foodTask.await()
        PipelineResult(sticker, StickerComposer.toPngBytes(alpha), food, food?.fromCloud == true)
    }

    private suspend fun recognizeFood(image: Bitmap): FoodInfo? {
        val r = NativeEngine.classify(centerCrop(image, 300))
        val (classId, conf) = r[0].toInt() to r[1]
        if (conf >= CONFIDENCE_THRESHOLD) db.queryByClassId(classId)?.let { return it }
        return runCatching { CloudApi.recognizeFood(image) }.getOrNull()   // 冷门兜底 ≤3s
    }

    /** 手动修正：本地别名搜索 → 云端兜底 */
    suspend fun correctFood(name: String): FoodInfo? =
        db.searchByName(name) ?: runCatching { CloudApi.queryNutrition(name) }.getOrNull()

    /** 高清导出（云端SD+ControlNet，复用Alpha） */
    suspend fun exportHD(original: Bitmap, alphaPng: ByteArray): Bitmap =
        CloudApi.generateHDSticker(original, alphaPng)

    // ── 工具 ──
    private fun padToSquare(src: Bitmap, size: Int): Triple<Bitmap, Int, Int> {
        val scale = size.toFloat() / maxOf(src.width, src.height)
        val cw = (src.width * scale).toInt()
        val ch = (src.height * scale).toInt()
        val out = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        Canvas(out).drawBitmap(Bitmap.createScaledBitmap(src, cw, ch, true), 0f, 0f, null)
        return Triple(out, cw, ch)
    }

    private fun centerCrop(src: Bitmap, size: Int): Bitmap {
        val side = minOf(src.width, src.height)
        val crop = Bitmap.createBitmap(src, (src.width - side) / 2, (src.height - side) / 2, side, side)
        return Bitmap.createScaledBitmap(crop, size, size, true)
    }

    /** 原图×Alpha → 白底主体（AnimeGAN 训练分布一致），缩放到 ganSize² */
    private fun applyAlphaOnWhite(src: Bitmap, alpha: Bitmap, size: Int): Bitmap {
        val out = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(out)
        canvas.drawColor(Color.WHITE)
        val subject = Bitmap.createBitmap(src.width, src.height, Bitmap.Config.ARGB_8888)
        Canvas(subject).apply {
            drawBitmap(src, 0f, 0f, null)
            val clip = android.graphics.Paint().apply {
                xfermode = android.graphics.PorterDuffXfermode(android.graphics.PorterDuff.Mode.DST_IN)
            }
            drawBitmap(alpha.extractAlpha(), 0f, 0f, clip)
        }
        canvas.drawBitmap(Bitmap.createScaledBitmap(subject, size, size, true), 0f, 0f, null)
        return out
    }
}
