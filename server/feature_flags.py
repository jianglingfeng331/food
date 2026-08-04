"""
灰度发布 / 功能开关：支持按用户比例、用户 ID 白名单启用新功能
"""
import hashlib
import os
from typing import Optional


def _pct(user_id: str, flag: str) -> int:
    """确定性哈希：同一用户+同一开关 → 固定 0-99 值"""
    h = hashlib.md5(f"{user_id}:{flag}".encode()).hexdigest()
    return int(h[:8], 16) % 100


def is_enabled(flag: str, user_id: Optional[str] = None) -> bool:
    """检查功能开关是否对当前用户启用

    优先级：环境变量 FORCE_<FLAG>=on/off > 白名单 > 比例滚动

    用法：
      # 环境变量控制比例
      export FF_NEW_UI=30         # 30% 用户看到新版 UI
      export FF_NEW_UI_WHITELIST=user-1,user-5  # 白名单用户强制开启
    """
    # 1. 强制开关（调试用）
    force_key = f"FF_FORCE_{flag.upper()}"
    force_val = os.getenv(force_key)
    if force_val == "on":
        return True
    if force_val == "off":
        return False

    if not user_id:
        return False

    # 2. 白名单
    whitelist_key = f"FF_{flag.upper()}_WHITELIST"
    whitelist = os.getenv(whitelist_key, "")
    if user_id in whitelist.split(","):
        return True

    # 3. 比例灰度
    pct_key = f"FF_{flag.upper()}"
    pct_val = os.getenv(pct_key)
    if pct_val is not None:
        try:
            ratio = int(pct_val)
            return _pct(user_id, flag) < ratio
        except ValueError:
            return False

    # 未配置 → 默认关闭
    return False
