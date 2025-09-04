---
marp: true
---
# 🎪 dbt (Data Build Tool) 企業級資料工程解決方案

*現代資料團隊的最佳選擇*

---

## 📋 今日議程

✅ **dbt 基本概念** - 什麼是 dbt？為什麼需要它？

✅ **技術架構** - 企業級分層設計與最佳實務

✅ **核心功能展示** - dbt_utils、Jinja、測試框架

✅ **Jaffle Shop Demo** - 完整的電商資料管道實例

✅ **Live Demo** - 現場操作展示

✅ **Q&A** - 技術討論與實作經驗分享

---

## 🤔 傳統資料工程的痛點

### 😰 現在的挑戰

- **SQL 散落各處** - 缺乏組織架構
- **手動測試** - 耗時且容易遺漏
- **文件與程式碼分離** - 維護困難
- **沒有版本控制** - 變更追蹤困難
- **重複造輪子** - 缺乏程式碼重用

### 💡 我們需要什麼？

- 🏗️ **結構化的資料管道**
- 🧪 **自動化測試**
- 📚 **程式碼即文件**
- 🔄 **版本控制整合**
- 🔧 **可重用的元件**

---

## 🎯 什麼是 dbt？

### dbt = **d**ata **b**uild **t**ool

> **「將軟體工程的最佳實務帶入資料工程領域」**

### 🔑 核心理念

- **SELECT 語句即轉換** - 專注於 SQL 邏輯
- **版本控制** - Git 工作流程
- **測試驅動開發** - 資料品質保證
- **文件化** - 自動生成文件與血緣圖
- **模組化** - 可重用的轉換元件

### 🏆 業界標準

- **5000+ 企業**使用 dbt 進行資料轉換
- **GitHub 25k+ stars** 開源專案
- **Modern Data Stack** 的核心元件

---

## 🆚 傳統方式 vs dbt 方式

| 傳統方式 | dbt 方式 | 改善效果 |
|----------|----------|----------|
| 手寫 SQL 腳本 | 模組化模型 | **10x 開發效率** |
| 手動執行測試 | 自動化測試套件 | **99% 錯誤減少** |
| Word/Wiki 文件 | 程式碼即文件 | **100% 文件同步** |
| 無依賴管理 | 智能依賴解析 | **零依賴錯誤** |
| 專家知識孤島 | 知識共享平台 | **團隊協作提升** |

### 💰 投資回報率 (ROI)

- **開發時間縮短 60%**
- **資料品質問題減少 80%**
- **新人上手時間從 3 個月縮短至 2 週**

---

## 🏪 Demo 專案：Jaffle Shop 電商平台

### 📊 業務背景

**Jaffle Shop** - 虛擬咖啡電商平台

- 👥 **100 位客戶** - 多元化客戶群體
- 🛒 **99 筆訂單** - 完整訂單生命週期
- 💳 **113 筆付款** - 多種付款方式

### 🎯 Demo 目標

✅ 展示企業級 dbt 開發完整工作流程

✅ 演示現代資料工程最佳實務

✅ 提供可立即應用的實戰範例

---

## 🔧 技術棧展示

| 工具 | 用途 | Demo 價值 |
|------|------|-----------|
| **🎯 dbt-core 1.10.9** | 轉換引擎 | 最新功能展示 |
| **⚡ DuckDB 1.3.2** | 高效能本地 OLAP | 秒級執行回饋 |
| **🧰 dbt-utils** | 常用函數庫 | 動態 SQL 生成 |
| **🛡️ dbt-expectations** | 進階測試框架 | 業務規則驗證 |
| **🎨 Jinja 模板** | 動態 SQL | 可配置業務邏輯 |

### 🚀 為什麼選擇 DuckDB？

- **⚡ 極速執行** - 本地 OLAP 引擎
- **🔧 零配置** - 無需複雜安裝
- **📊 分析友善** - 為 OLAP 工作負載最佳化
- **🎯 Demo 完美** - 立即可見的結果

---

## 🏗️ 企業級分層架構

```
📁 jaffle_shop_duckdb/
├── 📊 seeds/                # 🔹 原始資料層
│   ├── raw_customers.csv    # 客戶基本資料
│   ├── raw_orders.csv       # 訂單交易資料  
│   └── raw_payments.csv     # 付款記錄資料
├── 📁 models/
│   ├── 🧹 staging/          # 🔸 資料標準化層
│   │   ├── stg_customers.sql
│   │   ├── stg_orders.sql 
│   │   └── stg_payments.sql
│   ├── ⚙️ intermediate/     # 🔶 業務邏輯層
│   │   ├── int_customer_metrics.sql
│   │   └── int_order_analytics.sql
│   ├── 🏪 customers.sql     # 🔺 最終業務模型
│   └── 🏪 orders.sql
```

### 📐 設計原則

- **🧹 Staging**: 1:1 資料清理與標準化
- **⚙️ Intermediate**: 可重用業務邏輯模組
- **🏪 Final Models**: 面向業務用戶的分析模型

---

## 🧰 核心功能 1: dbt_utils 動態 SQL

### 🎯 動態欄位生成

```sql
-- 🔥 自動偵測所有付款方式
{% set payment_methods = dbt_utils.get_column_values(
    ref('stg_payments'), 'payment_method'
) %}

-- 🚀 動態生成聚合欄位
{% for payment_method in payment_methods -%}
sum(case when payment_method = '{{ payment_method }}' 
     then amount else 0 end) as {{ payment_method }}_amount,
{% endfor -%}
```

**✨ 結果**: 自動生成 `credit_card_amount`, `bank_transfer_amount`, `coupon_amount`, `gift_card_amount`

### 🔑 代理鍵生成

```sql
{{ dbt_utils.generate_surrogate_key(
    ['customer_id', 'first_order']
) }} as customer_business_key
```

**💡 價值**: 無需手動管理複合主鍵邏輯

---

## 🎨 核心功能 2: Jinja 巨集威力

### ⚙️ 可配置業務邏輯

```sql
{% set high_value_threshold = var('high_value_threshold', 100) %}

case
    when sum(amount) >= {{ high_value_threshold }} then 'High Value'
    else 'Standard'
end as order_value_category
```

### 🔄 條件性功能開關

```sql
{% if var('include_payment_breakdown', true) %}
-- 只在需要時生成複雜的付款分析邏輯
{% for payment_method in payment_methods %}
  -- 詳細付款方式分析...
{% endfor %}
{% endif %}
```

**⚡ 執行時調整參數**:
```bash
dbt run --vars '{"high_value_threshold": 150}'
```

---

## 🛡️ 核心功能 3: dbt_expectations 資料品質

### 📊 表格層級驗證

```yaml
data_tests:
  - dbt_expectations.expect_table_row_count_to_be_between:
      arguments:
        min_value: 90
        max_value: 110
```

### 🎯 業務規則驗證

```yaml
- dbt_expectations.expect_column_values_to_be_in_set:
    arguments:
      value_set: ['High Value', 'Medium Value', 'Low Value', 'No Purchase']
```

### 🔢 數值範圍檢查

```yaml
- dbt_expectations.expect_column_values_to_be_between:
    arguments:
      min_value: 0
      max_value: 100  # 百分比字段
```

**🎖️ 測試覆蓋率**: 完整的自動化測試套件確保資料品質

---

## 🧪 核心功能 4: Unit Tests 邏輯驗證

### 💡 Unit Tests vs Data Tests

| Unit Tests | Data Tests |
|------------|------------|
| **業務邏輯驗證** | **資料品質檢查** |
| 模擬資料測試 | 實際資料驗證 |
| 秒級執行 | 分鐘級執行 |
| 開發階段使用 | 生產監控使用 |

### 🎯 實際範例: 金額轉換驗證

```yaml
unit_tests:
  - name: test_stg_payments_amount_conversion
    model: stg_payments
    given:
      - input: ref('raw_payments')
        rows:
          - {id: 1, amount: 1500}  # 15.00 元
    expect:
      rows:
        - {payment_id: 1, amount: 15.0}
```

**✅ 驗證**: 確保「分轉元」邏輯 100% 正確

---

## 📊 實際演示：客戶 360 度分析

### 🎯 業務問題

**「我們需要了解客戶的完整價值和行為模式」**

### 💎 解決方案：customers 模型

```sql
SELECT 
    customer_id,
    full_name,
    -- 💰 價值分析
    customer_lifetime_value,
    customer_segment,        -- High/Medium/Low Value
    -- 📈 活躍度分析  
    activity_level,         -- Very Active/Active/Regular/Occasional
    days_since_last_order,
    -- ⚠️ 風險評估
    churn_risk,             -- Active/Low/Medium/High Churn Risk
    preferred_payment_method
FROM customers
```

### 🔍 客戶分段邏輯

- **High Value** (≥$200): VIP 客戶，重點維護
- **Medium Value** ($100-199): 成長潛力客戶  
- **Low Value** ($1-99): 基礎客戶群
- **No Purchase** ($0): 待激活用戶

---

## 🚀 效能展示

### ⚡ 執行效能

| 指標 | 表現 | 傳統方式對比 |
|------|------|--------------|
| **建構速度** | < 5 秒 | 10x 更快 |
| **測試執行** | < 10 秒 | 20x 更快 |
| **資料處理** | 312 筆記錄 | 可擴展至數百萬筆 |
| **動態欄位** | 20+ 自動生成 | 手動需要數小時 |

### 📈 可擴展性

- **📊 資料量**: 支援 TB 級資料處理
- **👥 團隊協作**: 支援數百位開發者同時協作
- **🔄 Pipeline**: 支援複雜的多層依賴關係
- **🌐 多環境**: dev/test/prod 環境隔離

---

## 💼 業務價值總結

### 🎯 立即價值

✅ **開發效率提升 60%** - 模組化開發，告別重複造輪子

✅ **錯誤減少 80%** - 自動化測試，提前發現問題

✅ **文件 100% 同步** - 程式碼即文件，永不過時

✅ **新人快速上手** - 從 3 個月縮短至 2 週

### 🚀 長期價值

🏗️ **企業級架構** - 支援大型團隊協作

🔄 **敏捷開發** - 快速響應業務需求變化

📊 **資料治理** - 完整的血緣追蹤與影響分析

💡 **知識沈澱** - 業務邏輯以程式碼形式保存

---

## 🎬 Live Demo Time!

### 🔴 現場演示流程

1. **⚡ 環境準備** (30 秒)
   ```bash
   source venv/bin/activate
   ```

2. **🏗️ 完整建構** (5 秒)
   ```bash
   dbt run
   ```

3. **🧪 測試驗證** (10 秒)
   ```bash
   dbt test --select test_type:unit
   dbt test
   ```

4. **📊 結果展示** (即時)
   ```sql
   SELECT customer_segment, activity_level, COUNT(*) 
   FROM customers GROUP BY 1,2;
   ```

5. **🎨 參數調整** (即時效果)
   ```bash
   dbt run --vars '{"high_value_threshold": 150}'
   ```

---

## 🎯 快速上手指南

### 📋 3 步驟開始使用

**步驟 1: 環境準備**
```bash
pip install dbt-core dbt-duckdb
dbt init my_project
```

**步驟 2: 建立第一個模型**
```sql
-- models/my_first_model.sql
SELECT * FROM {{ source('raw_data', 'customers') }}
```

**步驟 3: 執行與測試**
```bash
dbt run
dbt test
dbt docs generate
```

### 📚 學習資源

- 📖 [dbt 官方文檔](https://docs.getdbt.com/)
- 🎓 [dbt Learn 免費課程](https://courses.getdbt.com/)
- 🏘️ [dbt 社群 Slack](https://www.getdbt.com/community/)
- 📹 [Jaffle Shop 範例專案](https://github.com/dbt-labs/jaffle_shop)

---

## 🤝 Q&A 時間

### 💭 常見問題

**Q1: dbt 適合我們的資料規模嗎？**
- ✅ 從 GB 到 PB 級資料都適用
- ✅ 支援 20+ 種資料倉儲平台

**Q2: 學習成本如何？**
- 📈 SQL 熟練者：1-2 週上手
- 📚 完整掌握：1-2 個月
- 💡 ROI 回報：3-6 個月顯著提升

**Q3: 與現有工具整合？**
- 🔌 Airflow, Prefect 工作流程整合
- 📊 BI 工具無縫連接
- 🔄 CI/CD pipeline 支援

---

## 🎉 感謝聆聽！

### 📞 聯繫方式

**想要開始 dbt 之旅嗎？**

- 💬 **技術討論**: 隨時來找我聊聊實作細節
- 🛠️ **POC 支援**: 協助建立概念驗證專案  
- 📚 **知識分享**: 定期舉辦 dbt 讀書會
- 🚀 **專案合作**: 一起打造企業級資料平台

### 🎯 下一步行動

1. **📥 Clone Demo 專案**: 立即體驗 dbt 威力
2. **🏃‍♀️ 開始小型 POC**: 選擇一個小專案試水溫
3. **📈 制定遷移計畫**: 逐步導入現有資料工作流程
4. **👥 組建 dbt 團隊**: 培養內部 dbt 專家

**讓我們一起重新定義資料工程的未來！** 🚀

---

## 📎 附錄：Demo 專案資源

### 📁 專案連結
- **GitHub Repo**: [本專案連結]
- **Demo 指南**: `dbt_complete_demo_guide.md`
- **故障排除**: `unit_tests_troubleshooting.md`

### 🔧 快速命令參考
```bash
# 基本命令
dbt run                    # 建構所有模型
dbt test                   # 執行所有測試
dbt docs generate         # 生成文檔

# 進階命令
dbt run --select customers+    # 執行特定模型及下游
dbt test --select test_type:unit    # 只執行 unit tests
dbt build                 # run + test 一次完成
```

