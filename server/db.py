"""
数据层：SQLAlchemy 模型 + PostgreSQL（生产）/ SQLite（开发）+ 初始化与种子数据
迁移目标：承接原 Web 端 zustand store 的 mock 数据，使 iOS 原生端可拉取真实数据、并持久化用户行为。

读写分离：配置 DB_READ_URL 后，写走主库、读走副本库，自动路由。
"""
import os
from datetime import datetime

import bcrypt
from sqlalchemy import (
    create_engine, Column, String, Float, Integer, ForeignKey, Text, DateTime, event,
)
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from sqlalchemy.pool import NullPool

# ── 数据库连接：生产用 PostgreSQL，开发默认 SQLite ──
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    f"sqlite:///{os.path.join(os.path.dirname(__file__), 'foodsticker.db')}",
)
DATABASE_READ_URL = os.getenv("DB_READ_URL", "")  # 只读副本 URL（可选）


def _engine(url: str, *, read_only: bool = False) -> tuple:
    """创建 SQLAlchemy 引擎"""
    connect_args = {}
    engine_kwargs = {}

    if url.startswith("sqlite"):
        connect_args = {"check_same_thread": False}
    else:
        # ── PostgreSQL 连接池调优 ──
        # 读副本连接数可少一些（只分担查询）
        pool_size_key = "DB_READ_POOL_SIZE" if read_only else "DB_POOL_SIZE"
        overflow_key = "DB_READ_MAX_OVERFLOW" if read_only else "DB_MAX_OVERFLOW"
        engine_kwargs = {
            "pool_size": int(os.getenv(pool_size_key, "10" if read_only else "20")),
            "max_overflow": int(os.getenv(overflow_key, "5" if read_only else "10")),
            "pool_recycle": int(os.getenv("DB_POOL_RECYCLE", "3600")),
            "pool_timeout": int(os.getenv("DB_POOL_TIMEOUT", "30")),
            "pool_pre_ping": True,
        }

    eng = create_engine(url, connect_args=connect_args, **engine_kwargs)
    return eng


# 主库引擎（写 + 强一致读）
engine = _engine(DATABASE_URL)

# 只读副本引擎（可选）
read_engine = _engine(DATABASE_READ_URL, read_only=True) if DATABASE_READ_URL else None

SessionLocal = sessionmaker(bind=engine, autoflush=False)

# 只读会话工厂
ReadSessionLocal = sessionmaker(bind=read_engine, autoflush=False) if read_engine else None

Base = declarative_base()


def get_read_session() -> Session:
    """获取只读会话（有副本走副本，无副本走主库）"""
    if ReadSessionLocal:
        return ReadSessionLocal()
    return SessionLocal()


# ─────────────────────── 模型 ───────────────────────
class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    avatar = Column(String, default="🙂")
    current_weight = Column(Float, default=0)
    target_weight = Column(Float, default=0)
    height = Column(Float, default=0)
    password_hash = Column(String, default="")
    partner_id = Column(String, nullable=True)


class Record(Base):
    __tablename__ = "records"
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    type = Column(String, nullable=False)        # food | exercise | water | weight
    name = Column(String, default="")
    calories = Column(Float, default=0)
    amount = Column(Float, default=0)
    unit = Column(String, default="")
    time = Column(String, default="")            # HH:MM
    created_at = Column(DateTime, default=datetime.utcnow)


class Sticker(Base):
    __tablename__ = "stickers"
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String, default="")
    image_b64 = Column(Text, default="")          # 兼容旧数据，新贴纸存文件系统
    image_path = Column(String, default="")        # 贴纸文件路径（生产环境使用）
    created_at = Column(DateTime, default=datetime.utcnow)


class PKWeek(Base):
    __tablename__ = "pk_weeks"
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    partner_id = Column(String, nullable=True)
    start_date = Column(String, default="")
    days = Column(Integer, default=0)


# ─────────────────────── 密码工具（bcrypt，生产安全） ───────────────────────
def hash_password(password: str) -> str:
    """bcrypt 哈希，自动加盐，适合公网用户密码存储"""
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, hashed: str) -> bool:
    """验证密码是否匹配"""
    return bcrypt.checkpw(password.encode("utf-8"), hashed.encode("utf-8"))


# 兼容旧代码别名（内部还在引用 _hash）
def _hash(pwd: str) -> str:
    return hash_password(pwd)


# ─────────────────────── 初始化（Alembic 迁移优先） ───────────────────────
def init_db() -> None:
    """初始化数据库：优先使用 Alembic 迁移，降级则用 create_all"""
    try:
        from alembic.config import Config
        from alembic import command
        alembic_cfg = Config(os.path.join(os.path.dirname(__file__), "alembic.ini"))
        # 将 DATABASE_URL 注入 alembic 配置
        alembic_cfg.set_main_option("sqlalchemy.url", DATABASE_URL)
        command.upgrade(alembic_cfg, "head")
        print("[db] Alembic 迁移完成")
    except Exception as e:
        print(f"[db] Alembic 迁移失败，降级为 create_all: {e}")
        Base.metadata.create_all(engine)
    _seed()


def _seed() -> None:
    with SessionLocal() as s:
        if s.query(User).first():
            return

        u1 = User(id="user-1", name="小明", avatar="👦", current_weight=72.5,
                  target_weight=65, height=175, password_hash=hash_password("123456"),
                  partner_id="user-2")
        u2 = User(id="user-2", name="小红", avatar="👧", current_weight=59.2,
                  target_weight=55, height=165, password_hash=hash_password("123456"),
                  partner_id="user-1")
        s.add_all([u1, u2])

        s.add(PKWeek(id="pk-1", user_id="user-1", partner_id="user-2",
                     start_date="2026-07-01", days=15))

        seed_records = [
            ("1", "user-1", "food", "燕麦粥", 150, 200, "g", "07:30"),
            ("2", "user-1", "food", "水煮蛋", 70, 1, "个", "07:35"),
            ("3", "user-1", "food", "鸡胸肉沙拉", 320, 300, "g", "12:00"),
            ("4", "user-1", "exercise", "跑步", 350, 5, "km", "08:00"),
            ("5", "user-1", "exercise", "力量训练", 130, 40, "min", "18:30"),
            ("6", "user-1", "water", "白开水", 0, 250, "ml", "07:00"),
            ("7", "user-1", "water", "白开水", 0, 250, "ml", "09:00"),
            ("8", "user-1", "water", "白开水", 0, 250, "ml", "11:00"),
            ("9", "user-1", "water", "白开水", 0, 250, "ml", "14:00"),
            ("10", "user-1", "water", "白开水", 0, 250, "ml", "16:00"),
            ("11", "user-1", "weight", "体重", 0, 72.5, "kg", "07:00"),
            ("p1", "user-2", "food", "全麦面包", 180, 2, "片", "08:00"),
            ("p2", "user-2", "food", "蒸蛋", 90, 1, "个", "08:10"),
            ("p3", "user-2", "exercise", "瑜伽", 120, 30, "min", "19:00"),
            ("p4", "user-2", "water", "柠檬水", 0, 300, "ml", "10:00"),
        ]
        for rid, uid, rtype, name, cal, amt, unit, t in seed_records:
            s.add(Record(id=rid, user_id=uid, type=rtype, name=name,
                         calories=cal, amount=amt, unit=unit, time=t))

        s.commit()
