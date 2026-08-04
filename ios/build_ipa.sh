#!/bin/bash
set -e

PROJECT="FoodStickerApp.xcodeproj"
SCHEME="FoodStickerApp"
ARCHIVE_PATH="/tmp/FoodStickerApp.xcarchive"
EXPORT_DIR="$HOME/Desktop/FoodSticker-IPA"
EXPORT_PLIST="/tmp/export_options.plist"

# -------- 配置 --------
# Team ID：可通过环境变量 TEAM_ID 传入，否则用默认值
TEAM_ID="${TEAM_ID:-}"
# 导出方式：app-store（上架）/ development（内测）/ ad-hoc（企业分发）
EXPORT_METHOD="${EXPORT_METHOD:-app-store}"
# ---------------------

echo "=============================="
echo "  FitFood PK IPA 打包脚本"
echo "  Team ID: ${TEAM_ID:-自动}"
echo "  Export:  $EXPORT_METHOD"
echo "=============================="

# Step 1: Clean
echo ""
echo "[1/3] 清理旧构建…"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" clean > /dev/null 2>&1

# Step 2: Archive (with allowProvisioningUpdates)
echo "[2/3] 归档 Archive…"
xcodebuild -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination 'generic/platform=iOS' \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    archive

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive 失败"
    exit 1
fi
echo "✅ Archive 成功"

# Step 3: 生成 exportOptions.plist
cat > "$EXPORT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$EXPORT_METHOD</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

# Step 4: Export IPA
echo "[3/3] 导出 IPA…"
rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_PLIST" \
    -allowProvisioningUpdates

# Cleanup
rm -f "$EXPORT_PLIST"
rm -rf "$ARCHIVE_PATH"

# Result
IPA=$(find "$EXPORT_DIR" -name "*.ipa" | head -1)
if [ -f "$IPA" ]; then
    SIZE=$(du -sh "$IPA" | cut -f1)
    echo ""
    echo "=============================="
    echo "🎉 打包完成！"
    echo "📱 IPA: $IPA"
    echo "📦 大小: $SIZE"
    echo "📂 目录: $EXPORT_DIR"
    echo "=============================="
    open "$EXPORT_DIR"
else
    echo "❌ 导出 IPA 失败"
    exit 1
fi
