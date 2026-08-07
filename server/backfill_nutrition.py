"""
回填脚本：遍历所有营养字段为空的食物记录，调用 VLM 按名称查营养并更新数据库。

使用方式：
    cd server && python3 backfill_nutrition.py

解决的问题：
    旧记录在创建时（营养字段支持之前）没有携带营养数据，
    导致"对方的"贴纸详情页看不到营养成分和小贴士。
    本脚本按食物名称调用 VLM 补全 protein_g / carb_g / fat_g /
    dietary_fiber_g / sodium_mg / vitamin_tips 字段。
"""
import json
import os
import time
from collections import defaultdict
from typing import Optional

import httpx
from dotenv import load_dotenv

from db import SessionLocal, Record, init_db

load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

VLM_BASE = os.getenv("VLM_BASE_URL", "")
VLM_KEY = os.getenv("VLM_API_KEY", "")
VLM_MODEL = os.getenv("VLM_MODEL", "hunyuan-vision")

VLM_SYS = (
    "依据中国食物成分表返回食品每100g营养JSON："
    '{"name_cn":...,"kcal_100g":...,"protein_g":...,"carb_g":...,"fat_g":...,'
    '"dietary_fiber":...,"sodium_mg":...,'
    '"vitamin_tips":"一句健康小贴士（不要emoji、不要markdown）"}'
)


def query_nutrition(name: str) -> Optional[dict]:
    """按食物名称调用 VLM 查询每 100g 营养数据"""
    body = {
        "model": VLM_MODEL,
        "messages": [
            {"role": "system", "content": VLM_SYS},
            {"role": "user", "content": name},
        ],
        "response_format": {"type": "json_object"},
        "temperature": 0,
    }
    try:
        with httpx.Client(timeout=30) as cli:
            r = cli.post(
                f"{VLM_BASE}/chat/completions",
                json=body,
                headers={"Authorization": f"Bearer {VLM_KEY}"},
            )
            r.raise_for_status()
            content = r.json()["choices"][0]["message"]["content"]
            # 兜底：VLM 偶尔返回 markdown 包裹的 JSON
            content = content.strip()
            if content.startswith("```"):
                content = content.split("\n", 1)[-1].rsplit("```", 1)[0].strip()
            return json.loads(content)
    except Exception as e:
        print(f"  [VLM 错误] {name}: {e}")
        return None


def main():
    init_db()
    with SessionLocal() as s:
        # 查询所有营养字段为空的食物记录
        recs = (
            s.query(Record)
            .filter(Record.type == "food")
            .filter((Record.protein_g == 0) | (Record.vitamin_tips == ""))
            .all()
        )
        print(f"共 {len(recs)} 条食物记录需要回填营养数据\n")

        # 按名称去重：同名的记录只需调用一次 VLM
        name_to_records: dict[str, list[Record]] = defaultdict(list)
        for r in recs:
            name_to_records[r.name].append(r)

        print(f"去重后需查询 {len(name_to_records)} 种食物\n")

        success = 0
        fail = 0
        for i, (name, records) in enumerate(name_to_records.items(), 1):
            print(f"[{i}/{len(name_to_records)}] 查询: {name}")
            data = query_nutrition(name)
            if not data:
                fail += len(records)
                continue

            protein = float(data.get("protein_g", 0) or 0)
            carb = float(data.get("carb_g", 0) or 0)
            fat = float(data.get("fat_g", 0) or 0)
            fiber = float(data.get("dietary_fiber", 0) or 0)
            sodium = float(data.get("sodium_mg", 0) or 0)
            tips = data.get("vitamin_tips", "") or ""

            for r in records:
                r.protein_g = protein
                r.carb_g = carb
                r.fat_g = fat
                r.dietary_fiber_g = fiber
                r.sodium_mg = sodium
                r.vitamin_tips = tips
                success += 1

            print(f"  → 蛋白质={protein}g 碳水={carb}g 脂肪={fat}g "
                  f"纤维={fiber}g 钠={sodium}mg")
            print(f"  → 小贴士: {tips[:40]}")
            time.sleep(0.5)  # 避免 API 限流

        s.commit()
        print(f"\n回填完成: 成功 {success} 条, 失败 {fail} 条")


if __name__ == "__main__":
    main()
