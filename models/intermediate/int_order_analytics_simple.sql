{{
  config(
    materialized='view'
  )
}}

-- ================================================================
-- 🎯 Demo Purpose: Simplified order-level analytics for stable demo
-- This model demonstrates:
-- 1. Order enrichment with business context
-- 2. Window functions for customer journey
-- 3. Multi-dimensional order classification
-- ================================================================

{% set payment_methods = dbt_utils.get_column_values(ref('stg_payments'), 'payment_method') %}
{% set high_value_threshold = var('high_value_threshold', 100) %}

with orders as (
    select * from {{ ref('stg_orders') }}
),

payments as (
    select * from {{ ref('stg_payments') }}
),

-- Aggregate payment information per order
order_payments as (
    select
        order_id,
        sum(amount) as total_amount,
        count(payment_id) as payment_count,
        count(distinct payment_method) as payment_methods_count,
        
        -- Dynamic payment method breakdown
        {% for payment_method in payment_methods -%}
        sum(case when payment_method = '{{ payment_method }}' then amount else 0 end) as {{ payment_method }}_amount,
        {% endfor -%}
        
        -- Simple primary payment method logic
        case
            when count(distinct payment_method) = 1 then max(payment_method)
            else 'mixed'
        end as primary_payment_method

    from payments
    group by order_id
),

-- Calculate customer order context
customer_order_context as (
    select
        orders.*,
        
        -- Customer order sequencing
        row_number() over (
            partition by customer_id 
            order by order_date asc
        ) as customer_order_sequence,
        
        row_number() over (
            partition by customer_id 
            order by order_date desc
        ) as customer_order_recency_rank,
        
        -- Days between orders
        date_diff(
            'day',
            lag(order_date) over (partition by customer_id order by order_date asc),
            order_date
        ) as days_since_previous_order,
        
        -- Customer total orders
        count(*) over (partition by customer_id) as customer_total_orders

    from orders
)

-- Final enriched order analytics
select
    -- Basic order information
    o.order_id,
    o.customer_id,
    o.order_date,
    o.status,
    
    -- Payment information
    p.total_amount,
    p.payment_count,
    p.payment_methods_count,
    p.primary_payment_method,
    
    -- Dynamic payment method amounts
    {% for payment_method in payment_methods -%}
    p.{{ payment_method }}_amount,
    {% endfor -%}
    
    -- Customer context
    o.customer_order_sequence,
    o.customer_order_recency_rank,
    o.customer_total_orders,
    o.days_since_previous_order,
    
    -- Order classifications
    case 
        when o.customer_order_sequence = 1 then 'First Order'
        when o.customer_order_recency_rank = 1 then 'Latest Order'
        when o.customer_order_sequence <= 3 then 'Early Order'
        else 'Repeat Order'
    end as order_customer_journey_stage,
    
    case
        when p.total_amount >= {{ high_value_threshold }} then 'High Value'
        when p.total_amount >= {{ high_value_threshold * 0.5 }} then 'Medium Value'
        else 'Standard Value'
    end as order_value_tier,
    
    -- Order complexity analysis
    case
        when p.payment_methods_count > 2 then 'Complex Payment'
        when p.payment_methods_count = 2 then 'Dual Payment'
        else 'Simple Payment'
    end as payment_complexity,
    
    -- Time-based classifications (simplified)
    case
        when date_part('dow', o.order_date) in (0, 6) then 'Weekend'
        else 'Weekday'
    end as order_day_type,
    
    -- Order velocity analysis
    case
        when o.days_since_previous_order is null then 'First Order'
        when o.days_since_previous_order <= 7 then 'Quick Reorder'
        when o.days_since_previous_order <= 30 then 'Regular Reorder'
        when o.days_since_previous_order <= 90 then 'Slow Reorder'
        else 'Long Gap Reorder'
    end as reorder_velocity,
    
    -- Business success indicators
    case
        when o.status = 'completed' and p.total_amount > 0 then 'Successful'
        when o.status in ('returned', 'return_pending') then 'Problematic'
        when p.total_amount = 0 then 'Unpaid'
        else 'In Progress'
    end as order_outcome,
    
    -- Generate business surrogate key
    {{ dbt_utils.generate_surrogate_key(['o.order_id', 'o.order_date']) }} as order_analytics_key

from customer_order_context o
left join order_payments p using (order_id)
