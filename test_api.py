#!/usr/bin/env python3
"""
中国个人所得税计算器API测试脚本

Copyright (c) 2024 StanleyChanH
Licensed under the MIT License
"""

import requests
import json
import sys

def test_api():
    """测试API功能"""
    base_url = "http://localhost:8000"

    print("🧪 测试中国个人所得税计算器API...")
    print("=" * 50)

    # 测试1: 健康检查
    print("1. 测试健康检查接口...")
    try:
        response = requests.get(f"{base_url}/health", timeout=5)
        if response.status_code == 200:
            print("✅ 健康检查通过")
        else:
            print(f"❌ 健康检查失败: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ 健康检查连接失败: {e}")
        return False

    # 测试2: 根路径
    print("2. 测试根路径接口...")
    try:
        response = requests.get(f"{base_url}/", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ 根路径正常: {data.get('message', 'N/A')}")
        else:
            print(f"❌ 根路径失败: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ 根路径连接失败: {e}")
        return False

    # 测试3: 计算接口
    print("3. 测试个税计算接口...")
    test_data = {
        "monthly_salary": 15000,
        "social_insurance_base": 15000,
        "housing_fund_base": 15000,
        "base_upper_limit": 25000,
        "base_lower_limit": 5000,
        "pension_personal_rate": 8,
        "medical_personal_rate": 2,
        "unemployment_personal_rate": 0.5,
        "housing_fund_personal_rate": 7,
        "pension_company_rate": 16,
        "medical_company_rate": 7.5,
        "unemployment_company_rate": 0.5,
        "work_injury_company_rate": 0.4,
        "maternity_company_rate": 0.8,
        "housing_fund_company_rate": 7,
        "infant_care": 0,
        "children_education": 1000,
        "continuing_education": 400,
        "housing_loan_interest": 1000,
        "housing_rent": 0,
        "elder_care": 2000
    }

    try:
        response = requests.post(
            f"{base_url}/calculate",
            json=test_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        if response.status_code == 200:
            result = response.json()
            print("✅ 计算接口正常")
            print(f"   年度税前收入: ¥{result['annual_salary']:,.2f}")
            print(f"   年度个税总额: ¥{result['annual_tax']:,.2f}")
            print(f"   年度税后收入: ¥{result['annual_after_tax_income']:,.2f}")
            print(f"   有效税率: {result['annual_tax']/result['annual_salary']*100:.2f}%")
        else:
            print(f"❌ 计算接口失败: {response.status_code}")
            print(f"   错误信息: {response.text}")
            return False
    except Exception as e:
        print(f"❌ 计算接口连接失败: {e}")
        return False

    # 测试4: CORS预检请求
    print("4. 测试CORS跨域配置...")
    try:
        response = requests.options(
            f"{base_url}/calculate",
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "POST",
                "Access-Control-Request-Headers": "Content-Type"
            },
            timeout=5
        )
        if response.status_code == 200:
            cors_headers = {
                'Access-Control-Allow-Origin',
                'Access-Control-Allow-Methods',
                'Access-Control-Allow-Headers'
            }
            missing_headers = cors_headers - set(response.headers.keys())
            if not missing_headers:
                print("✅ CORS配置正常")
            else:
                print(f"⚠️  CORS配置不完整，缺少头部: {missing_headers}")
        else:
            print(f"❌ CORS预检失败: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ CORS测试失败: {e}")
        return False

    print("=" * 50)
    print("🎉 所有测试通过！API服务正常运行")
    return True

if __name__ == "__main__":
    success = test_api()
    sys.exit(0 if success else 1)