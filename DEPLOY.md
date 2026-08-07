# FitFood PK 部署运维手册

> 本文档记录首次部署、后期更新、常见问题排查的完整流程。
> 适用于阿里云 ECS（Ubuntu 22.04）+ 域名 rubyace.love。
>
> ⚠️ **命令执行位置**：
> - `ssh root@101.37.210.127` 开头的命令 → 先 SSH 登录服务器，在**服务器终端**执行
> - 标注「本地 Mac」的命令 → 在你的 Mac 终端执行
> - 涉及 `systemctl`、`/opt/fitfoodpk`、`journalctl`、`certbot`、`nginx` 的命令 → 一律在**服务器**执行

---

## 环境信息（备忘）

| 项目 | 值 |
|------|-----|
| ECS 公网 IP | `101.37.210.127` |
| ECS 内网 IP | `172.24.209.65` |
| 操作系统 | Ubuntu 22.04 LTS |
| 域名 | `rubyace.love` + `www.rubyace.love` |
| 代码仓库 | https://github.com/jianglingfeng331/food.git |
| 服务器代码目录 | `/root/fitfoodpk` |
| 部署目录 | `/opt/fitfoodpk/server` |
| 备份目录 | `/opt/fitfoodpk/backups` |
| 贴纸存储 | `/opt/fitfoodpk/server/stickers` |
| 日志目录 | `/opt/fitfoodpk/server/logs` |
| 服务名 | `fitfoodpk`（systemd） |
| 反向代理 | nginx（监听 80/443，转发到 127.0.0.1:8000） |
| 数据库 | PostgreSQL（库名/用户名 `fitfoodpk`） |
| 缓存 | Redis（127.0.0.1:6379） |
| 火山方舟接入点 | `ep-20260730160118-xqs5f`（食物识别） |
| 贴纸生成模型 | `doubao-seedream-5-0-260128`（直接用模型名） |

---

## 一、首次部署（完整流程）

### 前提条件
- 阿里云 ECS 已购买，系统为 Ubuntu 22.04
- 域名 `rubyace.love` 已在阿里云购买
- 火山方舟账号已开通，有 API Key
- ECS 安全组已放行：**22（SSH）、80（HTTP）、443（HTTPS）** 端口

### 1. 配置域名解析

在阿里云域名控制台添加两条 A 记录：

| 记录类型 | 主机记录 | 记录值 |
|---------|---------|--------|
| A | `@` | ECS 公网 IP |
| A | `www` | ECS 公网 IP |

验证：
```bash
dig +short rubyace.love
dig +short www.rubyace.love
# 两个都应返回 ECS 公网 IP
```

### 2. SSH 登录服务器

```bash
ssh root@101.37.210.127
```

> 如果 22 端口连不上，用阿里云控制台的「远程连接 → Workbench」进入。

### 3. 拉取代码

```bash
cd /root
git clone https://github.com/jianglingfeng331/food.git fitfoodpk
```

### 4. 运行部署脚本

```bash
cd /root/fitfoodpk/server
chmod +x deploy.sh
sudo ./deploy.sh
```

脚本会自动完成：
- 安装 PostgreSQL、Redis、Nginx、certbot
- 创建数据库（用户名/库名 `fitfoodpk`，密码随机生成）
- 创建 Python 虚拟环境 + 安装依赖
- 配置 nginx 反向代理
- 申请 HTTPS 证书
- 配置数据库自动备份（每天凌晨 3 点）
- 启动 systemd 服务

> ⚠️ 如果脚本中途报错，参考下方「常见问题」排查后重新运行即可（脚本可重复执行）。

### 5. 配置密钥（必须手动）

部署脚本不会自动填入敏感密钥，需要手动编辑：

```bash
nano /opt/fitfoodpk/server/.env
```

需要填写的项：

```bash
# 火山方舟 API Key
VLM_API_KEY=ark-你的Key

# 食物识别模型（必须用推理接入点 ID，不是模型名！）
VLM_MODEL=ep-20260730160118-xqs5f

# 贴纸生成模型（直接用模型名即可）
ARK_API_KEY=ark-你的Key          # 通常和 VLM_API_KEY 相同
ARK_SD_MODEL=doubao-seedream-5-0-260128

# JWT 密钥（用 openssl rand -hex 32 生成）
JWT_SECRET=你生成的随机密钥
```

生成 JWT 密钥：
```bash
openssl rand -hex 32
```

保存退出 nano：`Control + O` → 回车 → `Control + X`

### 6. 修复权限

```bash
chown -R www-data:www-data /opt/fitfoodpk
```

### 7. 重启服务

```bash
sudo systemctl restart fitfoodpk
```

### 8. 配置 HTTPS 证书（支持 www 子域）

```bash
# nginx 配置加 www
sudo sed -i 's/server_name rubyace.love;/server_name rubyace.love www.rubyace.love;/' /etc/nginx/sites-available/fitfoodpk
sudo nginx -t && sudo systemctl reload nginx

# 扩展证书到 www 子域
sudo certbot --nginx -d rubyace.love -d www.rubyace.love --non-interactive --agree-tos -m admin@rubyace.love --expand
# 如果上面提示找不到 server block，执行：
sudo certbot install --cert-name rubyace.love --nginx
```

### 9. 验证部署

```bash
# 服务状态（应 active (running)）
sudo systemctl status fitfoodpk

# 本地 API（应返回 404 或 JSON）
curl -s -i http://127.0.0.1:8000/docs

# 公网 HTTPS（应返回 Swagger 页面 HTML）
curl -s -i https://www.rubyace.love/docs

# 浏览器打开也能看到 Swagger 页面
# https://www.rubyace.love/docs
```

### 10. 创建火山方舟推理接入点（首次部署必做）

⚠️ 火山方舟的「对话/视觉模型」**必须创建推理接入点**才能用，直接填模型名会报 404。

1. 打开 https://console.volcengine.com/ark/region:ark+cn-beijing/endpoint
2. 点「创建推理接入点」
3. 选模型 `doubao-seed-1-6-vision-250815`（或其他已开通的视觉模型）
4. 创建后复制接入点 ID（格式 `ep-xxxxxxxx-xxxxx`）
5. 填入 `.env` 的 `VLM_MODEL`

测试接入点是否可用：
```bash
source /opt/fitfoodpk/server/.env && curl -s -X POST "https://ark.cn-beijing.volces.com/api/v3/chat/completions" -H "Authorization: Bearer $VLM_API_KEY" -H "Content-Type: application/json" -d '{"model":"你的接入点ID","messages":[{"role":"user","content":"你好"}],"max_tokens":10}' | python3 -m json.tool
```

返回 `choices` 内容 = 成功；返回 `error` = 失败。

---

## 二、后期更新（日常发版）

### 场景 A：只更新后端代码（最常见）

代码在本地 Mac 改好并推送到 GitHub 后，在服务器执行：

```bash
cd /root/fitfoodpk && git pull && cp server/main.py /opt/fitfoodpk/server/main.py && sudo systemctl restart fitfoodpk && sleep 2 && sudo systemctl status fitfoodpk --no-pager
```

> 如果改了多个 .py 文件，全量复制：
> ```bash
> cd /root/fitfoodpk && git pull && cp server/*.py /opt/fitfoodpk/server/ && sudo systemctl restart fitfoodpk
> ```

### 场景 B：更新了配置文件（.env）

```bash
nano /opt/fitfoodpk/server/.env       # 改完保存
sudo systemctl restart fitfoodpk
```

### 场景 C：更新了 nginx 配置

```bash
cp /root/fitfoodpk/server/nginx.conf /etc/nginx/sites-available/fitfoodpk
sudo nginx -t && sudo systemctl reload nginx
```

### 场景 D：更新了 systemd 服务文件

```bash
cp /root/fitfoodpk/server/fitfoodpk.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl restart fitfoodpk
```

### 场景 E：更新了 iOS 端

iOS 端改动不影响服务器，正常在 Xcode 改代码 → 提交 GitHub → 装真机即可。

---

## 三、常用运维命令

### 服务管理
```bash
sudo systemctl start fitfoodpk       # 启动
sudo systemctl stop fitfoodpk        # 停止
sudo systemctl restart fitfoodpk     # 重启
sudo systemctl status fitfoodpk      # 查看状态
```

### 查看日志
```bash
# 实时日志（Ctrl+C 退出）
sudo journalctl -u fitfoodpk -f

# 最近 50 行
sudo journalctl -u fitfoodpk -n 50 --no-pager

# 今天的日志
sudo journalctl -u fitfoodpk --since today --no-pager

# nginx 错误日志
sudo tail -20 /var/log/nginx/error.log

# API 结构化日志
cat /opt/fitfoodpk/server/logs/api_*.json.log | tail -20
```

### 数据库
```bash
# 登录数据库
sudo -u postgres psql -d fitfoodpk

# 查看用户数
sudo -u postgres psql -d fitfoodpk -c "SELECT COUNT(*) FROM users;"

# 手动备份
sudo bash /opt/fitfoodpk/server/backup.sh
```

### HTTPS 证书续期
```bash
# 证书有效期查看
sudo certbot certificates

# 手动续期（certbot 已配置自动续期，通常不用手动）
sudo certbot renew
```

---

## 四、常见问题排查

### Q1：服务启动失败（active: failed）

查日志定位：
```bash
sudo journalctl -u fitfoodpk -n 30 --no-pager
```

常见原因：
- **PermissionError（权限）**：`chown -R www-data:www-data /opt/fitfoodpk`
- **数据库密码不对**：参考下方 Q2
- **Python 依赖缺失**：`cd /opt/fitfoodpk/server && .venv/bin/pip install -r requirements.txt`

### Q2：数据库密码认证失败

部署脚本每次重跑会生成新密码，但 PostgreSQL 里还是旧的。解决：

```bash
# 1. 看 .env 里的密码
grep "^DATABASE_URL=" /opt/fitfoodpk/server/.env
# 输出类似：postgresql://fitfoodpk:密码@localhost:5432/fitfoodpk

# 2. 把密码同步到 PostgreSQL（用 .env 里的密码替换）
sudo -u postgres psql -c "ALTER USER fitfoodpk WITH PASSWORD '.env里的密码';"

# 3. 重启
sudo systemctl restart fitfoodpk
```

### Q3：公网访问报 500

```bash
# 看 nginx 错误日志
sudo tail -20 /var/log/nginx/error.log
```

如果是 `rewrite or internal redirection cycle`：
```bash
# 修复 try_files 死循环（前端目录不存在时不重定向到 /index.html）
sudo sed -i 's/try_files $uri $uri\/ \/index.html;/try_files $uri $uri\/ =404;/' /etc/nginx/sites-available/fitfoodpk
sudo nginx -t && sudo systemctl reload nginx
```

### Q4：AI 识别报 404（food_recognize 内部错误）

火山方舟的对话/视觉模型必须用**推理接入点 ID**（`ep-xxxx`），不能用模型名。

```bash
# 确认 .env 里的 VLM_MODEL 是接入点 ID
grep "^VLM_MODEL=" /opt/fitfoodpk/server/.env
# 应该是 ep-xxxxxxxx-xxxxx，不是 doubao-xxx
```

如果不对，去火山方舟控制台创建/查看接入点：
https://console.volcengine.com/ark/region:ark+cn-beijing/endpoint

### Q5：HTTPS 证书过期

证书有效期 90 天，certbot 已配置自动续期。如果收到过期告警：

```bash
sudo certbot renew && sudo systemctl reload nginx
```

### Q6：git pull 报冲突（服务器有本地改动）

服务器上不应手动改代码，所有改动从 GitHub 拉。如果有本地改动导致冲突：

```bash
cd /root/fitfoodpk
git checkout -- .        # 丢弃本地改动
git pull                 # 重新拉取
```

---

## 五、安全注意事项

1. **`.env` 文件绝不提交 GitHub**（已在 .gitignore 排除）
2. **JWT_SECRET 必须是随机值**（用 `openssl rand -hex 32` 生成）
3. **火山方舟 API Key 只存在服务器 `.env`**，iOS 端通过后端代理调用
4. **定期更新系统**：`sudo apt update && sudo apt upgrade`
5. **数据库自动备份**已配置（每天 03:00），备份文件在 `/opt/fitfoodpk/backups`
6. **ECS 安全组**只开放 22/80/443，不要开其他端口

---

## 六、iOS 真机测试配置

### 当前配置（内测期间）
iOS DEBUG 真机分支已指向生产服务器：
- 代码位置：`ios/FoodSticker/Cloud/CloudAPI.swift`
- `#else` 分支：`https://www.rubyace.love`（临时内测用）

### 内测结束后改回局域网联调
把 `#else` 分支改回 Mac 的局域网 IP：
```swift
return URL(string: "http://你的Mac局域网IP:8000")!
```
查询 Mac IP：终端执行 `ifconfig en0 | grep inet`

### Release 构建（上架用）
`#else` 分支已固定为 `https://www.rubyace.love`，不需要改。
