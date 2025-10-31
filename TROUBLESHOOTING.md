# 故障排除指南

## 常见问题及解决方案

### 1. "Failed to fetch" 错误

**问题描述**: 前端页面显示"Failed to fetch"，无法调用后端API。

**原因分析**: 通常是跨域(CORS)问题或后端服务未启动。

**解决方案**:

#### 方法1: 确保后端服务正常运行
```bash
# 检查后端服务状态
curl http://localhost:8000/health

# 如果没有响应，重新启动后端
python app.py
```

#### 方法2: 使用一键启动脚本
```bash
./start.sh
```

#### 方法3: 手动启动服务
```bash
# 终端1: 启动后端
python app.py

# 终端2: 启动前端
python -m http.server 3000
```

#### 方法4: 检查防火墙设置
确保8000和3000端口没有被防火墙阻止。

### 2. 端口占用问题

**问题描述**: 启动服务时提示端口已被占用。

**解决方案**:
```bash
# 查找占用端口的进程
lsof -i :8000  # 后端端口
lsof -i :3000  # 前端端口

# 杀死占用进程
kill -9 <PID>

# 或者使用不同端口
python app.py --port 8001
python -m http.server 3001
```

### 3. 依赖安装失败

**问题描述**: pip安装依赖时出现错误。

**解决方案**:
```bash
# 更新pip
pip install --upgrade pip

# 使用国内镜像源
pip install -i https://pypi.mirrors.ustc.edu.cn/simple/ fastapi uvicorn pydantic python-multipart

# 或者使用conda
conda install fastapi uvicorn pydantic
```

### 4. Python版本兼容性问题

**问题描述**: 运行时出现Python版本错误。

**解决方案**:
- 确保使用Python 3.8或更高版本
```bash
python --version

# 如果版本过低，请升级Python
# Ubuntu/Debian:
sudo apt update && sudo apt install python3.9

# CentOS/RHEL:
sudo yum install python39

# macOS:
brew install python@3.9
```

### 5. 浏览器缓存问题

**问题描述**: 修改代码后刷新页面没有变化。

**解决方案**:
- 硬刷新页面 (Ctrl+F5 或 Cmd+Shift+R)
- 清除浏览器缓存
- 使用无痕/隐私模式测试

### 6. 计算结果异常

**问题描述**: 个税计算结果与预期不符。

**解决方案**:
1. 检查输入参数是否正确
2. 验证社保公积金基数设置
3. 确认专项附加扣除金额
4. 查看后端日志是否有错误

**测试API**:
```bash
# 使用测试脚本验证API
python test_api.py

# 手动测试API
curl -X POST http://localhost:8000/calculate \
  -H "Content-Type: application/json" \
  -d '{"monthly_salary": 15000, "pension_personal_rate": 8, "medical_personal_rate": 2, "unemployment_personal_rate": 0.5, "housing_fund_personal_rate": 7, "pension_company_rate": 16, "medical_company_rate": 7.5, "unemployment_company_rate": 0.5, "work_injury_company_rate": 0.4, "maternity_company_rate": 0.8, "housing_fund_company_rate": 7, "infant_care": 0, "children_education": 0, "continuing_education": 0, "housing_loan_interest": 0, "housing_rent": 0, "elder_care": 0}'
```

### 7. 移动端显示问题

**问题描述**: 在手机上显示不正常。

**解决方案**:
- 确保使用现代浏览器（Chrome、Safari、Firefox最新版）
- 检查响应式设计是否正常工作
- 尝试横屏和竖屏模式

### 8. API文档无法访问

**问题描述**: 无法访问Swagger API文档。

**解决方案**:
- 确保后端服务正常启动
- 访问: http://localhost:8000/docs
- 如果仍然无法访问，检查FastAPI版本

### 9. Chart.js图表不显示

**问题描述**: 数据可视化图表无法正常显示。

**解决方案**:
- 检查浏览器控制台是否有JavaScript错误
- 确保Chart.js CDN可以正常访问
- 验证API返回的数据格式是否正确

### 10. 性能问题

**问题描述**: 计算速度慢或页面卡顿。

**解决方案**:
- 检查CPU和内存使用情况
- 关闭不必要的浏览器标签页
- 重启后端服务
- 检查网络连接稳定性

## 调试技巧

### 1. 查看浏览器开发者工具
- 按F12打开开发者工具
- 查看Console标签页的错误信息
- 检查Network标签页的请求状态

### 2. 查看后端日志
```bash
# 后端服务会在终端输出详细日志
python app.py
```

### 3. 测试网络连接
```bash
# 测试后端连接
curl http://localhost:8000/health

# 测试前端连接
curl http://localhost:3000/
```

### 4. 验证CORS配置
```bash
# 测试CORS预检请求
curl -X OPTIONS http://localhost:8000/calculate \
     -H "Origin: http://localhost:3000" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type"
```

## 联系支持

如果以上解决方案都无法解决您的问题，请：

1. 收集以下信息：
   - 操作系统版本
   - Python版本
   - 浏览器版本
   - 具体错误信息
   - 后端日志输出

2. 在GitHub上提交Issue，详细描述问题和复现步骤。

3. 提供完整的错误堆栈信息。

---

**注意**: 本工具仅供学习和参考使用，不构成专业的税务建议。实际税务问题请咨询专业税务顾问。