package com.foodsticker.cloud

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import com.foodsticker.nutrition.FoodInfo
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.util.concurrent.TimeUnit

/** 云端接口：冷门食品识别兜底 + SD高清贴纸生成 */
object CloudApi {
    private const val BASE = "https://api.yourserver.com"
    private val JSON = "application/json".toMediaType()
    private val client = OkHttpClient.Builder()
        .callTimeout(15, TimeUnit.SECONDS)   // 云端要求 ≤3s，快速失败
        .build()

    /** 冷门食品识别：原图压缩1024长边上传 → 名称+分量+营养 */
    suspend fun recognizeFood(image: Bitmap): FoodInfo = withContext(Dispatchers.IO) {
        val body = JSONObject().put("image_b64", image.toJpegBase64(1024)).toString()
        val resp = post("$BASE/food/recognize", body)
        FoodInfo(
            nameCn = resp.getString("name_cn"),
            kcal100g = resp.getDouble("kcal_100g"),
            proteinG = resp.getDouble("protein_g"),
            carbG = resp.getDouble("carb_g"),
            fatG = resp.getDouble("fat_g"),
            typicalG = resp.getDouble("portion_g"),
            fromCloud = true,
            portionG = resp.getDouble("portion_g"))
    }

    /** 手动修正名称 → 云端查营养 */
    suspend fun queryNutrition(name: String): FoodInfo = withContext(Dispatchers.IO) {
        val resp = post("$BASE/food/nutrition", JSONObject().put("name", name).toString())
        FoodInfo(resp.getString("name_cn"), resp.getDouble("kcal_100g"),
                 resp.getDouble("protein_g"), resp.getDouble("carb_g"),
                 resp.getDouble("fat_g"), 100.0, fromCloud = true)
    }

    /** 高清贴纸：原图+端侧Alpha → SD img2img + ControlNet Canny → 透明底PNG */
    suspend fun generateHDSticker(image: Bitmap, alphaPng: ByteArray): Bitmap =
        withContext(Dispatchers.IO) {
            val body = JSONObject()
                .put("image_b64", image.toJpegBase64(1536))
                .put("alpha_b64", Base64.encodeToString(alphaPng, Base64.NO_WRAP))
                .toString()
            val resp = post("$BASE/sticker/hd", body)
            val png = Base64.decode(resp.getString("sticker_png_b64"), Base64.NO_WRAP)
            BitmapFactory.decodeByteArray(png, 0, png.size)
        }

    private fun post(url: String, json: String): JSONObject {
        client.newCall(Request.Builder().url(url).post(json.toRequestBody(JSON)).build())
            .execute().use { resp ->
                check(resp.isSuccessful) { "HTTP ${resp.code}" }
                return JSONObject(resp.body!!.string())
            }
    }

    private fun Bitmap.toJpegBase64(maxSide: Int): String {
        val s = minOf(1f, maxSide.toFloat() / maxOf(width, height))
        val bmp = if (s < 1f) Bitmap.createScaledBitmap(this, (width * s).toInt(), (height * s).toInt(), true) else this
        val out = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.JPEG, 85, out)
        return Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
    }
}
