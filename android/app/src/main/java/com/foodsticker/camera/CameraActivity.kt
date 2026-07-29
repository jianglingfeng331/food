package com.foodsticker.camera

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.core.CameraSelector
import androidx.core.content.ContextCompat
import com.foodsticker.databinding.ActivityCameraBinding

/** 相机采集：CameraX 拍照 + 相册选图 + 取景框引导（布局内含中央虚线圆角框overlay） */
class CameraActivity : AppCompatActivity() {
    private lateinit var binding: ActivityCameraBinding
    private lateinit var imageCapture: ImageCapture

    private val pickImage = registerForActivityResult(
        ActivityResultContracts.PickVisualMedia()) { uri -> uri?.let(::onPicked) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityCameraBinding.inflate(layoutInflater)
        setContentView(binding.root)
        startCamera()

        binding.btnShutter.setOnClickListener { takePhoto() }
        binding.btnAlbum.setOnClickListener {
            pickImage.launch(PickVisualMediaRequest(
                ActivityResultContracts.PickVisualMedia.ImageOnly))
        }
        // binding.guideFrame: 布局中的取景框View（虚线圆角矩形+“将食品对准框内中心”提示）
    }

    private fun startCamera() {
        val providerFuture = ProcessCameraProvider.getInstance(this)
        providerFuture.addListener({
            val provider = providerFuture.get()
            val preview = Preview.Builder().build()
                .also { it.setSurfaceProvider(binding.previewView.surfaceProvider) }
            imageCapture = ImageCapture.Builder()
                .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY) // 速度优先
                .setJpegQuality(95)                                          // 高清原图
                .build()
            provider.unbindAll()
            provider.bindToLifecycle(this, CameraSelector.DEFAULT_BACK_CAMERA,
                                     preview, imageCapture)
        }, ContextCompat.getMainExecutor(this))
    }

    private fun takePhoto() {
        imageCapture.takePicture(ContextCompat.getMainExecutor(this),
            object : ImageCapture.OnImageCapturedCallback() {
                override fun onCaptureSuccess(proxy: ImageProxy) {
                    val full = proxy.toBitmap()   // 高清原图
                    proxy.close()
                    emit(full)
                }
                override fun onError(e: ImageCaptureException) { /* toast错误 */ }
            })
    }

    private fun onPicked(uri: Uri) {
        contentResolver.openInputStream(uri)?.use {
            emit(BitmapFactory.decodeStream(it))
        }
    }

    /** 输出高清原图 + 320px缩略图（快速预览），跳转结果页并触发流水线 */
    private fun emit(full: Bitmap) {
        val s = 320f / maxOf(full.width, full.height)
        val thumb = Bitmap.createScaledBitmap(
            full, (full.width * s).toInt(), (full.height * s).toInt(), true)
        ImageHolder.full = full          // 大图经内存单例传递，避免Intent超限
        ImageHolder.thumb = thumb
        startActivity(android.content.Intent(this, com.foodsticker.ResultActivity::class.java))
    }
}

object ImageHolder {
    var full: Bitmap? = null
    var thumb: Bitmap? = null
}
