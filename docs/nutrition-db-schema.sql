-- 本地营养数据库表结构（SQLite，随App预打包，只读）
-- 数据来源：《中国食物成分表》标准版，1000 种常见食品，均为每 100g 可食部数据

PRAGMA journal_mode = OFF;      -- 只读库，关闭日志减小体积
PRAGMA user_version = 1;        -- 库版本，用于App侧升级校验

-- 食品主表：class_id 与 EfficientNet-Lite4 的 1000 类输出索引一一对应
CREATE TABLE food (
    id            INTEGER PRIMARY KEY,          -- 主键
    class_id      INTEGER NOT NULL UNIQUE,      -- 分类模型输出索引 0~999
    name_cn       TEXT    NOT NULL,             -- 中文名（展示用）
    name_en       TEXT    NOT NULL,             -- 英文名（模型标签名）
    category      TEXT    NOT NULL,             -- 大类：谷物/水果/蔬菜/肉类/水产/乳制品/坚果/饮品/菜肴/零食
    kcal_100g     REAL    NOT NULL,             -- 每100g热量（千卡）
    protein_g     REAL    NOT NULL,             -- 蛋白质（克/100g）
    carb_g        REAL    NOT NULL,             -- 碳水化合物（克/100g）
    fat_g         REAL    NOT NULL,             -- 脂肪（克/100g）
    edible_ratio  REAL    DEFAULT 1.0,          -- 可食部比例（0~1，如香蕉0.59）
    typical_g     REAL    DEFAULT 100           -- 典型单份重量（克），用于份量估算展示
);

-- 别名表：支持用户手动修正时的模糊搜索（如“凤梨”→菠萝）
CREATE TABLE food_alias (
    alias    TEXT NOT NULL,
    food_id  INTEGER NOT NULL REFERENCES food(id)
);

CREATE INDEX idx_food_class   ON food(class_id);
CREATE INDEX idx_food_name    ON food(name_cn);
CREATE INDEX idx_alias        ON food_alias(alias);

-- 示例数据
INSERT INTO food (class_id, name_cn, name_en, category, kcal_100g, protein_g, carb_g, fat_g, edible_ratio, typical_g) VALUES
(0,  '香蕉',   'banana',      '水果', 93,  1.4, 22.0, 0.2, 0.59, 120),
(1,  '苹果',   'apple',       '水果', 53,  0.4, 13.7, 0.2, 0.85, 200),
(2,  '面包',   'bread',       '谷物', 313, 8.3, 58.6, 5.1, 1.00, 60),
(3,  '米饭',   'cooked_rice', '谷物', 116, 2.6, 25.9, 0.3, 1.00, 200),
(4,  '鸡蛋',   'boiled_egg',  '蛋类', 144, 13.3, 2.8, 8.8, 0.87, 50);

INSERT INTO food_alias (alias, food_id) VALUES ('凤梨', 6), ('番茄', 7), ('西红柿', 7);
