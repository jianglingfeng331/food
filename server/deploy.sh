#!/bin/bash
# FitFood PK 服务端一键部署脚本（阿里云 Ubuntu 20.04/22.04）
# 用法: chmod +x deploy.sh && sudo ./deploy.sh
set -e

echo "========================================"
echo "  FitFood PK 服务端部署"
echo "  域名: rubyace.love"
echo "========================================"

APP_DIR="/opt/fitfoodpk/server"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DB_USER="fitfoodpk"
DB_NAME="fitfoodpk"
DB_PASS=$(openssl rand -hex 16)
STICKER_DIR="$APP_DIR/stickers"
BACKUP_DIR="/opt/fitfoodpk/backups"

# 1. 安装系统依赖
echo "[1/12] 安装系统依赖..."
apt-get update
apt-get install -y python3-pip python3-venv postgresql postgresql-contrib nginx certbot python3-certbot-nginx libgl1-mesa-glx cron redis-server

# 2. 初始化 PostgreSQL
echo "[2/12] 配置 PostgreSQL..."
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
echo "   数据库用户: $DB_USER"
echo "   数据库密码: $DB_PASS (已随机生成)"

# 3. 配置 Redis（缓存 + 分布式限流）
echo "[3/12] 配置 Redis..."
sed -i 's/^# maxmemory .*/maxmemory 256mb/' /etc/redis/redis.conf
sed -i 's/^# maxmemory-policy .*/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf
systemctl enable redis-server
systemctl restart redis-server
echo "   Redis 已配置（max 256MB, LRU 淘汰）"

# 4. 创建应用目录
echo "[4/12] 创建应用目录: $APP_DIR"
mkdir -p "$APP_DIR" "$STICKER_DIR" "$BACKUP_DIR"
cp -r "$SCRIPT_DIR"/*.py "$SCRIPT_DIR/requirements.txt" "$APP_DIR/"
# 复制 Alembic 迁移文件
cp -r "$SCRIPT_DIR/migrations" "$APP_DIR/" 2>/dev/null || echo "    (无 migrations 目录，跳过)"
cp "$SCRIPT_DIR/alembic.ini" "$APP_DIR/" 2>/dev/null || echo "    (无 alembic.ini，跳过)"
# 复制备份脚本 + 监控配置 + 灰度配置
cp "$SCRIPT_DIR/backup.sh" "$APP_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/prometheus.yml" "$APP_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/grafana-dashboard.json" "$APP_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/docker-compose.monitoring.yml" "$APP_DIR/" 2>/dev/null || true
chmod +x "$APP_DIR/backup.sh" 2>/dev/null || true

# 5. 创建虚拟环境并安装 Python 依赖
echo "[5/12] 安装 Python 依赖..."
python3 -m venv "$APP_DIR/.venv"
"$APP_DIR/.venv/bin/pip" install --upgrade pip
"$APP_DIR/.venv/bin/pip" install -r "$APP_DIR/requirements.txt"

# 6. 配置环境变量
echo "[6/12] 配置环境变量..."
if [ ! -f "$APP_DIR/.env" ]; then
    cp "$APP_DIR/.env.example" "$APP_DIR/.env"
fi
# 写入 DATABASE_URL + REDIS_URL
sed -i "s|^DATABASE_URL=.*|DATABASE_URL=postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME|" "$APP_DIR/.env"
if ! grep -q "^REDIS_URL=" "$APP_DIR/.env"; then
    echo "REDIS_URL=redis://localhost:6379/0" >> "$APP_DIR/.env"
fi
echo "⚠️  请编辑 $APP_DIR/.env 填入火山方舟 VLM_API_KEY 和 JWT_SECRET"

# 7. 运行 Alembic 数据库迁移
echo "[7/12] 运行数据库迁移..."
cd "$APP_DIR"
source "$APP_DIR/.env" 2>/dev/null || true
export DATABASE_URL="postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME"
"$APP_DIR/.venv/bin/alembic" upgrade head || echo "⚠️ Alembic 迁移失败，将在首次启动时自动重试"

# 8. 创建贴纸目录
echo "[8/12] 创建贴纸存储目录: $STICKER_DIR"
chmod 755 "$STICKER_DIR"

# 9. 配置 Nginx + systemd
echo "[9/12] 配置 Nginx + systemd..."
cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/sites-available/fitfoodpk
ln -sf /etc/nginx/sites-available/fitfoodpk /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
cp "$SCRIPT_DIR/fitfoodpk.service" /etc/systemd/system/
systemctl daemon-reload
nginx -t && systemctl reload nginx

# 10. HTTPS 证书
echo "[10/12] 申请 HTTPS 证书..."
certbot --nginx -d rubyace.love --non-interactive --agree-tos -m admin@rubyace.love || echo "⚠️ certbot 失败，请手动运行"

# 11. 配置自动备份（每天凌晨 3 点）
echo "[11/12] 配置数据库自动备份..."
BACKUP_CRON="0 3 * * * /bin/bash $APP_DIR/backup.sh >> /var/log/fitfoodpk-backup.log 2>&1"
(crontab -l 2>/dev/null | grep -v "backup.sh" || true; echo "$BACKUP_CRON") | crontab -
echo "   备份计划: 每天 03:00 执行"
echo "   备份目录: $BACKUP_DIR"

# 12. 启动服务
echo "[12/12] 启动服务..."
systemctl enable fitfoodpk
systemctl restart fitfoodpk

echo ""
echo "========================================"
echo "  部署完成！"
echo "  数据库: PostgreSQL (用户: $DB_USER, 库: $DB_NAME)"
echo "  Redis: 已启用（缓存 + 分布式限流）"
echo "  贴纸目录: $STICKER_DIR"
echo "  备份目录: $BACKUP_DIR (每天 03:00 自动备份)"
echo "  服务状态: systemctl status fitfoodpk"
echo "  API 地址: https://rubyace.love"
echo "  指标端点: https://rubyace.love/metrics"
echo ""
echo "  ⚠️ 请编辑 $APP_DIR/.env 填入真实 Key 后重启:"
echo "     sudo systemctl restart fitfoodpk"
echo ""
echo "  📦 可选：Docker Compose 监控栈（Prometheus + Grafana）"
echo "     cd $APP_DIR && docker compose -f docker-compose.monitoring.yml up -d"
echo "     Grafana: http://localhost:3000 (admin/admin123)"
echo ""
echo "  🧪 运行测试:"
echo "     cd $APP_DIR && .venv/bin/pytest test_main.py -v"
echo "========================================\""
