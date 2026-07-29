"""
数据层：SQLAlchemy 模型 + SQLite + 初始化与种子数据
迁移目标：承接原 Web 端 zustand store 的 mock 数据（用户/搭档/PK/记录/贴纸墙），
使 iOS 原生端可拉取真实数据、并持久化用户行为。
"""
import os
import hashlib
from datetime import datetime

from sqlalchemy import (
    create_engine, Column, String, Float, Integer, ForeignKey, Text, DateTime,
)
from sqlalchemy.orm import declarative_base, sessionmaker

BASE_DIR = os.path.dirname(__file__)
DB_PATH = os.path.join(BASE_DIR, "foodsticker.db")

engine = create_engine(
    f"sqlite:///{DB_PATH}",
    connect_args={"check_same_thread": False},
)
SessionLocal = sessionmaker(bind=engine, autoflush=False)
Base = declarative_base()


# ─────────────────────── 模型（对齐 Web store.ts / iOS AppDataStore） ───────────────────────
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
    image_b64 = Column(Text, default="")        # 透明 PNG base64
    created_at = Column(DateTime, default=datetime.utcnow)


class PKWeek(Base):
    __tablename__ = "pk_weeks"
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    partner_id = Column(String, nullable=True)
    start_date = Column(String, default="")
    days = Column(Integer, default=0)


# ─────────────────────── 工具 ───────────────────────
def _hash(pwd: str) -> str:
    return hashlib.sha256(pwd.encode("utf-8")).hexdigest()


def init_db() -> None:
    Base.metadata.create_all(engine)
    _seed()


def _seed() -> None:
    with SessionLocal() as s:
        if s.query(User).first():
            return

        u1 = User(id="user-1", name="小明", avatar="👦", current_weight=72.5,
                  target_weight=65, height=175, password_hash=_hash("123456"),
                  partner_id="user-2")
        u2 = User(id="user-2", name="小红", avatar="👧", current_weight=59.2,
                  target_weight=55, height=165, password_hash=_hash("123456"),
                  partner_id="user-1")
        s.add_all([u1, u2])

        s.add(PKWeek(id="pk-1", user_id="user-1", partner_id="user-2",
                     start_date="2026-07-01", days=15))

        # 对齐 Web 端 mockRecords（user-1）
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
            # partner 的对比数据（user-2）
            ("p1", "user-2", "food", "全麦面包", 180, 2, "片", "08:00"),
            ("p2", "user-2", "food", "蒸蛋", 90, 1, "个", "08:10"),
            ("p3", "user-2", "exercise", "瑜伽", 120, 30, "min", "19:00"),
            ("p4", "user-2", "water", "柠檬水", 0, 300, "ml", "10:00"),
        ]
        for rid, uid, rtype, name, cal, amt, unit, t in seed_records:
            s.add(Record(id=rid, user_id=uid, type=rtype, name=name,
                         calories=cal, amount=amt, unit=unit, time=t))

        s.commit()
