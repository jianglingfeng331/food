"""
短信验证码服务：发码 / 校验 / 频次控制

设计要点：
- 验证码存储优先用 Redis（TTL 5 分钟、自动过期），Redis 不可用时降级为内存字典，
  保证本地开发与测试零依赖也能跑。
- 发码渠道抽象为 SmsProvider：默认 MockSmsProvider（验证码打印到服务端日志，
  方便联调）；真实上线时新增 AliyunSmsProvider / TencentSmsProvider 实现同一协议即可。
- 默认验证码 6 位数字；同一手机号 60 秒内只能发一次，每日上限 10 条（防刷）。
"""
from __future__ import annotations

import os
import random
import time
from datetime import datetime, timezone

import redis as _redis_lib

# ── 配置 ──
CODE_TTL_SECONDS = int(os.getenv("SMS_CODE_TTL", "300"))      # 验证码有效期 5 分钟
RESEND_INTERVAL = int(os.getenv("SMS_RESEND_INTERVAL", "60"))  # 重发间隔 60 秒
DAILY_LIMIT = int(os.getenv("SMS_DAILY_LIMIT", "10"))          # 单号每日上限
CODE_LEN = 6


# ─────────────────────── 验证码存储（Redis 优先，内存降级） ───────────────────────
class _CodeStore:
    def __init__(self) -> None:
        self._r: "_redis_lib.Redis | None" = None
        self._mem: dict[str, tuple[str, float]] = {}  # phone -> (code, expire_ts)
        self._daily: dict[str, tuple[int, str]] = {}   # phone -> (count, date_str)
        self._try_redis()

    def _try_redis(self) -> None:
        url = os.getenv("REDIS_URL", "")
        if not url:
            return
        try:
            r = _redis_lib.from_url(url, socket_timeout=2)
            r.ping()
            self._r = r
            print("[sms] 验证码存储已接入 Redis")
        except Exception as e:
            print(f"[sms] Redis 不可用，验证码降级为内存存储: {e}")
            self._r = None

    def _today(self) -> str:
        return datetime.now(timezone.utc).strftime("%Y-%m-%d")

    def daily_count(self, phone: str) -> int:
        if self._r is not None:
            key = f"sms:daily:{phone}:{self._today()}"
            return int(self._r.get(key) or 0)
        cnt, day = self._daily.get(phone, (0, ""))
        return cnt if day == self._today() else 0

    def incr_daily(self, phone: str) -> None:
        if self._r is not None:
            key = f"sms:daily:{phone}:{self._today()}"
            self._r.incr(key)
            self._r.expire(key, 86400)
            return
        cnt, day = self._daily.get(phone, (0, ""))
        self._daily[phone] = (cnt + 1 if day == self._today() else 1, self._today())

    def last_sent_ts(self, phone: str) -> float:
        if self._r is not None:
            v = self._r.get(f"sms:last:{phone}")
            return float(v) if v else 0.0
        return self._mem.get(f"__last__{phone}", (None, 0.0))[1]

    def set_code(self, phone: str, code: str) -> None:
        now = time.time()
        if self._r is not None:
            self._r.set(f"sms:code:{phone}", code, ex=CODE_TTL_SECONDS)
            self._r.set(f"sms:last:{phone}", str(now), ex=RESEND_INTERVAL)
            return
        self._mem[phone] = (code, now + CODE_TTL_SECONDS)
        self._mem[f"__last__{phone}"] = ("", now)

    def get_code(self, phone: str) -> "tuple[str | None, bool]":
        """返回 (code, valid)。code=None 表示不存在或已过期"""
        if self._r is not None:
            v = self._r.get(f"sms:code:{phone}")
            return (v.decode() if v else None, v is not None)
        code, exp = self._mem.get(phone, (None, 0.0))
        if code and time.time() < exp:
            return code, True
        if phone in self._mem:
            self._mem.pop(phone, None)
        return None, False

    def clear(self, phone: str) -> None:
        if self._r is not None:
            self._r.delete(f"sms:code:{phone}")
            return
        self._mem.pop(phone, None)


store = _CodeStore()


# ─────────────────────── 发码渠道（可插拔） ───────────────────────
class SmsProvider:
    def send(self, phone: str, code: str) -> None:
        raise NotImplementedError


class MockSmsProvider(SmsProvider):
    """开发/联调用：仅打印到服务端日志（不真正发短信）。
    客户端不会收到验证码原文，符合安全要求；联调时从服务端日志读取。"""

    def send(self, phone: str, code: str) -> None:
        print(f"[sms:MOCK] 向 {phone} 发送验证码：{code}（有效期 {CODE_TTL_SECONDS}s）")


# 真实渠道占位（上线时实现并替换下方实例）：
# class AliyunSmsProvider(SmsProvider): ...
_provider: SmsProvider = MockSmsProvider()


def set_provider(p: SmsProvider) -> None:
    global _provider
    _provider = p


def is_valid_phone(phone: str) -> bool:
    """中国大陆手机号校验：1 开头 + 11 位数字"""
    return phone.isdigit() and len(phone) == 11 and phone.startswith("1")


def generate_code() -> str:
    return "".join(random.choice("0123456789") for _ in range(CODE_LEN))


def send_code(phone: str) -> None:
    """发送验证码：校验格式 + 限流，成功则存储并下发。"""
    if not is_valid_phone(phone):
        raise ValueError("invalid_phone")
    if store.daily_count(phone) >= DAILY_LIMIT:
        raise ValueError("daily_limit")
    last = store.last_sent_ts(phone)
    if time.time() - last < RESEND_INTERVAL:
        raise ValueError("too_frequent")
    code = generate_code()
    store.set_code(phone, code)
    store.incr_daily(phone)
    _provider.send(phone, code)


def verify_code(phone: str, code: str) -> bool:
    """校验验证码；成功则消费（一次性）并清除。"""
    stored, valid = store.get_code(phone)
    if not valid or stored is None:
        raise ValueError("code_expired")
    if stored != code:
        raise ValueError("wrong_code")
    store.clear(phone)
    return True
