# 基于 uv 的项目架构说明

Copyright (c) 2024 StanleyChanH
Licensed under the MIT License

## 🏗️ 项目架构概览

本项目采用现代化的Python包管理和项目结构，完全基于 `uv` 进行依赖管理和任务执行。

## 📦 技术栈

### 核心依赖
- **FastAPI**: 现代、快速的Web框架
- **uvicorn**: ASGI服务器，支持标准扩展
- **Pydantic**: 数据验证和序列化
- **python-multipart**: 多部分表单数据支持

### 开发工具
- **pytest**: 测试框架
- **pytest-asyncio**: 异步测试支持
- **httpx**: 异步HTTP客户端
- **requests**: HTTP请求库
- **ruff**: 快速Python代码检查器
- **black**: Python代码格式化工具
- **mypy**: 静态类型检查器

## 🗂️ 项目结构

```
ChinaTaxTool/
├── app.py                    # 主应用文件 (FastAPI + 命令行接口)
├── index.html                # 前端单页应用 (包含所有CSS和JS)
├── pyproject.toml           # 项目配置和依赖管理
├── Makefile                  # 任务自动化
├── start_uv.sh              # uv版本启动脚本
├── start.sh                 # 传统启动脚本 (备用)
├── test_api.py              # API测试脚本
├── PROJECT_SUMMARY.md       # 项目总结
├── TROUBLESHOOTING.md       # 故障排除指南
├── README.md                # 项目说明文档
├── UV_ARCHITECTURE.md       # 本架构文档
└── .venv/                   # uv虚拟环境 (自动创建)
```

## ⚙️ 配置详解

### pyproject.toml 配置

```toml
[project]
name = "china-tax-tool"
version = "1.0.0"
description = "中国个人所得税（年度累计预扣预缴）计算器"
authors = [
    {name = "ChinaTaxTool Developer", email = "dev@chinataxtool.com"}
]
requires-python = ">=3.8"
dependencies = [
    "fastapi>=0.104.1",
    "uvicorn[standard]>=0.24.0",
    "pydantic>=2.5.0",
    "python-multipart>=0.0.6"
]

[dependency-groups]
dev = [
    "pytest>=7.4.0",
    "pytest-asyncio>=0.21.0",
    "httpx>=0.25.0",
    "requests>=2.31.0",
    "ruff>=0.1.0",
    "black>=23.0.0",
    "mypy>=1.5.0",
]

[project.scripts]
china-tax-tool = "app:main"
```

### 主要特性

1. **现代化依赖管理**: 使用 `dependency-groups` 替代 `optional-dependencies`
2. **命令行接口**: 支持多种启动参数
3. **开发工具集成**: 完整的linting、formatting、testing工具链
4. **标准Python入口**: 使用 `project.scripts` 创建可执行命令

## 🚀 启动方式

### 1. 一键启动 (推荐)
```bash
./start_uv.sh
```

### 2. Makefile命令
```bash
# 生产环境
make start

# 开发环境 (热重载)
make dev-run

# 完整检查
make check
```

### 3. 直接使用uv
```bash
# 基础启动
uv run python app.py

# 开发模式
uv run python app.py --reload

# 多进程模式
uv run python app.py --workers 4

# 自定义端口
uv run python app.py --port 8080
```

### 4. 可执行命令 (安装后)
```bash
# 安装项目到当前环境
uv pip install -e .

# 直接运行
china-tax-tool --help
```

## 🛠️ 开发工作流

### 环境准备
```bash
# 1. 安装uv (如果尚未安装)
curl -LsSf https://astral.sh/uv/install.sh | sh

# 2. 克隆项目
git clone <repository-url>
cd ChinaTaxTool

# 3. 安装依赖
uv sync

# 4. 安装开发工具
uv sync --group dev
```

### 开发循环
```bash
# 1. 启动开发服务器
make dev-run

# 2. 修改代码 (自动重载)

# 3. 代码检查
make lint

# 4. 代码格式化
make format

# 5. 运行测试
make test
```

### 生产部署
```bash
# 1. 环境检查
make check

# 2. 启动服务
make start

# 3. 健康检查
make check-api
```

## 📋 常用命令参考

### uv 基础命令
```bash
# 显示版本
uv --version

# 创建项目
uv init

# 安装依赖
uv sync

# 添加依赖
uv add fastapi
uv add --group dev pytest

# 运行脚本
uv run python app.py
uv run --group dev pytest
```

### 项目特定命令
```bash
# 应用启动选项
uv run python app.py --help
uv run python app.py --host 0.0.0.0 --port 8080 --reload

# 测试命令
uv run --group dev python test_api.py
uv run --group dev pytest

# 代码质量
uv run --group dev ruff check app.py
uv run --group dev ruff format app.py
uv run --group dev mypy app.py
```

## 🔧 配置优化

### 依赖锁定
- `uv.lock` 文件确保依赖版本一致性
- 支持跨平台依赖解析
- 快速依赖解析和安装

### 虚拟环境管理
- 自动创建 `.venv` 虚拟环境
- 项目级依赖隔离
- 支持 Python 版本切换

### 性能优化
- 并行依赖安装
- 智能缓存机制
- 增量更新支持

## 📊 项目优势

### 开发体验
- **快速启动**: uv 的高速依赖解析和安装
- **热重载**: 开发模式下支持代码变更自动重载
- **类型检查**: 集成 mypy 进行静态类型检查
- **代码质量**: ruff + black 确保代码风格一致性

### 部署便利
- **环境一致性**: 锁定文件确保生产环境一致性
- **多进程支持**: 支持多worker进程部署
- **灵活配置**: 丰富的命令行参数支持

### 维护性
- **现代化工具链**: 使用最新的Python生态工具
- **标准化配置**: 遵循Python项目最佳实践
- **文档完善**: 详细的使用和架构文档

## 🔮 未来扩展

### 可能的改进方向
1. **容器化**: 添加 Docker 配置
2. **CI/CD**: 集成 GitHub Actions
3. **数据库**: 添加数据持久化支持
4. **API版本化**: 支持API版本管理
5. **监控**: 添加应用性能监控

### 技术演进
- **异步优化**: 全面采用异步编程模式
- **微服务**: 支持服务拆分和独立部署
- **云原生**: 支持Kubernetes部署
- **边缘计算**: 支持边缘部署场景

---

本架构完全基于现代Python生态系统，充分利用 uv 的高效依赖管理能力，为开发和部署提供了优秀的体验。