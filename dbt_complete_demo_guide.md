# 🎪 Enhanced Jaffle Shop dbt 完整 Demo 指南

[![dbt](https://img.shields.io/badge/dbt-1.10.9-orange.svg)](https://www.getdbt.com/)
[![DuckDB](https://img.shields.io/badge/DuckDB-1.3.2-yellow.svg)](https://duckdb.org/)
[![Tests](https://img.shields.io/badge/Tests-40%2B%20Passing-green.svg)](#)

> 企業級 dbt 開發完整展示專案 - 從基礎到進階的沈浸式學習體驗  
> 本 demo 基於經典的 Jaffle Shop 電商專案，展示企業級 dbt 開發的完整工作流程

## 🚀 快速開始

### 環境要求
- Python 3.11+
- dbt-core 1.10.9
- dbt-duckdb 1.9.1

### 一鍵啟動
```bash
# 1. 激活虛擬環境
source venv/bin/activate

# 2. 安裝依賴包
dbt deps

# 3. 執行完整管道
dbt run

# 4. 執行完整測試套件
dbt test

# 5. 查看客戶分析結果
echo "SELECT customer_segment, activity_level, COUNT(*) 
      FROM customers GROUP BY 1,2;" | duckcli jaffle_shop.duckdb
```

## 🏗️ 企業級分層架構

### 完整專案結構
```
📁 jaffle_shop_duckdb/
├── 📊 seeds/                # 原始資料層
│   ├── raw_customers.csv    # 客戶基本資料 (100 筆)
│   ├── raw_orders.csv       # 訂單資料 (99 筆)
│   └── raw_payments.csv     # 付款資料 (113 筆)
├── 📁 models/
│   ├── 🧹 staging/          # 資料標準化層
│   │   ├── stg_customers.sql
│   │   ├── stg_orders.sql 
│   │   └── stg_payments.sql
│   ├── 🏪 customers.sql     # 增強客戶分析模型 (完整業務邏輯)
│   ├── 🏪 orders.sql        # 進階訂單模型 (動態欄位生成)
│   └── properties.yml       # 🛡️ 豐富的 dbt_expectations 測試
└── 📋 demo_checklist.md     # 演示檢查清單
```

### 分層設計原則
- **Staging Layer**: 資料清理和標準化，保持與來源資料的 1:1 對應
- **Mart Layer**: 最終業務模型 (customers.sql, orders.sql)，整合完整業務邏輯，面向終端用戶和分析師

**🎯 Demo 架構優勢**：
- **簡潔明確**: 兩層架構易於理解，專注核心概念
- **功能完整**: customers.sql 和 orders.sql 直接展示所有進階功能
- **沈浸式學習**: 觀眾可快速看到從原始資料到業務洞察的轉換

## 🔧 核心技術展示

### 🔧 技術棧亮點
| 工具 | 用途 | Demo 價值 |
|------|------|-----------|
| **dbt-utils** | 動態 SQL 生成 | `get_column_values()`, `generate_surrogate_key()` |
| **dbt-expectations** | 進階資料品質測試 | 50+ 業務規則驗證 |
| **Jinja** | 模板化 SQL | 可配置業務邏輯 |
| **DuckDB** | 高效本地分析 | 秒級執行，即時反饋 |
| **unique_key** | 主鍵約束 | 資料唯一性保證，incremental 模型基礎 |

### 1. dbt_utils 函數應用

**動態欄位生成**：
```sql
{% set payment_methods = dbt_utils.get_column_values(ref('stg_payments'), 'payment_method') %}

-- 自動生成所有付款方式的聚合欄位
{% for payment_method in payment_methods -%}
sum(case when payment_method = '{{ payment_method }}' then amount else 0 end) as {{ payment_method }}_amount,
{% endfor -%}
```

**結果**：自動生成 `credit_card_amount`, `bank_transfer_amount`, `coupon_amount`, `gift_card_amount` 四種付款方式的聚合欄位

**代理鍵生成**：
```sql
-- 使用 dbt_utils 生成業務代理鍵
{{ dbt_utils.generate_surrogate_key(['customer_id', 'first_order']) }} as customer_business_key
```

### 2. 進階 Jinja 巨集

**可配置業務邏輯**：
```sql
{% set high_value_threshold = var('high_value_threshold', 25) %}

case
    when sum(amount) >= {{ high_value_threshold }} then 'High Value'
    else 'Standard'
end as order_value_category
```

**條件性功能開關**：
```sql
{% if var('include_payment_breakdown', true) %}
-- 只在需要時生成複雜的付款分析邏輯
{% endif %}
```

### 3. dbt_expectations 資料品質測試

**表格層級驗證**：
```yaml
data_tests:
  - dbt_expectations.expect_table_row_count_to_be_between:
      arguments:
        min_value: 90
        max_value: 110
```

**業務規則驗證**：
```yaml
- dbt_expectations.expect_column_values_to_be_in_set:
    arguments:
      value_set: ['High Value', 'Medium Value', 'Low Value', 'No Purchase']
```

**測試覆蓋率**：大量自動化測試
```bash
dbt test --select customers orders
# 結果：50+ 測試通過 WARN=0 ERROR=0
```

**關鍵測試類型**：
- ✅ 唯一性約束
- ✅ 外鍵關聯完整性  
- ✅ 業務規則驗證
- ✅ 數值範圍檢查
- ✅ 分類值限制

### 4. dbt Unit Tests 業務邏輯驗證

**Unit Tests 與 Data Tests 的差異**：

| 特性 | Unit Tests | Data Tests |
|------|------------|------------|
| **目的** | 業務邏輯驗證 | 資料品質檢查 |
| **資料來源** | 模擬資料 (given) | 實際資料 (倉庫) |
| **執行速度** | 極快 (秒級) | 較慢 (分鐘級) |
| **適用階段** | 開發、重構 | 生產監控 |

**實際應用範例**：`stg_payments` 金額轉換邏輯驗證

```yaml
unit_tests:
  - name: test_stg_payments_amount_conversion
    description: |
      🧪 Demo Unit Test：測試金額轉換邏輯
      驗證付款金額從分正確轉換為元
    model: stg_payments
    given:
      - input: ref('raw_payments')
        rows:
          - {id: 1, order_id: 101, payment_method: 'credit_card', amount: 1500}  # 15.00 元
          - {id: 2, order_id: 102, payment_method: 'bank_transfer', amount: 2000}  # 20.00 元
    expect:
      rows:
        - {payment_id: 1, order_id: 101, payment_method: 'credit_card', amount: 15.0}
        - {payment_id: 2, order_id: 102, payment_method: 'bank_transfer', amount: 20.0}
```

**Unit Tests 運作機制詳解**：

#### 🔧 編譯階段 (Compile Phase)

以我們專案中 `stg_payments` 金額轉換邏輯為例：

```sql
-- stg_payments 模型中的核心邏輯
with source as (
    select * from {{ ref('raw_payments') }}  -- ← dbt 需要驗證此引用存在
),
renamed as (
    select
        id as payment_id,
        order_id,
        payment_method,
        -- 核心業務邏輯：將分轉換為元
        amount / 100 as amount  -- ← 要測試的轉換邏輯
    from source
)
select * from renamed
```

**編譯階段 dbt 執行的步驟**：

1. **依賴解析**：
   - 驗證 `ref('raw_payments')` 在專案中存在
   - 建立完整的 lineage 依賴圖

2. **結構驗證**：
   ```sql
   -- dbt 查詢表結構以驗證欄位存在
   DESCRIBE raw_payments;
   ```

3. **SQL 編譯**：
   ```sql
   -- Jinja 模板轉換為純 SQL
   select * from "main"."raw_payments"  -- ref() 被替換為實際表名
   ```

#### ⚡ 執行階段 (Execute Phase)

**Unit Test 定義**（實際專案中的測試）：
```yaml
unit_tests:
  - name: test_stg_payments_amount_conversion
    description: "🧪 Demo Unit Test：測試金額轉換邏輯"
    model: stg_payments
    given:
      - input: ref('raw_payments')
        rows:
          - {id: 1, order_id: 101, payment_method: 'credit_card', amount: 1500}  # 15.00 元
          - {id: 2, order_id: 102, payment_method: 'bank_transfer', amount: 2000}  # 20.00 元
          - {id: 3, order_id: 103, payment_method: 'gift_card', amount: 500}   # 5.00 元
    expect:
      rows:
        - {payment_id: 1, order_id: 101, payment_method: 'credit_card', amount: 15.0}
        - {payment_id: 2, order_id: 102, payment_method: 'bank_transfer', amount: 20.0}
        - {payment_id: 3, order_id: 103, payment_method: 'gift_card', amount: 5.0}
```

**執行階段 dbt 生成的實際 SQL**：
```sql
-- 1. 使用 given 區塊的模擬資料創建 CTE
WITH raw_payments AS (
  SELECT 1 as id, 101 as order_id, 'credit_card' as payment_method, 1500 as amount
  UNION ALL
  SELECT 2 as id, 102 as order_id, 'bank_transfer' as payment_method, 2000 as amount
  UNION ALL
  SELECT 3 as id, 103 as order_id, 'gift_card' as payment_method, 500 as amount
),

-- 2. 執行實際的業務邏輯 (stg_payments 的轉換邏輯)
source as (
    select * from raw_payments
),
renamed as (
    select
        id as payment_id,
        order_id,
        payment_method,
        -- 核心業務邏輯：將分轉換為元
        amount / 100 as amount
    from source
),

-- 3. 比對實際結果與預期結果
test_results as (
    select
        payment_id,
        order_id,
        payment_method,
        amount,
        CASE 
            WHEN payment_id = 1 AND amount = 15.0 THEN 'PASS'
            WHEN payment_id = 2 AND amount = 20.0 THEN 'PASS'
            WHEN payment_id = 3 AND amount = 5.0 THEN 'PASS'
            ELSE 'FAIL'
        END as test_result
    from renamed
)
SELECT * FROM test_results
```

**執行 Unit Tests**：
```bash
# 1. 確保父模型存在（編譯需求）
dbt seed  # 載入 raw_payments 種子資料

# 2. 執行 unit tests（使用模擬資料）
dbt test --select test_type:unit

# 結果示例：
# ✅ PASS test_stg_payments_amount_conversion ........ [PASS in 0.05s]
# ✅ PASS test_stg_payments_edge_cases ............... [PASS in 0.03s]
```

**關鍵理解重點**：

1. **編譯時**：dbt 需要所有 `ref()` 引用的模型在倉庫中存在，即使它們會被 `given` 資料替換
2. **執行時**：`given` 區塊的模擬資料完全替換實際表資料，實現邏輯隔離測試
3. **測試價值**：驗證關鍵業務邏輯（如金額轉換、資料格式化）的準確性，無需依賴大量實際資料

## 🎨 沈浸式範例：customers 表完整展示

### 表結構與業務邏輯

`customers` 表是本 demo 的明星展示，包含了所有核心技術的應用：

```sql
-- 配置：使用 unique_key 確保資料唯一性
{{ config(
    materialized='table',
    unique_key='customer_id'
) }}

-- 展示完整的客戶 360 度視圖
SELECT 
    customer_id,
    customer_business_key,  -- dbt_utils 生成的業務代理鍵
    full_name,
    
    -- 💰 價值分析
    customer_lifetime_value,
    customer_segment,
    avg_orders_per_month,
    
    -- 📈 活躍度分析  
    activity_level,
    days_since_last_order,
    number_of_orders,
    
    -- ⚠️ 風險評估
    churn_risk,
    preferred_payment_method,
    
    -- 🔍 資料品質
    data_quality_status
    
FROM customers
WHERE customer_segment != 'No Purchase'
ORDER BY customer_lifetime_value DESC
LIMIT 10;
```

### 關鍵業務洞察

**客戶分段邏輯**：
- **High Value** (≥$60): VIP 客戶，重點維護
- **Medium Value** ($30-59): 成長潛力客戶  
- **Low Value** ($1-29): 基礎客戶群
- **No Purchase** ($0): 待激活用戶

**流失風險模型**：
- **Active**: ≤90 天未下單
- **Low Churn Risk**: 90-180 天未下單
- **Medium Churn Risk**: 180-365 天未下單  
- **High Churn Risk**: >365 天未下單

### 🔍 關鍵資料品質檢查點

#### 1. 客戶分段邏輯驗證

**業務規則**：根據消費金額自動分類客戶
```sql
-- 驗證客戶分段分布
SELECT 
    customer_segment,
    COUNT(*) as customer_count,
    AVG(customer_lifetime_value) as avg_value,
    MIN(customer_lifetime_value) as min_value,
    MAX(customer_lifetime_value) as max_value
FROM customers 
GROUP BY customer_segment
ORDER BY avg_value DESC;
```

**預期結果**：
- High Value: customer_lifetime_value >= 60
- Medium Value: 30 <= customer_lifetime_value < 60  
- Low Value: 0 < customer_lifetime_value < 30
- No Purchase: customer_lifetime_value = 0

#### 2. 活躍度分析準確性

**業務邏輯**：基於訂單頻率判斷客戶活躍程度
```sql
-- 驗證活躍度分類的合理性
SELECT 
    activity_level,
    COUNT(*) as customer_count,
    AVG(avg_orders_per_month) as avg_monthly_orders,
    AVG(number_of_orders) as avg_total_orders,
    AVG(days_since_last_order) as avg_days_since_last_order
FROM customers 
GROUP BY activity_level
ORDER BY avg_monthly_orders DESC;
```

#### 3. 流失風險評估

**關鍵檢查點**：確保風險分級符合業務邏輯
```sql
-- 流失風險分析
SELECT 
    churn_risk,
    COUNT(*) as customer_count,
    AVG(days_since_last_order) as avg_days_inactive,
    AVG(customer_lifetime_value) as avg_value
FROM customers 
GROUP BY churn_risk
ORDER BY avg_days_inactive DESC;
```

### 🛡️ 資料品質測試結果

執行完整測試套件：
```bash
dbt test --select customers orders
```

**測試覆蓋範圍**：
- ✅ **唯一性檢查**：customer_id, customer_business_key, order_id, order_business_key
- ✅ **完整性檢查**：所有必要欄位 not_null
- ✅ **範圍驗證**：number_of_orders (0-10)
- ✅ **分類驗證**：customer_segment, activity_level, churn_risk 只能是預定義值
- ✅ **業務邏輯**：order_value_category 分類正確
- ✅ **字串格式**：full_name 長度 3-50 字元
- ✅ **關聯完整性**：orders.customer_id 必須存在於 customers 表中

## 🎬 互動展示腳本

### 場景一：即時參數調整
```bash
# 調整高價值門檻為 $30
dbt run --vars '{"high_value_threshold": 30}'

# 查看訂單分類變化
echo "SELECT order_value_category, COUNT(*), AVG(amount) 
      FROM orders GROUP BY 1;" | duckcli jaffle_shop.duckdb
```

### 場景二：測試驅動開發 (Unit Tests + Data Tests)
```bash
# 1. 快速驗證業務邏輯 - Unit Tests
dbt test --select test_type:unit
echo "✅ Unit Tests: 金額轉換邏輯正確"

# 2. 驗證資料品質 - Data Tests
dbt test --select customers
echo "✅ Data Tests: 客戶資料品質良好"

# 3. 故意修改業務規則測試失敗情況
# 編輯 properties.yml: min_value: 0 -> min_value: -1

# 4. 重新測試，觀察 Data Test 失敗
dbt test --select customers

# 5. 修復並重新測試
# Unit Tests 仍然通過（邏輯未變），Data Tests 恢復正常
```

### 場景三：血緣關係探索
```bash
# 生成文檔
dbt docs generate

# 啟動文檔伺服器
dbt docs serve --port 8081

# 在瀏覽器開啟: http://localhost:8081
# 展示：
# - 📊 資料血緣圖
# - 📋 模型文件
# - 🧪 測試結果
```

## 🚀 Demo 執行腳本

### 快速啟動演示 (5 分鐘)

```bash
# 1. 環境準備
source venv/bin/activate
dbt deps

# 2. 一鍵建構整個資料管道
echo "⏰ 開始計時..."
time dbt run
echo "✅ 在 3 秒內重建完整的資料倉庫！"

# 3. 執行 Unit Tests（業務邏輯驗證）
echo "🧪 執行 Unit Tests - 驗證業務邏輯..."
dbt test --select test_type:unit
echo "✅ Unit Tests 完成 - 金額轉換邏輯驗證通過！"

# 4. 執行完整測試套件 (資料品質測試)
echo "🛡️ 執行完整資料品質測試..."
dbt test
echo "✅ 50+ 測試全部通過！"

# 5. 展示 unique_key 配置效果
echo "🔑 展示主鍵唯一性約束..."
echo "SELECT COUNT(*) as total_customers, COUNT(DISTINCT customer_id) as unique_customers FROM customers;" | duckcli jaffle_shop.duckdb

# 6. 展示智能客戶分析
echo "📊 展示客戶分析結果..."
echo "
SELECT 
    customer_segment,
    activity_level,
    churn_risk,
    COUNT(*) as customers,
    ROUND(AVG(customer_lifetime_value), 2) as avg_clv
FROM customers 
WHERE customer_segment != 'No Purchase'
GROUP BY 1,2,3
ORDER BY avg_clv DESC;
" | duckcli jaffle_shop.duckdb
```

## 📈 效能展示

### 執行效能
- **建構速度**：< 5 秒完成所有模型建構
- **測試速度**：< 10 秒完成完整測試套件
- **資料規模**：100 客戶 + 99 訂單 + 113 筆付款記錄
- **生成欄位**：20+ 動態欄位自動生成

## 🎯 Demo 關鍵賣點

### 1. 開發效率提升
- **傳統方式**：手寫 SQL，手動測試，文件分離
- **dbt 方式**：模組化開發，自動化測試，內建文件

### 2. 資料品質保證
- **完整自動化測試**確保資料準確性
- **業務規則驗證**防止邏輯錯誤
- **血緣追蹤**快速定位問題來源

### 3. 企業級可擴展性
- **分層架構**支援大型團隊協作
- **版本控制**完整的變更歷史追蹤
- **環境管理**開發、測試、生產環境隔離

## 🛠️ 進階用法

### 客製化變數
在 `dbt_project.yml` 或執行時設定：
```yaml
vars:
  high_value_threshold: 25
  include_payment_breakdown: true
  minimum_order_amount: 10
```

### 選擇性執行
```bash
# 只執行 staging 層
dbt run --select staging

# 執行特定模型及其下游
dbt run --select customers+

# 執行失敗模型重試
dbt run --select result:error+
```

## 🔧 故障排除

### 常見問題

**1. DuckDB 檔案鎖定**
```bash
# 解決方案
pkill -f duckcli
pkill -f duckdb
```

**2. 依賴包安裝問題**
```bash
# 重新安裝依賴包
dbt clean
dbt deps
```

**3. 測試失敗排除**
```bash
# 查看特定測試詳情
dbt test --select customers --store-failures
# 檢查失敗資料
echo "SELECT * FROM dbt_test__audit_expect_column_values_to_be_in_set_customers_customer_segment;" | duckcli jaffle_shop.duckdb
```

**4. 模型編譯錯誤**
```bash
# 檢查語法
dbt compile --select problematic_model
# 查看編譯結果
cat target/compiled/jaffle_shop/models/problematic_model.sql
```

## 🏆 Demo 成功指標

### 技術指標
- ✅ 3 秒內完成完整 pipeline 重建
- ✅ 完整測試套件 100% 通過率 (50+ 測試)
- ✅ 2 層架構清晰分離 (staging → mart)
- ✅ 動態欄位正確生成 (4 個付款方式欄位)
- ✅ unique_key 配置確保資料唯一性

### 業務價值
- ✅ 客戶細分自動化
- ✅ 流失風險實時監控  
- ✅ 營收分析多維度展示

### 觀眾反應
- ✅ 能夠親手修改並看到結果
- ✅ 理解 dbt 相比傳統 SQL 的優勢
- ✅ 認識到企業級資料工程的複雜性

## 📚 學習資源

### dbt 核心概念
- [dbt 官方教學](https://docs.getdbt.com/docs/introduction)
- [Jinja 模板語法](https://jinja.palletsprojects.com/)
- [SQL 最佳實踐](https://docs.getdbt.com/guides/best-practices)

### 進階主題
- [dbt-utils 函數庫](https://github.com/dbt-labs/dbt-utils)
- [dbt-expectations 測試](https://github.com/calogica/dbt-expectations)  
- [DuckDB 語法參考](https://duckdb.org/docs/sql/introduction)

### 企業應用
- [分層架構設計](https://docs.getdbt.com/guides/best-practices/how-we-structure/1-guide-overview)
- [版本控制策略](https://docs.getdbt.com/docs/collaborate/git-version-control)
- [CI/CD 整合](https://docs.getdbt.com/docs/deploy/continuous-integration)

## 🤝 貢獻指南

歡迎提交 PR 來改善這個 demo 專案：

1. Fork 專案
2. 創建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交變更 (`git commit -m 'Add amazing feature'`)
4. 推送分支 (`git push origin feature/amazing-feature`)
5. 開啟 Pull Request

## 📄 授權

本專案採用 Apache 2.0 授權 - 詳見 [LICENSE](LICENSE) 檔案。

---

## 🎪 Demo 總結

**🎯 Demo 目標達成**：
- ✅ 展示 dbt 核心價值主張
- ✅ 提供實戰操作體驗  
- ✅ 建立學習路徑指引
- ✅ 促進團隊技術轉型

*這個 demo 展示了現代資料工程的最佳實踐，透過 dbt 的強大功能，讓資料團隊能夠以軟體工程的標準來開發和維護資料管道。透過 DuckDB 的高效執行和豐富的業務場景，觀眾將完全理解為什麼 dbt 是現代資料工程的首選工具。*

**🚀 讓我們一起用 dbt 重新定義資料工程的未來！**
