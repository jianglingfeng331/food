"""
pytest 单元测试：覆盖鉴权 / 数据聚合 / 贴纸读写 / 限流
运行: cd food-sticker-app/server && python -m pytest test_main.py -v
"""
import base64
import os
import sys
import uuid

import pytest
from fastapi.testclient import TestClient

# 强制 SQLite 模式（测试环境不依赖 PostgreSQL/Redis）
os.environ["DATABASE_URL"] = "sqlite:///test_foodsticker.db"

# 重新导入（此时 DATABASE_URL 已设定为 SQLite）
import importlib
import db as db_mod
importlib.reload(db_mod)

from main import app

# 测试环境中关闭登录限流，避免同一进程内多次登录互相打满配额
app.state.limiter.enabled = False

client = TestClient(app)


@pytest.fixture(autouse=True)
def clean_db():
    """每个测试前重建表"""
    db_mod.Base.metadata.drop_all(bind=db_mod.engine)
    db_mod.Base.metadata.create_all(bind=db_mod.engine)
    # 测试环境下启用演示数据（正式运行默认关闭）
    os.environ["FF_ENABLE_SEED"] = "1"
    # 手动种子数据
    db_mod._seed()
    yield
    db_mod.Base.metadata.drop_all(bind=db_mod.engine)


# ─────────────── 鉴权测试 ───────────────
class TestAuth:
    def test_login_success(self):
        r = client.post("/auth/login", json={"user_id": "user-1", "password": "123456"})
        assert r.status_code == 200
        data = r.json()
        assert "token" in data
        assert data["user"]["id"] == "user-1"

    def test_login_wrong_password(self):
        r = client.post("/auth/login", json={"user_id": "user-1", "password": "wrong"})
        assert r.status_code == 401

    def test_login_no_user(self):
        r = client.post("/auth/login", json={"user_id": "ghost", "password": "123456"})
        assert r.status_code == 401

    def test_missing_token(self):
        r = client.get("/user/me")
        assert r.status_code == 401

    def test_invalid_token(self):
        r = client.get("/user/me", headers={"Authorization": "Bearer bad-token"})
        assert r.status_code == 401


# ─────────────── 用户 / 仪表盘测试 ───────────────
class TestUserDashboard:
    def _auth(self, uid="user-1"):
        r = client.post("/auth/login", json={"user_id": uid, "password": "123456"})
        return r.json()["token"]

    def test_get_me(self):
        tok = self._auth()
        r = client.get("/user/me", headers={"Authorization": f"Bearer {tok}"})
        assert r.status_code == 200
        assert r.json()["id"] == "user-1"

    def test_update_profile(self):
        tok = self._auth()
        r = client.put("/profile", json={"name": "新名字", "currentWeight": 70.0},
                       headers={"Authorization": f"Bearer {tok}"})
        assert r.status_code == 200
        assert r.json()["name"] == "新名字"
        assert r.json()["currentWeight"] == 70.0

    def test_dashboard(self):
        tok = self._auth()
        r = client.get("/dashboard", headers={"Authorization": f"Bearer {tok}"})
        assert r.status_code == 200
        data = r.json()
        assert "user" in data
        assert "dailyStats" in data
        assert "todayRecords" in data
        assert data["dailyStats"]["target"] == 1500

    def test_add_and_delete_record(self):
        tok = self._auth()
        # 添加
        r = client.post("/records", json={
            "type": "food", "name": "苹果", "calories": 52, "amount": 100, "unit": "g", "time": "10:00"
        }, headers={"Authorization": f"Bearer {tok}"})
        assert r.status_code == 200
        rid = r.json()["id"]
        assert rid.startswith("r-")

        # 删除
        r2 = client.delete(f"/records/{rid}", headers={"Authorization": f"Bearer {tok}"})
        assert r2.status_code == 200

        # 确认已删除
        r3 = client.get("/dashboard", headers={"Authorization": f"Bearer {tok}"})
        ids = [rec["id"] for rec in r3.json()["todayRecords"]]
        assert rid not in ids


# ─────────────── PK 周报测试 ───────────────
class TestPK:
    def _auth(self, uid="user-1"):
        r = client.post("/auth/login", json={"user_id": uid, "password": "123456"})
        return r.json()["token"]

    def test_pk_week_structure(self):
        tok = self._auth()
        r = client.get("/pk/week", headers={"Authorization": f"Bearer {tok}"})
        assert r.status_code == 200
        data = r.json()
        assert "me" in data
        assert data["me"]["user"]["id"] == "user-1"
        # partner 应该是 user-2
        assert data["partner"] is not None
        assert data["partner"]["user"]["id"] == "user-2"


# ─────────────── 贴纸测试 ───────────────
class TestStickers:
    def _auth(self, uid="user-1"):
        r = client.post("/auth/login", json={"user_id": uid, "password": "123456"})
        return r.json()["token"]

    def _fake_png_b64(self) -> str:
        """生成最小合法 PNG 的 base64"""
        import struct, zlib
        def chunk(ctype, data):
            c = ctype + data
            return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)
        png = b"".join([
            b"\x89PNG\r\n\x1a\n",
            chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0)),
            chunk(b"IDAT", zlib.compress(b"\x00\xff\x00\x00")),
            chunk(b"IEND", b""),
        ])
        return base64.b64encode(png).decode()

    def test_add_and_list_sticker(self):
        tok = self._auth()
        b64 = self._fake_png_b64()

        # 添加贴纸
        r = client.post("/stickers", json={
            "name": "测试贴纸", "image_b64": b64
        }, headers={"Authorization": f"Bearer {tok}"})
        assert r.status_code == 200
        sid = r.json()["id"]

        # 列表
        r2 = client.get("/stickers", headers={"Authorization": f"Bearer {tok}"})
        assert r2.status_code == 200
        stickers = r2.json()
        assert len(stickers) >= 1
        ids = [s["id"] for s in stickers]
        assert sid in ids


# ─────────────── 限流测试 ───────────────
class TestRateLimit:
    def test_login_rate_limit(self):
        """快速连续请求 /auth/login，应触发 429（临时开启限流，不影响其他测试）"""
        app.state.limiter.enabled = True
        try:
            rl_client = TestClient(app)
            statuses = []
            for _ in range(7):  # 限制 5/min
                r = rl_client.post(
                    "/auth/login",
                    json={"user_id": "user-1", "password": "bad"},
                    headers={"X-Forwarded-For": "203.0.113.99"},
                )
                statuses.append(r.status_code)
            assert 429 in statuses
        finally:
            app.state.limiter.enabled = False


# ─────────────── 功能开关测试 ───────────────
class TestFeatureFlags:
    def test_flag_disabled_default(self):
        from feature_flags import is_enabled
        assert is_enabled("nonexistent", "user-1") is False

    def test_flag_percentage(self):
        from feature_flags import is_enabled
        os.environ["FF_TEST_PCT"] = "100"
        # 需要 reimport（因为模块导入时已缓存）
        import importlib
        importlib.reload(sys.modules["feature_flags"])
        from feature_flags import is_enabled as ie
        assert ie("test_pct", "user-1") is True
        del os.environ["FF_TEST_PCT"]

    def test_flag_whitelist(self):
        from feature_flags import is_enabled
        os.environ["FF_WL_WHITELIST"] = "user-1,user-5"
        import importlib
        importlib.reload(sys.modules["feature_flags"])
        from feature_flags import is_enabled as ie
        assert ie("wl", "user-1") is True
        assert ie("wl", "user-99") is False
        del os.environ["FF_WL_WHITELIST"]


# ─────────────── 清理测试数据库 ───────────────
@pytest.fixture(scope="session", autouse=True)
def cleanup_test_db():
    yield
    test_db = os.path.join(os.path.dirname(__file__), "test_foodsticker.db")
    if os.path.exists(test_db):
        os.remove(test_db)
