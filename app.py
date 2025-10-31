"""
中国个人所得税（年度累计预扣预缴）计算器后端API
实现2019年新个税法的累计预扣预缴法计算
"""

import argparse
import sys
from typing import List, Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

app = FastAPI(title="中国个人所得税计算器API", version="1.0.0")

# 添加CORS中间件解决跨域问题
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 允许所有来源，生产环境应该指定具体域名
    allow_credentials=True,
    allow_methods=["*"],  # 允许所有HTTP方法
    allow_headers=["*"],  # 允许所有请求头
)


class TaxInput(BaseModel):
    """税务计算输入参数"""

    # 基本信息
    monthly_salary: float = Field(..., description="月度税前工资(元)")

    # 社保公积金基数
    social_insurance_base: Optional[float] = Field(None, description="社保缴费基数(元)")
    housing_fund_base: Optional[float] = Field(None, description="公积金缴费基数(元)")

    # 基数上下限
    base_upper_limit: float = Field(0, description="缴费基数上限(元)")
    base_lower_limit: float = Field(0, description="缴费基数下限(元)")

    # 个人缴纳比例(%)
    pension_personal_rate: float = Field(8.0, description="养老保险个人比例(%)")
    medical_personal_rate: float = Field(2.0, description="医疗保险个人比例(%)")
    unemployment_personal_rate: float = Field(0.5, description="失业保险个人比例(%)")
    housing_fund_personal_rate: float = Field(7.0, description="公积金个人比例(%)")

    # 公司缴纳比例(%)
    pension_company_rate: float = Field(16.0, description="养老保险公司比例(%)")
    medical_company_rate: float = Field(7.5, description="医疗保险公司比例(%)")
    unemployment_company_rate: float = Field(0.5, description="失业保险公司比例(%)")
    work_injury_company_rate: float = Field(0.4, description="工伤保险公司比例(%)")
    maternity_company_rate: float = Field(0.8, description="生育保险公司比例(%)")
    housing_fund_company_rate: float = Field(7.0, description="公积金公司比例(%)")

    # 专项附加扣除（月度）
    infant_care: float = Field(0.0, description="3岁以下婴幼儿照护(元/月)")
    children_education: float = Field(0.0, description="子女教育(元/月)")
    continuing_education: float = Field(0.0, description="继续教育(元/月)")
    housing_loan_interest: float = Field(0.0, description="住房贷款利息(元/月)")
    housing_rent: float = Field(0.0, description="住房租金(元/月)")
    elder_care: float = Field(0.0, description="赡养老人(元/月)")


class MonthlyDetail(BaseModel):
    """月度详情数据模型"""

    month: int
    salary: float
    pension_personal: float
    medical_personal: float
    unemployment_personal: float
    housing_fund_personal: float
    social_personal_total: float
    social_company_total: float
    special_deduction: float
    cumulative_salary: float
    cumulative_deduction: float
    cumulative_taxable_income: float
    tax_rate: float
    monthly_tax: float
    cumulative_tax_paid: float
    after_tax_income: float


class TaxResult(BaseModel):
    """税务计算结果"""

    # 年度汇总
    annual_salary: float
    annual_tax: float
    annual_after_tax_income: float
    annual_social_personal: float
    annual_social_company: float

    # 分项明细
    annual_pension_personal: float
    annual_pension_company: float
    annual_medical_personal: float
    annual_medical_company: float
    annual_unemployment_personal: float
    annual_unemployment_company: float
    annual_work_injury_company: float
    annual_maternity_company: float
    annual_housing_fund_personal: float
    annual_housing_fund_company: float

    # 月度详情
    monthly_details: List[MonthlyDetail]


def clamp_value(value: float, min_val: float, max_val: float) -> float:
    """数值限制函数"""
    if max_val > 0 and value > max_val:
        return max_val
    if min_val > 0 and value < min_val:
        return min_val
    return value


def calculate_tax_rate_and_deduction(taxable_income: float) -> tuple[float, float]:
    """
    根据累计应纳税所得额计算适用税率和速算扣除数
    使用2024年个人所得税7级超额累进税率表
    """
    if taxable_income <= 36000:
        return 3.0, 0
    elif taxable_income <= 144000:
        return 10.0, 2520
    elif taxable_income <= 300000:
        return 20.0, 16920
    elif taxable_income <= 420000:
        return 25.0, 31920
    elif taxable_income <= 660000:
        return 30.0, 52920
    elif taxable_income <= 960000:
        return 35.0, 85920
    else:
        return 45.0, 181920


def calculate_tax(tax_input: TaxInput) -> TaxResult:
    """
    核心计算函数：累计预扣预缴法计算个税
    """
    # 获取输入参数
    monthly_salary = tax_input.monthly_salary

    # 处理基数默认值
    social_base = tax_input.social_insurance_base
    housing_fund_base = tax_input.housing_fund_base
    if social_base is None or social_base == 0:
        social_base = monthly_salary
    if housing_fund_base is None or housing_fund_base == 0:
        housing_fund_base = monthly_salary

    # 基数调整：应用上下限限制
    actual_social_base = clamp_value(
        social_base,
        tax_input.base_lower_limit,
        tax_input.base_upper_limit,
    )
    actual_housing_fund_base = clamp_value(
        housing_fund_base,
        tax_input.base_lower_limit,
        tax_input.base_upper_limit,
    )

    # 计算个人五险一金月缴纳额
    pension_personal = actual_social_base * tax_input.pension_personal_rate / 100
    medical_personal = actual_social_base * tax_input.medical_personal_rate / 100
    unemployment_personal = (
        actual_social_base * tax_input.unemployment_personal_rate / 100
    )
    housing_fund_personal = (
        actual_housing_fund_base * tax_input.housing_fund_personal_rate / 100
    )
    social_personal_total = (
        pension_personal
        + medical_personal
        + unemployment_personal
        + housing_fund_personal
    )

    # 计算公司五险一金月缴纳额
    pension_company = actual_social_base * tax_input.pension_company_rate / 100
    medical_company = actual_social_base * tax_input.medical_company_rate / 100
    unemployment_company = (
        actual_social_base * tax_input.unemployment_company_rate / 100
    )
    work_injury_company = actual_social_base * tax_input.work_injury_company_rate / 100
    maternity_company = actual_social_base * tax_input.maternity_company_rate / 100
    housing_fund_company = (
        actual_housing_fund_base * tax_input.housing_fund_company_rate / 100
    )
    social_company_total = (
        pension_company
        + medical_company
        + unemployment_company
        + work_injury_company
        + maternity_company
        + housing_fund_company
    )

    # 计算专项附加扣除总额
    special_deduction = (
        tax_input.infant_care
        + tax_input.children_education
        + tax_input.continuing_education
        + tax_input.housing_loan_interest
        + tax_input.housing_rent
        + tax_input.elder_care
    )

    # 初始化年度累计值
    annual_salary = 0
    annual_tax = 0
    annual_social_personal = 0
    annual_social_company = 0
    annual_pension_personal = 0
    annual_pension_company = 0
    annual_medical_personal = 0
    annual_medical_company = 0
    annual_unemployment_personal = 0
    annual_unemployment_company = 0
    annual_work_injury_company = 0
    annual_maternity_company = 0
    annual_housing_fund_personal = 0
    annual_housing_fund_company = 0

    # 月度详情列表
    monthly_details = []

    # 累计预扣预缴计算：逐月计算1-12月
    for month in range(1, 13):
        # 累计税前工资
        annual_salary += monthly_salary

        # 累计五险一金个人缴纳
        annual_social_personal += social_personal_total
        annual_pension_personal += pension_personal
        annual_medical_personal += medical_personal
        annual_unemployment_personal += unemployment_personal
        annual_housing_fund_personal += housing_fund_personal

        # 累计五险一金公司缴纳
        annual_social_company += social_company_total
        annual_pension_company += pension_company
        annual_medical_company += medical_company
        annual_unemployment_company += unemployment_company
        annual_work_injury_company += work_injury_company
        annual_maternity_company += maternity_company
        annual_housing_fund_company += housing_fund_company

        # 累计应纳税所得额 = 累计税前工资 - 累计五险一金个人 - 累计起征点 - 累计专项附加扣除
        cumulative_salary = monthly_salary * month
        cumulative_social_personal = social_personal_total * month
        cumulative_basic_deduction = 5000 * month  # 累计起征点
        cumulative_special_deduction = special_deduction * month  # 累计专项附加扣除
        cumulative_deduction = (
            cumulative_social_personal
            + cumulative_basic_deduction
            + cumulative_special_deduction
        )

        cumulative_taxable_income = cumulative_salary - cumulative_deduction
        if cumulative_taxable_income <= 0:
            cumulative_taxable_income = 0

        # 计算当月应缴个税
        tax_rate, quick_deduction = calculate_tax_rate_and_deduction(
            cumulative_taxable_income
        )
        cumulative_tax_should_pay = (
            cumulative_taxable_income * tax_rate / 100 - quick_deduction
        )
        if cumulative_tax_should_pay <= 0:
            cumulative_tax_should_pay = 0

        # 当月应缴个税 = 累计应纳税额 - 累计已预扣预缴税额
        monthly_tax = cumulative_tax_should_pay - annual_tax
        if monthly_tax <= 0:
            monthly_tax = 0

        annual_tax += monthly_tax

        # 当月税后收入
        after_tax_income = monthly_salary - social_personal_total - monthly_tax

        # 创建月度详情记录
        monthly_detail = MonthlyDetail(
            month=month,
            salary=monthly_salary,
            pension_personal=pension_personal,
            medical_personal=medical_personal,
            unemployment_personal=unemployment_personal,
            housing_fund_personal=housing_fund_personal,
            social_personal_total=social_personal_total,
            social_company_total=social_company_total,
            special_deduction=special_deduction,
            cumulative_salary=cumulative_salary,
            cumulative_deduction=cumulative_deduction,
            cumulative_taxable_income=cumulative_taxable_income,
            tax_rate=tax_rate,
            monthly_tax=monthly_tax,
            cumulative_tax_paid=annual_tax,
            after_tax_income=after_tax_income,
        )
        monthly_details.append(monthly_detail)

    # 计算年度税后总收入
    annual_after_tax_income = annual_salary - annual_social_personal - annual_tax

    # 返回计算结果
    return TaxResult(
        annual_salary=annual_salary,
        annual_tax=annual_tax,
        annual_after_tax_income=annual_after_tax_income,
        annual_social_personal=annual_social_personal,
        annual_social_company=annual_social_company,
        annual_pension_personal=annual_pension_personal,
        annual_pension_company=annual_pension_company,
        annual_medical_personal=annual_medical_personal,
        annual_medical_company=annual_medical_company,
        annual_unemployment_personal=annual_unemployment_personal,
        annual_unemployment_company=annual_unemployment_company,
        annual_work_injury_company=annual_work_injury_company,
        annual_maternity_company=annual_maternity_company,
        annual_housing_fund_personal=annual_housing_fund_personal,
        annual_housing_fund_company=annual_housing_fund_company,
        monthly_details=monthly_details,
    )


@app.post("/calculate", response_model=TaxResult)
async def calculate_tax_endpoint(tax_input: TaxInput):
    """
    个税计算API接口
    接收用户输入参数，返回计算结果
    """
    try:
        result = calculate_tax(tax_input)
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"计算错误: {str(e)}") from e


@app.get("/")
async def root():
    """API根路径"""
    return {"message": "中国个人所得税计算器API", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    """健康检查接口"""
    return {"status": "healthy"}


def main():
    """主函数，支持命令行参数"""
    parser = argparse.ArgumentParser(description="中国个人所得税计算器API服务")
    parser.add_argument(
        "--host", default="0.0.0.0", help="服务器监听地址 (默认: 0.0.0.0)"
    )
    parser.add_argument(
        "--port", type=int, default=8000, help="服务器端口 (默认: 8000)"
    )
    parser.add_argument("--reload", action="store_true", help="启用自动重载 (开发模式)")
    parser.add_argument("--workers", type=int, default=1, help="工作进程数量 (默认: 1)")

    args = parser.parse_args()

    print("🚀 启动中国个人所得税计算器API服务...")
    print(f"📍 服务地址: http://{args.host}:{args.port}")
    print(f"📖 API文档: http://{args.host}:{args.port}/docs")
    print(f"🔧 健康检查: http://{args.host}:{args.port}/health")
    print("📱 前端页面: 请在浏览器中打开 index.html 文件")
    print("=" * 50)

    import uvicorn

    # 配置uvicorn运行参数
    uvicorn_config = {
        "app": app,
        "host": args.host,
        "port": args.port,
        "reload": args.reload,
        "workers": args.workers
        if not args.reload
        else 1,  # reload模式下只能用1个worker
        "log_level": "info",
        "access_log": True,
    }

    try:
        uvicorn.run(**uvicorn_config)
    except KeyboardInterrupt:
        print("\n🛑 服务已停止")
        sys.exit(0)
    except Exception as e:
        print(f"❌ 服务启动失败: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
