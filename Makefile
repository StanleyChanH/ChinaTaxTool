# 中国个人所得税计算器 Makefile
# 使用 uv 进行包管理和任务执行

.PHONY: help install start dev test lint format clean check-api run-docs

# 默认目标
help:
	@echo "中国个人所得税计算器 - 可用命令:"
	@echo ""
	@echo "📦 安装和设置:"
	@echo "  make install     - 安装项目依赖"
	@echo "  make dev         - 安装开发依赖"
	@echo "  make clean       - 清理缓存和临时文件"
	@echo ""
	@echo "🚀 运行服务:"
	@echo "  make start       - 启动生产环境服务"
	@echo "  make dev-run     - 启动开发环境服务(自动重载)"
	@echo "  make run         - 运行应用 (默认参数)"
	@echo ""
	@echo "🧪 测试和检查:"
	@echo "  make test        - 运行API测试"
	@echo "  make check-api  - 快速API健康检查"
	@echo "  make lint        - 代码风格检查"
	@echo "  make format      - 代码格式化"
	@echo ""
	@echo "📚 文档:"
	@echo "  make run-docs   - 启动API文档服务"
	@echo ""
	@echo "💡 示例:"
	@echo "  make start HOST=0.0.0.0 PORT=8080"
	@echo "  make dev-run WORKERS=4"

# 安装基础依赖
install:
	uv sync

# 安装开发依赖
dev:
	uv sync --group dev

# 启动生产环境服务
start:
	@echo "🚀 启动生产环境服务..."
	uv run python app.py

# 启动开发环境服务(自动重载)
dev-run:
	@echo "🔧 启动开发环境服务(自动重载)..."
	uv run python app.py --reload

# 运行应用
run:
	uv run python app.py

# 运行API测试
test:
	uv run --group dev python test_api.py

# 快速API健康检查
check-api:
	@echo "🔍 检查API服务状态..."
	@if curl -s http://localhost:8000/health > /dev/null; then \
		echo "✅ API服务正常运行"; \
		curl -s http://localhost:8000/health | jq .; \
	else \
		echo "❌ API服务未运行，请先执行 'make start'"; \
		exit 1; \
	fi

# 代码风格检查
lint:
	uv run --group dev ruff check app.py

# 代码格式化
format:
	uv run --group dev ruff format app.py

# 清理缓存和临时文件
clean:
	@echo "🧹 清理项目缓存..."
	rm -rf .venv
	rm -rf uv.lock
	rm -rf .pytest_cache
	rm -rf .mypy_cache
	rm -rf .ruff_cache
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "✅ 清理完成"

# 启动API文档服务
run-docs:
	@echo "📚 启动API文档服务..."
	@if ! curl -s http://localhost:8000/health > /dev/null; then \
		echo "❌ API服务未运行，请先执行 'make start'"; \
		exit 1; \
	fi
	@echo "📖 API文档地址: http://localhost:8000/docs"
	@echo "🔧 ReDoc文档地址: http://localhost:8000/redoc"

# 完整的项目检查
check: install dev lint test
	@echo "✅ 所有检查通过！"