// NCNN 端侧推理引擎（Vulkan GPU + FP16）：MobileSAM / AnimeGANv3 / EfficientNet-Lite4
// 依赖: ncnn (Vulkan预编译包，内含 opencv-mobile 风格的简单Mat即可，形态学用ncnn自带)
#include <jni.h>
#include <android/asset_manager_jni.h>
#include <android/bitmap.h>
#include <ncnn/net.h>
#include <ncnn/gpu.h>
#include <cmath>
#include <vector>

static ncnn::Net g_samEnc, g_samDec, g_anime, g_cls;
static bool g_gpu = false;

static void configNet(ncnn::Net &net) {
    net.opt.use_vulkan_compute = g_gpu;      // GPU/NPU 加速；无Vulkan回退CPU
    net.opt.use_fp16_packed = true;          // FP16 全链路
    net.opt.use_fp16_storage = true;
    net.opt.use_fp16_arithmetic = true;
    net.opt.num_threads = ncnn::get_big_cpu_count();
}

extern "C" {

JNIEXPORT jboolean JNICALL
Java_com_foodsticker_ml_NativeEngine_init(JNIEnv *env, jobject, jobject assetMgr) {
    AAssetManager *mgr = AAssetManager_fromJava(env, assetMgr);
    g_gpu = ncnn::get_gpu_count() > 0;
    for (auto *net : {&g_samEnc, &g_samDec, &g_anime, &g_cls}) configNet(*net);
    return g_samEnc.load_param(mgr, "models/mobilesam_encoder.param") == 0 &&
           g_samEnc.load_model(mgr, "models/mobilesam_encoder.bin") == 0 &&
           g_samDec.load_param(mgr, "models/mobilesam_decoder.param") == 0 &&
           g_samDec.load_model(mgr, "models/mobilesam_decoder.bin") == 0 &&
           g_anime.load_param(mgr, "models/animeganv3.param") == 0 &&
           g_anime.load_model(mgr, "models/animeganv3.bin") == 0 &&
           g_cls.load_param(mgr, "models/food_classifier.param") == 0 &&
           g_cls.load_model(mgr, "models/food_classifier.bin") == 0;
}

JNIEXPORT jboolean JNICALL
Java_com_foodsticker_ml_NativeEngine_hasGpu(JNIEnv *, jobject) { return g_gpu; }

// ───────────────── MobileSAM: Bitmap → Alpha遮罩(byte[] 0/255, size²) ─────────────────
// 输入 bitmap 已由 Kotlin 侧等比缩放+左上pad到 size×size
JNIEXPORT jbyteArray JNICALL
Java_com_foodsticker_ml_NativeEngine_segment(JNIEnv *env, jobject, jobject bitmap,
                                             jint size, jint contentW, jint contentH) {
    ncnn::Mat in = ncnn::Mat::from_android_bitmap(env, bitmap, ncnn::Mat::PIXEL_RGBA2RGB);
    const float norm[3] = {1 / 255.f, 1 / 255.f, 1 / 255.f};
    in.substract_mean_normalize(nullptr, norm);

    // 1. 编码
    ncnn::Mat embeddings;
    { ncnn::Extractor ex = g_samEnc.create_extractor();
      ex.input("image", in);
      ex.extract("image_embeddings", embeddings); }

    // 2. 解码：中心正点 + 四角负点
    float pts[10] = {contentW / 2.f, contentH / 2.f, 8, 8, (float) contentW - 8, 8,
                     8, (float) contentH - 8, (float) contentW - 8, (float) contentH - 8};
    float lbl[5] = {1, 0, 0, 0, 0};
    ncnn::Mat coords(2, 5, 1), labels(5, 1), maskIn(256, 256, 1), hasMask(1), origSz(2);
    memcpy(coords.data, pts, sizeof(pts));
    memcpy(labels.data, lbl, sizeof(lbl));
    maskIn.fill(0.f); hasMask.fill(0.f);
    ((float *) origSz.data)[0] = (float) size; ((float *) origSz.data)[1] = (float) size;

    ncnn::Mat mask;
    { ncnn::Extractor ex = g_samDec.create_extractor();
      ex.input("image_embeddings", embeddings);
      ex.input("point_coords", coords);
      ex.input("point_labels", labels);
      ex.input("mask_input", maskIn);
      ex.input("has_mask_input", hasMask);
      ex.input("orig_im_size", origSz);
      ex.extract("masks", mask); }

    // 3. logits阈值化 → 0/255
    jbyteArray out = env->NewByteArray(size * size);
    std::vector<jbyte> buf(size * size);
    const float *p = (const float *) mask.data;
    for (int i = 0; i < size * size; i++) buf[i] = p[i] > 0 ? (jbyte) 255 : 0;
    env->SetByteArrayRegion(out, 0, size * size, buf.data());
    return out;
}

// ───────────────── AnimeGANv3: Bitmap(size²,白底主体) → 卡通RGB写回Bitmap ─────────────────
JNIEXPORT void JNICALL
Java_com_foodsticker_ml_NativeEngine_cartoonize(JNIEnv *env, jobject,
                                                jobject inBitmap, jobject outBitmap, jint size) {
    ncnn::Mat in = ncnn::Mat::from_android_bitmap(env, inBitmap, ncnn::Mat::PIXEL_RGBA2RGB);
    const float mean[3] = {127.5f, 127.5f, 127.5f};
    const float norm[3] = {1 / 127.5f, 1 / 127.5f, 1 / 127.5f};   // → [-1,1]
    in.substract_mean_normalize(mean, norm);

    ncnn::Mat out;
    { ncnn::Extractor ex = g_anime.create_extractor();
      ex.input("image", in);
      ex.extract("cartoon", out); }

    const float dmean[3] = {-1.f, -1.f, -1.f};                    // [-1,1] → [0,255]
    const float dnorm[3] = {127.5f, 127.5f, 127.5f};
    out.substract_mean_normalize(dmean, dnorm);
    out.to_android_bitmap(env, outBitmap, ncnn::Mat::PIXEL_RGB);
}

// ───────────────── EfficientNet-Lite4: Bitmap(300²) → [classId, confidence] ─────────────────
JNIEXPORT jfloatArray JNICALL
Java_com_foodsticker_ml_NativeEngine_classify(JNIEnv *env, jobject, jobject bitmap) {
    ncnn::Mat in = ncnn::Mat::from_android_bitmap(env, bitmap, ncnn::Mat::PIXEL_RGBA2RGB);
    const float mean[3] = {123.675f, 116.28f, 103.53f};
    const float norm[3] = {1 / 58.395f, 1 / 57.12f, 1 / 57.375f};
    in.substract_mean_normalize(mean, norm);

    ncnn::Mat probs;
    { ncnn::Extractor ex = g_cls.create_extractor();
      ex.input("image", in);
      ex.extract("probs", probs); }

    int best = 0; float bestP = 0;
    const float *p = (const float *) probs.data;
    for (int i = 0; i < probs.w; i++) if (p[i] > bestP) { bestP = p[i]; best = i; }
    float r[2] = {(float) best, bestP};
    jfloatArray out = env->NewFloatArray(2);
    env->SetFloatArrayRegion(out, 0, 2, r);
    return out;
}

} // extern "C"
