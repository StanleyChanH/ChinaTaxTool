#!/bin/bash

# 中国个人所得税计算器启动脚本 (Linux)
#
# Copyright (c) 2024 StanleyChanH
# Licensed under the MIT License

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检测Linux发行版
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$NAME"
    elif type lsb_release >/dev/null 2>&1; then
        lsb_release -si
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo "$DISTRIB_ID"
    elif [ -f /etc/debian_version ]; then
        echo "Debian"
    else
        echo "Unknown"
    fi
}

DISTRO=$(detect_distro)
echo -e "${BLUE}🚀 启动中国个人所得税计算器 (Linux版本 - $DISTRO)...${NC}"
echo "=================================="

# 检查Python是否安装
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ 错误: 未找到Python3，请先安装Python 3.8+${NC}"
    echo "💡 安装方法:"
    case $DISTRO in
        *"Ubuntu"*|*"Debian"*)
            echo "   sudo apt update"
            echo "   sudo apt install python3 python3-pip python3-venv"
            ;;
        *"CentOS"*|*"Red Hat"*|*"Fedora"*)
            echo "   sudo yum install python3 python3-pip"
            echo "   或者: sudo dnf install python3 python3-pip"
            ;;
        *"Arch"*)
            echo "   sudo pacman -S python python-pip"
            ;;
        *)
            echo "   请参考您的Linux发行版文档安装Python3"
            ;;
    esac
    echo "   或访问: https://www.python.org/downloads/"
    read -p "按回车键退出..."
    exit 1
fi

# 检查uv是否安装
if ! command -v uv &> /dev/null; then
    echo -e "${RED}❌ 错误: 未找到uv，请先安装uv${NC}"
    echo "💡 安装方法:"
    echo "   curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo "   或者，如果您的发行版有包："
    case $DISTRO in
        *"Arch"*)
            echo "   sudo pacman -S uv"
            ;;
    esac
    echo "   或访问: https://github.com/astral-sh/uv"
    read -p "按回车键退出..."
    exit 1
fi

# 显示版本信息
echo -e "${GREEN}📦 uv版本: $(uv --version)${NC}"
echo -e "${GREEN}🐍 Python版本: $(uv run python3 --version)${NC}"

# 检查端口是否被占用
check_port() {
    local port=$1
    if command -v netstat &> /dev/null; then
        netstat -tuln | grep ":$port " > /dev/null
    elif command -v ss &> /dev/null; then
        ss -tuln | grep ":$port " > /dev/null
    elif command -v lsof &> /dev/null; then
        lsof -i :$port > /dev/null
    else
        return 1
    fi
}

# 检查端口占用
if check_port 8000; then
    echo -e "${YELLOW}⚠️  端口8000已被占用，尝试停止现有进程...${NC}"
    pkill -f "python.*app.py" 2>/dev/null || true
    sleep 2
fi

if check_port 3000; then
    echo -e "${YELLOW}⚠️  端口3000已被占用，尝试停止现有进程...${NC}"
    pkill -f "python.*http.server.*3000" 2>/dev/null || true
    sleep 2
fi

# 同步依赖
echo ""
echo "📦 同步项目依赖..."
if ! uv sync; then
    echo -e "${RED}❌ 依赖同步失败，请检查网络连接${NC}"
    echo "💡 如果在防火墙/代理后，请尝试："
    echo "   uv sync --index-url https://pypi.org/simple/"
    read -p "按回车键退出..."
    exit 1
fi

echo -e "${GREEN}✅ 依赖同步完成${NC}"

# 启动后端服务
echo ""
echo "🔧 启动后端API服务..."
uv run python3 app.py &
BACKEND_PID=$!

# 等待后端服务启动
echo "⏳ 等待后端服务启动..."
sleep 3

# 检查后端服务是否启动成功
if curl -s http://localhost:8000/health > /dev/null; then
    echo -e "${GREEN}✅ 后端服务启动成功${NC}"
else
    echo -e "${RED}❌ 后端服务启动失败${NC}"
    kill $BACKEND_PID 2>/dev/null
    echo "💡 请检查："
    echo "   1. 防火墙是否阻止了端口8000"
    echo "   2. 端口8000是否被其他程序占用"
    echo "   3. 查看详细错误信息：uv run python3 app.py"
    read -p "按回车键退出..."
    exit 1
fi

# 测试CORS是否正常工作
echo "🔍 检查跨域配置..."
if curl -s -X OPTIONS http://localhost:8000/calculate \
     -H "Origin: http://localhost:3000" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" > /dev/null; then
    echo -e "${GREEN}✅ CORS跨域配置正常${NC}"
else
    echo -e "${YELLOW}⚠️  CORS配置可能有问题，但不影响基本功能${NC}"
fi

# 启动前端服务
echo "🌐 启动前端服务 (端口: 3000)..."
uv run python3 -m http.server 3000 &
FRONTEND_PID=$!

echo ""
echo "=================================="
echo -e "${GREEN}✅ 服务启动完成！${NC}"
echo ""
echo -e "${BLUE}📱 前端地址: http://localhost:3000${NC}"
echo -e "${BLUE}🔧 后端API: http://localhost:8000${NC}"
echo -e "${BLUE}📖 API文档: http://localhost:8000/docs${NC}"
echo -e "${BLUE}🔧 健康检查: http://localhost:8000/health${NC}"
echo ""
echo "💡 使用说明："
echo "1. 在浏览器中打开 http://localhost:3000"
echo "2. 输入您的收入和扣除信息"
echo "3. 查看计算结果和可视化图表"
echo ""
echo "🛠️  uv命令提示："
echo "   uv run python3 app.py --help     # 查看所有启动选项"
echo "   uv run python3 app.py --reload    # 开发模式（自动重载）"
echo "   uv run python3 -m pytest        # 运行测试"
echo "   uv run python3 test_api.py       # 运行API测试"
echo ""
echo "🐧 Linux特定提示："
echo "   - 如果使用防火墙，请确保端口3000和8000已开放"
echo "   - 可以使用以下命令检查端口："
echo "     sudo netstat -tlnp | grep ':3000\\|:8000'"
echo ""
echo -e "${YELLOW}📝 关闭方法：关闭此终端或按 Ctrl+C${NC}"
echo ""

# Linux 特定：尝试发送桌面通知（如果可用）
if command -v notify-send &> /dev/null; then
    notify-send "ChinaTaxTool 服务已启动" "前端: http://localhost:3000" --urgency=normal
fi

# 等待用户中断
trap 'echo ""; echo -e "${YELLOW}🛑 正在停止服务...${NC}"; kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; echo -e "${GREEN}✅ 服务已停止${NC}"; exit 0' INT

# 保持脚本运行
echo "按 Ctrl+C 停止所有服务..."
wait