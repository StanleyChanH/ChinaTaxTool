#!/bin/bash

# 中国个人所得税计算器启动脚本
#
# Copyright (c) 2024 StanleyChanH
# Licensed under the MIT License

echo "🚀 启动中国个人所得税计算器..."
echo "=================================="

# 检查Python是否安装
if ! command -v python &> /dev/null; then
    echo "❌ 错误: 未找到Python，请先安装Python 3.8+"
    exit 1
fi

# 检查依赖是否安装
echo "📦 检查依赖..."
python -c "import fastapi, uvicorn, pydantic" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "⬇️  安装依赖中..."
    pip install fastapi uvicorn pydantic python-multipart
    if [ $? -ne 0 ]; then
        echo "❌ 依赖安装失败，请检查网络连接"
        exit 1
    fi
fi

# 启动后端服务
echo "🔧 启动后端API服务 (端口: 8000)..."
python app.py &
BACKEND_PID=$!

# 等待后端服务启动
echo "⏳ 等待后端服务启动..."
sleep 3

# 检查后端服务是否启动成功
curl -s http://localhost:8000/health > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ 后端服务启动成功"
else
    echo "❌ 后端服务启动失败"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

# 测试CORS是否正常工作
echo "🔍 检查跨域配置..."
curl -s -X OPTIONS http://localhost:8000/calculate \
     -H "Origin: http://localhost:3000" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ CORS跨域配置正常"
else
    echo "⚠️  CORS配置可能有问题，但不影响基本功能"
fi

# 启动前端服务
echo "🌐 启动前端服务 (端口: 3000)..."
python -m http.server 3000 &
FRONTEND_PID=$!

echo "=================================="
echo "✅ 服务启动完成！"
echo ""
echo "📱 前端地址: http://localhost:3000"
echo "🔧 后端API: http://localhost:8000"
echo "📖 API文档: http://localhost:8000/docs"
echo ""
echo "💡 使用说明："
echo "1. 在浏览器中打开 http://localhost:3000"
echo "2. 输入您的收入和扣除信息"
echo "3. 查看计算结果和可视化图表"
echo ""
echo "按 Ctrl+C 停止所有服务"

# 等待用户中断
trap 'echo ""; echo "🛑 正在停止服务..."; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; echo "✅ 服务已停止"; exit 0' INT

# 保持脚本运行
wait