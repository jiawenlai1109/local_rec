# 本地推荐系统

本地吃喝玩乐推荐 Web 应用（类似大众点评极简版），支持用户浏览商家、发表点评、购买团购优惠券。

## 技术栈

| 层级 | 技术 |
|---|---|
| 前端 | React 18 + Ant Design + Axios + React Router |
| 后端 | Python 3.12 + FastAPI + SQLAlchemy 2.0 |
| 数据库 | MySQL 8.0 |
| 认证 | JWT（python-jose + bcrypt） |

## 项目结构

```
local_recommend/
├── backend/
│   ├── app/
│   │   ├── main.py              # FastAPI 入口
│   │   ├── api/                 # 路由层（users, merchants, reviews, deals）
│   │   ├── models/              # SQLAlchemy 模型（User, Merchant, Review, Deal, Order）
│   │   ├── schemas/             # Pydantic 请求/响应模型
│   │   ├── core/                # 配置、数据库、安全、依赖注入
│   │   └── services/            # 业务逻辑（预留）
│   ├── seed.py                  # 测试数据填充脚本
│   ├── requirements.txt         # Python 依赖
│   ├── database_schema.sql      # 数据库 DDL + DML（原始版）
│   ├── database_optimized.sql   # 数据库优化方案（含范式分析）
│   └── .env.example             # 环境变量模板
├── frontend/
│   └── src/
│       ├── pages/               # 页面组件（MerchantList, MerchantDetail, Login, Register, Orders）
│       ├── components/          # 通用组件（Layout）
│       └── services/            # API 调用封装
├── plan.md                      # 项目需求文档
├── CLAUDE_CONTEXT.md            # 开发进度记录
└── README.md                    # 本文件
```

## 快速开始

### 1. 环境要求

- Python 3.12+
- Node.js 16+
- MySQL 8.0+

### 2. 创建数据库

```sql
CREATE DATABASE local_rec DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 3. 启动后端

```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # macOS / Linux

pip install -r requirements.txt
copy .env.example .env          # 编辑 .env，填入你的 MySQL 密码
python seed.py                  # 填充测试数据（50 个商家，~200 条点评）

python -m uvicorn app.main:app --reload --port 8000
```

访问 http://localhost:8000/docs 查看 API 文档。

### 4. 启动前端

```bash
cd frontend
npm install
npm start
```

浏览器自动打开 http://localhost:3000。

### 5. 测试账号

| 用户名 | 密码 |
|---|---|
| tester | pass123 |
| user2 | pass123 |
| user3 | pass123 |
| user4 | pass123 |

### 6. 功能流程

1. 浏览商家列表（支持分类/城市筛选 + 关键词搜索 + 分页）
2. 注册新账号
3. 登录
4. 进入商家详情 → 查看团购商品 + 用户点评
5. 购买团购 → 订单状态「待使用」
6. 发表点评（评分 + 文字）→ 商家评分实时更新
7. 查看「我的订单」

## API 路由

| 方法 | 路径 | 需登录 | 说明 |
|---|---|---|---|
| POST | /api/register | 否 | 注册 |
| POST | /api/login | 否 | 登录 |
| GET | /api/merchants | 否 | 商家列表（page, size, category, city, keyword） |
| GET | /api/merchants/{id} | 否 | 商家详情 |
| GET | /api/merchants/{id}/reviews | 否 | 商家点评 |
| POST | /api/reviews | 是 | 发表点评 |
| GET | /api/merchants/{id}/deals | 否 | 商家团购 |
| POST | /api/orders | 是 | 购买团购 |
| GET | /api/orders | 是 | 我的订单 |

## 数据库表

| 表名 | 字段 |
|---|---|
| user | id, username, password_hash, created_at |
| merchant | id, name, image, rating, avg_price, category, city, address, phone, hours_desc |
| review | id, user_id, merchant_id, content, rating (unique: user+merchant) |
| deal | id, merchant_id, title, original_price, deal_price, sold_count |
| order | id, user_id, deal_id, status, created_at |
