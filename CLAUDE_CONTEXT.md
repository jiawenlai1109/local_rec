# 项目进度记录

## 当前阶段
阶段 8：全部 CRUD + 并发安全完成，项目可交付

## 项目概述
本地吃喝玩乐推荐系统（大众点评极简版）。技术栈：FastAPI + SQLAlchemy 2.0 + MySQL 8.0 / React 18 + Ant Design + Axios。

---

## 已完成

### 阶段 0-2：项目初始化 → 后端 API（2026-05-02）
- [x] 目录结构、requirements.txt、.env.example、config/database/security/dependencies
- [x] 5 个 SQLAlchemy 模型（User, Merchant, Review, Deal, Order）
- [x] 5 个 Pydantic Schema 文件
- [x] 4 个 API 路由（users, merchants, reviews, deals/orders）
- [x] `app/main.py` — FastAPI 应用 + CORS + 4 个 router

### 阶段 3-4：前端完整开发（2026-05-02）
- [x] create-react-app + antd + axios + react-router-dom
- [x] 5 个 service 文件（api.js + auth/merchants/reviews/deals）
- [x] Layout.js（顶部导航 + 登录态切换 + 路径监听更新）
- [x] App.js（BrowserRouter + 6 个路由 + Layout 包裹）
- [x] 5 个页面全部完整实现（MerchantList, MerchantDetail, Login, Register, Orders）

### 阶段 5：联调 + Bug 修复（2026-05-02/03）
- [x] **JWT sub 类型 Bug**（python-jose 要求 string，传了 int）← 核心修复
- [x] bcrypt 4.2.x 不兼容 passlib → 降级到 bcrypt==4.0.1
- [x] axios 拦截器 Bearer null Bug（interceptor 删除外部传入 header）
- [x] seed.py 重复点评 Bug（random.choice → random.sample）
- [x] 后端 reviews.py 首次点评 float(None) 崩溃（db.flush + or 0）
- [x] 前端 Layout.js 登录后导航栏不更新（useEffect + location.pathname）
- [x] deals.py 总数查询优化（func.count 替代全表加载）

### 阶段 6：账号注销功能（2026-05-11）
- [x] 后端 `DELETE /api/users/me` — 手动删除关联 reviews + orders 后删除 user
- [x] 前端 `auth.js` 新增 `deleteAccount()` — 调用 API 后清除 token
- [x] 前端 `Layout.js` 新增红色"注销账号"按钮 + Modal.confirm 确认弹窗

### 阶段 7：订单使用 + 退款（2026-05-11）
- [x] 后端 `PUT /api/orders/{id}/use` — 状态改为"已使用"，校验归属 + 状态必须为"待使用"
- [x] 后端 `PUT /api/orders/{id}/refund` — 状态改为"已退款"，deal.sold_count -= 1，同时锁定 Deal
- [x] 前端 `deals.js` 新增 `useOrder()` / `refundOrder()`
- [x] 前端 `Orders.js` 新增"去使用"/"退款"按钮 + 确认弹窗
- [x] 状态标签三色：蓝（待使用）、绿（已使用）、橙（已退款）

### 阶段 8：并发安全——悲观锁（2026-05-11）
- [x] `create_order` — `select(Deal).with_for_update()` 防销量丢失更新
- [x] `use_order` — `select(Order).with_for_update()` 防状态竞态
- [x] `refund_order` — Order + Deal 双行锁，防状态竞态 + 销量丢失
- [x] 测试：20 线程同时购买同一 deal，sold_count 精确 +20 ✅
- [x] 测试：同时使用+退款同一订单，一成一败，状态正确 ✅

### 文档
- [x] `plan.md` — 项目总体需求文档
- [x] `PROJECT_STRUCTURE.md` — 目录结构
- [x] `CLAUDE_CONTEXT.md` — 本文档
- [x] `backend/database_schema.sql` — 原始版完整 DDL + DML
- [x] `backend/database_optimized.sql` — 优化版（8 问题 + 11 维对比 + 范式分析）
- [x] `backend/README.md` — 数据库设计文档（ER 图/范式/优缺点/并发/ORM 配置）

---

## 当前后端 API 全景

| 方法 | 路径 | 功能 | 鉴权 |
|------|------|------|------|
| POST | /api/register | 注册 | 无 |
| POST | /api/login | 登录，返回 JWT | 无 |
| DELETE | /api/users/me | 注销当前账号 | 登录 |
| GET | /api/merchants | 商家列表（分页+筛选+关键词） | 无 |
| GET | /api/merchants/{id} | 商家详情 | 无 |
| GET | /api/merchants/{id}/reviews | 商家点评列表 | 无 |
| POST | /api/reviews | 发表点评（每人每店一条） | 登录 |
| GET | /api/merchants/{id}/deals | 商家团购列表 | 无 |
| GET | /api/deals | 所有团购（分页） | 无 |
| POST | /api/orders | 购买团购 | 登录 |
| GET | /api/orders | 我的订单 | 登录 |
| PUT | /api/orders/{id}/use | 使用订单 | 登录 |
| PUT | /api/orders/{id}/refund | 退款订单 | 登录 |
| GET | / | 健康检查 | 无 |

---

## 前端路由

| 路径 | 页面 | 鉴权 |
|------|------|------|
| / | 商家列表（首页） | 无 |
| /merchants | 商家列表 | 无 |
| /merchant/:id | 商家详情 | 无 |
| /login | 登录 | 无 |
| /register | 注册 | 无 |
| /orders | 我的订单 | 登录 |

---

## 技术要点（踩过的坑）

- **JWT sub 必须是字符串**：`create_access_token({"sub": str(user.id)})`，校验时 `int(payload.get("sub"))`
- **bcrypt 必须 4.0.x**：passlib 不兼容 4.1+，固定 `bcrypt==4.0.1`
- **axios 拦截器不删除外部 header**：`if (token && !config.headers.Authorization)`
- **seed.py 用 random.sample 避免 FK 冲突**
- **前端无 `.env` 文件**：`PORT` 和 `REACT_APP_API_BASE_URL` 均用默认值（3000 / localhost:8000/api）
- **后端无 `APP_PORT` 配置**：端口号在 uvicorn 命令行 `--port 8000` 指定

---

## 数据设计快览

- 5 张表：user → review ← merchant → deal ← order ← user
- 2 处 3NF 违规：`merchant.rating`（冗余评分）、`deal.sold_count`（冗余销量）
- `order` 是 MySQL 保留字，SQLAlchemy 自动加反引号
- 无 CHECK、无 ON DELETE CASCADE、无业务索引 → 详见 `backend/README.md` 优化方案
- 悲观锁覆盖 3 个写接口（create/use/refund order）

---

## 启动方式

```bash
# 后端（Git Bash / CMD）
cd backend
venv\Scripts\activate
python -m uvicorn app.main:app --reload --port 8000

# 前端（另开终端）
cd frontend
npm start
```

---

## 待完成
- [ ] 前端添加 `.env` 文件，集中管理端口和 API 地址
- [ ] 后端从 `.env` 读取 `APP_PORT`
- [ ] 发表点评页面完善（当前商家详情页可直接发表）
