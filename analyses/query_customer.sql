-- Customer Behavior Analysis: Exploratory Query
-- This analysis is used to analyze customer purchase behavior patterns and trends
-- Unlike the customers model, this is an ad-hoc query for exploratory analysis
-- 
-- Note: Customer segmentation thresholds aligned with customers.sql model:
-- - High Value: ≥$60 (VIP customers, top tier)
-- - Medium Value: $30-59 (growth potential customers)  
-- - Low Value: $1-29 (basic customer segment)
-- - No Purchase: $0 (inactive users)

with customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

payments as (

    select * from {{ ref('stg_payments') }}

),

-- Calculate purchase frequency analysis for each customer
customer_purchase_frequency as (

    select
        customer_id,
        count(order_id) as total_orders,
        count(distinct date_trunc('month', order_date)) as active_months,
        -- Calculate average orders per month
        round(count(order_id)::float / nullif(count(distinct date_trunc('month', order_date)), 0), 2) as avg_orders_per_month,
        -- Calculate average days between purchases
        round(
            (max(order_date) - min(order_date))::float / nullif(count(order_id) - 1, 0), 1
        ) as avg_days_between_orders
    from orders
    group by customer_id

),

-- Analyze customer payment preferences
customer_payment_preferences as (

    select
        orders.customer_id,
        payments.payment_method,
        count(*) as payment_count,
        sum(amount) as total_amount_by_method,
        round(avg(amount), 2) as avg_amount_by_method
    from payments
    left join orders on payments.order_id = orders.order_id
    group by orders.customer_id, payments.payment_method

),

-- Customer value tier analysis (aligned with customers.sql segmentation)
customer_value_tiers as (

    select
        customer_id,
        sum(amount) as total_spent,
        case 
            when sum(amount) >= 60 then 'High Value Customer'
            when sum(amount) >= 30 then 'Medium Value Customer'
            when sum(amount) > 0 then 'Low Value Customer'
            else 'No Purchase Customer'
        end as customer_tier
    from payments
    left join orders on payments.order_id = orders.order_id
    group by customer_id

),

-- Customer activity analysis
customer_activity_analysis as (

    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customer_purchase_frequency.total_orders,
        customer_purchase_frequency.active_months,
        customer_purchase_frequency.avg_orders_per_month,
        customer_purchase_frequency.avg_days_between_orders,
        customer_value_tiers.total_spent,
        customer_value_tiers.customer_tier,
        -- Calculate customer activity score
        case 
            when customer_purchase_frequency.avg_orders_per_month >= 2 then 'Very Active'
            when customer_purchase_frequency.avg_orders_per_month >= 1 then 'Active'
            when customer_purchase_frequency.avg_orders_per_month >= 0.5 then 'Regular'
            else 'Inactive'
        end as activity_level,
        -- Calculate days since last order
        datediff('day', max(orders.order_date), current_date) as days_since_last_order
    from customers
    left join customer_purchase_frequency 
        on customers.customer_id = customer_purchase_frequency.customer_id
    left join customer_value_tiers 
        on customers.customer_id = customer_value_tiers.customer_id
    left join orders 
        on customers.customer_id = orders.customer_id
    group by 
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customer_purchase_frequency.total_orders,
        customer_purchase_frequency.active_months,
        customer_purchase_frequency.avg_orders_per_month,
        customer_purchase_frequency.avg_days_between_orders,
        customer_value_tiers.total_spent,
        customer_value_tiers.customer_tier

)

-- Final query: Comprehensive customer behavior analysis
select 
    customer_id,
    first_name,
    last_name,
    total_orders,
    active_months,
    avg_orders_per_month,
    avg_days_between_orders,
    total_spent,
    customer_tier,
    activity_level,
    days_since_last_order,
    -- Risk assessment: High-value customers who haven't purchased recently (aligned with customers.sql)
    case 
        when customer_tier = 'High Value Customer' and days_since_last_order > 365 then 'High Churn Risk'
        when customer_tier = 'High Value Customer' and days_since_last_order > 180 then 'Medium Churn Risk'
        when customer_tier = 'High Value Customer' and days_since_last_order > 90 then 'Low Churn Risk'
        when customer_tier = 'Medium Value Customer' and days_since_last_order > 180 then 'Medium Churn Risk'
        when customer_tier = 'Medium Value Customer' and days_since_last_order > 90 then 'Low Churn Risk'
        when days_since_last_order > 90 then 'Low Churn Risk'
        else 'Active'
    end as retention_risk
from customer_activity_analysis
order by total_spent desc, days_since_last_order asc
