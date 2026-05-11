# Claude Code 配置 - 本地推荐系统

## 技术栈
- 后端：FastAPI + SQLAlchemy + PyMySQL + python-jose
- 前端：React 18 + Ant Design + Axios
- 数据库：MySQL 8.0

## 行为准则
1. 每次只执行我指定的单个任务，完成后等待确认。
2. 数据库配置必须从 `.env` 读取，给我 `.env.example` 模板。
3. 不要自动生成测试代码、不要执行任何系统命令。
4. Python 代码使用类型注解，SQLAlchemy 用 2.0 风格。
5. API 统一返回格式：`{"code": 0, "message": "ok", "data": null}`。

## 常用命令
- 启动后端：`uvicorn app.main:app --reload`
- 填充测试数据：`python seed.py`

## 记住的上下文
- 项目总体思路见 `PROJECT_OVERVIEW.md`
- 目录结构见 `PROJECT_STRUCTURE.md`
- 每次对话结束时，请更新 `CLAUDE_CONTEXT.md` 记录进度。

## 上下文恢复
- 每次对话开始时，如果存在 `CLAUDE_CONTEXT.md`，请先读取它。
- 每次完成一个子任务后，请更新 `CLAUDE_CONTEXT.md` 中的“已完成任务”和“下一步计划”。
- 关闭对话前，再次确认文件已更新。