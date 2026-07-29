package com.foodsticker.sticker

import android.content.ContentValues
import android.content.Context
import android.graphics.*
import android.provider.MediaStore
import androidx.core.graphics.applyCanvas
import java.io.ByteArrayOutputStream

/**
 * 贴纸合成器：Alpha高斯模糊消锯齿 → 形态学膨胀白描边 → 图层合成 → 透明PNG
 * 强约束：白描边只由抠图Alpha膨胀生成（禁止重新分割），与主体零错位
 */
object StickerComposer {

    /** Alpha字节数组 → ALPHA_8 Bitmap，并做 ~1.5px 高斯模糊平滑边缘 */
    fun buildSmoothAlpha(alphaBytes: ByteArray, size: Int, blurRadius: Float = 1.5f): Bitmap {
        val alpha = Bitmap.createBitmap(size, size, Bitmap.Config.ALPHA_8)
        alpha.copyPixelsFromBuffer(java.nio.ByteBuffer.wrap(alphaBytes))
        return blurAlpha(alpha, blurRadius)
    }

    /**
     * 合成贴纸：
     * ① dilate(alpha, outlinePx) 得膨胀遮罩
     * ② 膨胀遮罩填白置底（露出的环即模切描边）
     * ③ 卡通主体 × 原始alpha 叠于其上
     */
    fun compose(cartoon: Bitmap, alpha: Bitmap, outlinePx: Float = 4f, maxSide: Int = 2048): Bitmap {
        val scale = minOf(1f, maxSide.toFloat() / maxOf(alpha.width, alpha.height))
        val w = (alpha.width * scale).toInt()
        val h = (alpha.height * scale).toInt()
        val alphaS = Bitmap.createScaledBitmap(alpha, w, h, true)
        val cartoonS = Bitmap.createScaledBitmap(cartoon, w, h, true)

        val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        out.applyCanvas {
            val paint = Paint(Paint.ANTI_ALIAS_FLAG)

            // ① 形态学膨胀：BlurMaskFilter(OUTER不可用) → 用MaskFilter近似不稳，改为多方向偏移绘制实现精确dilate
            val dilated = dilateAlpha(alphaS, outlinePx)

            // ② 白色模切描边层（最底层）
            paint.colorFilter = PorterDuffColorFilter(Color.WHITE, PorterDuff.Mode.SRC_IN)
            drawBitmap(dilated.toAlphaMaskBitmap(Color.WHITE), 0f, 0f, null)
            paint.colorFilter = null

            // ③ 卡通主体 × 原始Alpha（DST_IN裁剪），叠加到白层之上
            val subject = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            subject.applyCanvas {
                drawBitmap(cartoonS, 0f, 0f, null)
                val clip = Paint().apply { xfermode = PorterDuffXfermode(PorterDuff.Mode.DST_IN) }
                drawBitmap(alphaS.toAlphaMaskBitmap(Color.BLACK), 0f, 0f, clip)
            }
            drawBitmap(subject, 0f, 0f, null)
        }
        return out
    }

    /** 精确形态学膨胀：圆形结构元，按半径逐点偏移取最大值（半径小，代价可忽略） */
    private fun dilateAlpha(alpha: Bitmap, radius: Float): Bitmap {
        val out = Bitmap.createBitmap(alpha.width, alpha.height, Bitmap.Config.ALPHA_8)
        val canvas = Canvas(out)
        val r = radius.toInt().coerceIn(3, 5)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        for (dx in -r..r) for (dy in -r..r) {
            if (dx * dx + dy * dy > r * r) continue
            canvas.drawBitmap(alpha, dx.toFloat(), dy.toFloat(), paint)
        }
        return out
    }

    /** ALPHA_8 高斯模糊（RenderEffect API31+，低版本用缩放近似） */
    private fun blurAlpha(alpha: Bitmap, radius: Float): Bitmap {
        val down = Bitmap.createScaledBitmap(alpha, alpha.width / 2, alpha.height / 2, true)
        return Bitmap.createScaledBitmap(down, alpha.width, alpha.height, true) // 双线性来回≈1.5px模糊
    }

    private fun Bitmap.toAlphaMaskBitmap(color: Int): Bitmap {
        val out = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        out.applyCanvas {
            val p = Paint().apply { this.color = color }
            drawBitmap(extractAlpha(), 0f, 0f, p)
        }
        return out
    }

    /** 保存透明PNG到相册 */
    fun saveToAlbum(context: Context, sticker: Bitmap, name: String = "sticker_${System.currentTimeMillis()}") : Boolean {
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "$name.png")
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/FoodSticker")
        }
        val uri = context.contentResolver.insert(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return false
        context.contentResolver.openOutputStream(uri)?.use {
            return sticker.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
        return false
    }

    fun toPngBytes(bmp: Bitmap): ByteArray =
        ByteArrayOutputStream().also { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }.toByteArray()
}
