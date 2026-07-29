# 模型转换 / 微调 / 端侧部署全流程

## 0. 环境准备

```bash
# Python 环境（转换与训练）
conda create -n foodsticker python=3.10 -y && conda activate foodsticker
pip install torch torchvision timm coremltools onnx onnxsim lpips
pip install git+https://github.com/ChaoningZhang/MobileSAM.git

# NCNN 工具链（onnx2ncnn / ncnnoptimize）
git clone https://github.com/Tencent/ncnn && cd ncnn
mkdir build && cd build
cmake -DNCNN_VULKAN=ON -DNCNN_BUILD_TOOLS=ON ..
make -j8 && export PATH=$PATH:$(pwd)/tools/onnx:$(pwd)/tools
```

## 1. MobileSAM（抠图）

```bash
wget https://github.com/ChaoningZhang/MobileSAM/raw/master/weights/mobile_sam.pt
python tools/convert_mobilesam.py --ckpt mobile_sam.pt --out ./out
```
产物：
- iOS: `MobileSAMEncoder.mlpackage`（~20MB FP16）、`MobileSAMDecoder.mlpackage`（~8MB）
- Android: `mobilesam_encoder.param/.bin`、`mobilesam_decoder.param/.bin`

端侧提示策略（免交互自动抠主体）：取景框引导用户把食品置中，推理时用
**中心正点 (cx, cy, label=1) + 负点四角**，单 mask 输出取 IoU 预测最高者。

## 2. AnimeGANv3 轻量版（贴纸风微调）

### 2.1 风格数据生产
```bash
# B域风格图：用云端SD+固定提示词批量生成（见 server/main.py /sticker/hd），
# 输入 Food-101 各类代表图，人工剔除轮廓变形样本，保留 ~5000 张
python batch_gen_style.py --src food101_samples/ --dst stickerB/
```

### 2.2 微调 + 导出
```bash
python tools/finetune_animegan.py train  --dataA foodA/ --dataB stickerB/ --epochs 40
python tools/finetune_animegan.py export --ckpt g_best.pt --out ./out
```
损失设计已内置贴纸风约束：LPIPS 保结构、通道均值 L1 保配色、Sobel 边缘 L1 保轮廓不变形。
验收标准：测试集人工评审「轮廓 IoU ≥ 0.98、无特征篡改」通过率 ≥ 95% 方可发版。

## 3. EfficientNet-Lite4（1000 类食品分类）

```bash
# 数据目录: food1000/train/<class_name>/*.jpg （1000个类目录，命名与营养库 name_en 一致）
python tools/convert_efficientnet.py train  --data ./food1000 --epochs 30
python tools/convert_efficientnet.py export --ckpt cls_best.pt --out ./out
```
验收：验证集 Top-1 ≥ 95%（常见 1000 类）。`labels_1000.txt` 行号 = `nutrition.db food.class_id`。

## 4. 营养数据库

```bash
python tools/build_nutrition_db.py --csv nutrition_1000.csv --alias alias.csv --out nutrition.db
```

## 5. 端侧集成

### iOS（Core ML + Metal/ANE）
1. 将 4 个 `.mlpackage` + `nutrition.db` + `labels_1000.txt` 拖入 Xcode 工程（Copy Bundle Resources）。
2. Xcode 自动生成模型类；所有引擎已在代码中设置 `MLModelConfiguration.computeUnits = .all`（ANE→GPU→CPU 自动回退）。
3. 首启时 Core ML 会做设备端编译缓存，建议在启动页预热一次空推理。

### Android（NCNN Vulkan）
1. 模型放 `app/src/main/assets/models/`，`nutrition.db`、`labels_1000.txt` 放 `assets/`。
2. `build.gradle` 开启 NDK；`cpp/CMakeLists.txt` 链接 ncnn（`-DNCNN_VULKAN=ON` 预编译包）。
3. 运行时 `net.opt.use_vulkan_compute = true; use_fp16_packed/storage/arithmetic = true`；
   无 Vulkan 设备自动回退 CPU + fp16 packed（代码已处理）。

## 6. 低端机降级策略（已在双端 Pipeline 实现）
| 档位 | 判定 | SAM输入 | 风格化输入 | 合成上限 |
|---|---|---|---|---|
| 高端 | ANE/NPU 或 Vulkan 且 RAM≥6G | 1024 | 512 | 原图 |
| 中端 | GPU 可用 | 1024 | 512 | 2048px |
| 低端 | 仅CPU 或 RAM<4G | 512 | 384 | 1080px |
