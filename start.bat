@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM 中国个人所得税计算器启动脚本 (Windows)
REM
REM Copyright (c) 2024 StanleyChanH
REM Licensed under the MIT License

echo.
echo 🚀 启动中国个人所得税计算器 (Windows版本)...
echo ==================================

REM 检查Python是否安装
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误: 未找到Python，请先安装Python 3.8+
    echo 💡 下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM 检查uv是否安装
uv --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误: 未找到uv，请先安装uv
    echo 💡 安装方法:
    echo    使用PowerShell: irm https://astral.sh/uv/install.ps1 | iex
    echo    或访问: https://github.com/astral-sh/uv
    pause
    exit /b 1
)

REM 显示版本信息
echo 📦 uv版本:
uv --version
echo 🐍 Python版本:
uv run python --version

REM 同步依赖
echo.
echo 📦 同步项目依赖...
uv sync
if %errorlevel% neq 0 (
    echo ❌ 依赖同步失败，请检查网络连接
    pause
    exit /b 1
)

echo ✅ 依赖同步完成

REM 启动后端服务
echo.
echo 🔧 启动后端API服务...
start /b uv run python app.py
set BACKEND_PID=!errorlevel!

REM 等待后端服务启动
echo ⏳ 等待后端服务启动...
timeout /t 3 /nobreak >nul

REM 检查后端服务是否启动成功
curl -s http://localhost:8000/health >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ 后端服务启动成功
) else (
    echo ❌ 后端服务启动失败
    taskkill /f /im python.exe >nul 2>&1
    pause
    exit /b 1
)

REM 测试CORS是否正常工作
echo 🔍 检查跨域配置...
curl -s -X OPTIONS http://localhost:8000/calculate ^
     -H "Origin: http://localhost:3000" ^
     -H "Access-Control-Request-Method: POST" ^
     -H "Access-Control-Request-Headers: Content-Type" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ CORS跨域配置正常
) else (
    echo ⚠️  CORS配置可能有问题，但不影响基本功能
)

REM 启动前端服务
echo 🌐 启动前端服务 (端口: 3000)...
start /b uv run python -m http.server 3000

echo.
echo ==================================
echo ✅ 服务启动完成！
echo.
echo 📱 前端地址: http://localhost:3000
echo 🔧 后端API: http://localhost:8000
echo 📖 API文档: http://localhost:8000/docs
echo 🔧 健康检查: http://localhost:8000/health
echo.
echo 💡 使用说明：
echo 1. 在浏览器中打开 http://localhost:3000
echo 2. 输入您的收入和扣除信息
echo 3. 查看计算结果和可视化图表
echo.
echo 🛠️  uv命令提示：
echo    uv run python app.py --help     # 查看所有启动选项
echo    uv run python app.py --reload    # 开发模式（自动重载）
echo    uv run python -m pytest        # 运行测试
echo    uv run python test_api.py       # 运行API测试
echo.
echo 📝 关闭方法：关闭此窗口或按 Ctrl+C
echo.

REM 等待用户中断
echo 按任意键停止所有服务...
pause >nul

REM 停止服务
echo.
echo 🛑 正在停止服务...
taskkill /f /im python.exe >nul 2>&1
echo ✅ 服务已停止

pause