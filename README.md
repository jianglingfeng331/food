# 食品拍照 → 卡通贴纸 + 营养识别（端云结合）

端侧离线为主力流程（常见食品全程 ≤1s），云端兜底（冷门食品识别 / 高清导出 ≤3s）。

## 一、总体架构

```
┌────────────────────────── 移动端（离线主力） ──────────────────────────┐
│ 相机采集 ──► 预处理(并行)                                              │
│              ├─ 1024² RGB  ──► MobileSAM(FP16) ──► Alpha遮罩           │
│              ├─ 512²  RGB  ──► AnimeGANv3-Lite(FP16) ──► 卡通主体      │
│              └─ 300²  RGB  ──► EfficientNet-Lite4(FP16) ──► Top1+置信度│
│                                                                        │
│ Alpha后处理: 1-2px高斯模糊消锯齿                                        │
│ 白色模切描边: dilate(Alpha,3~5px) − Alpha → 填白 → 置于最底层           │
│ 合成: 白描边层 + 卡通主体×Alpha → 透明底PNG                             │
│                                                                        │
│ 置信度≥85% ──► 本地SQLite营养库(1000种/中国食物成分表)                  │
└───────────────┬────────────────────────────────────────────────────────┘
                │ 置信度<85% 或 用户点「高清导出」
┌───────────────▼──────────── 云端（兜底/增强） ─────────────────────────┐
│ /food/recognize  多模态大模型：食品名+分量估算+营养估算                 │
│ /sticker/hd      SD图生图 + ControlNet Canny锁轮廓 → 复用Alpha抠白底    │
└────────────────────────────────────────────────────────────────────────┘
```

## 二、技术选型（固定）

| 模块 | iOS | Android |
|---|---|---|
| 推理框架 | Core ML + Metal/ANE | NCNN（Vulkan GPU / fp16） |
| 抠图 | MobileSAM FP16 `.mlpackage` | MobileSAM FP16 `.param/.bin` |
| 风格化 | AnimeGANv3-Lite FP16（食品贴纸风微调） | 同左 NCNN 版 |
| 分类 | EfficientNet-Lite4（Food-101+UEC-Food256 微调，1000类） | 同左 |
| 营养库 | 内置 SQLite `nutrition.db` | 同左（assets 预打包） |
| 云端 | SD img2img + ControlNet Canny；多模态视觉大模型 | 同左 |

描边强约束：黑内轮廓由风格化模型生成；白外模切描边**只由抠图 Alpha 形态学膨胀生成**，禁止重新分割，保证与主体零错位。

## 三、工程结构

```
food-sticker-app/
├── README.md
├── docs/
│   ├── model-conversion.md        # 模型转换/微调/部署全流程命令
│   └── nutrition-db-schema.sql    # 营养库表结构
├── tools/                          # 模型与数据生产脚本（Python）
│   ├── convert_mobilesam.py        # PyTorch → ONNX → CoreML/NCNN (FP16)
│   ├── finetune_animegan.py        # 贴纸风格微调 + 导出
│   ├── convert_efficientnet.py     # Food-101+UEC256 微调 + 双端导出
│   └── build_nutrition_db.py       # CSV → SQLite
├── ios/FoodSticker/
│   ├── Camera/CameraViewController.swift
│   ├── ML/MattingEngine.swift      # MobileSAM
│   ├── ML/CartoonizeEngine.swift   # AnimeGANv3
│   ├── ML/FoodClassifier.swift     # EfficientNet-Lite4
│   ├── Sticker/StickerComposer.swift  # Alpha后处理+白描边+合成导出
│   ├── Pipeline/StickerPipeline.swift # 并行预处理/串行推理调度
│   ├── Nutrition/NutritionDB.swift
│   └── Cloud/CloudAPI.swift
├── android/app/src/main/
│   ├── java/com/foodsticker/
│   │   ├── camera/CameraActivity.kt
│   │   ├── ml/NativeEngine.kt      # JNI 封装
│   │   ├── sticker/StickerComposer.kt
│   │   ├── pipeline/StickerPipeline.kt
│   │   ├── nutrition/NutritionDb.kt
│   │   └── cloud/CloudApi.kt
│   └── cpp/
│       ├── CMakeLists.txt
│       └── native_engine.cpp       # NCNN 三模型推理
└── server/
    ├── main.py                     # FastAPI：SD高清贴纸 + 多模态识别
    └── requirements.txt
```

## 四、性能预算（中高端机，FP16）

| 阶段 | 输入尺寸 | 目标耗时 |
|---|---|---|
| 预处理（三路并行缩放） | 1024/512/300 | ~30ms |
| MobileSAM 编码+解码 | 1024² | 300~450ms |
| AnimeGANv3-Lite | 512² | 120~200ms |
| EfficientNet-Lite4 | 300² | 20~40ms |
| Alpha模糊+膨胀+合成 | 原图分辨率 | 50~100ms |
| **端侧全流程** | — | **≤1s** |

低端机降级策略：SAM 输入降至 512²、风格化降至 384²、合成分辨率上限 1080px（见各端 Pipeline 中 `DeviceTier`）。

## 五、快速开始

1. 产出模型与数据：按 `docs/model-conversion.md` 依次执行 `tools/` 下脚本，得到
   `MobileSAMEncoder.mlpackage / MobileSAMDecoder.mlpackage / AnimeGANv3.mlpackage / FoodClassifier.mlpackage`（iOS）
   与 `*.param/*.bin`（Android），以及 `nutrition.db`、`labels_1000.txt`。
2. iOS：模型拖入 Xcode 工程（自动生成接口类），`nutrition.db` 加入 Bundle。
3. Android：模型放 `app/src/main/assets/models/`，`nutrition.db` 放 `assets/`；NDK 编译链接 ncnn（Vulkan 开启）。
4. 云端：`cd server && pip install -r requirements.txt && uvicorn main:app --port 8000`。
