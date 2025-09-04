{{
  config(
    materialized='table'
  )
}}

-- ================================================================
-- 🎯 Demo Purpose: Simple intermediate layer showcase
-- Demonstrates modular business logic separation
-- ================================================================

{% set payment_methods = dbt_utils.get_column_values(ref('stg_payments'), 'payment_method') %}

with orders as (

    select * from {{ ref('stg_orders') }}

),

payments as (

    select * from {{ ref('stg_payments') }}

),

-- Calculate order metrics per customer
customer_orders as (

    select
        customer_id,
        count(distinct order_id) as total_orders,
        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date,
        count(case when status = 'completed' then 1 end) as completed_orders,
        count(case when status = 'returned' then 1 end) as returned_orders

    from orders
    group by customer_id

),

-- Calculate payment metrics per customer  
customer_payments as (

    select
        orders.customer_id,
        sum(payments.amount) as total_amount,
        count(distinct payments.payment_id) as total_payments,
        
        -- Dynamic payment method totals
        {% for payment_method in payment_methods -%}
        sum(case when payments.payment_method = '{{ payment_method }}' then payments.amount else 0 end) as {{ payment_method }}_total,
        {% endfor -%}
        
        count(distinct payments.payment_method) as payment_methods_used

    from payments
    left join orders using (order_id)
    where orders.customer_id is not null
    group by orders.customer_id

)

-- Final customer summary
select
    coalesce(o.customer_id, p.customer_id) as customer_id,
    
    -- Order metrics
    coalesce(o.total_orders, 0) as total_orders,
    o.first_order_date,
    o.most_recent_order_date,
    coalesce(o.completed_orders, 0) as completed_orders,
    coalesce(o.returned_orders, 0) as returned_orders,
    
    -- Payment metrics
    coalesce(p.total_amount, 0) as total_amount,
    coalesce(p.total_payments, 0) as total_payments,
    coalesce(p.payment_methods_used, 0) as payment_methods_used,
    
    -- Payment method breakdown
    {% for payment_method in payment_methods -%}
    coalesce(p.{{ payment_method }}_total, 0) as {{ payment_method }}_total,
    {% endfor -%}
    
    -- Business calculations
    case 
        when coalesce(o.total_orders, 0) = 0 then 0
        else round(coalesce(p.total_amount, 0) / o.total_orders, 2)
    end as avg_order_value,
    
    case 
        when coalesce(o.total_orders, 0) = 0 then 0
        else round(coalesce(o.returned_orders, 0)::float / o.total_orders * 100, 1)
    end as return_rate_percent

from customer_orders o
full outer join customer_payments p using (customer_id)
