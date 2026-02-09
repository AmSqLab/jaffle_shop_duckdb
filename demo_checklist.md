# 🎯 dbt Demo 執行檢查清單

## 📋 演示前準備 (5 分鐘)

### ✅ 環境檢查
```bash
# 1. 確認虛擬環境
source venv/bin/activate
which dbt
# 預期輸出：/path/to/venv/bin/dbt

# 2. 確認依賴包
dbt --version
# 預期：dbt-core 1.10.9, dbt-duckdb 1.9.1

# 3. 測試 DuckDB 連線
duckcli jaffle_shop.duckdb -c "SELECT 'Connection OK' as status;"
# 預期輸出：Connection OK

# 4. 清理舊資料
rm -f jaffle_shop.duckdb
```

### ✅ 基礎建構檢查
```bash
# 建構所有模型
dbt run
# 預期：7 個模型全部成功 (PASS=7)

# 執行完整測試
dbt test  
# 預期：40+ 測試全部通過 (PASS=40+)

# 快速資料驗證
echo "SELECT COUNT(*) as customers FROM customers;" | duckcli jaffle_shop.duckdb
# 預期：customers = 100
```

## 🎬 Demo 流程腳本

### 第一部分：dbt 價值展示 (10 分鐘)

#### 1.1 快速重建展示
```bash
echo "⏰ 開始計時..."
time dbt run
echo "✅ 在 3 秒內重建完整的資料倉庫！"
```

#### 1.2 業務洞察展示
```sql
-- 執行這個查詢展示豐富的業務洞察
echo "
SELECT 
    customer_segment,
    activity_level,
    churn_risk,
    COUNT(*) as customers,
    AVG(customer_lifetime_value) as avg_value
FROM customers 
WHERE customer_segment != 'No Purchase'
GROUP BY 1,2,3
ORDER BY avg_value DESC;
" | duckcli jaffle_shop.duckdb
```

**💡 解說重點**：
> "這不只是 SQL，而是智能業務分析。每位客戶都被自動分類到風險等級和價值區間。"

### 第二部分：技術深度展示 (15 分鐘)

#### 2.1 動態 SQL 魔法
展示 `models/orders.sql` 的關鍵代碼：
```sql
{% set payment_methods = dbt_utils.get_column_values(ref('stg_payments'), 'payment_method') %}

{% for payment_method in payment_methods -%}
sum(case when payment_method = '{{ payment_method }}' then amount else 0 end) as {{ payment_method }}_amount,
{% endfor -%}
```

**🎯 Demo 技巧**：
1. 開啟 `models/orders.sql` 檔案
2. 指出第 22 行的 `get_column_values()` 函數
3. 展示結果資料表的動態欄位

#### 2.2 資料品質保證
```bash
# 展示測試威力
dbt test --select customers
echo "📊 共執行了多少個測試？讓我們算算..."
grep -r "data_tests:" models/ | wc -l
echo "✅ 超過 40 個自動化測試確保資料品質！"
```

#### 2.3 分層架構價值
```bash
# 展示血緣關係
dbt docs generate && echo "📊 正在啟動互動式文檔..."
dbt docs serve --port 8081 &
echo "🌐 請開啟 http://localhost:8081 查看資料血緣圖"
```

### 第三部分：互動體驗 (10 分鐘)

#### 3.1 觀眾動手環節
```bash
echo "🎯 現在讓觀眾來調整業務參數！"
echo "我們要把高價值訂單門檻從 $100 調整到 $150"

# 執行參數調整
dbt run --vars '{"high_value_threshold": 150}'

# 查看變化
echo "
SELECT 
    order_value_category,
    COUNT(*) as order_count,
    AVG(amount) as avg_amount
FROM orders 
GROUP BY 1;
" | duckcli jaffle_shop.duckdb
```

#### 3.2 測試驅動開發展示
```bash
echo "🧪 讓我們看看如果資料出現問題會發生什麼..."

# 故意建立會失敗的測試場景
# (可以臨時修改 properties.yml 中的期望值)

dbt test --select customers --store-failures
echo "❌ 測試失敗了！這就是資料品質保護的威力"
```

## 🔍 關鍵資料品質展示點

### 檢查點 1：客戶分段邏輯準確性
```sql
-- 驗證分段邏輯
echo "
-- 📊 客戶價值分段驗證
SELECT 
    customer_segment,
    MIN(customer_lifetime_value) as min_value,
    MAX(customer_lifetime_value) as max_value,
    COUNT(*) as customer_count
FROM customers 
GROUP BY 1
ORDER BY min_value;
" | duckcli jaffle_shop.duckdb
```

**預期結果**：
```
customer_segment | min_value | max_value | customer_count
No Purchase     | 0.00      | 0.00      | 1
Low Value       | 1.00      | 99.00     | 15  
Medium Value    | 100.00    | 199.00    | 22
High Value      | 200.00    | 500.00    | 62
```

### 檢查點 2：付款完整性驗證
```sql
-- 訂單與付款關聯完整性
echo "
-- 🔍 付款完整性檢查
SELECT 
    'Orders with payments' as check_type,
    COUNT(DISTINCT o.order_id) as count
FROM orders o
INNER JOIN (
    SELECT DISTINCT order_id FROM {{ ref('stg_payments') }}
) p USING (order_id)

UNION ALL

SELECT 
    'Orders without payments' as check_type,
    COUNT(DISTINCT o.order_id) as count  
FROM orders o
LEFT JOIN (
    SELECT DISTINCT order_id FROM {{ ref('stg_payments') }}
) p USING (order_id)
WHERE p.order_id IS NULL;
" | duckcli jaffle_shop.duckdb
```

### 檢查點 3：時間邏輯一致性
```sql
-- 訂單時間邏輯檢查
echo "
-- 📅 時間邏輯一致性驗證
SELECT 
    COUNT(*) as total_customers,
    COUNT(CASE WHEN first_order <= most_recent_order THEN 1 END) as valid_time_logic,
    COUNT(CASE WHEN days_since_last_order >= 0 THEN 1 END) as valid_recency
FROM customers
WHERE first_order IS NOT NULL;
" | duckcli jaffle_shop.duckdb
```

## ⚠️ 常見問題快速修復

### 問題 1：DuckDB 檔案鎖定
```bash
# 症狀：無法執行 dbt run
# 解決：
pkill -f duckcli
pkill -f duckdb  
echo "🔓 DuckDB 連線已清理"
```

### 問題 2：測試失敗
```bash
# 症狀：dbt test 出現錯誤
# 快速診斷：
dbt test --select customers --store-failures
echo "檢查失敗資料..." 
echo "SELECT * FROM main.dbt_test__audit LIMIT 5;" | duckcli jaffle_shop.duckdb
```

### 問題 3：模型編譯錯誤
```bash
# 症狀：Jinja 語法錯誤
# 快速檢查：
dbt compile --select problematic_model
cat target/compiled/jaffle_shop/models/problematic_model.sql
```

## 🎯 Demo 成功指標

### 技術指標
- ✅ `dbt run` 執行時間 < 10 秒
- ✅ `dbt test` 40+ 測試全部通過  
- ✅ 動態欄位正確生成 (4 個付款方式欄位)
- ✅ 客戶分段邏輯準確 (4 個分類)

### 觀眾互動指標
- ✅ 觀眾能夠成功修改業務參數
- ✅ 測試失敗演示引起關注
- ✅ 血緣圖展示獲得讚嘆
- ✅ 至少 3 個技術問題討論

### 業務價值傳達
- ✅ 理解 dbt vs 傳統 SQL 差異
- ✅ 認識資料品質保證重要性  
- ✅ 體會分層架構的可維護性
- ✅ 感受到開發效率提升潛力

## 📞 Demo 後續動作

### 立即行動
```bash
# 1. 提供專案連結
echo "📂 Demo 專案已上傳至：[GitHub連結]"

# 2. 分享學習資源
echo "📚 推薦學習路徑：
- dbt Fundamentals (免費課程)
- dbt-utils 官方文檔  
- 企業級 dbt 最佳實踐指南"

# 3. 建立學習群組
echo "💬 歡迎加入 dbt 學習交流群組"
```

### 長期規劃
- 📅 規劃 dbt 進階工作坊
- 🛠️ 評估企業導入可行性
- 👥 組建資料工程團隊
- 🚀 制定技術轉型路線圖

---

**🎪 Demo 總結**：
*透過這個 45 分鐘的沈浸式展示，觀眾將完全理解為什麼 dbt 是現代資料工程的首選工具。從動態 SQL 生成到企業級資料品質保證，每個功能都有明確的業務價值和實際應用場景。*
