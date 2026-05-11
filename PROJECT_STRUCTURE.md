local_recommend/                # 项目根目录
│
├── backend/                    # 后端根目录（建议叫 backend 而非 app，避免歧义）
│   ├── app/                    # FastAPI 应用主包
│   │   ├── __init__.py
│   │   ├── main.py             # 入口：创建 FastAPI 实例，注册路由
│   │   ├── api/                # 路由层（按模块拆分）
│   │   │   ├── __init__.py
│   │   │   ├── users.py
│   │   │   ├── merchants.py
│   │   │   ├── reviews.py
│   │   │   └── deals.py
│   │   ├── models/             # SQLAlchemy 模型
│   │   │   ├── __init__.py
│   │   │   ├── user.py
│   │   │   ├── merchant.py
│   │   │   ├── review.py
│   │   │   ├── deal.py
│   │   │   └── order.py
│   │   ├── schemas/            # Pydantic 请求/响应模型
│   │   │   ├── __init__.py
│   │   │   ├── user.py
│   │   │   ├── merchant.py
│   │   │   ├── review.py
│   │   │   ├── deal.py
│   │   │   └── order.py
│   │   ├── core/               # 核心配置、安全、依赖
│   │   │   ├── __init__.py
│   │   │   ├── config.py       # 读取 .env 配置
│   │   │   ├── database.py     # 创建 engine 和 SessionLocal
│   │   │   ├── security.py     # JWT 生成/验证、密码哈希
│   │   │   └── dependencies.py # 通用依赖（如 get_current_user）
│   │   └── services/           # 业务逻辑层（可选，简单 crud 可放在 api 中）
│   │       ├── __init__.py
│   │       ├── user_service.py
│   │       └── merchant_service.py
│   │
│   ├── requirements.txt        # Python 依赖列表
│   ├── .env.example            # 环境变量模板（DB连接、JWT密钥等）
│   ├── seed.py                 # 测试数据填充脚本（使用 Faker）
│   └── README.md               # 后端运行说明
│
├── frontend/                   # 前端根目录（create-react-app 生成后调整）
│   ├── public/                 # 静态资源（index.html 等）
│   ├── src/
│   │   ├── index.js            # React 入口
│   │   ├── App.js              # 根组件
│   │   ├── pages/              # 页面级组件
│   │   │   ├── MerchantList.js
│   │   │   ├── MerchantDetail.js
│   │   │   ├── Login.js
│   │   │   ├── Register.js
│   │   │   └── Orders.js
│   │   ├── components/         # 通用组件（Header, Footer, ReviewCard 等）
│   │   ├── services/           # API 调用封装
│   │   │   ├── api.js          # axios 实例，添加拦截器
│   │   │   ├── merchants.js
│   │   │   ├── reviews.js
│   │   │   └── orders.js
│   │   ├── hooks/              # 自定义 hooks（如 useAuth, usePagination）
│   │   ├── utils/              # 工具函数（如格式化日期、价格）
│   │   └── styles/             # 全局样式文件（可选）
│   ├── package.json
│   └── .env                    # 前端环境变量（如 REACT_APP_API_BASE_URL）
│
├── plan.md                     # 项目总体思路（业务需求+技术栈）
├── claude.md                   # Claude Code 协作规则
└── .gitignore                  # 忽略 venv, node_modules, .env, __pycache__