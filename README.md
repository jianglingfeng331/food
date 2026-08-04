# 食品拍照 → 卡通贴纸 + 营养识别（云端为主 + 端侧兜底抠图）

卡通贴纸与营养识别均以**云端为主力**：拍照后由服务端调用视觉大模型（seedream 图生图生成卡通贴纸、SD+ControlNet 做高清导出、多模态大模型做识别与营养）。
移动端仅做**轻量端侧抠图预览**（iOS 用 MobileSAM 兜底，作为构图辅助），其余 AI 推理全部在云端完成。

> 注意：端侧 MobileSAM 模型文件当前仍为**占位空壳**（需在有 GPU 的环境跑 `tools/` 脚本替换），未配置时抠图预览不可用，但不影响主链路（主链路走云端）。

## 一、总体架构

```
┌────────────────────────── 移动端（采集 + 预览） ──────────────────────────┐
│ 相机采集 ──► (iOS) MobileSAM 端侧兜底抠图预览（可选，占位中）              │
│             └─ 原图上传云端                                                │
└───────────────┬──────────────────────────────────────────────────────────┘
                │ 原图 / 请求
┌───────────────▼──────────── 云端（主力 AI） ──────────────────────────────┐
│ /sticker/seedream  火山方舟 seedream 图生图 → 卡通贴纸                    │
│ /sticker/hd        SD 图生图 + ControlNet Canny 锁轮廓 → 高清贴纸         │
│ /food/recognize    多模态大模型：食品名 + 分量 + 营养估算                 │
│ /food/nutrition    按食品名查询营养明细                                  │
└──────────────────────────────────────────────────────────────────────────┘
```

## 二、技术选型

| 模块 | 实现 |
|---|---|
| 卡通贴纸生成 | 云端：火山方舟 seedream 图生图（`/sticker/seedream`） |
| 高清贴纸导出 | 云端：SD img2img + ControlNet（`/sticker/hd`） |
| 食物识别 / 营养 | 云端：多模态视觉大模型（`/food/recognize`、`/food/nutrition`） |
| 端侧抠图预览 | iOS：MobileSAM（占位中，仅作兜底） |
| 客户端 ↔ 服务端 | `CloudAPI.swift`（iOS）/ `CloudApi.kt`（Android）统一走服务端代理 |

## 三、工程结构

```
food-sticker-app/
├── README.md
├── docs/
│   ├── model-conversion.md        # 模型转换/微调/部署全流程命令
│   └── nutrition-db-schema.sql    # 营养库表结构
├── tools/                          # 数据/模型生产脚本（Python）
│   └── build_nutrition_db.py       # CSV → SQLite 营养库
├── ios/FoodSticker/
│   ├── Camera/CameraViewController.swift
│   ├── ML/MattingEngine.swift      # MobileSAM 端侧抠图（占位中）
│   ├── ML/ImageTensorUtils.swift   # MattingEngine 复用工具
│   ├── Sticker/StickerComposer.swift  # 导出/分享工具
│   ├── Nutrition/NutritionDB.swift
│   └── Cloud/CloudAPI.swift        # 云端 AI 代理
└── server/
    ├── main.py                     # FastAPI：seedream 贴纸 + SD 高清 + 多模态识别
    └── requirements.txt
```

> 历史端侧能力（AnimeGAN 卡通化、EfficientNet 分类、Android NCNN 三模型流水线）已移除，相关代码与脚本不再存在。

## 四、快速开始

1. 云端：`cd server && pip install -r requirements.txt && uvicorn main:app --port 8000`
2. iOS：用 Xcode 打开 `ios/FoodStickerApp.xcodeproj`，配置签名后运行（详见 `docs/ios-xcode-setup.md`）。
3. 生产环境需在服务端配置 `ARK_API_KEY`（seedream）、`VLM_API_KEY`（识别/营养）等环境变量。
