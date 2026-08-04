# iOS 标准工程装配与上架指南（FoodSticker）

本文件说明如何把 `ios/` 下的源码（已是标准 Xcode 工程结构）真正跑起来、联调、并上架 App Store。

---

## 1. 前置条件

- macOS + 已安装 **Xcode 15+**（需支持 iOS 15 部署目标与 CoreML `.mlpackage`）
- **XcodeGen**：`brew install xcodegen`
- **Apple 开发者账号**（$99/年，用于真机调试与签名）
- 一台 iPhone（建议 iOS 15+）用于真机联调

---

## 2. 生成标准 Xcode 工程

```bash
cd food-sticker-app/ios
xcodegen generate
```

现在 **`ios/` 下已经有一份手写的 `FoodStickerApp.xcodeproj`**（不依赖 XcodeGen），直接用 Xcode 打开即可：

- 在 Finder 进入 `food-sticker-app/ios/`，**双击 `FoodStickerApp.xcodeproj`**；或终端执行 `open food-sticker-app/ios/FoodStickerApp.xcodeproj`。

> 若以后想用 XcodeGen 重新生成，仍可 `cd food-sticker-app/ios && xcodegen generate`（会覆盖同名 `.xcodeproj`）。当前默认无需这一步。

---

## 3. 配置签名（Signing）

在 Xcode 中选中 `FoodStickerApp` target → Signing & Capabilities：

1. 勾选 **Automatically manage signing**
2. **Team** 选择你的开发者账号
3. 修改 **Bundle Identifier** 为你的反向域名（如 `com.yourcompany.foodsticker`）
4. 把 `project.yml` 里的 `DEVELOPMENT_TEAM` 也填成对应 Team ID（可选，便于复现）

> 默认 `project.yml` 中 `PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.foodsticker`，上架前必须改掉 `yourcompany`。

---

## 4. 资源说明（当前仅营养库与端侧抠图模型）

当前主流程的 AI 推理（卡通贴纸、识别、营养）全部在云端完成，移动端只需：

- **营养库 SQLite**：`tools/build_nutrition_db.py` 产出 `nutrition.db`，加入 Bundle（用于端侧快速查表兜底）。
- **MobileSAM 端侧抠图预览（可选，当前为占位）**：模型文件 `MobileSAMEncoder.mlpackage` / `MobileSAMDecoder.mlpackage` 需在有 GPU 的环境跑 `tools/` 脚本生成后放入 `Resources/`。未配置时抠图预览不可用，但主链路不受影响（主链路走云端）。

> 历史端侧能力（AnimeGAN 卡通化、EfficientNet 分类、`StickerPipeline` 调度）已移除，无需再加入对应模型。

---

## 5. 运行真机

1. USB 连接 iPhone，Xcode 顶部选设备
2. 若首次运行提示「不受信任的开发者」，到 iPhone：设置 → 通用 → VPN与设备管理 → 信任你的开发者证书
3. 点击 Run。流程：相机拍摄/相册选图 → Loading → 结果页（贴纸预览 + 营养卡片）

---

## 6. 上架前检查清单（App Store 审核要点）

- [ ] **隐私政策 URL**：苹果强制要求（涉及相机 + 上传照片 + 营养数据）。部署一份网页并填入 App Store Connect 的「隐私政策」字段。
- [ ] **权限描述文案**：`Info.plist` 已含相机/相册描述，文案需真实准确，否则审核被拒。
- [ ] **ATS / HTTPS**：云端 `CloudAPI.swift` 的 `base` 默认 `https://api.yourserver.com` 是占位，**必须换成你的真实 HTTPS 域名**（ATS 禁止明文）。
- [ ] **App 图标**：把 `Assets.xcassets/AppIcon.appiconset` 的占位替换为真实 1024 图标（含各尺寸）。
- [ ] **隐私清单（Privacy Manifest）**：iOS 17+ 要求声明摄像头/用户数据使用目的，建议补 `PrivacyInfo.xcprivacy`。
- [ ] **包体大小**：CoreML 权重较大，注意瘦身（可选使用 `.mlmodelc` 压缩 / 按需资源）。
- [ ] **TestFlight 内测**：上架前用 TestFlight 跑一轮多机型（中高端 ≤1s 全流程）。
- [ ] **崩溃与性能**：在低端机验证不会因为内存峰值（卡通化 512² + Alpha）被系统强杀。

---

## 7. 目录结构（改造后）

```
ios/
├── project.yml                      # XcodeGen 工程描述
└── FoodSticker/
    ├── App/
    │   ├── AppDelegate.swift        # 标准 @main 入口
    │   ├── SceneDelegate.swift      # UIWindowScene + 导航根 = 相机
    │   └── Router.swift             # 相机→云端流水线→结果页 串联
    ├── Camera/
    │   └── CameraViewController.swift
    ├── ML/                          # Matting（MobileSAM 占位）/ TensorUtils
    ├── Sticker/
    │   └── StickerComposer.swift   # 导出/分享工具
    ├── Nutrition/
    │   └── NutritionDB.swift
    ├── Cloud/
    │   └── CloudAPI.swift
    └── Resources/
        ├── Assets.xcassets          # AppIcon / AccentColor
        └── LaunchScreen.storyboard
```

---

## 8. 常见问题

- **编译报「No such module」**：确认 `xcodegen generate` 已成功且 `.xcodeproj` 已生成；三方库是通过原生框架（AVFoundation/Photos/SQLite3），无需 CocoaPods。
- **运行时「处理失败」**：多半是 `Resources/` 缺少 `.mlpackage` 或 `nutrition.db`，按第 4 节补资源后重新 generate。
- **相机黑屏**：检查 Info.plist 相机权限与真机授权；模拟器无相机，需在真机运行。
