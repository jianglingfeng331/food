"""
《中国食物成分表》CSV → nutrition.db（SQLite，App 预打包）

CSV 列: class_id,name_cn,name_en,category,kcal_100g,protein_g,carb_g,fat_g,edible_ratio,typical_g
用法: python build_nutrition_db.py --csv nutrition_1000.csv --alias alias.csv --out nutrition.db
"""
import argparse, csv, sqlite3, os

SCHEMA = os.path.join(os.path.dirname(__file__), "../docs/nutrition-db-schema.sql")

def main(args):
    if os.path.exists(args.out):
        os.remove(args.out)
    db = sqlite3.connect(args.out)
    with open(SCHEMA, encoding="utf-8") as f:
        # 只执行建表/索引语句，跳过示例 INSERT
        stmts = [s for s in f.read().split(";") if s.strip() and "INSERT" not in s.upper()]
    for s in stmts:
        db.execute(s)

    with open(args.csv, encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    assert len(rows) == 1000, f"需要1000条，当前{len(rows)}"
    db.executemany(
        """INSERT INTO food (class_id,name_cn,name_en,category,kcal_100g,
           protein_g,carb_g,fat_g,edible_ratio,typical_g)
           VALUES (:class_id,:name_cn,:name_en,:category,:kcal_100g,
                   :protein_g,:carb_g,:fat_g,:edible_ratio,:typical_g)""", rows)

    if args.alias:
        with open(args.alias, encoding="utf-8") as f:
            db.executemany("INSERT INTO food_alias (alias, food_id) VALUES (?,?)",
                           [(r["alias"], int(r["food_id"])) for r in csv.DictReader(f)])
    db.execute("VACUUM")
    db.commit()
    db.close()
    print(f"OK -> {args.out} ({os.path.getsize(args.out)//1024} KB)")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True)
    ap.add_argument("--alias")
    ap.add_argument("--out", default="nutrition.db")
    main(ap.parse_args())
