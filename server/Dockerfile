FROM python:3.11-slim

WORKDIR /app

# 系统依赖（OpenCV + PostgreSQL 客户端库）
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev libgomp1 \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# 贴纸存储 + 备份目录
RUN mkdir -p /app/stickers /app/backups

# 复制 Alembic 迁移文件
COPY migrations /app/migrations
COPY alembic.ini /app/

EXPOSE 8000

# 启动前自动运行数据库迁移
CMD sh -c "alembic upgrade head && uvicorn main:app --host 0.0.0.0 --port 8000"
