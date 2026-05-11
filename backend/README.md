# 本地推荐系统 — 数据库设计与数据架构文档

## 1. 技术栈

| 层次 | 选型 | 版本 |
|------|------|------|
| 数据库 | MySQL | 8.0 |
| ORM | SQLAlchemy | 2.0 |
| 驱动 | PyMySQL | ≥1.1 |
| 配置管理 | pydantic-settings | 从 `.env` 读取 |
| 连接管理 | sessionmaker（autocommit=False） | 每次请求一个 Session |

---

## 2. ER 模型与表结构

### 2.1 实体关系图（5 张表）

```
user ──1:N──→ review ──N:1──→ merchant
  │                              │
  │                              │
  └──1:N──→ order ──N:1──→ deal ─┘
```

### 2.2 各表说明

#### user（用户表）
| 列 | 类型 | 约束 | 说明 |
|----|------|------|------|
| id | INT PK AUTO_INCREMENT | 主键 | |
| username | VARCHAR(64) | UNIQUE NOT NULL | 登录账号 |
| password_hash | VARCHAR(128) | NOT NULL | bcrypt 哈希 |
| created_at | DATETIME | DEFAULT NOW() | 注册时间 |

#### merchant（商家表）
| 列 | 类型 | 约束 | 说明 |
|----|------|------|------|
| id | INT PK AUTO_INCREMENT | 主键 | |
| name | VARCHAR(128) | NOT NULL | |
| image | VARCHAR(512) | NULL | 图片 URL |
| rating | FLOAT | DEFAULT 0.0 | **冗余列**：AVG(review.rating) |
| avg_price | INT | NULL | 人均消费 |
| category | VARCHAR(32) | NOT NULL | 裸字符串 |
| city | VARCHAR(32) | NOT NULL | 裸字符串 |
| address | VARCHAR(256) | NULL | |
| phone | VARCHAR(32) | NULL | |
| hours_desc | TEXT | NULL | 营业时间 |
| created_at | DATETIME | DEFAULT NOW() | |

#### deal（团购表）
| 列 | 类型 | 约束 | 说明 |
|----|------|------|------|
| id | INT PK AUTO_INCREMENT | 主键 | |
| merchant_id | INT FK→merchant | NOT NULL | |
| title | VARCHAR(256) | NOT NULL | |
| original_price | DECIMAL(10,2) | NOT NULL | |
| deal_price | DECIMAL(10,2) | NOT NULL | |
| sold_count | INT | DEFAULT 0 | **冗余列**：COUNT(order) |
| created_at | DATETIME | DEFAULT NOW() | |

#### order（订单表）
| 列 | 类型 | 约束 | 说明 |
|----|------|------|------|
| id | INT PK AUTO_INCREMENT | 主键 | |
| user_id | INT FK→user | NOT NULL | |
| deal_id | INT FK→deal | NOT NULL | |
| status | VARCHAR(16) | DEFAULT '待使用' | '待使用' / '已使用' / '已退款' |
| created_at | DATETIME | DEFAULT NOW() | |

#### review（点评表）
| 列 | 类型 | 约束 | 说明 |
|----|------|------|------|
| id | INT PK AUTO_INCREMENT | 主键 | |
| user_id | INT FK→user | NOT NULL | |
| merchant_id | INT FK→merchant | NOT NULL | |
| content | TEXT | NOT NULL | |
| rating | SMALLINT | NOT NULL | 1-5 星，应用层校验 |
| created_at | DATETIME | DEFAULT NOW() | |
| UNIQUE(user_id, merchant_id) | — | 每人每店限一条 | |

---

## 3. 设计规范分析

### 3.1 范式分析

**第一范式（1NF）：所有列都是原子值，无重复组**
- 全部满足。每个列存储单一值，没有用逗号分隔的多值列。

**第二范式（2NF）：非主属性完全函数依赖于主键**
- 全部满足。所有表使用单列自增主键，不存在部分依赖。

**第三范式（3NF）：非主属性不传递依赖于主键**
- **violation #1**：`merchant.rating` ← `AVG(review.rating)` ← `review.merchant_id`，存在传递依赖
- **violation #2**：`deal.sold_count` ← `COUNT(order)` ← `order.deal_id`，存在传递依赖
- 其余表满足 3NF

### 3.2 约束完整性

| 约束类型 | 当前状态 | 位置 |
|----------|----------|------|
| PRIMARY KEY | ALL 5 tables | DDL |
| UNIQUE | username, (user_id, merchant_id) | user, review |
| FOREIGN KEY | 4 条 | deal→merchant, order→user, order→deal, review→user, review→merchant |
| NOT NULL | 核心业务字段 | DDL |
| DEFAULT | created_at, rating, sold_count, status | DDL |
| CHECK | **无** | rating 1-5 在应用层校验 |
| ON DELETE CASCADE | **无** | 删除逻辑在 Python 层手动处理 |

### 3.3 字符集与排序规则
- 数据库级：`utf8mb4` / `utf8mb4_unicode_ci`
- 支持完整的 Unicode 字符集（含 Emoji），适合中文环境
- `utf8mb4_unicode_ci` 大小写不敏感排序

---

## 4. 当前设计的优点

1. **简单直接** — 5 张表，ER 关系清晰，学习成本低，适合小团队快速开发
2. **ORM 友好** — SQLAlchemy 2.0 Mapped 风格，类型安全，Python 代码即文档
3. **实时计算评分** — 每次插入点评后用 `AVG(review.rating)` 更新 `merchant.rating`，商家列表排序使用索引字段，查询性能好
4. **连接池内置** — SQLAlchemy connection pool 自动管理连接复用，无需额外配置
5. **请求级 Session** — `get_db()` 依赖注入，每个请求一个事务，结束时自动关闭，无连接泄漏
6. **事务支持** — InnoDB 引擎 + autocommit=False，关键的购买/退款操作在单个 commit 中完成
7. **悲观锁防护** — 购买了单的 3 个写接口使用 `SELECT ... FOR UPDATE`，防止丢失更新和状态竞态

---

## 5. 当前设计的缺点与风险

### 5.1 3NF 违规：冗余列

**（1）merchant.rating（FLOAT）**

```
风险：新增 review 后 UPDATE merchant SET rating = ... 若失败 → 评分与点评数据不一致
     直接 UPDATE merchant SET rating = 5.0 可伪造评分，无需任何 review
     删除/修改 review 后未重算 → 评分不准
     FLOAT 类型有精度误差，3.3 + 5.0 可能存为 8.299999
```

**（2）deal.sold_count（INT）**

```
风险：创建订单时 sold_count += 1 成功但 COMMIT 失败 → 计数偏大（本版本已靠事务+悲观锁缓解）
     退款时 sold_count -= 1 遗漏 → 计数不准
     直接 UPDATE deal SET sold_count = 99999 可刷数据
```

### 5.2 缺少字典表

`merchant.category` 和 `merchant.city` 用裸 VARCHAR：
- 同一含义可能出现多种写法（"火锅" / "四川火锅" / "重庆火锅"）
- 1000 个商家就有 1000 次字符串重复存储，浪费空间
- 无法统一修改（比如"北京"要改成"北京市"，需逐行 UPDATE）

### 5.3 缺少 CHECK 约束

- `review.rating` 用 SMALLINT 无 CHECK，可插入 0、-1、999 等非法值
- `deal.original_price` / `deal.deal_price` 无 CHECK，可插入负值或团购价高于原价
- 全部依赖应用层校验，任何绕过 API 的数据写入都可能破坏数据完整性

### 5.4 缺少 ON DELETE CASCADE

删除用户或商家时，需要 Python 代码手动逐表清理子记录（reviews → orders → user）。若清理逻辑有遗漏，会产生孤儿记录（FK 指向不存在的行）。

### 5.5 缺少业务索引

当前只有主键索引和 UNIQUE 约束自带索引。以下高频查询无索引加速：
- 按 `category` 筛选商家（全表扫描）
- 按 `city` 筛选商家（全表扫描）
- 按 `created_at` 排序（order、review 表）
- `merchant.name` 模糊搜索（LIKE '%keyword%'）
- `review.merchant_id` 查询点评列表

### 5.6 命名问题

`order` 是 MySQL 保留关键字，每次 SQL 必须用反引号 \`order\` 包裹，容易遗漏导致语法错误。

### 5.7 缺少审计字段

所有表都没有 `updated_at` 列，无法追踪记录修改时间。

---

## 6. 优化方案

完整的优化版 DDL 见 `database_optimized.sql`（含原始 vs 优化对比注释），核心改动总结：

| 维度 | 当前 | 优化 | 收益 |
|------|------|------|------|
| 命名 | `order`（保留字） | `user_order` | 无需反引号 |
| 范式 | 部分 3NF | BCNF | 消除冗余列 |
| 字典表 | 0 | category + city | 数据一致 + 省空间 |
| 冗余列 | rating, sold_count | 改为 VIEW 实时计算 | 单一真相来源 |
| CHECK | 0 | 3 个（价格×2 + 评分） | 数据库级约束 |
| ON DELETE | 0 | 3 处 CASCADE | 自动级联清理 |
| ENUM | status VARCHAR(16) | ENUM('待使用','已使用','已退款') | 存储更紧凑 + 自带校验 |
| 类型 | rating SMALLINT | TINYINT + CHECK(1-5) | 节省 50% 空间 |
| updated_at | 0 | 5 张表 | 审计追溯 |
| 业务索引 | 0 | 8 个 | 查询加速 |
| 视图 | 0 | merchant_rating + deal_sales | 评分/销量实时准确 |

### 6.1 视图方案详解

**merchant_rating 视图**：替代 `merchant.rating` 冗余列
```sql
CREATE VIEW merchant_rating AS
SELECT merchant_id,
       ROUND(AVG(rating), 1) AS avg_rating,
       COUNT(*)              AS review_count
FROM review
GROUP BY merchant_id;
```
优点：评分永远与 review 表一致（单一真相来源），零维护，同时提供点评数量。

**deal_sales 视图**：替代 `deal.sold_count` 冗余列
```sql
CREATE VIEW deal_sales AS
SELECT deal_id, COUNT(*) AS sold_count
FROM user_order
GROUP BY deal_id;
```
优点：销量从订单表实时计算，永远准确。

### 6.2 索引设计原则

```
高频筛选列 → INDEX：category_id, city_id, merchant_id
排序 + 范围查询列 → INDEX：created_at（review, user_order）
外键列 → INDEX（JOIN 加速）：所有 FK 列
模糊搜索 → 考虑全文索引（InnoDB FULLTEXT）
```

---

## 7. 并发控制设计

### 7.1 问题场景

| 接口 | 并发风险 |
|------|----------|
| `POST /api/orders` | 两人同时购买同一 deal → sold_count 丢失更新 |
| `PUT /api/orders/{id}/use` | 使用+退款同时请求 → 两个都成功 |
| `PUT /api/orders/{id}/refund` | 退款+使用同时请求 + 销量并发写 |

### 7.2 方案：悲观锁（SELECT ... FOR UPDATE）

MySQL InnoDB 行级锁，在事务中锁定目标行，串行化写操作：

```
create_order:  SELECT deal WHERE id=X FOR UPDATE    → 锁 deal 行
use_order:     SELECT order WHERE id=Y FOR UPDATE   → 锁 order 行
refund_order:  SELECT order WHERE id=Y FOR UPDATE   → 锁 order 行
               SELECT deal WHERE id=Z FOR UPDATE    → 锁 deal 行
```

### 7.3 隔离级别

MySQL 默认 `REPEATABLE READ`，配合行锁，能保证：
- **无丢失更新**（Lost Update）：锁保证串行读写
- **无脏写**（Dirty Write）：两个事务不能同时修改同一行
- **无幻读**（Phantom Read）：`FOR UPDATE` 锁定索引间隙

每个事务持有锁的时间是毫秒级（一次读写+commit），不会造成性能瓶颈。

### 7.4 为什么不用其他方案

| 方案 | 不选择的原因 |
|------|-------------|
| 乐观锁（version 字段） | 需改表结构加 version 列，侵入性强，冲突时需重试 |
| `UPDATE WHERE` 原子操作 | 无法在更新前做业务校验（如检查状态是否为"待使用"） |
| SERIALIZABLE 隔离级别 | MySQL 下会将行锁升级为表锁，性能差，需全局重试机制 |

---

## 8. ORM 配置说明

### 8.1 连接管理（database.py）

```python
engine = create_engine(settings.DATABASE_URL)    # 连接池：默认 5 + 10 overflow
SessionLocal = sessionmaker(engine, autocommit=False, autoflush=False)
```

- `autocommit=False`：每次请求一个隐式事务，`.commit()` 显式提交，异常自动回滚
- `autoflush=False`：手动控制 flush 时机（如 `db.flush()` 获取自增 ID），避免意外 DB 写入
- `get_db()`：FastAPI 依赖注入生成器，`yield` 提供 Session，`finally` 确保关闭归还连接池

### 8.2 配置读取（config.py）

```python
class Settings(BaseSettings):
    DB_HOST: str       # 从 .env 读取
    DB_PORT: int
    DB_USER: str
    DB_PASSWORD: str
    DB_NAME: str

    @property
    def DATABASE_URL(self) -> str:
        return f"mysql+pymysql://{self.DB_USER}:{self.DB_PASSWORD}@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
```

敏感信息不硬编码，`.env` 已加入 `.gitignore`，提供 `.env.example` 模板。

---

## 9. 数据字典速查

### 9.1 order 状态机

```
待使用 ──→ 已使用
  │
  └──────→ 已退款
```

| 状态 | 含义 | 触发操作 |
|------|------|----------|
| 待使用 | 已购买，未使用 | POST /api/orders |
| 已使用 | 已到店使用 | PUT /api/orders/{id}/use |
| 已退款 | 已取消退款 | PUT /api/orders/{id}/refund |

### 9.2 review.rating 取值范围

| 值 | 含义 |
|----|------|
| 1 | 很差 |
| 2 | 较差 |
| 3 | 一般 |
| 4 | 较好 |
| 5 | 很好 |

---

## 10. 维护建议

1. **定期备份**：`mysqldump local_rec > backup_$(date +%Y%m%d).sql`
2. **慢查询监控**：开启 `slow_query_log`，关注全表扫描的查询（如商家列表无索引的筛选）
3. **索引优化**：根据实际查询频率，优先为 `merchant.category` 和 `merchant.city` 添加索引
4. **迁移路径**：如需升级到 `database_optimized.sql` 的设计，先创建字典表 → 数据迁移 → 加约束 → 创建视图 → 移除冗余列，逐步灰度
