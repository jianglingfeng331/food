"""
结构化日志系统（loguru）：JSON 格式输出 + 自动轮转 + 错误告警
"""
import logging
import os
import sys

# 拦截标准 logging，统一用 loguru
import loguru

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
LOG_DIR = os.getenv("LOG_DIR", os.path.join(os.path.dirname(__file__), "logs"))
LOG_JSON = os.getenv("LOG_JSON", "true").lower() == "true"


def setup_logging() -> None:
    """初始化全局日志配置"""
    loguru.logger.remove()  # 移除默认 handler

    # 1. 控制台：彩色可读
    loguru.logger.add(
        sys.stderr,
        level=LOG_LEVEL,
        format="<green>{time:HH:mm:ss}</green> | <level>{level: <8}</level> | "
               "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
               "<level>{message}</level>",
        colorize=True,
    )

    # 2. 文件：JSON 结构化（生产环境友好接入 ELK / SLS）
    os.makedirs(LOG_DIR, exist_ok=True)

    if LOG_JSON:
        def json_formatter(record):
            import json as _json
            log_entry = {
                "time": record["time"].strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
                "level": record["level"].name,
                "logger": record["name"],
                "function": record["function"],
                "line": record["line"],
                "message": record["message"],
            }
            if record["extra"]:
                log_entry["extra"] = {k: v for k, v in record["extra"].items()}
            # loguru 会再次对 format 返回值做 format_map，转义花括号避免 JSON 的 {} 被当作占位符
            raw = _json.dumps(log_entry, default=str, ensure_ascii=False) + "\n"
            return raw.replace("{", "{{").replace("}", "}}")

        loguru.logger.add(
            os.path.join(LOG_DIR, "api_{time:YYYY-MM-DD}.json.log"),
            level=LOG_LEVEL,
            format=json_formatter,
            rotation="00:00",        # 每天午夜轮转
            retention="30 days",     # 保留 30 天
            compression="gz",        # 压缩旧日志
            encoding="utf-8",
        )

    # 3. 错误日志单独输出（便于告警）
    loguru.logger.add(
        os.path.join(LOG_DIR, "error_{time:YYYY-MM-DD}.log"),
        level="ERROR",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level} | {message}",
        rotation="00:00",
        retention="60 days",
        encoding="utf-8",
    )

    # 拦截 uvicorn/starlette 日志
    class InterceptHandler(logging.Handler):
        def emit(self, record):
            try:
                level = loguru.logger.level(record.levelname).name
            except ValueError:
                level = record.levelno
            frame, depth = logging.currentframe(), 2
            while frame and frame.f_code.co_filename == logging.__file__:
                frame = frame.f_back
                depth += 1
            loguru.logger.opt(depth=depth, exception=record.exc_info).log(
                level, record.getMessage()
            )

    for name in ("uvicorn", "uvicorn.access", "uvicorn.error", "sqlalchemy", "alembic"):
        logger = logging.getLogger(name)
        logger.handlers = [InterceptHandler()]
        logger.propagate = False

    loguru.logger.info("日志系统初始化完成")
