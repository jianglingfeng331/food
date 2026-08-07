"""
云端兜底服务（FastAPI）
  POST /sticker/hd       高清贴纸：SD img2img + ControlNet Canny 锁轮廓 → 复用Alpha抠白底
  POST /food/recognize   冷门食品识别：多模态大模型 → 名称+分量+营养（一步返回）
  POST /food/nutrition   按名称查营养（用户手动修正兜底）

依赖: pip install -r requirements.txt
启动: uvicorn main:app --host 0.0.0.0 --port 8000
"""
import base64
import io
import json
import os
import uuid
import time
from datetime import datetime, timedelta, timezone

# 中国标准时间（UTC+8）
CHINA_TZ = timezone(timedelta(hours=8))
from typing import Optional

import cv2
import httpx
import jwt
import numpy as np
import sqlalchemy
from sqlalchemy import select
from fastapi import Depends, FastAPI, Header, HTTPException, Request
from loguru import logger
from PIL import Image
from prometheus_fastapi_instrumentator import Instrumentator
from pydantic import BaseModel
from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from starlette.responses import JSONResponse

from db import SessionLocal, get_read_session, User, Record, Sticker, PKWeek, init_db, hash_password, verify_password
from sms import send_code as sms_send_code, verify_code as sms_verify_code, is_valid_phone as sms_is_valid_phone
from cache import cached, cache_invalidate, cache_get, cache_set
from dotenv import load_dotenv
from logging_config import setup_logging

# ── 加载 .env ──
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

# ── 结构化日志 ──
setup_logging()

init_db()

# ── CDN 配置（贴纸图片） ──
CDN_BASE_URL = os.getenv("CDN_BASE_URL", "").rstrip("/")

# ── 限流器（自动检测 Redis，可用则升级为分布式限流） ──
_redis_url = os.getenv("REDIS_URL", "")
if _redis_url:
    try:
        import redis as _r
        _redis_conn = _r.from_url(_redis_url, socket_timeout=2)
        _redis_conn.ping()
        from slowapi.extension import _get_redis_backend
        limiter = Limiter(key_func=get_remote_address, storage_uri=_redis_url)
        logger.info("限流器已升级为 Redis 分布式模式")
    except Exception as e:
        logger.warning(f"Redis 不可用，降级为内存限流: {e}")
        limiter = Limiter(key_func=get_remote_address)
else:
    limiter = Limiter(key_func=get_remote_address)

app = FastAPI(title="FoodSticker Cloud")
app.state.limiter = limiter

# ── Prometheus 指标采集 ──
Instrumentator().instrument(app).expose(app, include_in_schema=False)


@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request: Request, exc: RateLimitExceeded) -> JSONResponse:
    return JSONResponse(
        status_code=429,
        content={"detail": "请求过于频繁，请稍后再试"},
    )

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """全局异常处理器，捕获所有未处理的异常"""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": f"服务器内部错误: {str(exc)[:200]}"},
    )


# ── 请求日志中间件 ──
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start
    logger.info(
        f"{request.method} {request.url.path} → {response.status_code} ({duration:.3f}s)",
        status_code=response.status_code,
        duration_ms=round(duration * 1000),
    )
    return response


# ── 健康检查（供 Nginx / 负载均衡 / Kubernetes 探针使用） ──
@app.get("/health")
def health():
    return {"status": "ok", "service": "fitfoodpk"}

SD_BASE = os.getenv("SD_BASE_URL", "http://127.0.0.1:7860")
VLM_BASE = os.getenv("VLM_BASE_URL", "")
VLM_KEY = os.getenv("VLM_API_KEY", "")
VLM_MODEL = os.getenv("VLM_MODEL", "hunyuan-vision")

# 火山方舟图生图（seedream）—— 独立配置，默认复用 VLM_BASE / VLM_API_KEY
ARK_BASE = os.getenv("ARK_BASE_URL") or VLM_BASE
ARK_KEY = os.getenv("ARK_API_KEY") or VLM_KEY
ARK_SD_MODEL = os.getenv("ARK_SD_MODEL", "doubao-seedream-4-0-251215")

# ─────────────────────── 鉴权（JWT，承接原 mock 用户体系） ───────────────────────
# 默认密钥仅用于本地开发/测试；生产务必通过 JWT_SECRET 环境变量配置至少 32 字节的随机值
SECRET = os.getenv("JWT_SECRET", "dev-only-insecure-secret-please-override-32bytes-min")
ALGO = "HS256"
TARGET_KCAL = 0  # 默认每日热量目标为 0（不塞假数据），由用户在资料页自行设置


def _create_token(user_id: str) -> str:
    exp = datetime.utcnow() + timedelta(days=30)
    return jwt.encode({"sub": user_id, "exp": exp}, SECRET, algorithm=ALGO)


def get_current_user(authorization: str = Header(None)) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="missing token")
    try:
        payload = jwt.decode(authorization[7:], SECRET, algorithms=[ALGO])
    except Exception:
        raise HTTPException(status_code=401, detail="invalid token")
    with SessionLocal() as s:
        u = s.get(User, payload["sub"])
    if not u:
        raise HTTPException(status_code=401, detail="user not found")
    return u


def _user_dict(u: User) -> dict:
    return {
        "id": u.id, "name": u.name, "avatar": u.avatar,
        "avatar_b64": u.avatar_b64 or "",
        "username": u.username or "",
        "currentWeight": u.current_weight, "targetWeight": u.target_weight,
        "height": u.height,
    }


def _cutoff_for_days(days: int) -> datetime:
    """返回 days 过滤的截止 UTC 时间（以 UTC+8 自然天零点对齐）。

    days=1 → 今天 UTC+8 零点；days=7 → 7 天前 UTC+8 零点。
    created_at 存的是 UTC，故需将本地零点转为 UTC 后再比较。
    """
    now_local = datetime.now(CHINA_TZ)
    local_midnight = now_local.replace(hour=0, minute=0, second=0, microsecond=0)
    cutoff_local = local_midnight - timedelta(days=days - 1)
    # UTC+8 → UTC 朴素时间：减去 8 小时
    return cutoff_local.replace(tzinfo=None) - timedelta(hours=8)


def _aggregate(s, uid: str, days: int = 0) -> dict:
    q = s.query(Record).filter(Record.user_id == uid)
    if days > 0:
        q = q.filter(Record.created_at >= _cutoff_for_days(days))
    recs = q.all()
    intake = sum(r.calories for r in recs if r.type == "food")
    burned = sum(r.calories for r in recs if r.type == "exercise")
    target = TARGET_KCAL
    return {
        "intake": intake, "burned": burned,
        "remaining": target - intake + burned, "target": target,
    }


def _records_list(s, uid: str, days: int = 0) -> list:
    q = s.query(Record).filter(Record.user_id == uid)
    # 可选日期过滤：仅返回最近 N 天的记录，避免全量返回（PK 接口场景下对方历史数据量可能很大）
    if days > 0:
        q = q.filter(Record.created_at >= _cutoff_for_days(days))
    result = []
    for r in q.order_by(Record.created_at.desc()).all():
        # created_at 存的是 UTC 时间，需转 UTC+8 后输出日期，避免北京时间 0-8 点
        # 的记录日期落后一天（例如凌晨 2 点的记录显示为昨天的日期）
        local_dt = r.created_at.replace(tzinfo=timezone.utc).astimezone(CHINA_TZ) if r.created_at else datetime.now(CHINA_TZ)
        rec = {"id": r.id, "type": r.type, "name": r.name, "calories": r.calories,
               "amount": r.amount, "unit": r.unit, "time": r.time,
               "date": local_dt.strftime("%Y-%m-%d"),
               "protein_g": r.protein_g or 0,
               "carb_g": r.carb_g or 0,
               "fat_g": r.fat_g or 0,
               "dietary_fiber_g": r.dietary_fiber_g or 0,
               "sugar_g": r.sugar_g or 0,
               "sodium_mg": r.sodium_mg or 0,
               "vitamin_tips": r.vitamin_tips or ""}
        # 食物记录附带图片（对方可借此看到拍摄/预设图片）
        if r.type == "food" and r.image_path:
            img_path = os.path.join(FBASE, r.image_path)
            if os.path.exists(img_path):
                with open(img_path, "rb") as f:
                    rec["image_b64"] = base64.b64encode(f.read()).decode()
        result.append(rec)
    return result


# ─────────────────────── 业务接口：登录 / 用户 / 仪表盘 / 记录 / PK / 贴纸 ───────────────────────
class LoginReq(BaseModel):
    user_id: str
    password: str


class RegisterReq(BaseModel):
    user_id: str
    password: str
    name: Optional[str] = None
    avatar: Optional[str] = None


@app.post("/auth/login")
@limiter.limit("5/minute")  # 防暴力破解
def auth_login(req: LoginReq, request: Request = None):
    with SessionLocal() as s:
        # 账号密码体系按 username 查；手机号体系按 phone 查（id 已与登录标识解耦）
        u = (s.query(User).filter(User.username == req.user_id).first()
             or s.query(User).filter(User.phone == req.user_id).first())
        if not u:
            raise HTTPException(status_code=401, detail="用户名或密码错误")

        # 兼容旧 SHA256 密码和新 bcrypt 密码
        h = u.password_hash
        ok = False
        if h.startswith("$2") and len(h) >= 50:
            # 新 bcrypt 格式
            ok = verify_password(req.password, h)
        else:
            # 旧 SHA256 格式（向后兼容）
            import hashlib
            ok = (h == hashlib.sha256(req.password.encode("utf-8")).hexdigest())

        if not ok:
            raise HTTPException(status_code=401, detail="用户名或密码错误")
        return {"token": _create_token(u.id), "user": _user_dict(u)}


@app.post("/auth/register")
@limiter.limit("5/minute")  # 防接口滥用
def auth_register(req: RegisterReq, request: Request = None):
    user_id = req.user_id.strip()
    if not user_id or len(user_id) < 3:
        raise HTTPException(status_code=400, detail="账号至少 3 个字符")
    if not req.password or len(req.password) < 6:
        raise HTTPException(status_code=400, detail="密码至少 6 位")

    with SessionLocal() as s:
        if s.query(User).filter(User.username == user_id).first():
            raise HTTPException(status_code=409, detail="该账号已被注册")
        u = User(
            id=str(uuid.uuid4()),
            username=user_id,
            password_hash=hash_password(req.password),
            name=req.name or ("用户" + user_id[-4:]),
            avatar=req.avatar or "🙂",
        )
        s.add(u)
        s.commit()
        s.refresh(u)
        return {"token": _create_token(u.id), "user": _user_dict(u)}


@app.get("/user/me")
def user_me(u: User = Depends(get_current_user)):
    return _user_dict(u)


class ChangePasswordReq(BaseModel):
    new_password: str


@app.post("/auth/change-password")
@limiter.limit("10/minute")
def auth_change_password(req: ChangePasswordReq, request: Request = None,
                         u: User = Depends(get_current_user)):
    """修改当前登录用户的登录密码（需鉴权）。"""
    if not req.new_password or len(req.new_password) < 6:
        raise HTTPException(status_code=400, detail="密码至少 6 位")
    with SessionLocal() as s:
        cur = s.get(User, u.id)
        cur.password_hash = hash_password(req.new_password)
        s.commit()
    return {"ok": True}


@app.delete("/auth/account")
@limiter.limit("3/minute")
def auth_delete_account(request: Request = None,
                        u: User = Depends(get_current_user)):
    """删除当前登录用户的账号及全部数据（需鉴权）。

    清理范围：records / stickers / pk_weeks + 解除 PK 绑定 + 删除用户本体。
    满足 App Store 审核 5.1.1(v) 对账号删除功能的要求。
    """
    with SessionLocal() as s:
        # 解除 PK 绑定（双向清空 partner_id）
        if u.partner_id:
            partner = s.get(User, u.partner_id)
            if partner:
                partner.partner_id = None
        # 删除用户产生的全部业务数据
        s.query(Record).filter(Record.user_id == u.id).delete()
        s.query(Sticker).filter(Sticker.user_id == u.id).delete()
        s.query(PKWeek).filter(PKWeek.user_id == u.id).delete()
        s.delete(u)
        s.commit()
    return {"ok": True}


# ─────────────────────── 手机号 + 短信验证码体系 ───────────────────────
class SendCodeReq(BaseModel):
    phone: str


class PhoneCodeReq(BaseModel):
    phone: str
    code: str


class PhoneRegisterReq(BaseModel):
    phone: str
    code: str
    password: Optional[str] = None   # 可选：设置登录密码
    nickname: Optional[str] = None


@app.post("/auth/send-code")
@limiter.limit("20/minute")
def auth_send_code(req: SendCodeReq, request: Request = None):
    """发送短信验证码（Mock 模式打印到服务端日志）。限流 + 单号日上限在 sms 层处理。"""
    try:
        sms_send_code(req.phone)
    except ValueError as e:
        if str(e) == "invalid_phone":
            raise HTTPException(status_code=400, detail="手机号格式不正确")
        if str(e) == "daily_limit":
            raise HTTPException(status_code=429, detail="今日验证码发送次数已达上限")
        if str(e) == "too_frequent":
            raise HTTPException(status_code=429, detail="操作过于频繁，请稍后再试")
        raise HTTPException(status_code=400, detail="发送失败")
    return {"ok": True}


@app.post("/auth/login-by-phone")
@limiter.limit("10/minute")
def auth_login_by_phone(req: PhoneCodeReq, request: Request = None):
    """短信验证码登录：验证通过后，若手机号未注册则自动创建账号（即验即注册）。

    这样登录页的验证码流程对老用户直接登录、新用户自动开通，无需二次跳转。
    """
    try:
        sms_verify_code(req.phone, req.code)
    except ValueError as e:
        if str(e) == "code_expired":
            raise HTTPException(status_code=400, detail="验证码已过期，请重新获取")
        if str(e) == "wrong_code":
            raise HTTPException(status_code=400, detail="验证码错误")
        raise HTTPException(status_code=400, detail="验证码校验失败")
    with SessionLocal() as s:
        u = s.query(User).filter(User.phone == req.phone).first()
        if not u:
            # 自动注册（验证码已校验通过，无需重复校验）
            u = User(id=str(uuid.uuid4()), name=f"用户{req.phone[-4:]}",
                     avatar="🙂", phone=req.phone)
            s.add(u)
            s.commit()
            s.refresh(u)
        return {"token": _create_token(u.id), "user": _user_dict(u)}
        return {"token": _create_token(u.id), "user": _user_dict(u)}


@app.post("/auth/register-by-phone")
@limiter.limit("10/minute")
def auth_register_by_phone(req: PhoneRegisterReq, request: Request = None):
    """手机号验证码注册：校验验证码后建号（可选设置密码），返回 token。"""
    if not sms_is_valid_phone(req.phone):
        raise HTTPException(status_code=400, detail="手机号格式不正确")
    try:
        sms_verify_code(req.phone, req.code)
    except ValueError as e:
        if str(e) == "code_expired":
            raise HTTPException(status_code=400, detail="验证码已过期，请重新获取")
        if str(e) == "wrong_code":
            raise HTTPException(status_code=400, detail="验证码错误")
        raise HTTPException(status_code=400, detail="验证码校验失败")
    if req.password and len(req.password) < 6:
        raise HTTPException(status_code=400, detail="密码至少 6 位")

    with SessionLocal() as s:
        if s.query(User).filter(User.phone == req.phone).first():
            raise HTTPException(status_code=409, detail="该手机号已注册，请直接登录")
        u = User(
            id=str(uuid.uuid4()),
            name=req.nickname or f"用户{req.phone[-4:]}",
            avatar="🙂",
            phone=req.phone,
            password_hash=hash_password(req.password) if req.password else "",
        )
        s.add(u)
        s.commit()
        s.refresh(u)
        return {"token": _create_token(u.id), "user": _user_dict(u)}


class ProfileUpdate(BaseModel):
    name: Optional[str] = None
    avatar: Optional[str] = None
    avatar_b64: Optional[str] = None
    currentWeight: Optional[float] = None
    targetWeight: Optional[float] = None
    height: Optional[float] = None


@app.put("/profile")
def update_profile(body: ProfileUpdate, u: User = Depends(get_current_user)):
    with SessionLocal() as s:
        cur = s.get(User, u.id)
        if body.name is not None: cur.name = body.name
        if body.avatar is not None: cur.avatar = body.avatar
        if body.avatar_b64 is not None: cur.avatar_b64 = body.avatar_b64
        if body.currentWeight is not None: cur.current_weight = body.currentWeight
        if body.targetWeight is not None: cur.target_weight = body.targetWeight
        if body.height is not None: cur.height = body.height
        s.commit()
        return _user_dict(cur)


class FeedbackReq(BaseModel):
    content: str
    contact: Optional[str] = None


@app.post("/feedback")
@limiter.limit("5/minute")
def submit_feedback(req: FeedbackReq, request: Request = None,
                    u: User = Depends(get_current_user)):
    """提交意见反馈，记录到服务端日志（暂不落库）。"""
    content = req.content.strip()
    if not content:
        raise HTTPException(status_code=400, detail="反馈内容不能为空")
    if len(content) > 1000:
        raise HTTPException(status_code=400, detail="反馈内容不能超过 1000 字")
    logger.info(f"[Feedback] user={u.id} contact={req.contact or ''} content={content[:200]}")
    return {"ok": True}


@app.get("/dashboard")
def dashboard(u: User = Depends(get_current_user)):
    # 试用 Redis 缓存（60s TTL），数据变更缓存失效；dashboard 无 day 过滤时不缓存
    cache_key = f"cache:dashboard:{u.id}"
    cached_data = cache_get(cache_key)
    if cached_data:
        return cached_data

    with get_read_session() as s:
        # days=7：仪表盘显示最近7天数据，让用户能看到历史记录
        result = {"user": _user_dict(u), "dailyStats": _aggregate(s, u.id, days=7),
                  "todayRecords": _records_list(s, u.id, days=7)}
        cache_set(cache_key, result, ttl=60)
        return result


class RecordIn(BaseModel):
    type: str
    name: str = ""
    calories: float = 0
    amount: float = 0
    unit: str = ""
    time: str = ""
    image_b64: str = ""
    # 可选：记录创建时间（ISO 8601 格式字符串，如 "2026-08-06T12:00:00Z"）
    # 用于补上传历史记录时保持原始创建时间，避免误用上传时间
    created_at: str = ""
    # 营养成分与小贴士（食物记录携带，供对方查看详情）
    protein_g: float = 0
    carb_g: float = 0
    fat_g: float = 0
    dietary_fiber_g: float = 0
    sugar_g: float = 0
    sodium_mg: float = 0
    vitamin_tips: str = ""


def _invalidate_user_caches(s, user_id: str):
    """使指定用户及其伴侣的 dashboard/pk 缓存失效（记录变更后调用）"""
    cache_invalidate(f"cache:dashboard:{user_id}")
    cache_invalidate(f"cache:pk:{user_id}")
    partner = s.execute(select(User).where(User.partner_id == user_id)).scalar_one_or_none()
    if partner:
        cache_invalidate(f"cache:dashboard:{partner.id}")
        cache_invalidate(f"cache:pk:{partner.id}")


@app.post("/records")
@limiter.limit("60/minute")
def add_record(body: RecordIn, u: User = Depends(get_current_user), request: Request = None):
    with SessionLocal() as s:
        img_path = ""
        if body.image_b64 and body.type == "food":
            os.makedirs(FBASE, exist_ok=True)
            fn = f"{uuid.uuid4().hex}.jpg"
            try:
                raw = base64.b64decode(body.image_b64)
                with open(os.path.join(FBASE, fn), "wb") as f:
                    f.write(raw)
                img_path = fn
            except Exception:
                logger.warning("食物图片保存失败，跳过图片")

        # 饮水类型：当天只保留一条记录，新设置覆盖旧值（upsert）
        if body.type == "water":
            # 从 time 字段解析日期（格式 "HH:MM"，加上今天日期得到 date）
            today = datetime.utcnow()
            date_str = today.strftime("%Y-%m-%d")
            # 查找当天已有的 water 记录
            existing = s.query(Record).filter(
                Record.user_id == u.id,
                Record.type == "water",
                sqlalchemy.func.DATE(Record.created_at) == today.date()
            ).order_by(Record.created_at.desc()).first()
            if existing:
                # 更新已有记录
                existing.name = body.name
                existing.calories = body.calories
                existing.amount = body.amount
                existing.unit = body.unit
                existing.time = body.time
                s.commit()
                _invalidate_user_caches(s, u.id)
                return {"ok": True, "id": existing.id}

        # 解析传入的 created_at（如有），用于补上传历史记录时保持原始时间
        record_created_at = None
        if body.created_at:
            try:
                # 支持 ISO 8601 格式（带或不带时区）
                # 如 "2026-08-06T12:00:00Z" 或 "2026-08-06T12:00:00+08:00"
                from dateutil import parser as dateutil_parser
                parsed_dt = dateutil_parser.parse(body.created_at)
                # 转换为 UTC（不带时区信息），与数据库存储一致
                if parsed_dt.tzinfo is not None:
                    record_created_at = parsed_dt.astimezone(timezone.utc).replace(tzinfo=None)
                else:
                    record_created_at = parsed_dt
            except Exception as e:
                logger.warning(f"解析 created_at 失败: {body.created_at}, error: {e}")

        r = Record(id=f"r-{uuid.uuid4().hex[:10]}", user_id=u.id, type=body.type,
                   name=body.name, calories=body.calories, amount=body.amount,
                   unit=body.unit, time=body.time, image_path=img_path,
                   created_at=record_created_at,
                   protein_g=body.protein_g, carb_g=body.carb_g, fat_g=body.fat_g,
                   dietary_fiber_g=body.dietary_fiber_g, sugar_g=body.sugar_g,
                   sodium_mg=body.sodium_mg, vitamin_tips=body.vitamin_tips)
        s.add(r)
        s.commit()
        _invalidate_user_caches(s, u.id)
        return {"ok": True, "id": r.id}


@app.put("/records/{rid}")
def update_record(rid: str, body: RecordIn, u: User = Depends(get_current_user)):
    """更新已有记录（用于饮水覆盖式更新等场景）"""
    with SessionLocal() as s:
        r = s.get(Record, rid)
        if not r or r.user_id != u.id:
            raise HTTPException(status_code=404, detail="记录不存在")
        r.type = body.type
        r.name = body.name
        r.calories = body.calories
        r.amount = body.amount
        r.unit = body.unit
        r.time = body.time
        r.protein_g = body.protein_g
        r.carb_g = body.carb_g
        r.fat_g = body.fat_g
        r.dietary_fiber_g = body.dietary_fiber_g
        r.sugar_g = body.sugar_g
        r.sodium_mg = body.sodium_mg
        r.vitamin_tips = body.vitamin_tips
        s.commit()
        _invalidate_user_caches(s, u.id)
        return {"ok": True}


@app.delete("/records/{rid}")
def del_record(rid: str, u: User = Depends(get_current_user)):
    with SessionLocal() as s:
        r = s.get(Record, rid)
        if r and r.user_id == u.id:
            s.delete(r)
            s.commit()
            _invalidate_user_caches(s, u.id)
        return {"ok": True}


# ─────────────────────── PK 绑定关系（云端落地，跨设备同步） ───────────────────────

def _public_partner_info(u: Optional[User]):
    if not u:
        return None
    return {
        "uid": u.id,
        "nickname": u.name or ("用户" + u.id[-4:]),
        "avatar": u.avatar or "",
    }


class PKBindReq(BaseModel):
    target_uid: str


@app.post("/pk/bind")
def pk_bind(body: PKBindReq, u: User = Depends(get_current_user)):
    """绑定对方为 PK 伙伴（互绑，关系写入云端，跨设备同步）。"""
    target_uid = (body.target_uid or "").strip()
    if not target_uid:
        raise HTTPException(status_code=400, detail="缺少 target_uid")
    if target_uid == u.id:
        raise HTTPException(status_code=400, detail="不能绑定自己")
    with SessionLocal() as s:
        me = s.get(User, u.id)
        other = s.get(User, target_uid)
        if not me or not other:
            raise HTTPException(status_code=404, detail="用户不存在")
        if me.partner_id:
            raise HTTPException(status_code=409, detail="你已绑定伙伴，请先解绑")
        if other.partner_id:
            raise HTTPException(status_code=409, detail="对方已绑定伙伴")
        me.partner_id = other.id
        other.partner_id = me.id
        s.commit()
        s.refresh(other)
        cache_invalidate(f"cache:pk:{me.id}")
        cache_invalidate(f"cache:pk:{other.id}")
        return {"ok": True, "partner": _public_partner_info(other)}


@app.post("/pk/unbind")
def pk_unbind(u: User = Depends(get_current_user)):
    """解除当前用户的 PK 绑定（互解）。"""
    with SessionLocal() as s:
        me = s.get(User, u.id)
        if me and me.partner_id:
            other = s.get(User, me.partner_id)
            if other:
                other.partner_id = None
                s.add(other)
                cache_invalidate(f"cache:pk:{other.id}")
            me.partner_id = None
            s.add(me)
            s.commit()
            cache_invalidate(f"cache:pk:{me.id}")
        return {"ok": True}


@app.get("/pk/relation")
def pk_relation(u: User = Depends(get_current_user)):
    """返回当前绑定关系（云端查询，跨设备同步）。"""
    with SessionLocal() as s:
        me = s.get(User, u.id)
        partner = s.get(User, me.partner_id) if me and me.partner_id else None
        return {
            "bound": partner is not None,
            "partner": _public_partner_info(partner),
        }


@app.get("/pk/week")
def pk_week(u: User = Depends(get_current_user)):
    cache_key = f"cache:pk:{u.id}"
    cached_data = cache_get(cache_key)
    if cached_data:
        return cached_data

    with get_read_session() as s:
        wk = s.query(PKWeek).filter(PKWeek.user_id == u.id).first()
        partner = s.get(User, u.partner_id) if u.partner_id else None
        # dailyStats 按 7 天聚合（PK 对比按周）；todayRecords 取 30 天，
        # 覆盖 CardPageView 周历过去 4 周（28 天）的查看范围
        me = {"user": _user_dict(u), "dailyStats": _aggregate(s, u.id, days=7),
              "todayRecords": _records_list(s, u.id, days=30)}
        pa = None
        if partner:
            pa = {"user": _user_dict(partner), "dailyStats": _aggregate(s, partner.id, days=7),
                  "todayRecords": _records_list(s, partner.id, days=30)}
        result = {"startDate": wk.start_date if wk else "", "days": wk.days if wk else 0,
                  "me": me, "partner": pa}
        cache_set(cache_key, result, ttl=60)
        return result


SBASE = os.getenv("STICKER_DIR", os.path.join(os.path.dirname(__file__), "stickers"))
FBASE = os.getenv("FOOD_IMAGES_DIR", os.path.join(os.path.dirname(__file__), "food_images"))


def _save_sticker_png(b64_str: str) -> str:
    """将 base64 PNG 写入文件系统，返回相对路径"""
    os.makedirs(SBASE, exist_ok=True)
    name = f"{uuid.uuid4().hex}.png"
    path = os.path.join(SBASE, name)
    data = base64.b64decode(b64_str)
    with open(path, "wb") as f:
        f.write(data)
    return name


def _read_sticker_b64(path_or_name: str) -> str:
    """从文件系统读取贴纸并返回 base64；兼容旧数据直接返回原值"""
    full = os.path.join(SBASE, path_or_name) if path_or_name and not path_or_name.startswith("/") else path_or_name
    if path_or_name and os.path.isfile(full):
        return base64.b64encode(open(full, "rb").read()).decode()
    return ""   # 文件不存在返回空


def _sticker_url(path: str) -> dict:
    """返回贴纸的 base64 + CDN URL（如果配置了 CDN）"""
    result: dict = {"base64": "", "url": ""}

    if path:
        result["base64"] = _read_sticker_b64(path)
        if CDN_BASE_URL:
            result["url"] = f"{CDN_BASE_URL}/stickers/{path}"

    return result


class StickerIn(BaseModel):
    name: str = ""
    image_b64: str = ""
    # 营养/贴士字段（多设备同步）
    kcal_per_100g: float = 0
    protein_g: float = 0
    carb_g: float = 0
    fat_g: float = 0
    dietary_fiber_g: float = 0
    sodium_mg: float = 0
    typical_portion_g: float = 0
    vitamin_tips: str = ""


@app.post("/stickers")
@limiter.limit("30/minute")
def add_sticker(body: StickerIn, u: User = Depends(get_current_user), request: Request = None):
    with SessionLocal() as s:
        # 新贴纸存文件系统
        path = _save_sticker_png(body.image_b64) if body.image_b64 else ""
        st = Sticker(id=f"s-{uuid.uuid4().hex[:10]}", user_id=u.id,
                     name=body.name, image_b64="", image_path=path,
                     kcal_per_100g=body.kcal_per_100g,
                     protein_g=body.protein_g,
                     carb_g=body.carb_g,
                     fat_g=body.fat_g,
                     dietary_fiber_g=body.dietary_fiber_g,
                     sodium_mg=body.sodium_mg,
                     typical_portion_g=body.typical_portion_g,
                     vitamin_tips=body.vitamin_tips)
        s.add(st)
        s.commit()
        # 贴纸变更后使缓存失效
        cache_invalidate(f"cache:stickers:{u.id}")
        return {"ok": True, "id": st.id}


@app.get("/stickers")
def list_stickers(u: User = Depends(get_current_user)):
    cache_key = f"cache:stickers:{u.id}"
    cached_data = cache_get(cache_key)
    if cached_data:
        return cached_data

    with get_read_session() as s:
        items = s.query(Sticker).filter(Sticker.user_id == u.id)\
                  .order_by(Sticker.created_at.desc()).all()
        result = []
        for x in items:
            sticker_data = _sticker_url(x.image_path)
            b64 = sticker_data.get("base64", "")
            if not b64 and x.image_b64:
                b64 = x.image_b64  # 兼容旧数据
            item = {"id": x.id, "name": x.name, "image_b64": b64,
                    "kcal_per_100g": x.kcal_per_100g or 0,
                    "protein_g": x.protein_g or 0,
                    "carb_g": x.carb_g or 0,
                    "fat_g": x.fat_g or 0,
                    "dietary_fiber_g": x.dietary_fiber_g or 0,
                    "sodium_mg": x.sodium_mg or 0,
                    "typical_portion_g": x.typical_portion_g or 0,
                    "vitamin_tips": x.vitamin_tips or ""}
            if sticker_data.get("url"):
                item["cdn_url"] = sticker_data["url"]
            result.append(item)
        cache_set(cache_key, result, ttl=60)
        return result


# ─────────────────────── 固定提示词（产品级，禁止改动） ───────────────────────
POSITIVE_PROMPT = (
    "将实拍实物照片转为可爱 Q 版卡通贴纸，完整保留原物体外形、结构、标志性配色与关键细节；"
    "加粗清晰黑色轮廓线，纯色平涂上色，尽量还原原本色彩，弱化复杂光影与明暗渐变；"
    "纯白色纯净背景，物体外围增加一圈细白模切描边（贴纸裁边效果）；"
    "扁平化矢量画风，画面干净无杂色、无环境阴影、无多余杂物；"
    "高清晰度，线条工整利落，8K 分辨率，标准商品贴纸质感，"
    "不扭曲物体形态，不篡改物品特征，仅做卡通化美化。"
)
NEGATIVE_PROMPT = (
    "真人、人物、多余背景景物、复杂透视、写实照片质感、3D 立体渲染、厚重阴影、"
    "环境反光、噪点模糊、水印文字、物体变形、颜色严重失真、渐变光影、脏污杂点、"
    "多余装饰、场景环境。"
)


# ─────────────────────── /sticker/hd ───────────────────────
class HDReq(BaseModel):
    image_b64: str   # 原图 JPEG
    alpha_b64: str   # 端侧MobileSAM输出的Alpha PNG（复用，禁止重新分割）


@app.post("/sticker/hd")
@limiter.limit("10/minute")
async def sticker_hd(req: HDReq, request: Request = None):
    img = Image.open(io.BytesIO(base64.b64decode(req.image_b64))).convert("RGB")
    alpha = Image.open(io.BytesIO(base64.b64decode(req.alpha_b64))).convert("L")
    alpha = alpha.resize(img.size, Image.BILINEAR)

    # 1. 主体贴白底（与提示词"纯白背景"一致），并生成Canny控制图锁轮廓
    white = Image.new("RGB", img.size, (255, 255, 255))
    subject = Image.composite(img, white, alpha)
    canny = cv2.Canny(np.array(subject), 80, 160)
    canny_b64 = _pil_b64(Image.fromarray(canny))

    # 2. SD img2img + ControlNet Canny
    payload = {
        "init_images": [_pil_b64(subject)],
        "prompt": POSITIVE_PROMPT,
        "negative_prompt": NEGATIVE_PROMPT,
        "denoising_strength": 0.55,          # 风格化力度与保形的平衡点
        "steps": 22, "cfg_scale": 7, "sampler_name": "DPM++ 2M Karras",
        "width": _round64(img.width), "height": _round64(img.height),
        "alwayson_scripts": {"controlnet": {"args": [{
            "input_image": canny_b64,
            "module": "none",                # 已预计算canny
            "model": "control_v11p_sd15_canny",
            "weight": 1.0,
            "guidance_start": 0.0, "guidance_end": 0.9,
        }]}},
    }
    try:
        async with httpx.AsyncClient(timeout=30) as cli:
            r = await cli.post(f"{SD_BASE}/sdapi/v1/img2img", json=payload)
            r.raise_for_status()
            gen = Image.open(io.BytesIO(base64.b64decode(r.json()["images"][0]))).convert("RGB")
    except httpx.ConnectError:
        raise HTTPException(status_code=502, detail="SD 服务未启动，贴纸生成暂不可用")
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="SD 生成超时，请稍后重试")
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"SD 调用失败: {str(e)[:200]}")

    # 3. 后处理：复用原Alpha做膨胀，抠掉白底 → 透明底 + 白模切描边保留
    a = np.array(alpha.resize(gen.size, Image.BILINEAR))
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (11, 11))  # ~5px描边
    dilated = cv2.dilate(a, kernel)
    dilated = cv2.GaussianBlur(dilated, (3, 3), 0)                   # 描边外缘平滑
    out = np.dstack([np.array(gen), dilated])                        # RGBA
    sticker = Image.fromarray(out, "RGBA")

    return {"sticker_png_b64": _pil_b64(sticker, fmt="PNG")}


# ─────────────────────── /food/recognize ───────────────────────
class RecognizeReq(BaseModel):
    image_b64: str


VLM_SYS = (
    "你是食品营养分析助手。识别图片中的食品，估算画面中的分量，"
    "并给出每100g的核心营养数据（依据中国食物成分表）。"
    '只输出JSON：{"name_cn":食品中文名,"portion_g":画面分量克数,'
    '"kcal_100g":每100g千卡,"protein_g":蛋白质克,"carb_g":碳水克,"fat_g":脂肪克,'
    '"dietary_fiber":膳食纤维克,"sodium_mg":钠毫克,'
    '"vitamin_tips":"一句健康小贴士（不要emoji、不要markdown）"}'
)


@app.post("/food/recognize")
@limiter.limit("20/minute")
async def food_recognize(req: RecognizeReq, request: Request = None):
    import traceback
    try:
        body = {
            "model": VLM_MODEL,
            "messages": [
                {"role": "system", "content": VLM_SYS},
                {"role": "user", "content": [
                    {"type": "image_url",
                     "image_url": {"url": f"data:image/jpeg;base64,{req.image_b64}"}},
                    {"type": "text", "text": "识别这个食品并返回营养JSON"}]},
            ],
            "response_format": {"type": "json_object"},
            "temperature": 0.1,
        }
        async with httpx.AsyncClient(timeout=60) as cli:
            r = await cli.post(f"{VLM_BASE}/chat/completions", json=body,
                               headers={"Authorization": f"Bearer {VLM_KEY}"})
            r.raise_for_status()
            content = r.json()["choices"][0]["message"]["content"]
            print(f"[food_recognize] VLM raw: {content[:500]}")
            return json.loads(content)
    except Exception:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="food_recognize 内部错误")


# ─────────────────────── /food/nutrition ───────────────────────
class NutritionReq(BaseModel):
    name: str


@app.post("/food/nutrition")
@limiter.limit("30/minute")
async def food_nutrition(req: NutritionReq, request: Request = None):
    import traceback
    try:
        body = {
            "model": VLM_MODEL,
            "messages": [
                {"role": "system", "content":
                    '依据中国食物成分表返回食品每100g营养JSON：'
                    '{"name_cn":...,"kcal_100g":...,"protein_g":...,"carb_g":...,"fat_g":...,'
                    '"dietary_fiber":...,"sodium_mg":...,'
                    '"vitamin_tips":"一句健康小贴士（不要emoji、不要markdown）"}'},
                {"role": "user", "content": req.name}],
            "response_format": {"type": "json_object"},
            "temperature": 0,
        }
        async with httpx.AsyncClient(timeout=30) as cli:
            r = await cli.post(f"{VLM_BASE}/chat/completions", json=body,
                               headers={"Authorization": f"Bearer {VLM_KEY}"})
            r.raise_for_status()
            content = r.json()["choices"][0]["message"]["content"]
            print(f"[food_nutrition] VLM raw: {content[:300]}")
            return json.loads(content)
    except Exception:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"food_nutrition 内部错误")


# ─────────────────────── /sticker/seedream ───────────────────────
# 火山方舟图生图代理：客户端不再持有 API Key，所有图生图调用经服务端中转
class SeedreamReq(BaseModel):
    food_name: str
    image_b64: str     # 原图 JPEG base64


SEEDREAM_PROMPT = (
    "独立食物，软萌3D卡通，哑光材质，细腻环境光，柔和明暗过渡，"
    "一圈柔和白色外描边，emoji风格，单独物件，无环境、无桌面，"
    "透明背景，画面居中，8k高清，边缘干净，贴纸成品效果。"
)


@app.post("/sticker/seedream")
@limiter.limit("10/hour")  # 图生图是高成本 AI 调用，严格限制
async def sticker_seedream(req: SeedreamReq, request: Request = None):
    """代理调用火山方舟图生图 API，返回 PNG 贴纸（服务端持有密钥）"""
    prompt = f"{SEEDREAM_PROMPT} 食物名：{req.food_name}"

    body = {
        "model": ARK_SD_MODEL,
        "prompt": prompt,
        "image": f"data:image/jpeg;base64,{req.image_b64}",
        "size": "2K",
        "output_format": "png",
        "watermark": False,
        "sequential_image_generation": "disabled",
    }
    print(f"[seedream] → 模型={ARK_SD_MODEL}, prompt前100字={prompt[:100]}")

    async with httpx.AsyncClient(timeout=90) as cli:
        r = await cli.post(
            f"{ARK_BASE}/images/generations",
            json=body,
            headers={"Authorization": f"Bearer {ARK_KEY}"}
        )
        print(f"[seedream] ← HTTP {r.status_code}")
        if r.status_code != 200:
            detail = r.text[:500]
            print(f"[seedream] ← 错误: {detail}")
            raise HTTPException(status_code=502, detail=f"火山方舟返回错误: {detail}")
        j = r.json()
        data_items = j.get("data", [])
        if not data_items:
            raise HTTPException(status_code=502, detail="火山方舟未返回图片数据")

        first = data_items[0]
        # 优先取 b64_json，其次取 url 下载
        sticker_b64 = first.get("b64_json") or first.get("url")
        if sticker_b64 and (sticker_b64.startswith("http://") or sticker_b64.startswith("https://")):
            async with httpx.AsyncClient(timeout=30) as cli2:
                r2 = await cli2.get(sticker_b64)
                r2.raise_for_status()
                sticker_b64 = base64.b64encode(r2.content).decode()
        if not sticker_b64:
            raise HTTPException(status_code=502, detail="火山方舟返回数据格式异常")

        return {"sticker_png_b64": sticker_b64}


# ─────────────────────── 灰度功能开关 ───────────────────────
@app.get("/feature-flags")
def feature_flags():
    """返回当前环境的功能开关。生产可通过环境变量 NEW_UI_FLAG 控制灰度。"""
    return {"newUI": os.getenv("NEW_UI_FLAG", "0").lower() in ("1", "true", "yes")}


# ─────────────────────── utils ───────────────────────
def _pil_b64(img: Image.Image, fmt: str = "JPEG") -> str:
    buf = io.BytesIO()
    img.save(buf, format=fmt)
    return base64.b64encode(buf.getvalue()).decode()


def _round64(x: int, cap: int = 1536) -> int:
    return min(cap, (x // 64) * 64)
