#!/bin/bash
# FitFood PK 数据库自动备份脚本
# 用法: ./backup.sh [local|oss]
#   local  → 仅本地保留（默认）
#   oss    → 本地保留 + 上传阿里云 OSS
# 推荐加入 crontab: 0 3 * * * /opt/fitfoodpk/server/backup.sh oss
set -euo pipefail

# ────── 配置 ──────
BACKUP_DIR="${BACKUP_DIR:-/opt/fitfoodpk/backups}"
DB_NAME="${DB_NAME:-fitfoodpk}"
DB_USER="${DB_USER:-fitfoodpk}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"      # 本地保留天数

# 阿里云 OSS 配置（环境变量，可选）
OSS_BUCKET="${OSS_BUCKET:-}"                # 如: oss://fitfoodpk-backups
OSS_ENDPOINT="${OSS_ENDPOINT:-}"            # 如: oss-cn-hangzhou.aliyuncs.com
OSS_ACCESS_KEY="${OSS_ACCESS_KEY:-}"
OSS_SECRET_KEY="${OSS_SECRET_KEY:-}"
MODE="${1:-local}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="${DB_NAME}_${TIMESTAMP}.sql.gz"
FILEPATH="${BACKUP_DIR}/${FILENAME}"

# ────── 1. 创建备份目录 ──────
mkdir -p "$BACKUP_DIR"

# ────── 2. pg_dump + gzip ──────
echo "[backup] 开始备份: $FILENAME"
PGPASSWORD="${PGPASSWORD:-}" pg_dump -U "$DB_USER" -h localhost -F p "$DB_NAME" | gzip > "$FILEPATH"
SIZE=$(du -h "$FILEPATH" | cut -f1)
echo "[backup] 备份完成: $FILEPATH ($SIZE)"

# ────── 3. 清理过期备份 ──────
echo "[backup] 清理 $RETENTION_DAYS 天前的备份..."
find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

# ────── 4. OSS 上传（可选） ──────
if [ "$MODE" = "oss" ] && [ -n "$OSS_BUCKET" ]; then
    echo "[backup] 上传到 OSS: $OSS_BUCKET"
    if command -v ossutil64 &>/dev/null; then
        # 使用阿里云 ossutil 工具
        ossutil64 cp "$FILEPATH" "${OSS_BUCKET}/${FILENAME}" \
            -e "$OSS_ENDPOINT" \
            -i "$OSS_ACCESS_KEY" \
            -k "$OSS_SECRET_KEY"
        echo "[backup] OSS 上传完成"
    elif command -v ossutil &>/dev/null; then
        ossutil cp "$FILEPATH" "${OSS_BUCKET}/${FILENAME}" \
            -e "$OSS_ENDPOINT" \
            -i "$OSS_ACCESS_KEY" \
            -k "$OSS_SECRET_KEY"
        echo "[backup] OSS 上传完成"
    else
        echo "[backup] ⚠️ 未安装 ossutil，跳过 OSS 上传。安装: https://help.aliyun.com/document_detail/120075.html"
    fi
fi

echo "[backup] 完成。备份数: $(ls "$BACKUP_DIR"/*.sql.gz 2>/dev/null | wc -l) 个"
