{{ 
  config(
    materialized='table',
    unique_key='order_id'
  ) 
}}

-- ================================================================
-- 🎯 Demo 目的：展示 Jinja 巨集與動態 SQL 生成
-- 此模型展示以下核心 dbt 概念：
-- 1. 使用變數與迴圈動態生成欄位
-- 2. 透過變數實現可配置的商業邏輯
-- 3. dbt_utils 函數的實際應用
-- ================================================================

-- Demo：從源資料動態取得付款方式
{% set payment_methods = dbt_utils.get_column_values(ref('stg_payments'), 'payment_method') %}

-- Demo：可配置的商業門檻值
{% set high_value_threshold = var('high_value_threshold', 10) %}

with orders as (

    select * from {{ ref('stg_orders') }}

),

payments as (

    select * from {{ ref('stg_payments') }}

),

-- Demo: Dynamic payment aggregation using Jinja loops
order_payments as (

    select
        order_id,

        -- Demo: Dynamic payment method columns (core Jinja feature)
        {% for payment_method in payment_methods -%}
        sum(case when payment_method = '{{ payment_method }}' then amount else 0 end) as {{ payment_method }}_amount,
        {% endfor -%}

        sum(amount) as total_amount,
        
        -- Demo: Business logic with configurable threshold
        case
            when sum(amount) >= {{ high_value_threshold }} then 'High Value'
            else 'Standard'
        end as order_value_category

    from payments
    group by order_id

),

final as (

    select
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        orders.status,

        -- Demo: Include dynamic payment columns
        {% for payment_method in payment_methods -%}
        order_payments.{{ payment_method }}_amount,
        {% endfor -%}

        order_payments.total_amount as amount,
        order_payments.order_value_category,
        
        -- Demo: Generate business key using dbt_utils
        {{ dbt_utils.generate_surrogate_key(['orders.order_id', 'orders.order_date']) }} as order_business_key

    from orders
    left join order_payments
        on orders.order_id = order_payments.order_id

)

select * from final
