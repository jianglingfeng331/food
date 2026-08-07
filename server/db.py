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
# 注意：os.getenv 在环境变量被显式设为空字符串（如 .env 中 DATABASE_URL=）时
# 会返回 "" 而非默认值，因此需对空值做回退，否则 create_engine("") 会崩溃。
_DEFAULT_SQLITE = f"sqlite:///{os.path.join(os.path.dirname(__file__), 'foodsticker.db')}"
_database_url = os.getenv("DATABASE_URL")
DATABASE_URL = _database_url.strip() if _database_url and _database_url.strip() else _DEFAULT_SQLITE
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
    phone = Column(String, nullable=True, unique=True, index=True)  # 手机号（短信验证码体系）
    username = Column(String, nullable=True, unique=True, index=True)  # 账号登录标识（不可预测，与 id 解耦）
    partner_id = Column(String, nullable=True)
    avatar_b64 = Column(Text, default="")  # 图片头像（base64 JPEG），为空时回退 emoji avatar


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
    image_path = Column(String, default="")       # 食物图片文件路径（存储在 FOOD_IMAGES_DIR）
    # 营养成分与小贴士（食物记录携带，供对方查看详情时展示）
    protein_g = Column(Float, default=0)
    carb_g = Column(Float, default=0)
    fat_g = Column(Float, default=0)
    dietary_fiber_g = Column(Float, default=0)
    sugar_g = Column(Float, default=0)
    sodium_mg = Column(Float, default=0)
    vitamin_tips = Column(Text, default="")


class Sticker(Base):
    __tablename__ = "stickers"
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String, default="")
    image_b64 = Column(Text, default="")          # 兼容旧数据，新贴纸存文件系统
    image_path = Column(String, default="")        # 贴纸文件路径（生产环境使用）
    created_at = Column(DateTime, default=datetime.utcnow)
    # 营养/贴士字段（多设备同步需要）
    kcal_per_100g = Column(Float, default=0)
    protein_g = Column(Float, default=0)
    carb_g = Column(Float, default=0)
    fat_g = Column(Float, default=0)
    dietary_fiber_g = Column(Float, default=0)
    sodium_mg = Column(Float, default=0)
    typical_portion_g = Column(Float, default=0)
    vitamin_tips = Column(Text, default="")


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
def _ensure_phone_column() -> None:
    """兼容已部署库：若 users 表缺少 phone 列则自动补齐（无需手写迁移）"""
    import sqlalchemy
    insp = sqlalchemy.inspect(engine)
    cols = {c["name"] for c in insp.get_columns("users")}
    if "phone" in cols:
        return
    with engine.begin() as conn:
        if engine.dialect.name == "sqlite":
            conn.execute(sqlalchemy.text("ALTER TABLE users ADD COLUMN phone VARCHAR"))
        else:
            conn.execute(sqlalchemy.text("ALTER TABLE users ADD COLUMN phone VARCHAR UNIQUE"))
    print("[db] 已自动补齐 users.phone 列")


def _ensure_username_column() -> None:
    """兼容已部署库：补齐 username 列，并把老账号密码用户（id 即账号）回填。

    旧版账号密码体系 user.id 直接等于用户填写的账号（可预测、且暴露在二维码中）。
    新版改为 id=随机 UUID、username=账号登录标识。此处为已上线库做平滑迁移。
    """
    import sqlalchemy
    insp = sqlalchemy.inspect(engine)
    cols = {c["name"] for c in insp.get_columns("users")}
    if "username" in cols:
        # 列已存在：回填老数据中 username 为空的账号密码用户（id 不含 u_ 前缀的旧账号）
        with SessionLocal() as s:
            rows = s.query(User).filter(User.username == None).all()  # noqa: E711
            for u in rows:
                if not (u.id or "").startswith("u_"):
                    u.username = u.id  # 旧账号密码用户：账号即原 id
            s.commit()
        return
    with engine.begin() as conn:
        if engine.dialect.name == "sqlite":
            conn.execute(sqlalchemy.text("ALTER TABLE users ADD COLUMN username VARCHAR"))
        else:
            conn.execute(sqlalchemy.text("ALTER TABLE users ADD COLUMN username VARCHAR UNIQUE"))
    print("[db] 已自动补齐 users.username 列")
    # 新库或列刚建好：回填老账号密码用户
    with SessionLocal() as s:
        rows = s.query(User).filter(User.username == None).all()  # noqa: E711
        for u in rows:
            if not (u.id or "").startswith("u_"):
                u.username = u.id
        s.commit()


def _ensure_image_path_column() -> None:
    """兼容已部署库：若 records 表缺少 image_path 列则自动补齐（食物图片云端存储）"""
    import sqlalchemy
    insp = sqlalchemy.inspect(engine)
    cols = {c["name"] for c in insp.get_columns("records")}
    if "image_path" in cols:
        return
    with engine.begin() as conn:
        conn.execute(sqlalchemy.text("ALTER TABLE records ADD COLUMN image_path VARCHAR DEFAULT ''"))
    print("[db] 已自动补齐 records.image_path 列")


def _ensure_record_nutrition_columns() -> None:
    """兼容已部署库：补齐 records 表的营养/贴士列"""
    import sqlalchemy
    insp = sqlalchemy.inspect(engine)
    cols = {c["name"] for c in insp.get_columns("records")}
    needed = [
        ("protein_g", "FLOAT DEFAULT 0"),
        ("carb_g", "FLOAT DEFAULT 0"),
        ("fat_g", "FLOAT DEFAULT 0"),
        ("dietary_fiber_g", "FLOAT DEFAULT 0"),
        ("sugar_g", "FLOAT DEFAULT 0"),
        ("sodium_mg", "FLOAT DEFAULT 0"),
        ("vitamin_tips", "TEXT DEFAULT ''"),
    ]
    any_added = False
    with engine.begin() as conn:
        for cname, cdef in needed:
            if cname not in cols:
                conn.execute(sqlalchemy.text(f"ALTER TABLE records ADD COLUMN {cname} {cdef}"))
                any_added = True
    if any_added:
        print("[db] 已自动补齐 records 营养/贴士列")


def _ensure_user_avatar_b64_column() -> None:
    """兼容已部署库：若 users 表缺少 avatar_b64 列则自动补齐（图片头像同步）"""
    import sqlalchemy
    insp = sqlalchemy.inspect(engine)
    cols = {c["name"] for c in insp.get_columns("users")}
    if "avatar_b64" in cols:
        return
    with engine.begin() as conn:
        conn.execute(sqlalchemy.text("ALTER TABLE users ADD COLUMN avatar_b64 TEXT DEFAULT ''"))
    print("[db] 已自动补齐 users.avatar_b64 列")


def _ensure_sticker_image_path_column() -> None:
    """兼容已部署库：若 stickers 表缺少 image_path 列则自动补齐"""
    import sqlalchemy
    insp = sqlalchemy.inspect(engine)
    cols = {c["name"] for c in insp.get_columns("stickers")}
    if "image_path" in cols:
        return
    with engine.begin() as conn:
        conn.execute(sqlalchemy.text("ALTER TABLE stickers ADD COLUMN image_path VARCHAR DEFAULT ''"))
    print("[db] 已自动补齐 stickers.image_path 列")


def _ensure_sticker_nutrition_columns() -> None:
    """兼容已部署库：补齐 stickers 表的营养/贴士列"""
    import sqlalchemy
    insp = sqlalchemy.inspect(engine)
    cols = {c["name"] for c in insp.get_columns("stickers")}
    needed = [
        ("kcal_per_100g", "FLOAT DEFAULT 0"),
        ("protein_g", "FLOAT DEFAULT 0"),
        ("carb_g", "FLOAT DEFAULT 0"),
        ("fat_g", "FLOAT DEFAULT 0"),
        ("dietary_fiber_g", "FLOAT DEFAULT 0"),
        ("sodium_mg", "FLOAT DEFAULT 0"),
        ("typical_portion_g", "FLOAT DEFAULT 0"),
        ("vitamin_tips", "TEXT DEFAULT ''"),
    ]
    any_added = False
    with engine.begin() as conn:
        for cname, cdef in needed:
            if cname not in cols:
                conn.execute(sqlalchemy.text(f"ALTER TABLE stickers ADD COLUMN {cname} {cdef}"))
                any_added = True
    if any_added:
        print("[db] 已自动补齐 stickers 营养/贴士列")


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
    _ensure_phone_column()
    _ensure_user_avatar_b64_column()   # 必须在 _ensure_username 之前：后者执行 ORM 查询
    _ensure_username_column()
    _ensure_image_path_column()
    _ensure_record_nutrition_columns()
    _ensure_sticker_image_path_column()
    _ensure_sticker_nutrition_columns()
    _seed()


def _seed() -> None:
    # 正式用户体系：默认不预置演示账号。
    # 需要本地开发演示数据时，设置环境变量 FF_ENABLE_SEED=1 后重启服务。
    if os.getenv("FF_ENABLE_SEED") != "1":
        return

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
