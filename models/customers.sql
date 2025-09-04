{{ 
  config(
    materialized='table',
    indexes=[
      {'columns': ['customer_id'], 'unique': true},
      {'columns': ['customer_segment']}
    ]
  ) 
}}

-- ================================================================
-- 🎯 Demo 目的：展示 dbt_utils 函數與進階資料轉換
-- 此模型展示以下核心 dbt 概念：
-- 1. 使用 dbt_utils 函數進行資料品質控制與轉換
-- 2. 實作客戶分群的商業邏輯
-- 3. 文件撰寫與最佳實務範例
-- ================================================================

{% set payment_methods = dbt_utils.get_column_values(ref('stg_payments'), 'payment_method') %}

with customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

payments as (

    select * from {{ ref('stg_payments') }}

),

-- Calculate order metrics per customer
customer_orders as (

    select
        customer_id,
        min(order_date) as first_order,
        max(order_date) as most_recent_order,
        count(order_id) as number_of_orders,
        
        -- Demo: Advanced date calculations (using standard SQL since DuckDB supports it)
        date_diff('day', min(order_date), max(order_date)) as customer_lifespan_days,
        
        -- Demo: Calculate order frequency
        case 
            when count(order_id) = 0 then 0
            when date_diff('day', min(order_date), max(order_date)) = 0 then 1
            else round(
                count(order_id)::float / 
                date_diff('day', min(order_date), max(order_date))::float * 30, 2
            )
        end as avg_orders_per_month

    from orders
    group by customer_id

),

-- Calculate payment metrics per customer with dynamic payment method breakdown
customer_payments as (

    select
        orders.customer_id,
        sum(payments.amount) as total_amount,
        count(distinct payments.payment_id) as number_of_payments,
        
        -- Demo: Dynamic payment method columns using dbt_utils.get_column_values
        {% for payment_method in payment_methods %}
        sum(case when payments.payment_method = '{{ payment_method }}' then payments.amount else 0 end) as {{ payment_method }}_amount,
        {% endfor %}
        
        -- Demo: Calculate most used payment method per customer
        -- (We'll calculate this in the final select for simplicity)

    from payments
    left join orders on payments.order_id = orders.order_id
    group by orders.customer_id

),

-- Demo: Customer segmentation with business logic
customer_segments as (

    select 
        *,
        -- Demo: Generate business surrogate key
        {{ dbt_utils.generate_surrogate_key(['customer_id', 'first_order']) }} as customer_business_key,
        
        -- Demo: Customer value segmentation
        case 
            when customer_lifetime_value >= 200 then 'High Value'
            when customer_lifetime_value >= 100 then 'Medium Value'
            when customer_lifetime_value > 0 then 'Low Value'
            else 'No Purchase'
        end as customer_segment,
        
        -- Demo: Customer activity status
        case 
            when number_of_orders = 0 then 'Inactive'
            when avg_orders_per_month >= 2 then 'Very Active'
            when avg_orders_per_month >= 1 then 'Active' 
            when avg_orders_per_month >= 0.5 then 'Regular'
            else 'Occasional'
        end as activity_level,
        
        -- Demo: Recency analysis (days since last order)  
        date_diff('day', most_recent_order, current_date) as days_since_last_order,
        
        -- Demo: Risk assessment
        case 
            when date_diff('day', most_recent_order, current_date) > 365 then 'High Churn Risk'
            when date_diff('day', most_recent_order, current_date) > 180 then 'Medium Churn Risk'
            when date_diff('day', most_recent_order, current_date) > 90 then 'Low Churn Risk'
            else 'Active'
        end as churn_risk

    from (
        select
            customers.customer_id,
            -- Demo: Safe string concatenation (using standard SQL cast)
            cast(customers.first_name as varchar) || ' ' || 
            cast(customers.last_name as varchar) as full_name,
            customers.first_name,
            customers.last_name,
            
            coalesce(customer_orders.first_order, '1900-01-01') as first_order,
            customer_orders.most_recent_order,
            coalesce(customer_orders.number_of_orders, 0) as number_of_orders,
            coalesce(customer_orders.customer_lifespan_days, 0) as customer_lifespan_days,
            coalesce(customer_orders.avg_orders_per_month, 0) as avg_orders_per_month,
            coalesce(customer_payments.total_amount, 0) as customer_lifetime_value,
            coalesce(customer_payments.number_of_payments, 0) as number_of_payments,
            
            {% for payment_method in payment_methods %}
            coalesce(customer_payments.{{ payment_method }}_amount, 0) as {{ payment_method }}_amount,
            {% endfor %}
            
            -- Demo: We'll calculate preferred payment method dynamically
            case
                {% for payment_method in payment_methods %}
                when customer_payments.{{ payment_method }}_amount = greatest(
                    {% for pm in payment_methods %}
                    coalesce(customer_payments.{{ pm }}_amount, 0){{ ',' if not loop.last }}
                    {% endfor %}
                ) then '{{ payment_method }}'
                {% endfor %}
                else 'unknown'
            end as preferred_payment_method

        from customers
        left join customer_orders using (customer_id)
        left join customer_payments using (customer_id)
    )

)

-- Demo: Final output with rich business context
select 
    customer_id,
    customer_business_key,
    full_name,
    first_name,
    last_name,
    first_order,
    most_recent_order,
    number_of_orders,
    customer_lifetime_value,
    customer_segment,
    activity_level,
    churn_risk,
    avg_orders_per_month,
    customer_lifespan_days,
    days_since_last_order,
    number_of_payments,
    preferred_payment_method,
    
    {% for payment_method in payment_methods %}
    {{ payment_method }}_amount,
    {% endfor %}
    
    -- Demo: Data quality indicator
    case 
        when first_name is null or last_name is null then 'Missing Name'
        when number_of_orders = 0 then 'No Orders'
        when customer_lifetime_value = 0 then 'No Payments'
        else 'Complete'
    end as data_quality_status

from customer_segments
