-- ==================================================================
-- 本地推荐系统 — 数据库优化方案（含原始 vs 优化对比注释）
-- 数据库：MySQL 8.0，字符集 utf8mb4
-- 设计目标：3NF + BCNF + 工程化最佳实践
-- ==================================================================
--
-- 【原始设计存在的 8 个问题总览】
--
-- 问题1 | order 表名是 MySQL 保留字 → 每次查询必须加反引号，易出错
-- 问题2 | merchant.rating 存储聚合值 → 违反 3NF，可由 AVG(review.rating) 计算
-- 问题3 | deal.sold_count 存储计数值 → 违反 3NF，可由 COUNT(user_order) 推导
-- 问题4 | category/city 用裸 VARCHAR → 无约束，易出现同一含义不同写法
-- 问题5 | 缺少 updated_at → 无法追踪记录修改时间，不符合工程标准
-- 问题6 | 缺少业务索引 → category/city/created_at 高频查询无加速
-- 问题7 | 外键无 ON DELETE → 删除商家/用户时子表数据悬空，破坏参照完整性
-- 问题8 | rating/price 无 CHECK → 可插入非法值（如 rating=999, price=-10）
--
-- ==================================================================

CREATE DATABASE IF NOT EXISTS local_rec
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE local_rec;


-- ==================================================================
-- 1. 用户表（user）
-- ==================================================================
--
-- 【原始设计问题】
-- ❌ 缺少 updated_at：无法追踪用户最后修改密码/信息的时间，不符合审计要求
--
-- 【优化内容】
-- ✅ 新增 updated_at 列，ON UPDATE CURRENT_TIMESTAMP 自动维护
-- ✅ 命名规范：唯一索引名 uq_user_username（uq=unique，语义清晰）
--
-- 【对比】
-- 原始：CREATE TABLE `user` (id, username, password_hash, created_at)
-- 优化：CREATE TABLE `user` (id, username, password_hash, created_at, updated_at)
--
CREATE TABLE `user` (
    id            INT           NOT NULL AUTO_INCREMENT,
    username      VARCHAR(64)   NOT NULL,
    password_hash VARCHAR(128)  NOT NULL,
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE INDEX uq_user_username (username)
) ENGINE=InnoDB;


-- ==================================================================
-- 2. 城市字典表（city）— 新增表
-- ==================================================================
--
-- 【原始设计问题】
-- ❌ 城市用 merchant.city VARCHAR(32) 直接存储
--    后果1：每次新增商家重复存储"北京"字符串，50 个商家 = 50 次"北京"
--    后果2：输入不一致风险——可能同时出现"北京"、"北京市"、"beijing"
--    后果3：无法统一修改——若需把"北京"改为"北京市"需逐行 UPDATE
--    后果4：没有城市维度的统计/联表——无法扩展城市级别的功能
--
-- 【优化方案】
-- ✅ 提取为独立字典表 city，merchant 通过 city_id 外键引用
--    → 每个城市名只存一次，消除冗余
--    → UNIQUE 约束确保不重复
--    → 统一修改只需 UPDATE 一行
--
-- 【对比】
-- 原始：merchant.city VARCHAR(32) — 1000 商家 = "北京"存 300 次
-- 优化：city(id=1, name='北京') + merchant.city_id=1 — "北京"只存 1 次
--
CREATE TABLE city (
    id   INT          NOT NULL AUTO_INCREMENT,
    name VARCHAR(32)  NOT NULL,
    PRIMARY KEY (id),
    UNIQUE INDEX uq_city_name (name)
) ENGINE=InnoDB;


-- ==================================================================
-- 3. 类别字典表（category）— 新增表
-- ==================================================================
--
-- 【原始设计问题】
-- 与 city 完全一致的问题：merchant.category VARCHAR(32) 裸字符串
-- 同类风险："火锅" / "四川火锅" / "重庆火锅" 写法不可控
--
-- 【优化方案】
-- ✅ 独立字典表，与 city 相同设计模式
--
CREATE TABLE category (
    id   INT          NOT NULL AUTO_INCREMENT,
    name VARCHAR(32)  NOT NULL,
    PRIMARY KEY (id),
    UNIQUE INDEX uq_category_name (name)
) ENGINE=InnoDB;


-- ==================================================================
-- 4. 商家表（merchant）
-- ==================================================================
--
-- 【原始设计问题】
-- ❌ 问题 A：merchant.rating FLOAT DEFAULT 0.0
--    这是典型的"传递依赖"违反 3NF：
--      review.rating → AVG(review.rating) → merchant.rating
--    merchant.rating 可由 review 表完全推导，不应单独存储。
--    存储带来的风险：
--      - 新增点评后若 UPDATE merchant 失败 → 数据不一致
--      - 直接 UPDATE merchant SET rating=5 可伪造评分
--      - 删除/修改点评后需再次重算，容易漏掉
--    FLOAT 类型的额外问题：浮点数存在精度误差，3.3 + 5.0 = 8.3 但 FLOAT 可能存成 8.299999
--
-- ❌ 问题 B：category VARCHAR(32) / city VARCHAR(32)
--    见上方字典表分析，数据冗余 + 一致性风险
--
-- ❌ 问题 C：缺少业务索引
--    category、city、name 是筛选/搜索高频字段，无索引导致全表扫描
--
-- ❌ 问题 D：缺少 updated_at
--
-- 【优化内容】
-- ✅ rating 字段完全移除 → 通过 VIEW merchant_rating 实时计算
-- ✅ category / city 改为 category_id / city_id FK → 消除冗余
-- ✅ 新增 idx_merchant_category / idx_merchant_city / idx_merchant_name
-- ✅ 新增 updated_at
--
-- 【对比】
-- 原始：rating FLOAT, category VARCHAR(32), city VARCHAR(32), 0 个业务索引
-- 优化：price_level INT, category_id FK, city_id FK, 3 个业务索引 + VIEW 计算评分
--
CREATE TABLE merchant (
    id          INT           NOT NULL AUTO_INCREMENT,
    name        VARCHAR(128)  NOT NULL,
    image       VARCHAR(512)  NULL,
    price_level INT           NULL        COMMENT '人均消费（元）',
    category_id INT           NOT NULL,
    city_id     INT           NOT NULL,
    address     VARCHAR(256)  NULL,
    phone       VARCHAR(32)   NULL,
    hours_desc  TEXT          NULL,
    created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY (category_id) REFERENCES category(id),
    FOREIGN KEY (city_id)     REFERENCES city(id),
    INDEX idx_merchant_category (category_id),
    INDEX idx_merchant_city     (city_id),
    INDEX idx_merchant_name     (name)
) ENGINE=InnoDB;


-- ==================================================================
-- 5. 团购表（deal）
-- ==================================================================
--
-- 【原始设计问题】
-- ❌ 问题 A：sold_count INT DEFAULT 0 — 违反 3NF
--    sold_count = COUNT(user_order WHERE deal_id = X)
--    存储冗余计数器的风险：
--      - 创建订单时若 sold_count+=1 成功但 COMMIT 失败 → 计数不准
--      - 删除订单时未同步减 1 → 计数偏大
--      - 直接 UPDATE SET sold_count=99999 可刷数据
--    → 改由 VIEW deal_sales 从 user_order 实时 COUNT
--
-- ❌ 问题 B：original_price / deal_price 无 CHECK 约束
--    可能插入 deal_price > original_price（团购价比原价贵）的非法数据
--    可能插入负价格
--
-- ❌ 问题 C：外键无 ON DELETE CASCADE
--    如果删除商家，其团购商品变成"孤儿记录"（merchant_id 指向不存在的商家）
--
-- ❌ 问题 D：缺少 updated_at
--
-- 【优化内容】
-- ✅ sold_count 移除 → VIEW deal_sales 实时计算
-- ✅ CHECK(deal_price > 0 AND original_price > 0 AND deal_price <= original_price)
-- ✅ FK ON DELETE CASCADE：商家删除自动删除其团购
-- ✅ 新增 idx_deal_merchant 索引
-- ✅ 新增 updated_at
--
-- 【对比】
-- 原始：sold_count INT, 无 CHECK, 无 ON DELETE, 无业务索引
-- 优化：无冗余列, CHECK 2 项, ON DELETE CASCADE, idx_deal_merchant
--
CREATE TABLE deal (
    id             INT            NOT NULL AUTO_INCREMENT,
    merchant_id    INT            NOT NULL,
    title          VARCHAR(256)   NOT NULL,
    original_price DECIMAL(10,2)  NOT NULL,
    deal_price     DECIMAL(10,2)  NOT NULL,
    created_at     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY (merchant_id) REFERENCES merchant(id) ON DELETE CASCADE,
    INDEX idx_deal_merchant (merchant_id),
    CONSTRAINT chk_deal_price CHECK (
        deal_price > 0
        AND original_price > 0
        AND deal_price <= original_price
    )
) ENGINE=InnoDB;


-- ==================================================================
-- 6. 订单表（user_order）
-- ==================================================================
--
-- 【原始设计问题】
-- ❌ 问题 A：表名 `order` 是 MySQL 保留关键字
--    MySQL 8.0 保留字列表含 ORDER, GROUP, SELECT 等
--    后果：每一条 SQL 都必须写成 `order` （反引号），忘记就报语法错误
--    违反 ISO SQL 命名规范
--
-- ❌ 问题 B：status VARCHAR(16) DEFAULT '待使用'
--    VARCHAR 类型存储固定取值集合（待使用/已使用/已退款），浪费空间
--    无约束，可插入任意字符串如 'abc', 'cancelled', '完成' 等
--    → ENUM 存储更紧凑（1-2 字节 vs 3*n 字节），自带取值范围校验
--
-- ❌ 问题 C：缺少业务索引
--    按用户查订单、按时间排序是高频操作，无索引
--
-- ❌ 问题 D：缺少 updated_at
--
-- 【优化内容】
-- ✅ 表名 `order` → `user_order`（避免保留字，同时表达"用户订单"语义）
-- ✅ status VARCHAR → ENUM('待使用','已使用','已退款')
-- ✅ 新增 idx_order_user / idx_order_deal / idx_order_created
-- ✅ 新增 updated_at
--
-- 【对比】
-- 原始：`order` (保留字), status VARCHAR(16), 0 个业务索引
-- 优化：user_order, status ENUM, 3 个业务索引
--
CREATE TABLE user_order (
    id         INT          NOT NULL AUTO_INCREMENT,
    user_id    INT          NOT NULL,
    deal_id    INT          NOT NULL,
    status     ENUM('待使用', '已使用', '已退款') NOT NULL DEFAULT '待使用',
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY (user_id) REFERENCES `user`(id),
    FOREIGN KEY (deal_id) REFERENCES deal(id),
    INDEX idx_order_user    (user_id),
    INDEX idx_order_deal    (deal_id),
    INDEX idx_order_created (created_at)
) ENGINE=InnoDB;


-- ==================================================================
-- 7. 点评表（review）
-- ==================================================================
--
-- 【原始设计问题】
-- ❌ 问题 A：rating SMALLINT 无 CHECK 约束
--    SMALLINT 范围是 -32768 ~ 32767，而业务要求是 1-5
--    没有 CHECK 时可以插入 rating=0, -1, 999，导致评分计算异常
--
-- ❌ 问题 B：外键无 ON DELETE CASCADE
--    删除用户/商家时，点评变成孤儿记录
--
-- ❌ 问题 C：缺少业务索引
--    按商家查点评（merchant_id）、按时间倒序（created_at desc）是核心查询
--    无索引导致每次查点评都全表扫描
--
-- ❌ 问题 D：SMALLINT 范围过大
--    rating 取值 1-5，TINYINT 就够（1 字节 vs 2 字节）
--
-- ❌ 问题 E：缺少 updated_at
--    用户可能需要修改自己的点评内容
--
-- 【优化内容】
-- ✅ rating 类型 TINYINT + CHECK(rating >= 1 AND rating <= 5)
-- ✅ FK ON DELETE CASCADE（user + merchant 双向）
-- ✅ 新增 idx_review_merchant + idx_review_created
-- ✅ 新增 updated_at
--
-- 【对比】
-- 原始：rating SMALLINT 无 CHECK, 无 ON DELETE, 0 个业务索引
-- 优化：rating TINYINT + CHECK 1-5, ON DELETE CASCADE x2, 2 个业务索引
--
CREATE TABLE review (
    id          INT       NOT NULL AUTO_INCREMENT,
    user_id     INT       NOT NULL,
    merchant_id INT       NOT NULL,
    content     TEXT      NOT NULL,
    rating      TINYINT   NOT NULL,
    created_at  DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE INDEX uq_user_merchant (user_id, merchant_id),
    FOREIGN KEY (user_id)     REFERENCES `user`(id)     ON DELETE CASCADE,
    FOREIGN KEY (merchant_id) REFERENCES merchant(id)   ON DELETE CASCADE,
    INDEX idx_review_merchant (merchant_id),
    INDEX idx_review_created  (created_at),
    CONSTRAINT chk_rating_range CHECK (rating >= 1 AND rating <= 5)
) ENGINE=InnoDB;


-- ==================================================================
-- 8. 视图：商家评分（merchant_rating）
-- ==================================================================
--
-- 【为什么用 VIEW 替代 merchant.rating 列？】
--
-- 原始设计：merchant 表有一个 rating FLOAT 列
--   每次添加/修改/删除 review 后，要用 Python 代码 UPDATE merchant SET rating = ...
--   这是典型的"冗余列"，属于 3NF 违规（传递依赖）
--
-- 存储冗余列的三个致命问题：
--   1. 数据不一致：review 表已修改，但 UPDATE merchant 失败/遗漏 → 评分与真实值不一致
--   2. 绕过约束：直接 UPDATE merchant SET rating = 5.0，无需任何 review 即可伪造评分
--   3. 维护负担：任何涉及 review 的操作都要记得同步更新 merchant.rating
--
-- VIEW 方案：
--   - 评分由数据库引擎实时计算，永远与 review 表一致（单一真相来源）
--   - 无法伪造：必须真实插 review 才能改变评分
--   - 零维护：增删改 review 后自动反映
--   - 额外收益：同时返回 review_count，便于前端显示"共 N 条点评"
--
CREATE VIEW merchant_rating AS
SELECT merchant_id,
       ROUND(AVG(rating), 1) AS avg_rating,
       COUNT(*)              AS review_count
FROM review
GROUP BY merchant_id;


-- ==================================================================
-- 9. 视图：团购销量（deal_sales）
-- ==================================================================
--
-- 【为什么用 VIEW 替代 deal.sold_count 列？】
--
-- 与 merchant.rating 同理：
--   原始 sold_count 是冗余计数器，存在数据不一致风险
--   VIEW 从 user_order 实时 COUNT，永远是准确的
--
CREATE VIEW deal_sales AS
SELECT deal_id,
       COUNT(*) AS sold_count
FROM user_order
GROUP BY deal_id;


-- ==================================================================
-- 10. 预填充字典数据
-- ==================================================================
INSERT INTO category (name) VALUES
    ('火锅'), ('日料'), ('川菜'), ('咖啡'),
    ('烧烤'), ('粤菜'), ('西餐'), ('甜品'),
    ('小吃'), ('其他');

INSERT INTO city (name) VALUES
    ('北京'), ('上海'), ('广州'), ('深圳'),
    ('杭州'), ('成都'), ('武汉'), ('南京');


-- ==================================================================
-- 11. 查询示例（优化后 vs 原始）
-- ==================================================================

-- —————— 商家列表（优化后：关联字典表 + 评分视图）——————
-- 原始做法：SELECT * FROM merchant WHERE category='火锅' ... ORDER BY rating DESC
--            → 评分是静态冗余值，可能与实际 review 不一致
-- 优化做法：LEFT JOIN merchant_rating 视图，评分实时计算
SELECT m.id, m.name, m.image, m.price_level,
       c.name  AS category,
       ct.name AS city,
       COALESCE(mr.avg_rating,   0) AS rating,
       COALESCE(mr.review_count, 0) AS review_count
FROM merchant m
JOIN category c   ON m.category_id = c.id
JOIN city ct      ON m.city_id     = ct.id
LEFT JOIN merchant_rating mr ON m.id = mr.merchant_id
WHERE c.name  = '火锅'
  AND ct.name = '北京'
  AND m.name LIKE '%海底捞%'
ORDER BY mr.avg_rating DESC
LIMIT 12 OFFSET 0;

-- —————— 团购列表（优化后：关联销量视图）——————
-- 原始做法：SELECT * FROM deal WHERE merchant_id = 1 （sold_count 是静态值）
-- 优化做法：LEFT JOIN deal_sales 视图，销量实时计算
SELECT d.id, d.title, d.original_price, d.deal_price,
       COALESCE(ds.sold_count, 0) AS sold_count
FROM deal d
LEFT JOIN deal_sales ds ON d.id = ds.deal_id
WHERE d.merchant_id = 1;


-- ==================================================================
-- 附录：优化效果量化对比
-- ==================================================================
--
-- | 对比维度         | 原始设计                | 优化设计                    |
-- |-----------------|------------------------|----------------------------|
-- | 表名规范         | order（保留字，需反引号） | user_order（安全）          |
-- | 范式等级         | 部分 3NF（rating/sold 冗余）| 全部 BCNF                   |
-- | 字典表           | 0 个                    | 2 个（category + city）     |
-- | 冗余列           | 2 个（rating, sold）     | 0 个（全部改为 VIEW）       |
-- | 视图             | 0 个                    | 2 个（实时计算评分 + 销量） |
-- | 外键级联         | 0 处                    | 3 处（ON DELETE CASCADE）   |
-- | CHECK 约束       | 0 个                    | 3 个（价格 x2 + 评分 x1）   |
-- | ENUM 枚举        | 0 个                    | 1 个（order status）        |
-- | updated_at       | 0 张表                  | 5 张表                      |
-- | 业务索引         | 0 个                    | 8 个                        |
-- | 数据一致性风险   | 高（冗余列可不同步）     | 零（单一真相来源）          |
-- | 存储空间         | 较大（字符串反复存储）    | 较小（字典引用 4 字节）     |
--
-- 【范式说明】
-- 1NF：每列原子值，无重复组                 → 原始满足
-- 2NF：非主属性完全函数依赖于主键            → 原始满足
-- 3NF：非主属性不传递依赖于主键              → 原始违反（rating、sold_count）
-- BCNF：每个决定因素都是候选键               → 优化后满足
-- ==================================================================
