# 🧪 dbt Unit Tests Demo 指南

## 📋 概述

此文檔展示如何在 dbt 中使用 **Unit Tests** 功能，以 `stg_payments` 模型為例，演示核心概念和最佳實務。

## 🎯 Demo 重點

### 為什麼需要 Unit Tests？
- **快速驗證**：不依賴完整資料庫，快速測試業務邏輯
- **邊界測試**：驗證邊界情況和異常案例
- **重構安全**：在修改模型時確保邏輯正確性
- **文件化**：測試即文檔，清楚展示預期行為

### 選擇的測試目標：`stg_payments`
```sql
-- 核心業務邏輯：將分轉換為元
amount / 100 as amount
```

## 🧪 建立的 Unit Tests

### Test 1：基本金額轉換邏輯
```yaml
test_stg_payments_amount_conversion:
  描述：驗證付款金額從分正確轉換為元
  輸入：1500分 → 預期：15.0元
  輸入：2000分 → 預期：20.0元
  輸入：500分  → 預期：5.0元
```

### Test 2：邊界情況測試
```yaml
test_stg_payments_edge_cases:
  描述：驗證零金額和大金額的處理
  輸入：0分      → 預期：0.0元
  輸入：999999分 → 預期：9999.99元
```

## 🚀 執行 Unit Tests

### 1. 運行所有 Unit Tests
```bash
dbt test --select test_type:unit
```

### 2. 運行特定模型的 Unit Tests
```bash
dbt test --select stg_payments,test_type:unit
```

### 3. 運行特定的 Unit Test
```bash
dbt test --select test_stg_payments_amount_conversion
```

### 4. 詳細輸出模式
```bash
dbt test --select test_type:unit --verbose
```

## 📊 預期結果

成功執行時應該看到：
```
✅ PASS test_stg_payments_amount_conversion ..................... [PASS in 0.05s]
✅ PASS test_stg_payments_edge_cases ............................ [PASS in 0.03s]
```

## 🎯 Demo 展示要點

### 1. **語法結構**
- `given`: 定義輸入資料
- `expect`: 定義預期輸出
- `model`: 指定要測試的模型

### 2. **業務邏輯驗證**
- 金額單位轉換 (分 → 元)
- 欄位重命名驗證
- 資料型態轉換

### 3. **測試策略**
- **正常情況**：常見的金額轉換
- **邊界情況**：零值和極大值
- **多樣化資料**：不同付款方式

## 💡 最佳實務

### ✅ 做什麼
- 測試核心業務邏輯
- 涵蓋邊界和異常情況
- 保持測試簡單專注
- 使用描述性測試名稱

### ❌ 避免什麼
- 測試過於複雜的邏輯
- 重複已有的資料測試
- 測試 dbt 內建功能
- 忽略邊界情況

## 🔧 與傳統測試的比較

| 特性 | Unit Tests | Data Tests |
|------|------------|------------|
| **目的** | 業務邏輯驗證 | 資料品質檢查 |
| **資料來源** | 模擬資料 | 實際資料 |
| **執行速度** | 極快 | 中等-慢 |
| **適用場景** | 重構、開發 | 生產監控 |

## 🎭 Demo 演示流程

1. **解釋背景**：為什麼需要 Unit Tests
2. **展示語法**：如何定義 unit tests
3. **執行測試**：實際運行命令
4. **解讀結果**：成功/失敗情況分析
5. **修改測試**：展示失敗案例和修復

## 📚 進階主題

- 複雜模型的 Unit Testing 策略
- Mock 外部依賴
- CI/CD 中的自動化測試
- 測試覆蓋率分析

---

**💡 提示**：Unit Tests 是 dbt v1.8+ 的新功能，為 Analytics Engineering 帶來了軟體開發的最佳實務！
