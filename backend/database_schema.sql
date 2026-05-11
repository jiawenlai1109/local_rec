-- ============================================================
-- 本地推荐系统 — 数据库完整 SQL（等效于 SQLAlchemy ORM 操作）
-- 数据库：MySQL 8.0，字符集 utf8mb4
-- ============================================================

-- 1. 创建数据库
CREATE DATABASE IF NOT EXISTS local_rec
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE local_rec;


-- ============================================================
-- 2. DDL：建表语句（由 SQLAlchemy Base.metadata.create_all 生成）
-- ============================================================

CREATE TABLE `user` (
    id         INT           NOT NULL AUTO_INCREMENT,
    username   VARCHAR(64)   NOT NULL,
    password_hash VARCHAR(128) NOT NULL,
    created_at DATETIME      DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE INDEX ix_user_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE merchant (
    id         INT           NOT NULL AUTO_INCREMENT,
    name       VARCHAR(128)  NOT NULL,
    image      VARCHAR(512)  NULL,
    rating     FLOAT         NOT NULL DEFAULT 0.0,
    avg_price  INT           NULL,
    category   VARCHAR(32)   NOT NULL,
    city       VARCHAR(32)   NOT NULL,
    address    VARCHAR(256)  NULL,
    phone      VARCHAR(32)   NULL,
    hours_desc TEXT          NULL,
    created_at DATETIME      DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE deal (
    id             INT           NOT NULL AUTO_INCREMENT,
    merchant_id    INT           NOT NULL,
    title          VARCHAR(256)  NOT NULL,
    original_price NUMERIC(10,2) NOT NULL,
    deal_price     NUMERIC(10,2) NOT NULL,
    sold_count     INT           NOT NULL DEFAULT 0,
    created_at     DATETIME      DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY (merchant_id) REFERENCES merchant(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE `order` (
    id         INT          NOT NULL AUTO_INCREMENT,
    user_id    INT          NOT NULL,
    deal_id    INT          NOT NULL,
    status     VARCHAR(16)  NOT NULL DEFAULT '待使用',
    created_at DATETIME     DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY (user_id) REFERENCES `user`(id),
    FOREIGN KEY (deal_id) REFERENCES deal(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE review (
    id          INT       NOT NULL AUTO_INCREMENT,
    user_id     INT       NOT NULL,
    merchant_id INT       NOT NULL,
    content     TEXT      NOT NULL,
    rating      SMALLINT  NOT NULL,
    created_at  DATETIME  DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE uk_user_merchant (user_id, merchant_id),
    FOREIGN KEY (user_id) REFERENCES `user`(id),
    FOREIGN KEY (merchant_id) REFERENCES merchant(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- 3. DML：API 接口对应的 SQL 语句
-- ============================================================

-- --------------------------------------------
-- 3.1 用户模块（app/api/users.py）
-- --------------------------------------------

-- POST /api/register — 注册前查重
SELECT user.id, user.username, user.password_hash, user.created_at
FROM `user`
WHERE `user`.username = 'tester';

-- POST /api/register — 插入新用户
INSERT INTO `user` (username, password_hash)
VALUES ('tester', '$2b$12$...');

-- POST /api/login — 登录查用户
SELECT user.id, user.username, user.password_hash, user.created_at
FROM `user`
WHERE `user`.username = 'tester';


-- --------------------------------------------
-- 3.2 商家模块（app/api/merchants.py）
-- --------------------------------------------

-- GET /api/merchants — 总数统计
SELECT count(merchant.id) AS count_1
FROM merchant;

-- GET /api/merchants — 分类+城市筛选+关键词搜索+分页
SELECT merchant.id, merchant.name, merchant.image, merchant.rating,
       merchant.avg_price, merchant.category, merchant.city,
       merchant.address, merchant.phone, merchant.hours_desc, merchant.created_at
FROM merchant
WHERE merchant.category = '火锅'
  AND merchant.city = '北京'
  AND merchant.name LIKE '%海底捞%'
ORDER BY merchant.rating DESC
LIMIT 12 OFFSET 0;

-- GET /api/merchants/{id} — 商家详情
SELECT merchant.id, merchant.name, merchant.image, merchant.rating,
       merchant.avg_price, merchant.category, merchant.city,
       merchant.address, merchant.phone, merchant.hours_desc, merchant.created_at
FROM merchant
WHERE merchant.id = 1;


-- --------------------------------------------
-- 3.3 点评模块（app/api/reviews.py）
-- --------------------------------------------

-- GET /api/merchants/{id}/reviews — 点评列表（JOIN 用户表取用户名）
SELECT review.id, review.user_id, review.merchant_id,
       review.content, review.rating, review.created_at,
       `user`.username
FROM review
JOIN `user` ON review.user_id = `user`.id
WHERE review.merchant_id = 1
ORDER BY review.created_at DESC;

-- POST /api/reviews — 查重（该用户是否已点评该商家）
SELECT review.id, review.user_id, review.merchant_id,
       review.content, review.rating, review.created_at
FROM review
WHERE review.user_id = 1 AND review.merchant_id = 1;

-- POST /api/reviews — 插入点评
INSERT INTO review (user_id, merchant_id, content, rating)
VALUES (1, 1, '味道不错，环境也很好！', 5);

-- POST /api/reviews — 重新计算商家平均评分
SELECT avg(review.rating) AS avg_1
FROM review
WHERE review.merchant_id = 1;

-- POST /api/reviews — 更新商家评分（Python 端 round(float(avg), 1) 后 UPDATE）
UPDATE merchant SET rating = 4.3 WHERE merchant.id = 1;


-- --------------------------------------------
-- 3.4 团购与订单模块（app/api/deals.py）
-- --------------------------------------------

-- GET /api/merchants/{id}/deals — 某商家的团购商品
SELECT deal.id, deal.merchant_id, deal.title,
       deal.original_price, deal.deal_price, deal.sold_count, deal.created_at
FROM deal
WHERE deal.merchant_id = 1;

-- GET /api/deals — 所有团购（分页，按销量降序）
SELECT count(deal.id) AS count_1 FROM deal;

SELECT deal.id, deal.merchant_id, deal.title,
       deal.original_price, deal.deal_price, deal.sold_count, deal.created_at
FROM deal
ORDER BY deal.sold_count DESC
LIMIT 10 OFFSET 0;

-- POST /api/orders — 购买团购：插入订单
INSERT INTO `order` (user_id, deal_id, status)
VALUES (1, 3, '待使用');

-- POST /api/orders — 同时更新团购销量（Python 端 deal.sold_count += 1）
UPDATE deal SET sold_count = sold_count + 1 WHERE deal.id = 3;

-- GET /api/orders — 我的订单（JOIN 团购 + 商家）
SELECT `order`.id, `order`.user_id, `order`.deal_id,
       `order`.status, `order`.created_at,
       deal.id, deal.merchant_id, deal.title,
       deal.original_price, deal.deal_price, deal.sold_count, deal.created_at,
       merchant.name
FROM `order`
JOIN deal ON `order`.deal_id = deal.id
JOIN merchant ON deal.merchant_id = merchant.id
WHERE `order`.user_id = 1
ORDER BY `order`.created_at DESC;


-- ============================================================
-- 4. 清空数据（seed.py 按外键倒序删除）
-- ============================================================

DELETE FROM `order`;
DELETE FROM review;
DELETE FROM deal;
DELETE FROM merchant;
DELETE FROM `user`;
