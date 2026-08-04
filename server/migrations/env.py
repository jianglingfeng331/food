"""
Alembic 迁移环境配置
从环境变量 DATABASE_URL 读取数据库连接，自动发现 db.py 中的所有模型。
"""
import os
import sys
from logging.config import fileConfig

# 把 server 目录加入 sys.path，确保能 import db
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from alembic import context
from sqlalchemy import engine_from_config, pool

from db import Base  # noqa: F401 — 确保所有模型被导入

# ── Alembic Config 对象 ──
config = context.config
if config.config_file_name:
    fileConfig(config.config_file_name)

# ── 从环境变量读取数据库 URL（生产 PostgreSQL / 开发 SQLite） ──
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    f"sqlite:///{os.path.join(os.path.dirname(os.path.dirname(__file__)), 'foodsticker.db')}",
)
config.set_main_option("sqlalchemy.url", DATABASE_URL)

# ── 元数据（自动发现 db.py 中所有 Base 子类） ──
target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """离线模式：生成 SQL 脚本（不连数据库）"""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """在线模式：直接连接数据库执行迁移"""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            # SQLite 不支持 ALTER，用 batch 模式
            render_as_batch=bool(DATABASE_URL.startswith("sqlite")),
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
