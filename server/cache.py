"""
Redis 缓存层：热门查询缓存 + 分布式限流后端
- 仪表盘 / 贴纸列表 / PK 周报 → 自动缓存 60s
- slowapi 限流器 → 升级为 Redis 后端（多实例共享状态）
"""
import json
import os
from functools import wraps
from typing import Any, Callable, Optional

REDIS_URL = os.getenv("REDIS_URL", "")

_redis: Any = None  # Lazy init


def _get_redis():
    """惰性初始化 Redis 连接（支持 Sentinel / Cluster）"""
    global _redis
    if _redis is not None:
        return _redis
    if not REDIS_URL:
        return None
    try:
        import redis
        _redis = redis.from_url(
            REDIS_URL,
            socket_connect_timeout=2,
            socket_timeout=2,
            decode_responses=True,
        )
        _redis.ping()
        print("[cache] Redis 连接成功")
        return _redis
    except Exception as e:
        print(f"[cache] Redis 不可用，降级直查数据库: {e}")
        _redis = False  # 标记已尝试，不再重试
        return None


def cached(ttl: int = 60, key_prefix: str = "cache"):
    """装饰器：自动缓存函数返回值（JSON 序列化）"""
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            r = _get_redis()
            if r is None:
                return await func(*args, **kwargs)

            # 构造 key: cache:prefix:arg1:arg2...
            key_parts = [key_prefix, func.__name__]
            for a in args:
                if hasattr(a, "id"):
                    key_parts.append(str(a.id))
                elif isinstance(a, (str, int)):
                    key_parts.append(str(a))
            for _, v in sorted(kwargs.items()):
                if isinstance(v, (str, int)):
                    key_parts.append(str(v))
            key = ":".join(key_parts)

            cached_val = r.get(key)
            if cached_val:
                return json.loads(cached_val)

            result = await func(*args, **kwargs)
            r.setex(key, ttl, json.dumps(result, default=str))
            return result
        return wrapper
    return decorator


def cache_get(key: str) -> Optional[dict]:
    """手动缓存读取"""
    r = _get_redis()
    if not r:
        return None
    val = r.get(key)
    return json.loads(val) if val else None


def cache_set(key: str, value: Any, ttl: int = 60) -> bool:
    """手动缓存写入"""
    r = _get_redis()
    if not r:
        return False
    r.setex(key, ttl, json.dumps(value, default=str))
    return True


def cache_invalidate(pattern: str) -> int:
    """按模式删除缓存（用户数据变更后调用）"""
    r = _get_redis()
    if not r:
        return 0
    keys = list(r.scan_iter(match=pattern))
    if keys:
        return r.delete(*keys)
    return 0
