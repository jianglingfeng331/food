"""
云端兜底服务（FastAPI）
  POST /sticker/hd       高清贴纸：SD img2img + ControlNet Canny 锁轮廓 → 复用Alpha抠白底
  POST /food/recognize   冷门食品识别：多模态大模型 → 名称+分量+营养（一步返回）
  POST /food/nutrition   按名称查营养（用户手动修正兜底）

依赖: pip install -r requirements.txt
SD后端: 本地 stable-diffusion-webui (--api) 或 ComfyUI，此处以 webui API 为例
大模型: OpenAI 兼容接口（如 hunyuan-vision / gpt-4o / qwen-vl 等），配置环境变量:
  export VLM_BASE_URL=https://... VLM_API_KEY=sk-... VLM_MODEL=hunyuan-vision
  export SD_BASE_URL=http://127.0.0.1:7860

启动: uvicorn main:app --host 0.0.0.0 --port 8000
"""
import base64
import io
import json
import os
import uuid
from datetime import datetime, timedelta
from typing import Optional

import cv2
import httpx
import jwt
import numpy as np
from fastapi import Depends, FastAPI, Header, HTTPException
from PIL import Image
from pydantic import BaseModel

from db import SessionLocal, User, Record, Sticker, PKWeek, init_db, _hash

init_db()

app = FastAPI(title="FoodSticker Cloud")

SD_BASE = os.getenv("SD_BASE_URL", "http://127.0.0.1:7860")
VLM_BASE = os.getenv("VLM_BASE_URL", "")
VLM_KEY = os.getenv("VLM_API_KEY", "")
VLM_MODEL = os.getenv("VLM_MODEL", "hunyuan-vision")

# ─────────────────────── 鉴权（JWT，承接原 mock 用户体系） ───────────────────────
SECRET = os.getenv("JWT_SECRET", "dev-secret-change-me")
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
def auth_login(req: LoginReq):
    with SessionLocal() as s:
        u = s.get(User, req.user_id)
        if not u or u.password_hash != _hash(req.password):
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
    with SessionLocal() as s:
        return {"user": _user_dict(u), "dailyStats": _aggregate(s, u.id),
                "todayRecords": _records_list(s, u.id)}


class RecordIn(BaseModel):
    type: str
    name: str = ""
    calories: float = 0
    amount: float = 0
    unit: str = ""
    time: str = ""


@app.post("/records")
def add_record(body: RecordIn, u: User = Depends(get_current_user)):
    with SessionLocal() as s:
        r = Record(id=f"r-{uuid.uuid4().hex[:10]}", user_id=u.id, type=body.type,
                   name=body.name, calories=body.calories, amount=body.amount,
                   unit=body.unit, time=body.time)
        s.add(r)
        s.commit()
        return {"ok": True, "id": r.id}


@app.delete("/records/{rid}")
def del_record(rid: str, u: User = Depends(get_current_user)):
    with SessionLocal() as s:
        r = s.get(Record, rid)
        if r and r.user_id == u.id:
            s.delete(r)
            s.commit()
        return {"ok": True}


@app.get("/pk/week")
def pk_week(u: User = Depends(get_current_user)):
    with SessionLocal() as s:
        wk = s.query(PKWeek).filter(PKWeek.user_id == u.id).first()
        partner = s.get(User, u.partner_id) if u.partner_id else None
        me = {"user": _user_dict(u), "dailyStats": _aggregate(s, u.id),
              "todayRecords": _records_list(s, u.id)}
        pa = None
        if partner:
            pa = {"user": _user_dict(partner), "dailyStats": _aggregate(s, partner.id),
                  "todayRecords": _records_list(s, partner.id)}
        return {"startDate": wk.start_date if wk else "", "days": wk.days if wk else 0,
                "me": me, "partner": pa}


class StickerIn(BaseModel):
    name: str = ""
    image_b64: str = ""


@app.post("/stickers")
def add_sticker(body: StickerIn, u: User = Depends(get_current_user)):
    with SessionLocal() as s:
        st = Sticker(id=f"s-{uuid.uuid4().hex[:10]}", user_id=u.id,
                     name=body.name, image_b64=body.image_b64)
        s.add(st)
        s.commit()
        return {"ok": True, "id": st.id}


@app.get("/stickers")
def list_stickers(u: User = Depends(get_current_user)):
    with SessionLocal() as s:
        items = s.query(Sticker).filter(Sticker.user_id == u.id)\
                  .order_by(Sticker.created_at.desc()).all()
        return [{"id": x.id, "name": x.name, "image_b64": x.image_b64} for x in items]

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
async def sticker_hd(req: HDReq):
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
async def food_recognize(req: RecognizeReq):
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
async def food_nutrition(req: NutritionReq):
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


# ─────────────────────── utils ───────────────────────
def _pil_b64(img: Image.Image, fmt: str = "JPEG") -> str:
    buf = io.BytesIO()
    img.save(buf, format=fmt)
    return base64.b64encode(buf.getvalue()).decode()


def _round64(x: int, cap: int = 1536) -> int:
    return min(cap, (x // 64) * 64)
