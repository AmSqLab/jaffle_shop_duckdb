{{
  config(
    materialized='table',
    indexes=[
      {'columns': ['customer_id']}
    ]
  )
}}

-- ================================================================
-- 🎯 Demo 目的：展示中間層最佳實務範例
-- 此模型展示：
-- 1. 將複雜商業邏輯從最終數據集市模型中分離
-- 2. 可重用的模組化資料轉換
-- 3. 清晰的文件與命名慣例
-- ================================================================

{% set payment_methods = dbt_utils.get_column_values(ref('stg_payments'), 'payment_method') %}

with orders as (

    select * from {{ ref('stg_orders') }}

),

payments as (

    select * from {{ ref('stg_payments') }}

),

-- Calculate comprehensive order metrics per customer
customer_order_metrics as (

    select
        customer_id,
        
        -- Basic order statistics
        count(distinct order_id) as total_orders,
        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date,
        
        -- Time-based metrics
        date_diff('day', min(order_date), max(order_date)) as customer_lifespan_days,
        date_diff('day', max(order_date), current_date) as days_since_last_order,
        
        -- Order frequency analysis
        case 
            when count(distinct order_id) = 0 then 0
            when date_diff('day', min(order_date), max(order_date)) = 0 then 1
            else round(
                count(distinct order_id)::float / 
                (date_diff('day', min(order_date), max(order_date)) + 1)::float * 30, 2
            )
        end as avg_orders_per_month,
        
        -- Order status analysis
        count(distinct case when status = 'completed' then order_id end) as completed_orders,
        count(distinct case when status = 'returned' then order_id end) as returned_orders,
        count(distinct case when status in ('return_pending', 'returned') then order_id end) as problematic_orders

    from orders
    group by customer_id

),

-- Calculate comprehensive payment metrics per customer
customer_payment_metrics as (

    select
        orders.customer_id,
        
        -- Payment value metrics
        sum(payments.amount) as total_payment_amount,
        avg(payments.amount) as avg_payment_amount,
        count(distinct payments.payment_id) as total_payments,
        count(distinct orders.order_id) as paid_orders,
        
        -- Payment method analysis - dynamic columns
        {% for payment_method in payment_methods -%}
        sum(case when payments.payment_method = '{{ payment_method }}' then payments.amount else 0 end) as {{ payment_method }}_total,
        count(case when payments.payment_method = '{{ payment_method }}' then payments.payment_id end) as {{ payment_method }}_count,
        {% endfor -%}
        
        -- Payment method diversity
        count(distinct payments.payment_method) as payment_methods_used,
        
        -- Payment timing analysis
        avg(date_diff('day', orders.order_date, current_date)) as avg_days_since_order

    from payments
    left join orders using (order_id)
    where orders.customer_id is not null
    group by orders.customer_id

),

-- Combine and calculate derived metrics
final_customer_metrics as (

    select
        coalesce(o.customer_id, p.customer_id) as customer_id,
        
        -- Order metrics
        coalesce(o.total_orders, 0) as total_orders,
        o.first_order_date,
        o.most_recent_order_date,
        coalesce(o.customer_lifespan_days, 0) as customer_lifespan_days,
        coalesce(o.days_since_last_order, 9999) as days_since_last_order,
        coalesce(o.avg_orders_per_month, 0) as avg_orders_per_month,
        coalesce(o.completed_orders, 0) as completed_orders,
        coalesce(o.returned_orders, 0) as returned_orders,
        coalesce(o.problematic_orders, 0) as problematic_orders,
        
        -- Payment metrics
        coalesce(p.total_payment_amount, 0) as total_payment_amount,
        coalesce(p.avg_payment_amount, 0) as avg_payment_amount,
        coalesce(p.total_payments, 0) as total_payments,
        coalesce(p.paid_orders, 0) as paid_orders,
        coalesce(p.payment_methods_used, 0) as payment_methods_used,
        
        -- Dynamic payment method metrics
        {% for payment_method in payment_methods -%}
        coalesce(p.{{ payment_method }}_total, 0) as {{ payment_method }}_total,
        coalesce(p.{{ payment_method }}_count, 0) as {{ payment_method }}_count,
        {% endfor -%}
        
        -- Calculated business metrics
        case 
            when coalesce(o.total_orders, 0) = 0 then 0
            else round(coalesce(p.total_payment_amount, 0) / o.total_orders, 2)
        end as avg_order_value,
        
        -- Return rate calculation
        case 
            when coalesce(o.total_orders, 0) = 0 then 0
            else round(coalesce(o.returned_orders, 0)::float / o.total_orders * 100, 2)
        end as return_rate_percent,
        
        -- Payment completion rate
        case 
            when coalesce(o.total_orders, 0) = 0 then 0
            else round(coalesce(p.paid_orders, 0)::float / o.total_orders * 100, 2)
        end as payment_completion_rate_percent

    from customer_order_metrics o
    full outer join customer_payment_metrics p
        on o.customer_id = p.customer_id

)

select * from final_customer_metrics
