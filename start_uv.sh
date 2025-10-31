#!/bin/bash

# 中国个人所得税计算器启动脚本 (基于uv)
#
# Copyright (c) 2024 StanleyChanH
# Licensed under the MIT License

echo "🚀 启动中国个人所得税计算器 (uv版本)..."
echo "=================================="

# 检查uv是否安装
if ! command -v uv &> /dev/null; then
    echo "❌ 错误: 未找到uv，请先安装uv"
    echo "💡 安装方法:"
    echo "   curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo "   或访问: https://github.com/astral-sh/uv"
    exit 1
fi

# 显示uv版本
echo "📦 uv版本: $(uv --version)"

# 检查Python版本
echo "🐍 Python版本: $(uv run python --version)"

# 同步依赖
echo "📦 同步项目依赖..."
if ! uv sync; then
    echo "❌ 依赖同步失败，请检查网络连接"
    exit 1
fi

echo "✅ 依赖同步完成"

# 启动后端服务
echo "🔧 启动后端API服务..."
uv run python app.py &
BACKEND_PID=$!

# 等待后端服务启动
echo "⏳ 等待后端服务启动..."
sleep 3

# 检查后端服务是否启动成功
if curl -s http://localhost:8000/health > /dev/null; then
    echo "✅ 后端服务启动成功"
else
    echo "❌ 后端服务启动失败"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

# 测试CORS是否正常工作
echo "🔍 检查跨域配置..."
if curl -s -X OPTIONS http://localhost:8000/calculate \
     -H "Origin: http://localhost:3000" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" > /dev/null; then
    echo "✅ CORS跨域配置正常"
else
    echo "⚠️  CORS配置可能有问题，但不影响基本功能"
fi

# 启动前端服务
echo "🌐 启动前端服务 (端口: 3000)..."
uv run python -m http.server 3000 &
FRONTEND_PID=$!

echo "=================================="
echo "✅ 服务启动完成！"
echo ""
echo "📱 前端地址: http://localhost:3000"
echo "🔧 后端API: http://localhost:8000"
echo "📖 API文档: http://localhost:8000/docs"
echo "🔧 健康检查: http://localhost:8000/health"
echo ""
echo "💡 使用说明："
echo "1. 在浏览器中打开 http://localhost:3000"
echo "2. 输入您的收入和扣除信息"
echo "3. 查看计算结果和可视化图表"
echo ""
echo "🛠️  uv命令提示："
echo "   uv run python app.py --help     # 查看所有启动选项"
echo "   uv run python app.py --reload    # 开发模式（自动重载）"
echo "   uv run python -m pytest        # 运行测试"
echo "   uv run python test_api.py       # 运行API测试"
echo ""
echo "按 Ctrl+C 停止所有服务"

# 等待用户中断
trap 'echo ""; echo "🛑 正在停止服务..."; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; echo "✅ 服务已停止"; exit 0' INT

# 保持脚本运行
wait