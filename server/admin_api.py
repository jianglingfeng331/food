"""
管理后台 API 路由
单管理员体系，通过环境变量 ADMIN_USERNAME / ADMIN_PASSWORD 配置
所有接口前缀 /admin，需独立的管理员 JWT 认证
"""
import os
import csv
import io
import json
import jwt
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Query
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from sqlalchemy import select, func, or_

from db import SessionLocal, User, Record, Sticker, PKWeek, hash_password, verify_password

router = APIRouter(prefix="/admin", tags=["admin"])

# ── 管理员配置 ──
ADMIN_USERNAME = os.getenv("ADMIN_USERNAME", "admin")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "FitFood@2026")
SECRET = os.getenv("JWT_SECRET", "dev-only-insecure-secret-please-override-32bytes-min")
ALGO = "HS256"
CHINA_TZ = timezone(timedelta(hours=8))

FOOD_IMAGES_DIR = os.getenv("FOOD_IMAGES_DIR", os.path.join(os.path.dirname(__file__), "food_images"))
STICKER_DIR = os.getenv("STICKER_DIR", os.path.join(os.path.dirname(__file__), "stickers"))


# ── 管理员认证 ──
def _create_admin_token() -> str:
    exp = datetime.utcnow() + timedelta(hours=12)
    return jwt.encode({"admin": True, "sub": "admin", "exp": exp}, SECRET, algorithm=ALGO)


def get_admin(authorization: str = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="未登录")
    try:
        payload = jwt.decode(authorization[7:], SECRET, algorithms=[ALGO])
        if not payload.get("admin"):
            raise HTTPException(status_code=403, detail="无管理员权限")
    except Exception:
        raise HTTPException(status_code=401, detail="token 无效")
    return payload


# ── 工具函数 ──
def _dt_str(dt) -> str:
    if not dt:
        return ""
    if isinstance(dt, str):
        return dt
    return dt.replace(tzinfo=timezone.utc).astimezone(CHINA_TZ).strftime("%Y-%m-%d %H:%M")


def _user_to_dict(u: User, s=None) -> dict:
    record_count = sticker_count = 0
    partner_name = ""
    if s:
        record_count = s.query(func.count(Record.id)).filter(Record.user_id == u.id).scalar() or 0
        sticker_count = s.query(func.count(Sticker.id)).filter(Sticker.user_id == u.id).scalar() or 0
        if u.partner_id:
            partner = s.get(User, u.partner_id)
            partner_name = partner.name if partner else ""
    return {
        "id": u.id,
        "name": u.name,
        "phone": u.phone or "",
        "username": u.username or "",
        "avatar": u.avatar or "🙂",
        "avatar_b64": u.avatar_b64 or "",
        "current_weight": u.current_weight or 0,
        "target_weight": u.target_weight or 0,
        "height": u.height or 0,
        "partner_id": u.partner_id or "",
        "partner_name": partner_name,
        "record_count": record_count,
        "sticker_count": sticker_count,
    }


def _record_to_dict(r: Record) -> dict:
    return {
        "id": r.id,
        "type": r.type,
        "name": r.name or "",
        "calories": r.calories or 0,
        "amount": r.amount or 0,
        "unit": r.unit or "",
        "time": r.time or "",
        "created_at": _dt_str(r.created_at),
        "image_path": r.image_path or "",
        "protein_g": r.protein_g or 0,
        "carb_g": r.carb_g or 0,
        "fat_g": r.fat_g or 0,
        "dietary_fiber_g": r.dietary_fiber_g or 0,
        "sugar_g": r.sugar_g or 0,
        "sodium_mg": r.sodium_mg or 0,
        "vitamin_tips": r.vitamin_tips or "",
    }


def _sticker_to_dict(st: Sticker, s=None) -> dict:
    user_name = ""
    image_url = ""
    if st.user_id and s:
        u = s.get(User, st.user_id)
        if u:
            user_name = u.name
    if st.image_path:
        image_url = f"/admin/stickers/image/{st.id}"
    elif st.image_b64:
        image_url = f"data:image/png;base64,{st.image_b64}"
    return {
        "id": st.id,
        "user_id": st.user_id,
        "user_name": user_name,
        "name": st.name or "",
        "image_b64": st.image_b64 or "",
        "image_url": image_url,
        "created_at": _dt_str(st.created_at),
        "kcal_per_100g": st.kcal_per_100g or 0,
        "protein_g": st.protein_g or 0,
        "carb_g": st.carb_g or 0,
        "fat_g": st.fat_g or 0,
        "dietary_fiber_g": st.dietary_fiber_g or 0,
        "sodium_mg": st.sodium_mg or 0,
        "typical_portion_g": st.typical_portion_g or 0,
        "vitamin_tips": st.vitamin_tips or "",
    }


# ─────────────────────── 请求模型 ───────────────────────
class LoginReq(BaseModel):
    username: str
    password: str

class UserUpdateReq(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    current_weight: Optional[float] = None
    target_weight: Optional[float] = None
    height: Optional[float] = None
    avatar_b64: Optional[str] = None

class RecordCreateReq(BaseModel):
    type: str
    name: str = ""
    calories: float = 0
    amount: float = 0
    unit: str = ""
    time: str = ""
    protein_g: float = 0
    carb_g: float = 0
    fat_g: float = 0

class RecordUpdateReq(BaseModel):
    type: Optional[str] = None
    name: Optional[str] = None
    calories: Optional[float] = None
    amount: Optional[float] = None
    unit: Optional[str] = None
    time: Optional[str] = None
    protein_g: Optional[float] = None
    carb_g: Optional[float] = None
    fat_g: Optional[float] = None
    dietary_fiber_g: Optional[float] = None
    sugar_g: Optional[float] = None
    sodium_mg: Optional[float] = None
    vitamin_tips: Optional[str] = None

class StickerUpdateReq(BaseModel):
    name: Optional[str] = None
    kcal_per_100g: Optional[float] = None
    protein_g: Optional[float] = None
    carb_g: Optional[float] = None
    fat_g: Optional[float] = None
    dietary_fiber_g: Optional[float] = None
    sodium_mg: Optional[float] = None
    typical_portion_g: Optional[float] = None
    vitamin_tips: Optional[str] = None


# ─────────────────────── 路由 ───────────────────────

@router.post("/login")
def admin_login(req: LoginReq):
    if req.username != ADMIN_USERNAME or req.password != ADMIN_PASSWORD:
        raise HTTPException(status_code=401, detail="用户名或密码错误")
    return {"token": _create_admin_token()}


@router.get("/overview")
def overview(_=Depends(get_admin)):
    with SessionLocal() as s:
        user_count = s.query(func.count(User.id)).scalar() or 0
        sticker_count = s.query(func.count(Sticker.id)).scalar() or 0
        record_count = s.query(func.count(Record.id)).scalar() or 0
        today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        today_records = s.query(func.count(Record.id)).filter(Record.created_at >= today_start).scalar() or 0
        today_stickers = s.query(func.count(Sticker.id)).filter(Sticker.created_at >= today_start).scalar() or 0
        return {
            "user_count": user_count,
            "sticker_count": sticker_count,
            "record_count": record_count,
            "today_records": today_records,
            "today_stickers": today_stickers,
        }


@router.get("/users")
def list_users(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    keyword: str = Query("", description="搜索手机号/昵称/用户名"),
    _=Depends(get_admin),
):
    with SessionLocal() as s:
        q = select(User)
        if keyword:
            kw = f"%{keyword}%"
            q = q.where(or_(User.phone.like(kw), User.name.like(kw), User.username.like(kw)))
        total = s.query(func.count()).select_from(q.subquery()).scalar() or 0
        users = s.execute(q.order_by(User.id).offset((page - 1) * size).limit(size)).scalars().all()
        return {"items": [_user_to_dict(u, s) for u in users], "total": total}


@router.get("/users/{uid}")
def get_user(uid: str, _=Depends(get_admin)):
    with SessionLocal() as s:
        u = s.get(User, uid)
        if not u:
            raise HTTPException(status_code=404, detail="用户不存在")
        return _user_to_dict(u, s)


@router.put("/users/{uid}")
def update_user(uid: str, req: UserUpdateReq, _=Depends(get_admin)):
    with SessionLocal() as s:
        u = s.get(User, uid)
        if not u:
            raise HTTPException(status_code=404, detail="用户不存在")
        if req.name is not None:
            u.name = req.name
        if req.phone is not None:
            existing = s.query(User).filter(User.phone == req.phone, User.id != uid).first()
            if existing:
                raise HTTPException(status_code=400, detail="手机号已被其他用户使用")
            u.phone = req.phone
        if req.current_weight is not None:
            u.current_weight = req.current_weight
        if req.target_weight is not None:
            u.target_weight = req.target_weight
        if req.height is not None:
            u.height = req.height
        if req.avatar_b64 is not None:
            u.avatar_b64 = req.avatar_b64
        s.commit()
        return _user_to_dict(u, s)


@router.delete("/users/{uid}")
def delete_user(uid: str, _=Depends(get_admin)):
    with SessionLocal() as s:
        u = s.get(User, uid)
        if not u:
            raise HTTPException(status_code=404, detail="用户不存在")
        # 解除 PK 绑定
        if u.partner_id:
            partner = s.get(User, u.partner_id)
            if partner:
                partner.partner_id = None
        # 删除关联数据
        s.query(Record).filter(Record.user_id == uid).delete()
        s.query(Sticker).filter(Sticker.user_id == uid).delete()
        s.query(PKWeek).filter(PKWeek.user_id == uid).delete()
        s.delete(u)
        s.commit()
        return {"detail": "已删除"}


# ── 用户健康数据 ──
@router.get("/users/{uid}/records")
def list_user_records(
    uid: str,
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    type: str = Query("", description="筛选类型"),
    _=Depends(get_admin),
):
    with SessionLocal() as s:
        q = select(Record).where(Record.user_id == uid)
        if type:
            q = q.where(Record.type == type)
        total = s.query(func.count()).select_from(q.subquery()).scalar() or 0
        records = s.execute(q.order_by(Record.created_at.desc()).offset((page - 1) * size).limit(size)).scalars().all()
        return {"items": [_record_to_dict(r) for r in records], "total": total}


@router.post("/users/{uid}/records")
def create_record(uid: str, req: RecordCreateReq, _=Depends(get_admin)):
    with SessionLocal() as s:
        u = s.get(User, uid)
        if not u:
            raise HTTPException(status_code=404, detail="用户不存在")
        r = Record(
            id=f"r-{uuid.uuid4().hex[:12]}",
            user_id=uid,
            type=req.type,
            name=req.name,
            calories=req.calories,
            amount=req.amount,
            unit=req.unit,
            time=req.time,
            protein_g=req.protein_g,
            carb_g=req.carb_g,
            fat_g=req.fat_g,
        )
        s.add(r)
        s.commit()
        return _record_to_dict(r)


@router.put("/records/{rid}")
def update_record(rid: str, req: RecordUpdateReq, _=Depends(get_admin)):
    with SessionLocal() as s:
        r = s.get(Record, rid)
        if not r:
            raise HTTPException(status_code=404, detail="记录不存在")
        for field in ["type", "name", "calories", "amount", "unit", "time",
                       "protein_g", "carb_g", "fat_g", "dietary_fiber_g",
                       "sugar_g", "sodium_mg", "vitamin_tips"]:
            val = getattr(req, field)
            if val is not None:
                setattr(r, field, val)
        s.commit()
        return _record_to_dict(r)


@router.delete("/records/{rid}")
def delete_record(rid: str, _=Depends(get_admin)):
    with SessionLocal() as s:
        r = s.get(Record, rid)
        if not r:
            raise HTTPException(status_code=404, detail="记录不存在")
        s.delete(r)
        s.commit()
        return {"detail": "已删除"}


# ── 贴纸管理 ──
@router.get("/stickers")
def list_stickers(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    user_id: str = Query(""),
    keyword: str = Query(""),
    _=Depends(get_admin),
):
    with SessionLocal() as s:
        q = select(Sticker)
        if user_id:
            q = q.where(Sticker.user_id == user_id)
        if keyword:
            q = q.where(Sticker.name.like(f"%{keyword}%"))
        total = s.query(func.count()).select_from(q.subquery()).scalar() or 0
        stickers = s.execute(q.order_by(Sticker.created_at.desc()).offset((page - 1) * size).limit(size)).scalars().all()
        return {"items": [_sticker_to_dict(st, s) for st in stickers], "total": total}


@router.get("/stickers/{sid}")
def get_sticker(sid: str, _=Depends(get_admin)):
    with SessionLocal() as s:
        st = s.get(Sticker, sid)
        if not st:
            raise HTTPException(status_code=404, detail="贴纸不存在")
        return _sticker_to_dict(st, s)


@router.put("/stickers/{sid}")
def update_sticker(sid: str, req: StickerUpdateReq, _=Depends(get_admin)):
    with SessionLocal() as s:
        st = s.get(Sticker, sid)
        if not st:
            raise HTTPException(status_code=404, detail="贴纸不存在")
        for field in ["name", "kcal_per_100g", "protein_g", "carb_g", "fat_g",
                       "dietary_fiber_g", "sodium_mg", "typical_portion_g", "vitamin_tips"]:
            val = getattr(req, field)
            if val is not None:
                setattr(st, field, val)
        s.commit()
        return _sticker_to_dict(st, s)


@router.delete("/stickers/{sid}")
def delete_sticker(sid: str, _=Depends(get_admin)):
    with SessionLocal() as s:
        st = s.get(Sticker, sid)
        if not st:
            raise HTTPException(status_code=404, detail="贴纸不存在")
        # 删除图片文件
        if st.image_path:
            full_path = os.path.join(STICKER_DIR, st.image_path)
            if os.path.exists(full_path):
                os.remove(full_path)
        s.delete(st)
        s.commit()
        return {"detail": "已删除"}


@router.get("/stickers/image/{sid}")
def get_sticker_image(sid: str, _=Depends(get_admin)):
    """获取贴纸图片"""
    import base64
    from starlette.responses import Response
    with SessionLocal() as s:
        st = s.get(Sticker, sid)
        if not st:
            raise HTTPException(status_code=404, detail="贴纸不存在")
        if st.image_path:
            full_path = os.path.join(STICKER_DIR, st.image_path)
            if os.path.exists(full_path):
                with open(full_path, "rb") as f:
                    return Response(content=f.read(), media_type="image/png")
        if st.image_b64:
            img_data = base64.b64decode(st.image_b64)
            return Response(content=img_data, media_type="image/png")
        raise HTTPException(status_code=404, detail="无图片")


# ── PK 绑定管理 ──
@router.get("/users/{uid}/binding")
def get_binding(uid: str, _=Depends(get_admin)):
    with SessionLocal() as s:
        u = s.get(User, uid)
        if not u:
            raise HTTPException(status_code=404, detail="用户不存在")
        if not u.partner_id:
            return {"partner_id": "", "partner_name": "", "bound_at": ""}
        partner = s.get(User, u.partner_id)
        return {
            "partner_id": u.partner_id,
            "partner_name": partner.name if partner else "",
            "bound_at": "",
        }


@router.post("/users/{uid}/unbind")
def unbind(uid: str, _=Depends(get_admin)):
    with SessionLocal() as s:
        u = s.get(User, uid)
        if not u:
            raise HTTPException(status_code=404, detail="用户不存在")
        if not u.partner_id:
            return {"detail": "该用户未绑定"}
        partner = s.get(User, u.partner_id)
        if partner:
            partner.partner_id = None
        u.partner_id = None
        s.commit()
        return {"detail": "已解绑"}


# ── 数据导出 ──
@router.get("/export/users/{uid}")
def export_user_data(uid: str, _=Depends(get_admin)):
    with SessionLocal() as s:
        u = s.get(User, uid)
        if not u:
            raise HTTPException(status_code=404, detail="用户不存在")
        records = s.query(Record).filter(Record.user_id == uid).all()
        stickers = s.query(Sticker).filter(Sticker.user_id == uid).all()
        data = {
            "user": _user_to_dict(u, s),
            "records": [_record_to_dict(r) for r in records],
            "stickers": [{
                "id": st.id, "name": st.name,
                "kcal_per_100g": st.kcal_per_100g,
                "protein_g": st.protein_g, "carb_g": st.carb_g, "fat_g": st.fat_g,
                "created_at": _dt_str(st.created_at),
                "vitamin_tips": st.vitamin_tips,
            } for st in stickers],
            "exported_at": datetime.now(CHINA_TZ).strftime("%Y-%m-%d %H:%M:%S"),
        }
        content = json.dumps(data, ensure_ascii=False, indent=2)
        filename = f"user_{u.phone or u.id}_export.json"
        return StreamingResponse(
            io.BytesIO(content.encode("utf-8")),
            media_type="application/json",
            headers={"Content-Disposition": f'attachment; filename="{filename}"'},
        )
