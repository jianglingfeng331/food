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
from datetime import datetime, timedelta
from typing import Optional

import cv2
import httpx
import jwt
import numpy as np
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
from cache import cached, cache_invalidate, cache_get, cache_set
from logging_config import setup_logging

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
ARK_BASE = os.getenv("ARK_BASE_URL", VLM_BASE)
ARK_KEY = os.getenv("ARK_API_KEY", VLM_KEY)
ARK_SD_MODEL = os.getenv("ARK_SD_MODEL", "doubao-seedream-4-0-251215")

# ─────────────────────── 鉴权（JWT，承接原 mock 用户体系） ───────────────────────
# 默认密钥仅用于本地开发/测试；生产务必通过 JWT_SECRET 环境变量配置至少 32 字节的随机值
SECRET = os.getenv("JWT_SECRET", "dev-only-insecure-secret-please-override-32bytes-min")
ALGO = "HS256"
TARGET_KCAL = 1500  # 默认每日热量目标，后续可由用户资料覆盖


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
        "currentWeight": u.current_weight, "targetWeight": u.target_weight,
        "height": u.height,
    }


def _aggregate(s, uid: str) -> dict:
    recs = s.query(Record).filter(Record.user_id == uid).all()
    intake = sum(r.calories for r in recs if r.type == "food")
    burned = sum(r.calories for r in recs if r.type == "exercise")
    target = TARGET_KCAL
    return {
        "intake": intake, "burned": burned,
        "remaining": target - intake + burned, "target": target,
    }


def _records_list(s, uid: str) -> list:
    return [
        {"id": r.id, "type": r.type, "name": r.name, "calories": r.calories,
         "amount": r.amount, "unit": r.unit, "time": r.time}
        for r in s.query(Record).filter(Record.user_id == uid)
        .order_by(Record.created_at.desc()).all()
    ]


# ─────────────────────── 业务接口：登录 / 用户 / 仪表盘 / 记录 / PK / 贴纸 ───────────────────────
class LoginReq(BaseModel):
    user_id: str
    password: str = "123456"


@app.post("/auth/login")
@limiter.limit("5/minute")  # 防暴力破解
def auth_login(req: LoginReq, request: Request = None):
    with SessionLocal() as s:
        u = s.get(User, req.user_id)
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


@app.get("/user/me")
def user_me(u: User = Depends(get_current_user)):
    return _user_dict(u)


class ProfileUpdate(BaseModel):
    name: Optional[str] = None
    avatar: Optional[str] = None
    currentWeight: Optional[float] = None
    targetWeight: Optional[float] = None
    height: Optional[float] = None


@app.put("/profile")
def update_profile(body: ProfileUpdate, u: User = Depends(get_current_user)):
    with SessionLocal() as s:
        cur = s.get(User, u.id)
        if body.name is not None: cur.name = body.name
        if body.avatar is not None: cur.avatar = body.avatar
        if body.currentWeight is not None: cur.current_weight = body.currentWeight
        if body.targetWeight is not None: cur.target_weight = body.targetWeight
        if body.height is not None: cur.height = body.height
        s.commit()
        return _user_dict(cur)


@app.get("/dashboard")
def dashboard(u: User = Depends(get_current_user)):
    # 尝试 Redis 缓存（60s TTL，数据变更时自动失效）
    cache_key = f"cache:dashboard:{u.id}"
    cached_data = cache_get(cache_key)
    if cached_data:
        return cached_data

    with get_read_session() as s:
        result = {"user": _user_dict(u), "dailyStats": _aggregate(s, u.id),
                  "todayRecords": _records_list(s, u.id)}
        cache_set(cache_key, result, ttl=60)
        return result


class RecordIn(BaseModel):
    type: str
    name: str = ""
    calories: float = 0
    amount: float = 0
    unit: str = ""
    time: str = ""


@app.post("/records")
@limiter.limit("60/minute")
def add_record(body: RecordIn, u: User = Depends(get_current_user), request: Request = None):
    with SessionLocal() as s:
        r = Record(id=f"r-{uuid.uuid4().hex[:10]}", user_id=u.id, type=body.type,
                   name=body.name, calories=body.calories, amount=body.amount,
                   unit=body.unit, time=body.time)
        s.add(r)
        s.commit()
        # 数据变更后使相关缓存失效
        cache_invalidate(f"cache:dashboard:{u.id}")
        cache_invalidate(f"cache:pk:{u.id}")
        return {"ok": True, "id": r.id}


@app.delete("/records/{rid}")
def del_record(rid: str, u: User = Depends(get_current_user)):
    with SessionLocal() as s:
        r = s.get(Record, rid)
        if r and r.user_id == u.id:
            s.delete(r)
            s.commit()
            cache_invalidate(f"cache:dashboard:{u.id}")
            cache_invalidate(f"cache:pk:{u.id}")
        return {"ok": True}


@app.get("/pk/week")
def pk_week(u: User = Depends(get_current_user)):
    cache_key = f"cache:pk:{u.id}"
    cached_data = cache_get(cache_key)
    if cached_data:
        return cached_data

    with get_read_session() as s:
        wk = s.query(PKWeek).filter(PKWeek.user_id == u.id).first()
        partner = s.get(User, u.partner_id) if u.partner_id else None
        me = {"user": _user_dict(u), "dailyStats": _aggregate(s, u.id),
              "todayRecords": _records_list(s, u.id)}
        pa = None
        if partner:
            pa = {"user": _user_dict(partner), "dailyStats": _aggregate(s, partner.id),
                  "todayRecords": _records_list(s, partner.id)}
        result = {"startDate": wk.start_date if wk else "", "days": wk.days if wk else 0,
                  "me": me, "partner": pa}
        cache_set(cache_key, result, ttl=60)
        return result


SBASE = os.getenv("STICKER_DIR", os.path.join(os.path.dirname(__file__), "stickers"))


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


@app.post("/stickers")
@limiter.limit("30/minute")
def add_sticker(body: StickerIn, u: User = Depends(get_current_user), request: Request = None):
    with SessionLocal() as s:
        # 新贴纸存文件系统
        path = _save_sticker_png(body.image_b64) if body.image_b64 else ""
        st = Sticker(id=f"s-{uuid.uuid4().hex[:10]}", user_id=u.id,
                     name=body.name, image_b64="", image_path=path)
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
            item = {"id": x.id, "name": x.name, "image_b64": b64}
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
    async with httpx.AsyncClient(timeout=30) as cli:
        r = await cli.post(f"{SD_BASE}/sdapi/v1/img2img", json=payload)
        r.raise_for_status()
        gen = Image.open(io.BytesIO(base64.b64decode(r.json()["images"][0]))).convert("RGB")

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
    '"kcal_100g":每100g千卡,"protein_g":蛋白质克,"carb_g":碳水克,"fat_g":脂肪克}'
)


@app.post("/food/recognize")
@limiter.limit("20/minute")
async def food_recognize(req: RecognizeReq, request: Request = None):
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
    async with httpx.AsyncClient(timeout=15) as cli:
        r = await cli.post(f"{VLM_BASE}/chat/completions", json=body,
                           headers={"Authorization": f"Bearer {VLM_KEY}"})
        r.raise_for_status()
        return json.loads(r.json()["choices"][0]["message"]["content"])


# ─────────────────────── /food/nutrition ───────────────────────
class NutritionReq(BaseModel):
    name: str


@app.post("/food/nutrition")
@limiter.limit("30/minute")
async def food_nutrition(req: NutritionReq, request: Request = None):
    body = {
        "model": VLM_MODEL,
        "messages": [
            {"role": "system", "content":
                '依据中国食物成分表返回食品每100g营养JSON：'
                '{"name_cn":...,"kcal_100g":...,"protein_g":...,"carb_g":...,"fat_g":...}'},
            {"role": "user", "content": req.name}],
        "response_format": {"type": "json_object"},
        "temperature": 0,
    }
    async with httpx.AsyncClient(timeout=10) as cli:
        r = await cli.post(f"{VLM_BASE}/chat/completions", json=body,
                           headers={"Authorization": f"Bearer {VLM_KEY}"})
        r.raise_for_status()
        return json.loads(r.json()["choices"][0]["message"]["content"])


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
